<?php

namespace Tests\Feature;

use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopTelegramFlowTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
        config()->set('services.telegram.bot_token', 'test-token');
    }

    protected function tearDown(): void
    {
        Http::preventStrayRequests(false);
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_owner_can_link_telegram_and_new_booking_triggers_message(): void
    {
        $this->post('/owner/login', [
            'workshopId' => 'w-1',
            'accessCode' => '5252',
        ])->assertRedirect('/owner/bookings');

        $this->post('/owner/telegram/generate')
            ->assertRedirect();

        $workshop = app(UstaTopRepository::class)->workshopById('w-1');
        $code = (string) ($workshop['telegramLinkCode'] ?? '');
        $this->assertNotSame('', $code);

        Http::fake([
            'https://api.telegram.org/*/getUpdates*' => Http::response([
                'ok' => true,
                'result' => [[
                    'update_id' => 1,
                    'message' => [
                        'text' => '/start '.$code,
                        'chat' => [
                            'id' => 99887766,
                            'username' => 'usta_top_owner',
                        ],
                    ],
                ]],
            ], 200),
            'https://api.telegram.org/*/sendMessage' => Http::response([
                'ok' => true,
                'result' => ['message_id' => 1],
            ], 200),
        ]);

        $this->post('/owner/telegram/check')
            ->assertRedirect();

        $linkedWorkshop = app(UstaTopRepository::class)->workshopById('w-1');
        $this->assertSame('99887766', (string) ($linkedWorkshop['telegramChatId'] ?? ''));
        $this->assertSame('', (string) ($linkedWorkshop['telegramLinkCode'] ?? ''));

        $register = $this->postJson('/auth/register', [
            'fullName' => 'Telegram Flow',
            'phone' => '+99890'.random_int(1000000, 9999999),
            'password' => 'secret123',
        ])->assertOk();

        $token = (string) $register->json('data.token');
        $calendar = $this->getJson('/workshops/w-1/availability/calendar?serviceId=srv-1&from=2026-03-30&days=7')
            ->assertOk();

        $date = (string) $calendar->json('data.nearestAvailableDate');
        $time = (string) $calendar->json('data.nearestAvailableTime');

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/bookings', [
                'workshopId' => 'w-1',
                'serviceId' => 'srv-1',
                'vehicleBrand' => 'Chevrolet',
                'vehicleModelName' => 'Cobalt',
                'vehicleModel' => 'Chevrolet Cobalt',
                'catalogVehicleId' => 'chevrolet_cobalt',
                'isCustomVehicle' => false,
                'vehicleTypeId' => 'sedan',
                'dateTime' => $date.'T'.$time.':00Z',
                'paymentMethod' => 'cash',
            ])
            ->assertCreated();

        Http::assertSent(fn ($request) => str_contains($request->url(), '/sendMessage'));
    }
}
