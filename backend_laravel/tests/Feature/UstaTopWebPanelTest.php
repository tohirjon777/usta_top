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

    public function test_admin_and_owner_web_routes_are_not_publicly_accessible(): void
    {
        $this->get('/admin/login')->assertNotFound();
        $this->get('/owner/login')->assertNotFound();
        $this->get('/admin/workshops')->assertNotFound();
        $this->get('/owner/bookings')->assertNotFound();
    }

    public function test_customer_website_renders_public_workshops_and_detail_pages(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('Usta Top')
            ->assertSee('Ustaxonalar katalogi')
            ->assertSee('api-maps.yandex.ru/2.1/?apikey=test-yandex-key', false)
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
    }

    public function test_customer_can_register_manage_cards_and_book_from_website(): void
    {
        $this->get('/customer/login')
            ->assertOk()
            ->assertSee('Mijoz kabinetiga kiring');

        $this->post('/customer/register', [
            'fullName' => 'Web Mijoz',
            'phone' => '+998901234500',
            'password' => 'secret123',
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
}
