<?php

namespace Tests\Feature;

use App\Support\UstaTop\UstaTopRepository;
use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopApiFlowTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        CarbonImmutable::setTestNow();
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_customer_api_flow_works_end_to_end(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);

        $registerResponse = $this->postJson('/auth/register', [
            'fullName' => 'Laravel Flow',
            'phone' => $phone,
            'password' => 'secret123',
        ]);
        $registerResponse->assertOk();

        $token = (string) $registerResponse->json('data.token');
        $this->assertNotSame('', $token);

        $headers = ['Authorization' => 'Bearer '.$token];

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.phone', $phone);

        $this->getJson('/workshops')
            ->assertOk()
            ->assertJsonPath('data.1.id', 'w-1');

        $this->getJson('/workshops/w-1')
            ->assertOk()
            ->assertJsonPath('data.id', 'w-1');

        $this->getJson('/workshops/w-1/price-quote?serviceId=srv-1&vehicleBrand=Chevrolet&vehicleModelName=Cobalt&vehicleTypeId=sedan')
            ->assertOk()
            ->assertJsonPath('data.basePrice', 120);

        $calendarResponse = $this->getJson('/workshops/w-1/availability/calendar?serviceId=srv-1&from=2026-03-30&days=7');
        $calendarResponse->assertOk();

        $date = (string) $calendarResponse->json('data.nearestAvailableDate');
        $time = (string) $calendarResponse->json('data.nearestAvailableTime');
        $this->assertNotSame('', $date);
        $this->assertNotSame('', $time);

        $bookingDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$time,
            'Asia/Tashkent'
        )->utc()->toIso8601String();
        $bookingResponse = $this->withHeaders($headers)->postJson('/bookings', [
            'workshopId' => 'w-1',
            'serviceId' => 'srv-1',
            'vehicleBrand' => 'Chevrolet',
            'vehicleModelName' => 'Cobalt',
            'vehicleModel' => 'Chevrolet Cobalt',
            'catalogVehicleId' => 'chevrolet_cobalt',
            'isCustomVehicle' => false,
            'vehicleTypeId' => 'sedan',
            'dateTime' => $bookingDateTime,
            'paymentMethod' => 'cash',
        ]);
        $bookingResponse
            ->assertCreated()
            ->assertJsonPath('data.status', 'upcoming');

        $bookingId = (string) $bookingResponse->json('data.id');
        $this->assertNotSame('', $bookingId);

        $this->withHeaders($headers)
            ->postJson('/bookings/'.$bookingId.'/messages', ['text' => 'Salom, mashinani ertaroq olib kelsam bo‘ladimi?'])
            ->assertCreated()
            ->assertJsonPath('data.senderRole', 'customer');

        $this->withHeaders($headers)
            ->getJson('/bookings/'.$bookingId.'/messages')
            ->assertOk()
            ->assertJsonPath('data.0.bookingId', $bookingId);

        $availabilityResponse = $this->getJson('/workshops/w-1/availability?serviceId=srv-1&date='.$date);
        $availabilityResponse->assertOk();
        $slots = $availabilityResponse->json('data.slots');
        $this->assertIsArray($slots);

        $nextTime = collect($slots)
            ->first(fn ($slot) => $slot !== $time);
        $this->assertNotNull($nextTime);

        $rescheduledDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$nextTime,
            'Asia/Tashkent'
        )->utc()->toIso8601String();
        $this->withHeaders($headers)
            ->patchJson('/bookings/'.$bookingId.'/reschedule', [
                'dateTime' => $rescheduledDateTime,
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'rescheduled')
            ->assertJsonPath('data.rescheduledByRole', 'customer');

        app(UstaTopRepository::class)->updateBookingStatus($bookingId, 'completed', [
            'actorRole' => 'admin',
        ]);

        $reviewResponse = $this->withHeaders($headers)->postJson('/workshops/w-1/reviews', [
            'serviceId' => 'srv-1',
            'rating' => 5,
            'comment' => 'Juda yaxshi xizmat.',
            'bookingId' => $bookingId,
        ]);
        $reviewResponse->assertOk();

        $this->withHeaders($headers)
            ->getJson('/bookings')
            ->assertOk()
            ->assertJsonPath('data.0.reviewId', fn ($value) => is_string($value) && $value !== '');
    }

    public function test_today_availability_hides_past_slots_and_old_booking_is_rejected(): void
    {
        Carbon::setTestNow('2026-03-30 14:10:00');
        CarbonImmutable::setTestNow('2026-03-30 14:10:00');

        $phone = '+99890'.random_int(1000000, 9999999);
        $registerResponse = $this->postJson('/auth/register', [
            'fullName' => 'Time Guard',
            'phone' => $phone,
            'password' => 'secret123',
        ])->assertOk();

        $token = (string) $registerResponse->json('data.token');
        $headers = ['Authorization' => 'Bearer '.$token];

        $availabilityResponse = $this->getJson('/workshops/w-1/availability?serviceId=srv-1&date=2026-03-30')
            ->assertOk();

        $slots = $availabilityResponse->json('data.slots');
        $allSlots = $availabilityResponse->json('data.allSlots');
        $this->assertIsArray($slots);
        $this->assertIsArray($allSlots);
        $this->assertFalse(in_array('09:00', $slots, true));
        $this->assertFalse(in_array('13:30', $slots, true));
        $this->assertFalse(in_array('14:00', $slots, true));
        $this->assertSame('14:30', $slots[0] ?? null);
        $this->assertContains([
            'time' => '09:00',
            'isAvailable' => false,
            'reason' => 'past',
        ], $allSlots);
        $this->assertContains([
            'time' => '14:30',
            'isAvailable' => true,
            'reason' => 'available',
        ], $allSlots);

        $pastBookingDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i:s',
            '2026-03-30 10:00:00',
            'Asia/Tashkent'
        )->utc()->toIso8601String();
        $this->withHeaders($headers)
            ->postJson('/bookings', [
                'workshopId' => 'w-1',
                'serviceId' => 'srv-1',
                'vehicleBrand' => 'Chevrolet',
                'vehicleModelName' => 'Cobalt',
                'vehicleModel' => 'Chevrolet Cobalt',
                'catalogVehicleId' => 'chevrolet_cobalt',
                'isCustomVehicle' => false,
                'vehicleTypeId' => 'sedan',
                'dateTime' => $pastBookingDateTime,
                'paymentMethod' => 'cash',
            ])
            ->assertStatus(400)
            ->assertJsonPath('error', 'Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
    }

    public function test_customer_can_accept_rescheduled_booking_from_workshop_side(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);

        $registerResponse = $this->postJson('/auth/register', [
            'fullName' => 'Accept Flow',
            'phone' => $phone,
            'password' => 'secret123',
        ]);
        $registerResponse->assertOk();

        $token = (string) $registerResponse->json('data.token');
        $headers = ['Authorization' => 'Bearer '.$token];

        $calendarResponse = $this->getJson('/workshops/w-1/availability/calendar?serviceId=srv-1&from=2026-03-30&days=7');
        $calendarResponse->assertOk();

        $date = (string) $calendarResponse->json('data.nearestAvailableDate');
        $time = (string) $calendarResponse->json('data.nearestAvailableTime');
        $bookingDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$time,
            'Asia/Tashkent'
        )->utc()->toIso8601String();

        $bookingResponse = $this->withHeaders($headers)->postJson('/bookings', [
            'workshopId' => 'w-1',
            'serviceId' => 'srv-1',
            'vehicleBrand' => 'Chevrolet',
            'vehicleModelName' => 'Cobalt',
            'vehicleModel' => 'Chevrolet Cobalt',
            'catalogVehicleId' => 'chevrolet_cobalt',
            'isCustomVehicle' => false,
            'vehicleTypeId' => 'sedan',
            'dateTime' => $bookingDateTime,
            'paymentMethod' => 'cash',
        ]);
        $bookingResponse->assertCreated();

        $bookingId = (string) $bookingResponse->json('data.id');

        $availabilityResponse = $this->getJson('/workshops/w-1/availability?serviceId=srv-1&date='.$date);
        $availabilityResponse->assertOk();

        $nextTime = collect($availabilityResponse->json('data.slots'))
            ->first(fn ($slot) => $slot !== $time);
        $this->assertNotNull($nextTime);

        $rescheduledDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$nextTime,
            'Asia/Tashkent'
        )->utc()->toIso8601String();

        app(UstaTopRepository::class)->updateBookingStatus($bookingId, 'rescheduled', [
            'actorRole' => 'admin',
            'scheduledAt' => $rescheduledDateTime,
        ]);

        $this->withHeaders($headers)
            ->patchJson('/bookings/'.$bookingId.'/accept-reschedule')
            ->assertOk()
            ->assertJsonPath('data.status', 'accepted')
            ->assertJsonPath('data.acceptedAt', fn ($value) => is_string($value) && $value !== '')
            ->assertJsonPath('data.rescheduledByRole', 'admin');
    }

    public function test_customer_can_manage_saved_payment_cards(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);

        $registerResponse = $this->postJson('/auth/register', [
            'fullName' => 'Card Flow',
            'phone' => $phone,
            'password' => 'secret123',
        ]);
        $registerResponse->assertOk();

        $token = (string) $registerResponse->json('data.token');
        $headers = ['Authorization' => 'Bearer '.$token];

        $createResponse = $this->withHeaders($headers)->postJson('/auth/me/cards', [
            'holderName' => 'Tokhirjon U',
            'cardNumber' => '8600123456789012',
            'expiryMonth' => 12,
            'expiryYear' => 2028,
            'isDefault' => true,
        ]);

        $createResponse
            ->assertOk()
            ->assertJsonPath('data.savedPaymentCards.0.brand', 'Uzcard')
            ->assertJsonPath('data.savedPaymentCards.0.last4', '9012')
            ->assertJsonPath('data.savedPaymentCards.0.isDefault', true);

        $cardId = (string) $createResponse->json('data.savedPaymentCards.0.id');
        $this->assertNotSame('', $cardId);

        $this->withHeaders($headers)->patchJson('/auth/me/cards/'.$cardId, [
            'holderName' => 'Tokhirjon Updated',
            'cardNumber' => '',
            'expiryMonth' => 1,
            'expiryYear' => 2029,
            'isDefault' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.savedPaymentCards.0.holderName', 'Tokhirjon Updated')
            ->assertJsonPath('data.savedPaymentCards.0.expiryMonth', 1)
            ->assertJsonPath('data.savedPaymentCards.0.expiryYear', 2029);

        $this->withHeaders($headers)->deleteJson('/auth/me/cards/'.$cardId)
            ->assertOk()
            ->assertJsonPath('data.savedPaymentCards', []);
    }
}
