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
        app(UstaTopRepository::class)->updateWorkshop('w-1', [
            'telegramChatId' => '99887766',
            'telegramChatLabel' => '@usta_top_owner',
            'telegramLinkCode' => '',
        ]);

        Http::fake([
            'https://api.telegram.org/*/sendMessage' => Http::response([
                'ok' => true,
            'result' => ['message_id' => 1],
        ], 200),
        ]);

        $token = $this->registerCustomerViaOtp('Telegram Flow', '+99890'.random_int(1000000, 9999999));
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
            ->assertCreated()
            ->assertJsonPath('data.status', 'upcoming');

        $bookingId = (string) $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/bookings')
            ->json('data.0.id');

        app(UstaTopRepository::class)->updateBookingStatus($bookingId, 'completed', [
            'actorRole' => 'admin',
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/workshops/w-1/reviews', [
                'serviceId' => 'srv-1',
                'rating' => 5,
                'comment' => 'Zo‘r xizmat, tez va toza ishlashdi.',
                'bookingId' => $bookingId,
            ])
            ->assertOk();

        Http::assertSent(fn ($request) => str_contains($request->url(), '/sendMessage'));
        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }

            $text = (string) ($request->data()['text'] ?? '');

            return str_contains($text, 'AutoMaster: yangi sharh qoldirildi')
                && str_contains($text, 'Sharh ID:');
        });
    }

    private function registerCustomerViaOtp(
        string $fullName,
        string $phone,
        string $password = 'secret123'
    ): string {
        $sendRegisterCode = $this->postJson('/auth/register/send-code', [
            'phone' => $phone,
        ]);
        $sendRegisterCode->assertOk();

        $code = (string) $sendRegisterCode->json('data.debugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        $verifyRegisterCode = $this->postJson('/auth/register/verify-code', [
            'fullName' => $fullName,
            'phone' => $phone,
            'password' => $password,
            'code' => $code,
        ]);
        $verifyRegisterCode->assertOk();

        return (string) $verifyRegisterCode->json('data.token');
    }
}
