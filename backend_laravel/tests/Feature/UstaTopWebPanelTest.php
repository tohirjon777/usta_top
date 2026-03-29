<?php

namespace Tests\Feature;

use App\Support\UstaTop\Money;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\VehiclePricingExcelService;
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
    }

    protected function tearDown(): void
    {
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_admin_and_owner_panels_cover_core_management_flow(): void
    {
        $this->get('/admin/login')
            ->assertOk()
            ->assertSee('Admin login');

        $this->post('/admin/login', [
            'username' => config('ustatop.admin_username'),
            'password' => config('ustatop.admin_password'),
        ])->assertRedirect('/admin/workshops');

        $this->followingRedirects()
            ->get('/admin/workshops')
            ->assertOk()
            ->assertSee('Ustaxonalar');

        $this->get('/admin/analytics')
            ->assertOk()
            ->assertSee('Statistika')
            ->assertSee('Jami zakazlar')
            ->assertSee('Top xizmatlar');

        $this->get('/admin/analytics/export.csv?range=30d')
            ->assertOk()
            ->assertHeader('content-type', 'text/csv; charset=UTF-8')
            ->assertSee('booking_id')
            ->assertSee('Turbo Usta Servis');

        $this->get('/admin/workshops/w-1/vehicle-pricing/template.xlsx')
            ->assertOk()
            ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        $this->post('/admin/workshops', [
            'name' => 'Laravel Ustaxona',
            'master' => 'Bek Usta',
            'address' => 'Sergeli',
            'description' => 'Sinov uchun yaratilgan ustaxona',
            'badge' => 'Tez servis',
            'imageUrl' => 'https://example.com/workshop-cover.jpg',
            'latitude' => '41.300000',
            'longitude' => '69.250000',
            'startingPrice' => '150000',
            'ownerAccessCode' => '7878',
            'isOpen' => '1',
            'servicesText' => 'srv-l1|Diagnostika|150000|30|10',
        ])->assertRedirect('/admin/workshops');

        $createdWorkshop = collect(app(UstaTopRepository::class)->listWorkshops())
            ->first(fn (array $workshop): bool => ($workshop['name'] ?? '') === 'Laravel Ustaxona');

        $this->assertNotNull($createdWorkshop);
        $this->assertSame(150, (int) ($createdWorkshop['startingPrice'] ?? 0));
        $this->assertSame(
            'https://example.com/workshop-cover.jpg',
            (string) ($createdWorkshop['imageUrl'] ?? '')
        );
        $this->assertSame('7878', (string) ($createdWorkshop['ownerAccessCode'] ?? ''));

        $this->post('/owner/login', [
            'workshopId' => (string) ($createdWorkshop['id'] ?? ''),
            'accessCode' => '7878',
        ])->assertRedirect('/owner/bookings');

        $this->post('/admin/bookings/b-seed-1/status', [
            'bookingStatus' => 'accepted',
        ])->assertRedirect();

        $this->assertSame(
            'accepted',
            (string) (app(UstaTopRepository::class)->bookingById('b-seed-1')['status'] ?? '')
        );

        $this->get('/owner/login')
            ->assertOk()
            ->assertSee('Owner login');

        $this->post('/owner/login', [
            'workshopId' => 'w-1',
            'accessCode' => '5252',
        ])->assertRedirect('/owner/bookings');

        $this->followingRedirects()
            ->get('/owner/bookings')
            ->assertOk()
            ->assertSee('Zakazlar')
            ->assertSee(Money::formatUzs(120));

        $this->get('/owner/vehicle-pricing/template.xlsx')
            ->assertOk()
            ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        $this->post('/owner/services/srv-1/price', [
            'price' => '155000',
            'durationMinutes' => '45',
            'prepaymentPercent' => '20',
        ])->assertRedirect();

        $this->post('/owner/schedule', [
            'openingTime' => '08:30',
            'closingTime' => '20:00',
            'breakStartTime' => '13:00',
            'breakEndTime' => '14:00',
            'closedWeekdays' => ['7'],
        ])->assertRedirect();

        $workshopBeforeImport = app(UstaTopRepository::class)->workshopById('w-1');
        $workbookBinary = app(VehiclePricingExcelService::class)->buildWorkbook($workshopBeforeImport);
        $pricingFile = UploadedFile::fake()->createWithContent('pricing.xlsx', $workbookBinary);

        $this->post('/owner/vehicle-pricing/import', [
            'pricingFile' => $pricingFile,
        ])->assertRedirect();

        $this->post('/owner/workshop/image', [
            'imageUrl' => 'https://example.com/owner-updated.jpg',
        ])->assertRedirect();

        $workshop = app(UstaTopRepository::class)->workshopById('w-1');
        $service = collect($workshop['services'] ?? [])
            ->first(fn (array $item): bool => ($item['id'] ?? '') === 'srv-1');

        $this->assertNotNull($service);
        $this->assertSame(155, (int) ($service['price'] ?? 0));
        $this->assertSame(45, (int) ($service['durationMinutes'] ?? 0));
        $this->assertSame(20, (int) ($service['prepaymentPercent'] ?? 0));
        $this->assertSame('https://example.com/owner-updated.jpg', (string) ($workshop['imageUrl'] ?? ''));
        $this->assertSame('08:30', (string) ($workshop['schedule']['openingTime'] ?? ''));
        $this->assertGreaterThan(0, count($workshop['vehiclePricingRules'] ?? []));
        $this->assertSame('0002', (string) (app(UstaTopRepository::class)->workshopById('w-2')['ownerAccessCode'] ?? ''));
    }
}
