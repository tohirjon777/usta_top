<?php

namespace Tests\Feature;

use App\Support\UstaTop\JsonFileStore;
use App\Support\UstaTop\UstaTopRepository;
use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Illuminate\Http\UploadedFile;
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

        $token = $this->registerCustomerViaOtp('Laravel Flow', $phone);
        $this->assertNotSame('', $token);

        $headers = ['Authorization' => 'Bearer '.$token];

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.phone', $phone);

        $this->withHeaders($headers)
            ->post('/auth/me/avatar', [
                'avatar' => UploadedFile::fake()->image('avatar.png', 240, 240),
            ])
            ->assertOk()
            ->assertJsonPath('data.avatarUrl', fn ($value) => is_string($value) && str_contains($value, '/media/customers/'));

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

    public function test_workshop_api_responses_are_not_cached(): void
    {
        $response = $this->getJson('/workshops')->assertOk();
        $cacheControl = (string) $response->headers->get('Cache-Control');
        $this->assertStringContainsString('no-store', $cacheControl);
        $this->assertStringContainsString('no-cache', $cacheControl);
        $this->assertSame('no-cache', $response->headers->get('Pragma'));

        $detailResponse = $this->getJson('/workshops/w-1')->assertOk();
        $this->assertStringContainsString(
            'no-store',
            (string) $detailResponse->headers->get('Cache-Control')
        );
    }

    public function test_emergency_services_and_trial_cashback_flow(): void
    {
        $workshopsResponse = $this->getJson('/workshops')->assertOk();
        $serviceIds = collect($workshopsResponse->json('data.0.services'))
            ->pluck('id')
            ->all();
        $this->assertContains('emergency-tire-change', $serviceIds);
        $this->assertContains('emergency-fuel-delivery', $serviceIds);

        $phone = '+99890'.random_int(1000000, 9999999);
        $token = $this->registerCustomerViaOtp('Cashback Flow', $phone);
        $headers = ['Authorization' => 'Bearer '.$token];

        $calendarResponse = $this->getJson('/workshops/w-1/availability/calendar?serviceId=emergency-tire-change&from=2026-03-30&days=7');
        $calendarResponse->assertOk();
        $date = (string) $calendarResponse->json('data.nearestAvailableDate');
        $time = (string) $calendarResponse->json('data.nearestAvailableTime');
        $bookingDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$time,
            'Asia/Tashkent'
        )->utc()->toIso8601String();

        $payload = [
            'workshopId' => 'w-1',
            'serviceId' => 'emergency-tire-change',
            'vehicleBrand' => 'Chevrolet',
            'vehicleModelName' => 'Cobalt',
            'vehicleModel' => 'Chevrolet Cobalt',
            'catalogVehicleId' => 'chevrolet_cobalt',
            'isCustomVehicle' => false,
            'vehicleTypeId' => 'sedan',
            'dateTime' => $bookingDateTime,
            'paymentMethod' => 'test_card',
        ];

        $this->withHeaders($headers)
            ->postJson('/bookings', $payload)
            ->assertStatus(400)
            ->assertJsonPath('error', 'Test karta bilan to‘lash uchun avval kartani kiriting');

        $this->withHeaders($headers)
            ->postJson('/auth/me/cards', [
                'holderName' => 'Cashback Flow',
                'cardNumber' => '8600123412341234',
                'expiryMonth' => 12,
                'expiryYear' => 2030,
                'isDefault' => true,
            ])
            ->assertOk();

        $bookingResponse = $this->withHeaders($headers)->postJson('/bookings', $payload);
        $bookingResponse
            ->assertCreated()
            ->assertJsonPath('data.serviceId', 'emergency-tire-change')
            ->assertJsonPath('data.paymentStatus', 'paid')
            ->assertJsonPath('data.cashbackPercent', 5)
            ->assertJsonPath('data.cashbackStatus', 'pending_completion');

        $bookingId = (string) $bookingResponse->json('data.id');
        $cashbackAmount = (int) $bookingResponse->json('data.cashbackAmount');
        $this->assertGreaterThan(0, $cashbackAmount);

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.cashbackBalance', 0)
            ->assertJsonPath('data.cashbackEarnedTotal', 0)
            ->assertJsonCount(0, 'data.cashbackTransactions');

        app(UstaTopRepository::class)->updateBookingStatus($bookingId, 'completed', [
            'actorRole' => 'owner',
        ]);

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.cashbackBalance', $cashbackAmount)
            ->assertJsonPath('data.cashbackEarnedTotal', $cashbackAmount)
            ->assertJsonPath('data.cashbackTransactions.0.type', 'earned')
            ->assertJsonPath('data.cashbackTransactions.0.amount', $cashbackAmount)
            ->assertJsonPath('data.cashbackTransactions.0.bookingId', $bookingId);

        $nextCalendarResponse = $this->getJson('/workshops/w-1/availability/calendar?serviceId=emergency-fuel-delivery&from=2026-03-30&days=7');
        $nextCalendarResponse->assertOk();
        $nextDate = (string) $nextCalendarResponse->json('data.nearestAvailableDate');
        $nextTime = (string) $nextCalendarResponse->json('data.nearestAvailableTime');
        $nextBookingDateTime = CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $nextDate.' '.$nextTime,
            'Asia/Tashkent'
        )->utc()->toIso8601String();

        $nextPayload = $payload;
        $nextPayload['serviceId'] = 'emergency-fuel-delivery';
        $nextPayload['dateTime'] = $nextBookingDateTime;
        $nextPayload['paymentMethod'] = 'cash';

        $nextBookingResponse = $this->withHeaders($headers)->postJson('/bookings', $nextPayload);
        $nextBookingResponse
            ->assertCreated()
            ->assertJsonPath('data.serviceId', 'emergency-fuel-delivery')
            ->assertJsonPath('data.cashbackAppliedAmount', $cashbackAmount)
            ->assertJsonPath('data.cashbackAppliedStatus', 'applied');
        $this->assertSame(
            (int) $nextBookingResponse->json('data.originalPrice') - $cashbackAmount,
            (int) $nextBookingResponse->json('data.price')
        );

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.cashbackBalance', 0)
            ->assertJsonPath('data.cashbackEarnedTotal', $cashbackAmount)
            ->assertJsonPath('data.cashbackTransactions.0.type', 'redeemed')
            ->assertJsonPath('data.cashbackTransactions.0.amount', -$cashbackAmount)
            ->assertJsonPath('data.cashbackTransactions.0.bookingId', (string) $nextBookingResponse->json('data.id'));

        $this->withHeaders($headers)
            ->patchJson('/bookings/'.((string) $nextBookingResponse->json('data.id')).'/cancel')
            ->assertOk()
            ->assertJsonPath('data.cashbackAppliedStatus', 'refunded');

        $this->withHeaders($headers)
            ->getJson('/auth/me')
            ->assertOk()
            ->assertJsonPath('data.cashbackBalance', $cashbackAmount)
            ->assertJsonPath('data.cashbackEarnedTotal', $cashbackAmount)
            ->assertJsonPath('data.cashbackTransactions.0.type', 'refunded')
            ->assertJsonPath('data.cashbackTransactions.0.amount', $cashbackAmount)
            ->assertJsonCount(3, 'data.cashbackTransactions');
    }

    public function test_today_availability_hides_past_slots_and_old_booking_is_rejected(): void
    {
        Carbon::setTestNow('2026-03-30 14:10:00');
        CarbonImmutable::setTestNow('2026-03-30 14:10:00');

        $phone = '+99890'.random_int(1000000, 9999999);
        $token = $this->registerCustomerViaOtp('Time Guard', $phone);
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

        $token = $this->registerCustomerViaOtp('Accept Flow', $phone);
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

        $token = $this->registerCustomerViaOtp('Card Flow', $phone);
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

    public function test_sms_verification_flow_works_for_register_and_password_reset(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);

        $sendRegisterCode = $this->postJson('/auth/register/send-code', [
            'phone' => $phone,
        ]);
        $sendRegisterCode->assertOk();

        $registerCode = (string) $sendRegisterCode->json('data.debugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $registerCode);

        $verifyRegisterCode = $this->postJson('/auth/register/verify-code', [
            'fullName' => 'SMS Register',
            'phone' => $phone,
            'password' => 'secret123',
            'code' => $registerCode,
        ]);
        $verifyRegisterCode
            ->assertOk()
            ->assertJsonPath('data.user.phone', $phone);

        $token = (string) $verifyRegisterCode->json('data.token');
        $this->assertNotSame('', $token);

        $loginResponse = $this->postJson('/auth/login', [
            'phone' => $phone,
            'password' => 'secret123',
        ]);
        $loginResponse->assertOk();

        $sendResetCode = $this->postJson('/auth/password/send-code', [
            'phone' => $phone,
        ]);
        $sendResetCode->assertOk();

        $resetCode = (string) $sendResetCode->json('data.debugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $resetCode);

        $this->postJson('/auth/password/verify-code', [
            'phone' => $phone,
            'newPassword' => 'newsecret123',
            'code' => $resetCode,
        ])->assertOk();

        $this->postJson('/auth/login', [
            'phone' => $phone,
            'password' => 'newsecret123',
        ])->assertOk();
    }

    public function test_direct_auth_mutations_require_verification_code(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);

        $this->postJson('/auth/register', [
            'fullName' => 'No Code',
            'phone' => $phone,
            'password' => 'secret123',
        ])
            ->assertStatus(400)
            ->assertJsonPath('error', 'Tasdiqlash kodi kerak. Avval /auth/register/send-code orqali SMS kod oling');

        $this->registerCustomerViaOtp('Reset Guard', $phone);

        $this->postJson('/auth/forgot-password', [
            'phone' => $phone,
            'newPassword' => 'newsecret123',
        ])
            ->assertStatus(400)
            ->assertJsonPath('error', 'Tasdiqlash kodi kerak. Avval /auth/password/send-code orqali SMS kod oling');
    }

    public function test_passwords_are_hashed_and_legacy_plaintext_passwords_are_upgraded_on_login(): void
    {
        $phone = '+99890'.random_int(1000000, 9999999);
        $this->registerCustomerViaOtp('Hash Flow', $phone);

        $store = app(JsonFileStore::class);
        $usersPath = (string) config('ustatop.users_file');
        $users = $store->readArray($usersPath, []);
        $registeredUser = collect($users)->first(fn (array $user): bool => ($user['phone'] ?? '') === $phone);

        $this->assertIsArray($registeredUser);
        $this->assertNotSame('secret123', (string) ($registeredUser['password'] ?? ''));
        $this->assertTrue(password_verify('secret123', (string) ($registeredUser['password'] ?? '')));

        $users[] = [
            'id' => 'u-legacy-1',
            'fullName' => 'Legacy User',
            'phone' => '+998900000222',
            'password' => 'legacy123',
            'avatarUrl' => '',
            'pushTokens' => [],
            'savedVehicles' => [],
            'paymentCards' => [],
        ];
        $store->writeArray($usersPath, $users);

        $this->postJson('/auth/login', [
            'phone' => '+998900000222',
            'password' => 'legacy123',
        ])->assertOk();

        $upgradedUsers = $store->readArray($usersPath, []);
        $legacyUser = collect($upgradedUsers)->first(fn (array $user): bool => ($user['id'] ?? '') === 'u-legacy-1');

        $this->assertIsArray($legacyUser);
        $this->assertNotSame('legacy123', (string) ($legacyUser['password'] ?? ''));
        $this->assertTrue(password_verify('legacy123', (string) ($legacyUser['password'] ?? '')));
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

        $registerCode = (string) $sendRegisterCode->json('data.debugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $registerCode);

        $verifyRegisterCode = $this->postJson('/auth/register/verify-code', [
            'fullName' => $fullName,
            'phone' => $phone,
            'password' => $password,
            'code' => $registerCode,
        ]);
        $verifyRegisterCode->assertOk();

        return (string) $verifyRegisterCode->json('data.token');
    }
}
