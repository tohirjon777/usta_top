<?php

namespace Tests\Feature;

use App\Support\UstaTop\UstaTopRepository;
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

        $bookingDateTime = CarbonImmutable::parse($date.' '.$time, 'UTC')->toIso8601String();
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

        $rescheduledDateTime = CarbonImmutable::parse($date.' '.$nextTime, 'UTC')->toIso8601String();
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
}
