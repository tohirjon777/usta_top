<?php

namespace Tests\Feature;

use App\Support\UstaTop\UstaTopRepository;
use Carbon\CarbonImmutable;
use Illuminate\Http\UploadedFile;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopWebPanelTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
        config()->set('services.yandex_maps.js_api_key', 'test-yandex-key');
    }

    protected function tearDown(): void
    {
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_admin_and_owner_login_pages_are_public_but_panels_require_authentication(): void
    {
        $this->get('/admin/login')
            ->assertOk()
            ->assertSee('Admin login');
        $this->get('/owner/login')
            ->assertOk()
            ->assertSee('Owner login');
        $this->get('/admin/workshops')->assertRedirect('/admin/login');
        $this->get('/owner/bookings')->assertRedirect('/owner/login');
    }

    public function test_customer_website_renders_public_workshops_and_detail_pages(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('AutoMaster')
            ->assertSee('Ustaxonalar katalogi')
            ->assertSee('api-maps.yandex.ru/2.1/?apikey=test-yandex-key', false)
            ->assertSee('id="mapPanel" class="map-panel is-hidden"', false)
            ->assertSee('Turbo Usta Servis');

        $this->get('/workshops')
            ->assertOk()
            ->assertHeader('content-type', 'application/json')
            ->assertSee('Turbo Usta Servis');

        $this->get('/workshop/w-1')
            ->assertOk()
            ->assertSee('Turbo Usta Servis')
            ->assertSee('Xizmatlar')
            ->assertSee('Yandex Maps’da ochish')
            ->assertSee('Lokatsiya');

        $this->get('/workshop/w-1?embedded=1')
            ->assertOk()
            ->assertSee('Turbo Usta Servis')
            ->assertSee('To‘liq sahifa')
            ->assertSee('Marshrut');

        $this->get('/account/delete')
            ->assertOk()
            ->assertSee('AutoMaster akkauntini o‘chirish')
            ->assertSee('Kirish va o‘chirish');
    }

    public function test_customer_can_register_manage_cards_and_book_from_website(): void
    {
        $this->get('/customer/login')
            ->assertOk()
            ->assertSee('Mijoz kabinetiga kiring');

        $registerStart = $this->post('/customer/register', [
            'fullName' => 'Web Mijoz',
            'phone' => '+998901234500',
            'password' => 'secret123',
        ]);
        $registerStart
            ->assertRedirect('/customer/login')
            ->assertSessionHas('registerDebugCode');

        $code = (string) session('registerDebugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        $this->post('/customer/register', [
            'code' => $code,
        ])->assertRedirect('/customer/account');

        $this->followingRedirects()
            ->get('/customer/account')
            ->assertOk()
            ->assertSee('Web Mijoz')
            ->assertSee('Mening bronlarim');

        $this->post('/customer/avatar', [
            'avatar' => UploadedFile::fake()->image('customer-avatar.png', 240, 240),
        ])->assertRedirect('/customer/account#profile');

        $this->followingRedirects()
            ->get('/customer/account')
            ->assertOk()
            ->assertSee('/media/customers/', false);

        $this->post('/customer/cards', [
            'brand' => 'Uzcard',
            'cardNumber' => '8600123412341234',
            'holderName' => 'Web Mijoz',
            'expiryMonth' => '12',
            'expiryYear' => '2029',
            'isDefault' => '1',
        ])->assertRedirect('/customer/account#cards');

        $auth = app(UstaTopRepository::class)->login('+998901234500', 'secret123');
        $this->assertNotNull($auth);
        $userId = (string) ($auth['user']['id'] ?? '');
        $this->assertNotSame('', $userId);

        $calendar = app(UstaTopRepository::class)->availabilityCalendar(
            'w-1',
            'srv-1',
            CarbonImmutable::now()->addDay()->startOfDay(),
            14
        );
        $this->assertNotNull($calendar['nearestAvailableDate']);
        $this->assertNotSame('', (string) $calendar['nearestAvailableTime']);

        $bookingDate = (string) $calendar['nearestAvailableDate'];
        $bookingTime = (string) $calendar['nearestAvailableTime'];

        $this->post('/customer/workshops/w-1/book', [
            'serviceId' => 'srv-1',
            'vehicleBrand' => 'Chevrolet',
            'vehicleModelName' => 'Cobalt',
            'vehicleTypeId' => 'sedan',
            'bookingDate' => $bookingDate,
            'bookingTime' => $bookingTime,
            'paymentMethod' => 'cash',
        ])->assertRedirect();

        $bookings = app(UstaTopRepository::class)->bookingsForUser($userId);
        $booking = collect($bookings)->first(fn (array $item): bool => ($item['customerPhone'] ?? '') === '+998901234500');
        $this->assertNotNull($booking);

        $this->post('/customer/bookings/'.urlencode((string) $booking['id']).'/messages', [
            'text' => 'Web sayt orqali yozilgan test xabar',
        ])->assertRedirect('/customer/account#booking-'.urlencode((string) $booking['id']));

        $availability = app(UstaTopRepository::class)->availability('w-1', 'srv-1', $bookingDate);
        $alternateTime = collect($availability['slots'])->first(fn (string $slot): bool => $slot !== $bookingTime);
        $this->assertNotNull($alternateTime);

        $this->post('/customer/bookings/'.urlencode((string) $booking['id']).'/reschedule', [
            'bookingDate' => $bookingDate,
            'bookingTime' => $alternateTime,
        ])->assertRedirect('/customer/account#booking-'.urlencode((string) $booking['id']));

        $this->post('/customer/bookings/'.urlencode((string) $booking['id']).'/accept-reschedule')
            ->assertRedirect('/customer/account#booking-'.urlencode((string) $booking['id']));

        app(UstaTopRepository::class)->updateBookingStatus((string) $booking['id'], 'completed');

        $this->post('/customer/workshops/w-1/reviews', [
            'bookingId' => (string) $booking['id'],
            'serviceId' => 'srv-1',
            'rating' => '5',
            'comment' => 'Web customer flow review',
        ])->assertRedirect('/customer/account#booking-'.urlencode((string) $booking['id']));

        $this->followingRedirects()
            ->get('/customer/account')
            ->assertOk()
            ->assertSee('Uzcard')
            ->assertSee('Web sayt orqali yozilgan test xabar')
            ->assertSee('Ko‘chirdi: Mijoz')
            ->assertSee('Oldingi vaqt:');
    }

    public function test_customer_can_delete_account_from_public_web_page(): void
    {
        $this->post('/customer/login', [
            'phone' => '+998900000111',
            'password' => 'secret123',
        ])->assertRedirect();

        $this->get('/account/delete')
            ->assertOk()
            ->assertSee('Web orqali o‘chirish')
            ->assertSee('Akkauntni butunlay o‘chirish');

        $this->post('/customer/account/delete', [
            'confirm_delete' => '1',
        ])->assertRedirect('/account/delete');

        $this->followingRedirects()
            ->get('/account/delete')
            ->assertOk()
            ->assertSee('Akkauntingiz va shaxsiy ma’lumotlaringiz o‘chirildi')
            ->assertSee('Kirish va o‘chirish');

        $this->post('/customer/login', [
            'phone' => '+998900000111',
            'password' => 'secret123',
        ])->assertRedirect('/customer/login');
    }

    public function test_owner_can_update_workshop_location_from_panel_with_yandex_map(): void
    {
        $this->post('/owner/login', [
            'workshopId' => 'w-1',
            'accessCode' => '1111',
        ])->assertRedirect('/owner/bookings');

        $this->get('/owner/bookings')
            ->assertOk()
            ->assertSee('ownerWorkshopMap', false)
            ->assertSee('data-location-picker', false)
            ->assertSee('api-maps.yandex.ru/2.1/?apikey=test-yandex-key', false)
            ->assertSee('/owner/workshop/location', false)
            ->assertDontSee('Latitude')
            ->assertDontSee('Longitude');

        $this->post('/owner/workshop/location', [
            'address' => 'Toshkent, Chilonzor 12',
            'latitude' => '41.299500',
            'longitude' => '69.240100',
        ])->assertRedirect();

        $workshop = app(UstaTopRepository::class)->workshopById('w-1');
        $this->assertNotNull($workshop);
        $this->assertSame('Toshkent, Chilonzor 12', (string) ($workshop['address'] ?? ''));
        $this->assertSame(41.2995, (float) ($workshop['latitude'] ?? 0));
        $this->assertSame(69.2401, (float) ($workshop['longitude'] ?? 0));
    }

    public function test_owner_can_add_service_from_panel(): void
    {
        $this->post('/owner/login', [
            'workshopId' => 'w-1',
            'accessCode' => '1111',
        ])->assertRedirect('/owner/bookings');

        $this->get('/owner/bookings')
            ->assertOk()
            ->assertSee('Yangi xizmat qo‘shish')
            ->assertSee('/owner/services', false);

        $this->post('/owner/services', [
            'name' => 'Generator ta’miri',
            'price' => '250000',
            'durationMinutes' => '55',
            'prepaymentPercent' => '20',
        ])->assertRedirect('/owner/bookings');

        $workshop = app(UstaTopRepository::class)->workshopById('w-1');
        $this->assertNotNull($workshop);
        $service = collect($workshop['services'] ?? [])
            ->first(fn (array $item): bool => ($item['name'] ?? '') === 'Generator ta’miri');

        $this->assertNotNull($service);
        $this->assertStringStartsWith('srv-', (string) ($service['id'] ?? ''));
        $this->assertSame(250, (int) ($service['price'] ?? 0));
        $this->assertSame(55, (int) ($service['durationMinutes'] ?? 0));
        $this->assertSame(20, (int) ($service['prepaymentPercent'] ?? 0));

        $this->followingRedirects()
            ->get('/owner/bookings')
            ->assertOk()
            ->assertSee('Generator ta’miri');
    }

    public function test_admin_can_manage_workshop_location_from_map_picker(): void
    {
        $this->post('/admin/login', [
            'username' => 'admin',
            'password' => 'admin123',
        ])->assertRedirect('/admin/workshops');

        $this->get('/admin/workshops')
            ->assertOk()
            ->assertSee('adminWorkshopCreateMap', false)
            ->assertSee('data-location-picker', false)
            ->assertSee('api-maps.yandex.ru/2.1/?apikey=test-yandex-key', false)
            ->assertDontSee('Latitude')
            ->assertDontSee('Longitude');

        $this->post('/admin/workshops', [
            'name' => 'Map Picker Workshop',
            'master' => 'Map Usta',
            'address' => 'Toshkent, Yunusobod 5',
            'description' => 'Yandex map bilan tanlangan lokatsiya.',
            'badge' => 'Map',
            'latitude' => '41.325500',
            'longitude' => '69.228800',
            'startingPrice' => '150000',
            'ownerAccessCode' => '5555',
            'telegramChatId' => '',
            'openingTime' => '09:00',
            'closingTime' => '19:00',
            'breakStartTime' => '13:00',
            'breakEndTime' => '14:00',
            'closedWeekdays' => '7',
            'isOpen' => '1',
            'servicesText' => '',
        ])->assertRedirect('/admin/workshops');

        $createdWorkshop = collect(app(UstaTopRepository::class)->listWorkshops())
            ->first(fn (array $workshop): bool => ($workshop['name'] ?? '') === 'Map Picker Workshop');

        $this->assertNotNull($createdWorkshop);
        $this->assertSame('Toshkent, Yunusobod 5', (string) ($createdWorkshop['address'] ?? ''));
        $this->assertSame(41.3255, (float) ($createdWorkshop['latitude'] ?? 0));
        $this->assertSame(69.2288, (float) ($createdWorkshop['longitude'] ?? 0));
    }
}
