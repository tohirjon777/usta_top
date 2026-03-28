<?php

namespace App\Support\UstaTop;

use Carbon\CarbonImmutable;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use RuntimeException;

class UstaTopRepository
{
    public function __construct(
        private readonly JsonFileStore $store,
    ) {
    }

    public function listWorkshops(): array
    {
        return array_map(
            fn (array $workshop): array => $this->normalizeWorkshop($workshop),
            $this->rawWorkshops()
        );
    }

    public function workshopById(string $workshopId): ?array
    {
        foreach ($this->rawWorkshops() as $workshop) {
            if (($workshop['id'] ?? '') === $workshopId) {
                return $this->normalizeWorkshop($workshop, includeReviews: true);
            }
        }

        return null;
    }

    public function workshopByOwnerAccess(string $workshopId, string $accessCode): ?array
    {
        foreach ($this->rawWorkshops() as $workshop) {
            if (($workshop['id'] ?? '') !== $workshopId) {
                continue;
            }

            if (trim((string) ($workshop['ownerAccessCode'] ?? '')) !== trim($accessCode)) {
                return null;
            }

            return $this->normalizeWorkshop($workshop, includeReviews: true);
        }

        return null;
    }

    public function createWorkshop(array $payload): array
    {
        $workshops = $this->rawWorkshops();
        $workshopId = $this->id('w');
        $workshop = $this->buildWorkshopPayload($payload, null, $workshopId);
        $workshops[] = $workshop;

        $this->saveWorkshops($workshops);
        $this->syncWorkshopLocation($workshop);

        return $this->normalizeWorkshop($workshop, includeReviews: true);
    }

    public function updateWorkshop(string $workshopId, array $payload): array
    {
        $workshops = $this->rawWorkshops();

        foreach ($workshops as $index => $workshop) {
            if (($workshop['id'] ?? '') !== $workshopId) {
                continue;
            }

            $next = $this->buildWorkshopPayload($payload, $workshop, $workshopId);
            $workshops[$index] = $next;
            $this->saveWorkshops($workshops);
            $this->syncWorkshopLocation($next);

            return $this->normalizeWorkshop($next, includeReviews: true);
        }

        throw new RuntimeException('Ustaxona topilmadi');
    }

    public function deleteWorkshop(string $workshopId): void
    {
        foreach ($this->rawBookings() as $booking) {
            if (($booking['workshopId'] ?? '') === $workshopId) {
                throw new RuntimeException('Bu ustaxonaga bog‘langan zakazlar bor, o‘chirib bo‘lmaydi');
            }
        }

        $workshops = array_values(array_filter(
            $this->rawWorkshops(),
            fn (array $workshop): bool => ($workshop['id'] ?? '') !== $workshopId
        ));
        $this->saveWorkshops($workshops);

        $locations = $this->store->readArray(config('ustatop.workshop_locations_file'));
        unset($locations[$workshopId]);
        $this->store->writeArray(config('ustatop.workshop_locations_file'), $locations);
    }

    public function authUserFromToken(?string $token): ?array
    {
        if (! $token) {
            return null;
        }

        foreach ($this->authSessions() as $session) {
            if (($session['token'] ?? '') !== $token) {
                continue;
            }

            return $this->userById((string) ($session['userId'] ?? ''));
        }

        return null;
    }

    public function createUser(string $fullName, string $phone, string $password): array
    {
        $normalizedPhone = trim($phone);
        foreach ($this->users() as $user) {
            if (($user['phone'] ?? '') === $normalizedPhone) {
                throw new RuntimeException('Bu telefon raqam bilan akkaunt allaqachon mavjud');
            }
        }

        $created = [
            'id' => $this->id('u'),
            'fullName' => trim($fullName),
            'phone' => $normalizedPhone,
            'password' => $password,
            'pushTokens' => [],
            'savedVehicles' => [],
        ];

        $users = $this->users();
        $users[] = $created;
        $this->saveUsers($users);

        return $created;
    }

    public function login(string $phone, string $password): ?array
    {
        foreach ($this->users() as $user) {
            if (($user['phone'] ?? '') !== trim($phone) || ($user['password'] ?? '') !== $password) {
                continue;
            }

            $token = 'token-'.Str::lower(Str::random(24));
            $sessions = $this->authSessions();
            $sessions[] = [
                'token' => $token,
                'userId' => $user['id'],
                'createdAt' => now()->toIso8601String(),
            ];
            $this->saveAuthSessions($sessions);

            return [
                'token' => $token,
                'user' => $this->publicUser($user),
            ];
        }

        return null;
    }

    public function resetPassword(string $phone, string $newPassword): void
    {
        $users = $this->users();
        foreach ($users as $index => $user) {
            if (($user['phone'] ?? '') !== trim($phone)) {
                continue;
            }

            $users[$index]['password'] = $newPassword;
            $this->saveUsers($users);
            $this->dropSessionsForUser((string) $user['id']);

            return;
        }

        throw new RuntimeException('Bu telefon raqam bilan akkaunt topilmadi');
    }

    public function updateUserProfile(string $userId, string $fullName, string $phone): array
    {
        $users = $this->users();
        $normalizedPhone = trim($phone);

        foreach ($users as $user) {
            if (($user['id'] ?? '') === $userId) {
                continue;
            }

            if (($user['phone'] ?? '') === $normalizedPhone) {
                throw new RuntimeException('Bu telefon raqam boshqa akkauntga biriktirilgan');
            }
        }

        foreach ($users as $index => $user) {
            if (($user['id'] ?? '') !== $userId) {
                continue;
            }

            $users[$index]['fullName'] = trim($fullName);
            $users[$index]['phone'] = $normalizedPhone;
            $this->saveUsers($users);

            return $this->publicUser($users[$index]);
        }

        throw new RuntimeException('Foydalanuvchi topilmadi');
    }

    public function changePassword(string $userId, string $currentPassword, string $newPassword): void
    {
        $users = $this->users();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? '') !== $userId) {
                continue;
            }

            if (($user['password'] ?? '') !== $currentPassword) {
                throw new RuntimeException('Joriy parol noto‘g‘ri');
            }

            $users[$index]['password'] = $newPassword;
            $this->saveUsers($users);
            $this->dropSessionsForUser($userId);

            return;
        }

        throw new RuntimeException('Foydalanuvchi topilmadi');
    }

    public function registerPushToken(string $userId, string $token, string $platform): void
    {
        $normalizedToken = trim($token);
        if ($normalizedToken === '') {
            throw new RuntimeException('Push token bo‘sh bo‘lmasligi kerak');
        }

        $users = $this->users();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? '') !== $userId) {
                continue;
            }

            $pushTokens = array_values($user['pushTokens'] ?? []);
            $nextTokens = [];
            $matched = false;

            foreach ($pushTokens as $item) {
                if (($item['token'] ?? '') === $normalizedToken) {
                    $item['platform'] = trim($platform);
                    $item['updatedAt'] = now()->toIso8601String();
                    $matched = true;
                }
                $nextTokens[] = $item;
            }

            if (! $matched) {
                $nextTokens[] = [
                    'token' => $normalizedToken,
                    'platform' => trim($platform),
                    'createdAt' => now()->toIso8601String(),
                    'updatedAt' => now()->toIso8601String(),
                ];
            }

            $users[$index]['pushTokens'] = $nextTokens;
            $this->saveUsers($users);

            return;
        }

        throw new RuntimeException('Foydalanuvchi topilmadi');
    }

    public function unregisterPushToken(string $userId, string $token): void
    {
        $normalizedToken = trim($token);

        $users = $this->users();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? '') !== $userId) {
                continue;
            }

            $users[$index]['pushTokens'] = array_values(array_filter(
                $user['pushTokens'] ?? [],
                fn (array $item): bool => ($item['token'] ?? '') !== $normalizedToken
            ));
            $this->saveUsers($users);

            return;
        }

        throw new RuntimeException('Foydalanuvchi topilmadi');
    }

    public function sendTestPush(string $userId): array
    {
        $user = $this->userById($userId);
        if (! $user) {
            throw new RuntimeException('Foydalanuvchi topilmadi');
        }

        return [
            'sent' => ! empty($user['pushTokens']),
            'tokens' => count($user['pushTokens'] ?? []),
            'message' => empty($user['pushTokens'])
                ? 'Push token hali ulanmagan'
                : 'Laravel test rejimida push qabul qilindi',
        ];
    }

    public function bookingsForUser(string $userId): array
    {
        $items = array_filter(
            $this->rawBookings(),
            fn (array $booking): bool => ($booking['userId'] ?? '') === $userId
        );

        usort($items, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values(array_map(
            fn (array $booking): array => $this->enrichBooking($booking),
            $items
        ));
    }

    public function bookingsForWorkshop(string $workshopId): array
    {
        $items = array_filter(
            $this->rawBookings(),
            fn (array $booking): bool => ($booking['workshopId'] ?? '') === $workshopId
        );

        usort($items, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values(array_map(
            fn (array $booking): array => $this->enrichBooking($booking),
            $items
        ));
    }

    public function bookingById(string $bookingId): ?array
    {
        foreach ($this->rawBookings() as $booking) {
            if (($booking['id'] ?? '') === $bookingId) {
                return $this->enrichBooking($booking);
            }
        }

        return null;
    }

    public function createBooking(array $user, array $payload): array
    {
        $workshopId = trim((string) ($payload['workshopId'] ?? ''));
        $serviceId = trim((string) ($payload['serviceId'] ?? ''));
        $vehicleBrand = trim((string) ($payload['vehicleBrand'] ?? ''));
        $vehicleModelName = trim((string) ($payload['vehicleModelName'] ?? ''));
        $vehicleModel = trim((string) ($payload['vehicleModel'] ?? ''));
        $catalogVehicleId = trim((string) ($payload['catalogVehicleId'] ?? ''));
        $vehicleTypeId = trim((string) ($payload['vehicleTypeId'] ?? 'sedan'));
        $dateTimeRaw = trim((string) ($payload['dateTime'] ?? ''));
        $paymentMethod = trim((string) ($payload['paymentMethod'] ?? 'cash'));
        $isCustomVehicle = ($payload['isCustomVehicle'] ?? false) === true;

        if ($workshopId === '' || $serviceId === '' || $dateTimeRaw === '') {
            throw new RuntimeException('workshopId, serviceId va dateTime kerak');
        }

        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Ustaxona topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $displayVehicle = trim($vehicleModel);
        if ($displayVehicle === '') {
            $displayVehicle = trim(implode(' ', array_filter([$vehicleBrand, $vehicleModelName])));
        }
        if ($displayVehicle === '') {
            throw new RuntimeException('Mashina modeli kerak');
        }

        $dateTime = CarbonImmutable::parse($dateTimeRaw);
        $availableSlots = $this->slotTimesForDate($workshop, $service, $dateTime->startOfDay(), null);
        if (! in_array($dateTime->format('H:i'), $availableSlots, true)) {
            throw new RuntimeException('Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
        }

        $quote = $this->computePriceQuote(
            $workshop,
            $service,
            $catalogVehicleId,
            $vehicleBrand,
            $vehicleModelName,
            $vehicleTypeId
        );
        $paymentStatus = $quote['prepaymentPercent'] > 0
            ? ($paymentMethod === 'test_card' ? 'paid' : 'pending')
            : 'not_required';

        $booking = [
            'id' => $this->id('b'),
            'userId' => $user['id'],
            'customerName' => $user['fullName'],
            'customerPhone' => $user['phone'],
            'workshopId' => $workshop['id'],
            'workshopName' => $workshop['name'],
            'masterName' => $workshop['master'] ?? '',
            'serviceId' => $service['id'],
            'serviceName' => $service['name'],
            'vehicleModel' => $displayVehicle,
            'vehicleTypeId' => $vehicleTypeId,
            'catalogVehicleId' => $catalogVehicleId,
            'vehicleBrand' => $vehicleBrand,
            'vehicleModelName' => $vehicleModelName,
            'isCustomVehicle' => $isCustomVehicle,
            'dateTime' => $dateTime->toIso8601String(),
            'basePrice' => $quote['basePrice'],
            'price' => $quote['price'],
            'status' => 'upcoming',
            'createdAt' => now()->toIso8601String(),
            'prepaymentPercent' => $quote['prepaymentPercent'],
            'prepaymentAmount' => $quote['prepaymentAmount'],
            'remainingAmount' => $quote['remainingAmount'],
            'paymentStatus' => $paymentStatus,
            'paymentMethod' => $paymentMethod,
            'paidAt' => $paymentStatus === 'paid' ? now()->toIso8601String() : null,
        ];

        $bookings = $this->rawBookings();
        $bookings[] = $booking;
        $this->saveBookings($bookings);

        $this->rememberVehicle(
            $user['id'],
            [
                'brand' => $vehicleBrand,
                'model' => $vehicleModelName !== '' ? $vehicleModelName : $displayVehicle,
                'vehicleTypeId' => $vehicleTypeId,
                'catalogVehicleId' => $catalogVehicleId,
                'isCustom' => $isCustomVehicle,
            ]
        );

        return $this->enrichBooking($booking);
    }

    public function cancelBookingForUser(string $userId, string $bookingId): array
    {
        return $this->mutateBooking($bookingId, function (array $booking) use ($userId): array {
            if (($booking['userId'] ?? '') !== $userId) {
                throw new RuntimeException('Buyurtma topilmadi');
            }

            $this->ensureMutableStatus($booking);

            $booking['status'] = 'cancelled';
            $booking['cancelReasonId'] = 'customer_request';
            $booking['cancelledByRole'] = 'customer';
            $booking['cancelledAt'] = now()->toIso8601String();
            $booking['completedAt'] = null;

            return $booking;
        });
    }

    public function rescheduleBookingForUser(string $userId, string $bookingId, string $dateTimeRaw): array
    {
        return $this->mutateBooking($bookingId, function (array $booking) use ($userId, $dateTimeRaw): array {
            if (($booking['userId'] ?? '') !== $userId) {
                throw new RuntimeException('Buyurtma topilmadi');
            }

            $this->ensureMutableStatus($booking);

            return $this->applyReschedule($booking, $dateTimeRaw, 'customer');
        });
    }

    public function updateBookingStatus(string $bookingId, string $status, array $options = []): array
    {
        return $this->mutateBooking($bookingId, function (array $booking) use ($status, $options): array {
            $normalizedStatus = trim($status);
            if (! in_array($normalizedStatus, ['accepted', 'rescheduled', 'completed', 'cancelled'], true)) {
                throw new RuntimeException('Noto‘g‘ri status');
            }

            if ($normalizedStatus === 'rescheduled') {
                $dateTimeRaw = trim((string) ($options['scheduledAt'] ?? ''));
                if ($dateTimeRaw === '') {
                    throw new RuntimeException('Ko‘chirish uchun yangi vaqtni tanlang');
                }

                return $this->applyReschedule(
                    $booking,
                    $dateTimeRaw,
                    (string) ($options['actorRole'] ?? 'admin')
                );
            }

            $booking['status'] = $normalizedStatus;

            if ($normalizedStatus === 'accepted') {
                $booking['completedAt'] = null;
                $booking['cancelReasonId'] = '';
                $booking['cancelledByRole'] = '';
                $booking['cancelledAt'] = null;
            }

            if ($normalizedStatus === 'completed') {
                $booking['completedAt'] = now()->toIso8601String();
                $booking['cancelReasonId'] = '';
                $booking['cancelledByRole'] = '';
                $booking['cancelledAt'] = null;
            }

            if ($normalizedStatus === 'cancelled') {
                $booking['cancelReasonId'] = (string) ($options['cancelReasonId'] ?? 'workshop_busy');
                $booking['cancelledByRole'] = (string) ($options['actorRole'] ?? 'admin');
                $booking['cancelledAt'] = now()->toIso8601String();
                $booking['completedAt'] = null;
            }

            return $booking;
        });
    }

    public function availability(string $workshopId, string $serviceId, string $date): array
    {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $day = CarbonImmutable::parse($date)->startOfDay();
        $schedule = $this->scheduleForWorkshop($workshop);
        $slots = $this->slotTimesForDate($workshop, $service, $day, null);

        return [
            'date' => $day->format('Y-m-d'),
            'slots' => $slots,
            'isClosedDay' => in_array($day->dayOfWeekIso, $schedule['closedWeekdays'], true),
            'serviceDurationMinutes' => max(30, (int) ($service['durationMinutes'] ?? 30)),
            'openingTime' => $schedule['openingTime'],
            'closingTime' => $schedule['closingTime'],
            'breakStartTime' => $schedule['breakStartTime'],
            'breakEndTime' => $schedule['breakEndTime'],
        ];
    }

    public function availabilityCalendar(
        string $workshopId,
        string $serviceId,
        CarbonImmutable $fromDate,
        int $days = 14
    ): array {
        $items = [];
        $nearestDate = null;
        $nearestTime = '';

        for ($offset = 0; $offset < $days; $offset++) {
            $day = $fromDate->addDays($offset)->startOfDay();
            $availability = $this->availability($workshopId, $serviceId, $day->format('Y-m-d'));
            $slotCount = count($availability['slots']);

            if ($nearestDate === null && $slotCount > 0) {
                $nearestDate = $day->format('Y-m-d');
                $nearestTime = $availability['slots'][0];
            }

            $items[] = [
                'date' => $day->format('Y-m-d'),
                'isClosedDay' => $availability['isClosedDay'],
                'slotCount' => $slotCount,
                'activeBookingCount' => $this->activeBookingCount($workshopId, $day),
                'isFullyBooked' => ! $availability['isClosedDay'] && $slotCount === 0,
                'firstSlot' => $slotCount > 0 ? $availability['slots'][0] : '',
            ];
        }

        return [
            'days' => $items,
            'nearestAvailableDate' => $nearestDate,
            'nearestAvailableTime' => $nearestTime,
        ];
    }

    public function suggestedRescheduleSlots(
        string $workshopId,
        string $serviceId,
        string $fromDateTimeRaw,
        string $excludeBookingId,
        int $days = 14,
        int $limit = 4
    ): array {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $threshold = CarbonImmutable::parse($fromDateTimeRaw)->setTimezone(config('app.timezone'));
        $startDate = $threshold->startOfDay();
        $suggestions = [];
        $safeDays = max(1, $days);
        $safeLimit = max(1, $limit);

        for ($dayIndex = 0; $dayIndex < $safeDays && count($suggestions) < $safeLimit; $dayIndex++) {
            $date = $startDate->addDays($dayIndex);
            $slots = $this->slotTimesForDate($workshop, $service, $date, $excludeBookingId);

            foreach ($slots as $slot) {
                [$hours, $minutes] = array_map('intval', explode(':', $slot));
                $slotDateTime = $date->setTime($hours, $minutes);
                if (! $slotDateTime->gt($threshold)) {
                    continue;
                }

                $suggestions[] = $slotDateTime->utc()->toIso8601String();
                if (count($suggestions) >= $safeLimit) {
                    break;
                }
            }
        }

        return $suggestions;
    }

    public function rescheduleSlotPage(
        string $workshopId,
        string $serviceId,
        string $fromDateTimeRaw,
        string $excludeBookingId,
        int $dayOffset = 0,
        int $days = 14,
        int $limit = 6
    ): array {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $threshold = CarbonImmutable::parse($fromDateTimeRaw)->setTimezone(config('app.timezone'));
        $startDate = $threshold->startOfDay();
        $safeMaxOffset = max(0, $days - 1);
        $requestedOffset = max(0, min($dayOffset, $safeMaxOffset));
        $resolvedOffset = $this->firstAvailableOffsetAtOrAfter(
            $workshop,
            $service,
            $threshold,
            $excludeBookingId,
            $requestedOffset,
            $safeMaxOffset,
        );

        $date = $startDate->addDays($resolvedOffset);
        $availability = $this->availability(
            (string) ($workshop['id'] ?? ''),
            (string) ($service['id'] ?? ''),
            $date->format('Y-m-d'),
        );

        $slots = [];
        foreach ($availability['slots'] as $slot) {
            [$hours, $minutes] = array_map('intval', explode(':', $slot));
            $slotDateTime = $date->setTime($hours, $minutes);
            if ($resolvedOffset === 0 && ! $slotDateTime->gt($threshold)) {
                continue;
            }
            $slots[] = $slotDateTime->utc()->toIso8601String();
            if (count($slots) >= max(1, $limit)) {
                break;
            }
        }

        return [
            'offset' => $resolvedOffset,
            'date' => $date->format('Y-m-d'),
            'slots' => $slots,
            'slotCount' => count($availability['slots']),
            'isClosedDay' => (bool) ($availability['isClosedDay'] ?? false),
            'isFullyBooked' => ! ($availability['isClosedDay'] ?? false) && count($availability['slots']) === 0,
            'prevOffset' => $this->previousAvailableOffset(
                $workshop,
                $service,
                $threshold,
                $excludeBookingId,
                $resolvedOffset,
            ),
            'nextOffset' => $this->nextAvailableOffset(
                $workshop,
                $service,
                $threshold,
                $excludeBookingId,
                $resolvedOffset,
                $safeMaxOffset,
            ),
        ];
    }

    public function priceQuote(
        string $workshopId,
        string $serviceId,
        string $catalogVehicleId = '',
        string $vehicleBrand = '',
        string $vehicleModelName = '',
        string $vehicleTypeId = ''
    ): array {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        return $this->computePriceQuote(
            $workshop,
            $service,
            $catalogVehicleId,
            $vehicleBrand,
            $vehicleModelName,
            $vehicleTypeId
        );
    }

    public function createReview(array $user, string $workshopId, array $payload): array
    {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $serviceId = trim((string) ($payload['serviceId'] ?? ''));
        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $bookingId = trim((string) ($payload['bookingId'] ?? ''));
        if ($bookingId !== '') {
            $booking = $this->bookingById($bookingId);
            if (! $booking || ($booking['userId'] ?? '') !== $user['id']) {
                throw new RuntimeException('Sharh uchun mos buyurtma topilmadi');
            }
            if (($booking['workshopId'] ?? '') !== $workshopId || ($booking['serviceId'] ?? '') !== $serviceId) {
                throw new RuntimeException('Sharh buyurtma xizmatiga mos emas');
            }
            if (($booking['status'] ?? '') !== 'completed') {
                throw new RuntimeException('Sharh qoldirish uchun buyurtma yakunlangan bo‘lishi kerak');
            }
            if (trim((string) ($booking['reviewId'] ?? '')) !== '') {
                throw new RuntimeException('Bu buyurtma uchun sharh allaqachon qoldirilgan');
            }
        }

        $review = [
            'id' => $this->id('r'),
            'workshopId' => $workshopId,
            'userId' => $user['id'],
            'customerName' => $user['fullName'],
            'serviceId' => $serviceId,
            'serviceName' => $service['name'],
            'rating' => max(1, min(5, (int) ($payload['rating'] ?? 5))),
            'comment' => trim((string) ($payload['comment'] ?? '')),
            'bookingId' => $bookingId,
            'createdAt' => now()->toIso8601String(),
            'ownerReply' => '',
            'ownerReplyAt' => null,
            'ownerReplySource' => '',
            'isHidden' => false,
        ];

        $reviews = $this->rawReviews();
        $reviews[] = $review;
        $this->saveReviews($reviews);

        if ($bookingId !== '') {
            $this->mutateBooking($bookingId, function (array $booking) use ($review): array {
                $booking['reviewId'] = $review['id'];
                $booking['reviewSubmittedAt'] = now()->toIso8601String();

                return $booking;
            });
        }

        $this->incrementWorkshopReviewStats($workshopId, $review['rating']);

        return $this->workshopById($workshopId)
            ?? throw new RuntimeException('Sharhdan keyin ustaxona topilmadi');
    }

    public function listAdminReviews(): array
    {
        $reviews = $this->rawReviews();
        usort($reviews, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values(array_map(function (array $review): array {
            $workshop = $this->workshopById((string) ($review['workshopId'] ?? ''));
            $review['workshopName'] = $workshop['name'] ?? '';

            return $review;
        }, $reviews));
    }

    public function setReviewHidden(string $reviewId, bool $hidden): array
    {
        $reviews = $this->rawReviews();
        foreach ($reviews as $index => $review) {
            if (($review['id'] ?? '') !== $reviewId) {
                continue;
            }

            $reviews[$index]['isHidden'] = $hidden;
            $this->saveReviews($reviews);

            return $reviews[$index];
        }

        throw new RuntimeException('Sharh topilmadi');
    }

    public function replyReview(string $reviewId, string $reply, string $source = 'owner_panel'): array
    {
        $normalizedReply = trim($reply);
        if ($normalizedReply === '') {
            throw new RuntimeException('Javob bo‘sh bo‘lmasligi kerak');
        }

        $reviews = $this->rawReviews();
        foreach ($reviews as $index => $review) {
            if (($review['id'] ?? '') !== $reviewId) {
                continue;
            }

            $reviews[$index]['ownerReply'] = $normalizedReply;
            $reviews[$index]['ownerReplyAt'] = now()->toIso8601String();
            $reviews[$index]['ownerReplySource'] = $source;
            $this->saveReviews($reviews);

            return $reviews[$index];
        }

        throw new RuntimeException('Sharh topilmadi');
    }

    public function fetchBookingMessagesForCustomer(string $userId, string $bookingId): array
    {
        $booking = $this->bookingById($bookingId);
        if (! $booking || ($booking['userId'] ?? '') !== $userId) {
            throw new RuntimeException('Buyurtma topilmadi');
        }

        $items = array_filter(
            $this->rawBookingMessages(),
            fn (array $message): bool => ($message['bookingId'] ?? '') === $bookingId
        );

        usort($items, fn (array $a, array $b): int => strcmp((string) ($a['createdAt'] ?? ''), (string) ($b['createdAt'] ?? '')));

        return array_values($items);
    }

    public function createBookingMessageForCustomer(array $user, string $bookingId, string $text): array
    {
        $booking = $this->bookingById($bookingId);
        if (! $booking || ($booking['userId'] ?? '') !== $user['id']) {
            throw new RuntimeException('Buyurtma topilmadi');
        }

        $normalizedText = trim($text);
        if ($normalizedText === '') {
            throw new RuntimeException('Xabar bo‘sh bo‘lmasligi kerak');
        }

        $messages = $this->rawBookingMessages();
        $message = [
            'id' => $this->id('m'),
            'bookingId' => $bookingId,
            'senderRole' => 'customer',
            'senderName' => $user['fullName'],
            'text' => $normalizedText,
            'createdAt' => now()->toIso8601String(),
            'readByCustomerAt' => now()->toIso8601String(),
            'readByOwnerAt' => null,
        ];
        $messages[] = $message;
        $this->saveBookingMessages($messages);

        return $message;
    }

    public function markBookingMessagesReadForCustomer(string $userId, string $bookingId): void
    {
        $booking = $this->bookingById($bookingId);
        if (! $booking || ($booking['userId'] ?? '') !== $userId) {
            throw new RuntimeException('Buyurtma topilmadi');
        }

        $messages = $this->rawBookingMessages();
        foreach ($messages as $index => $message) {
            if (($message['bookingId'] ?? '') !== $bookingId) {
                continue;
            }
            if (($message['senderRole'] ?? '') !== 'workshop_owner') {
                continue;
            }

            $messages[$index]['readByCustomerAt'] = now()->toIso8601String();
        }

        $this->saveBookingMessages($messages);
    }

    public function publicUser(array $user): array
    {
        return [
            'id' => $user['id'],
            'fullName' => $user['fullName'],
            'phone' => $user['phone'],
            'savedVehicles' => array_values($user['savedVehicles'] ?? []),
        ];
    }

    private function rawWorkshops(): array
    {
        return array_values($this->store->readArray(config('ustatop.workshops_file')));
    }

    private function rawBookings(): array
    {
        return array_values($this->store->readArray(config('ustatop.bookings_file')));
    }

    private function rawReviews(): array
    {
        return array_values($this->store->readArray(config('ustatop.reviews_file')));
    }

    private function rawBookingMessages(): array
    {
        return array_values($this->store->readArray(config('ustatop.booking_messages_file')));
    }

    private function authSessions(): array
    {
        return array_values($this->store->readArray(config('ustatop.auth_sessions_file')));
    }

    private function saveUsers(array $users): void
    {
        $this->store->writeArray(config('ustatop.users_file'), array_values($users));
    }

    private function saveBookings(array $bookings): void
    {
        $this->store->writeArray(config('ustatop.bookings_file'), array_values($bookings));
    }

    private function saveWorkshops(array $workshops): void
    {
        $this->store->writeArray(config('ustatop.workshops_file'), array_values($workshops));
    }

    private function saveReviews(array $reviews): void
    {
        $this->store->writeArray(config('ustatop.reviews_file'), array_values($reviews));
    }

    private function saveBookingMessages(array $messages): void
    {
        $this->store->writeArray(config('ustatop.booking_messages_file'), array_values($messages));
    }

    private function saveAuthSessions(array $sessions): void
    {
        $this->store->writeArray(config('ustatop.auth_sessions_file'), array_values($sessions));
    }

    private function users(): array
    {
        return array_values($this->store->readArray(config('ustatop.users_file')));
    }

    private function userById(string $userId): ?array
    {
        foreach ($this->users() as $user) {
            if (($user['id'] ?? '') === $userId) {
                $user['pushTokens'] = array_values($user['pushTokens'] ?? []);
                $user['savedVehicles'] = array_values($user['savedVehicles'] ?? []);

                return $user;
            }
        }

        return null;
    }

    private function rememberVehicle(string $userId, array $payload): void
    {
        $brand = trim((string) ($payload['brand'] ?? ''));
        $model = trim((string) ($payload['model'] ?? ''));
        if ($brand === '' && $model === '') {
            return;
        }

        $users = $this->users();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? '') !== $userId) {
                continue;
            }

            $savedVehicles = array_values($user['savedVehicles'] ?? []);
            $matchedIndex = null;
            foreach ($savedVehicles as $savedIndex => $item) {
                if (
                    trim((string) ($item['brand'] ?? '')) === $brand
                    && trim((string) ($item['model'] ?? '')) === $model
                ) {
                    $matchedIndex = $savedIndex;
                    break;
                }
            }

            $now = now()->toIso8601String();
            $vehicle = [
                'id' => $matchedIndex === null
                    ? $this->id('veh')
                    : (string) ($savedVehicles[$matchedIndex]['id'] ?? $this->id('veh')),
                'brand' => $brand,
                'model' => $model,
                'vehicleTypeId' => trim((string) ($payload['vehicleTypeId'] ?? 'sedan')),
                'catalogVehicleId' => trim((string) ($payload['catalogVehicleId'] ?? '')),
                'isCustom' => ($payload['isCustom'] ?? false) === true,
                'usageCount' => $matchedIndex === null
                    ? 1
                    : (int) (($savedVehicles[$matchedIndex]['usageCount'] ?? 0) + 1),
                'lastUsedAt' => $now,
            ];

            if ($matchedIndex !== null) {
                unset($savedVehicles[$matchedIndex]);
            }
            array_unshift($savedVehicles, $vehicle);

            usort($savedVehicles, function (array $a, array $b): int {
                $usageCompare = ((int) ($b['usageCount'] ?? 0)) <=> ((int) ($a['usageCount'] ?? 0));
                if ($usageCompare !== 0) {
                    return $usageCompare;
                }

                return strcmp((string) ($b['lastUsedAt'] ?? ''), (string) ($a['lastUsedAt'] ?? ''));
            });

            $users[$index]['savedVehicles'] = array_slice(array_values($savedVehicles), 0, 8);
            $this->saveUsers($users);

            return;
        }
    }

    private function normalizeWorkshop(array $workshop, bool $includeReviews = false): array
    {
        $locations = $this->store->readArray(config('ustatop.workshop_locations_file'));
        $location = Arr::get($locations, $workshop['id'], []);

        if (! isset($workshop['latitude']) && isset($location['latitude'])) {
            $workshop['latitude'] = $location['latitude'];
        }

        if (! isset($workshop['longitude']) && isset($location['longitude'])) {
            $workshop['longitude'] = $location['longitude'];
        }

        $workshop['services'] = array_values(array_map(
            function (array $service): array {
                return [
                    'id' => (string) ($service['id'] ?? ''),
                    'name' => (string) ($service['name'] ?? ''),
                    'price' => (int) ($service['price'] ?? 0),
                    'durationMinutes' => max(15, (int) ($service['durationMinutes'] ?? 30)),
                    'prepaymentPercent' => max(0, min(100, (int) ($service['prepaymentPercent'] ?? 0))),
                ];
            },
            array_values($workshop['services'] ?? [])
        ));

        if ($includeReviews) {
            $workshop['reviews'] = $this->reviewsForWorkshop((string) ($workshop['id'] ?? ''));
        }

        return $workshop;
    }

    private function buildWorkshopPayload(array $payload, ?array $current, string $workshopId): array
    {
        $latitude = $payload['latitude'] ?? ($current['latitude'] ?? null);
        $longitude = $payload['longitude'] ?? ($current['longitude'] ?? null);

        return [
            'id' => $workshopId,
            'name' => trim((string) ($payload['name'] ?? $current['name'] ?? 'Yangi ustaxona')),
            'master' => trim((string) ($payload['master'] ?? $current['master'] ?? '')),
            'rating' => (float) ($current['rating'] ?? 0),
            'reviewCount' => (int) ($current['reviewCount'] ?? 0),
            'address' => trim((string) ($payload['address'] ?? $current['address'] ?? '')),
            'description' => trim((string) ($payload['description'] ?? $current['description'] ?? '')),
            'distanceKm' => (float) ($payload['distanceKm'] ?? $current['distanceKm'] ?? 0),
            'latitude' => $latitude === null || $latitude === '' ? null : (float) $latitude,
            'longitude' => $longitude === null || $longitude === '' ? null : (float) $longitude,
            'isOpen' => ($payload['isOpen'] ?? $current['isOpen'] ?? true) === true,
            'badge' => trim((string) ($payload['badge'] ?? $current['badge'] ?? '')),
            'ownerAccessCode' => trim((string) ($payload['ownerAccessCode'] ?? $current['ownerAccessCode'] ?? $this->defaultOwnerAccessCode($workshopId))),
            'startingPrice' => (int) ($payload['startingPrice'] ?? $current['startingPrice'] ?? 0),
            'services' => array_values($payload['services'] ?? $current['services'] ?? []),
            'schedule' => $current['schedule'] ?? [
                'openingTime' => '09:00',
                'closingTime' => '19:00',
                'breakStartTime' => '13:00',
                'breakEndTime' => '14:00',
                'closedWeekdays' => [7],
            ],
            'vehiclePricingRules' => array_values($current['vehiclePricingRules'] ?? []),
            'telegramChatId' => trim((string) ($payload['telegramChatId'] ?? $current['telegramChatId'] ?? '')),
            'telegramChatLabel' => trim((string) ($payload['telegramChatLabel'] ?? $current['telegramChatLabel'] ?? '')),
            'telegramLinkCode' => trim((string) ($payload['telegramLinkCode'] ?? $current['telegramLinkCode'] ?? '')),
        ];
    }

    private function reviewsForWorkshop(string $workshopId): array
    {
        $items = array_filter($this->rawReviews(), function (array $review) use ($workshopId): bool {
            if (($review['workshopId'] ?? '') !== $workshopId) {
                return false;
            }

            return ! (($review['isHidden'] ?? false) === true);
        });

        usort($items, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values($items);
    }

    private function computePriceQuote(
        array $workshop,
        array $service,
        string $catalogVehicleId,
        string $vehicleBrand,
        string $vehicleModelName,
        string $vehicleTypeId
    ): array {
        $basePrice = (int) ($service['price'] ?? $workshop['startingPrice'] ?? 0);
        $matchedRule = false;
        $matchedVehicleLabel = '';

        foreach (array_values($workshop['vehiclePricingRules'] ?? []) as $rule) {
            $ruleServiceId = trim((string) ($rule['serviceId'] ?? ''));
            if ($ruleServiceId !== '' && $ruleServiceId !== (string) ($service['id'] ?? '')) {
                continue;
            }

            $catalogMatch = trim((string) ($rule['catalogVehicleId'] ?? ''));
            $brandMatch = trim((string) ($rule['vehicleBrand'] ?? ''));
            $modelMatch = trim((string) ($rule['vehicleModelName'] ?? ''));
            $typeMatch = trim((string) ($rule['vehicleTypeId'] ?? ''));

            if ($catalogMatch !== '' && $catalogMatch !== $catalogVehicleId) {
                continue;
            }
            if ($brandMatch !== '' && strcasecmp($brandMatch, $vehicleBrand) !== 0) {
                continue;
            }
            if ($modelMatch !== '' && strcasecmp($modelMatch, $vehicleModelName) !== 0) {
                continue;
            }
            if ($typeMatch !== '' && strcasecmp($typeMatch, $vehicleTypeId) !== 0) {
                continue;
            }

            $basePrice = (int) ($rule['price'] ?? $basePrice);
            $matchedRule = true;
            $matchedVehicleLabel = trim((string) ($rule['vehicleLabel'] ?? trim($vehicleBrand.' '.$vehicleModelName)));
            break;
        }

        $prepaymentPercent = (int) ($service['prepaymentPercent'] ?? 0);
        $prepaymentAmount = (int) ceil(($basePrice * $prepaymentPercent) / 100);

        return [
            'basePrice' => $basePrice,
            'price' => $basePrice,
            'prepaymentPercent' => $prepaymentPercent,
            'prepaymentAmount' => $prepaymentAmount,
            'remainingAmount' => max(0, $basePrice - $prepaymentAmount),
            'requiresPrepayment' => $prepaymentPercent > 0,
            'matchedRule' => $matchedRule,
            'matchedVehicleLabel' => $matchedVehicleLabel,
            'serviceDurationMinutes' => max(30, (int) ($service['durationMinutes'] ?? 30)),
        ];
    }

    private function enrichBooking(array $booking): array
    {
        $booking['basePrice'] = (int) ($booking['basePrice'] ?? $booking['price'] ?? 0);
        $booking['price'] = (int) ($booking['price'] ?? 0);
        $booking['prepaymentPercent'] = (int) ($booking['prepaymentPercent'] ?? 0);
        $booking['prepaymentAmount'] = (int) ($booking['prepaymentAmount'] ?? 0);
        $booking['remainingAmount'] = (int) ($booking['remainingAmount'] ?? max(
            0,
            $booking['price'] - $booking['prepaymentAmount']
        ));

        $messages = array_values(array_filter(
            $this->rawBookingMessages(),
            fn (array $message): bool => ($message['bookingId'] ?? '') === ($booking['id'] ?? '')
        ));
        usort($messages, fn (array $a, array $b): int => strcmp((string) ($a['createdAt'] ?? ''), (string) ($b['createdAt'] ?? '')));

        $booking['messageCount'] = count($messages);
        $booking['unreadForCustomerCount'] = count(array_filter(
            $messages,
            fn (array $message): bool => ($message['senderRole'] ?? '') === 'workshop_owner'
                && trim((string) ($message['readByCustomerAt'] ?? '')) === ''
        ));

        $lastMessage = end($messages);
        $booking['lastMessagePreview'] = $lastMessage['text'] ?? '';
        $booking['lastMessageSenderRole'] = $lastMessage['senderRole'] ?? '';
        $booking['lastMessageAt'] = $lastMessage['createdAt'] ?? null;

        if (trim((string) ($booking['reviewId'] ?? '')) === '') {
            foreach ($this->rawReviews() as $review) {
                if (($review['bookingId'] ?? '') === ($booking['id'] ?? '')) {
                    $booking['reviewId'] = $review['id'];
                    $booking['reviewSubmittedAt'] = $review['createdAt'] ?? null;
                    break;
                }
            }
        }

        return $booking;
    }

    private function applyReschedule(array $booking, string $dateTimeRaw, string $actorRole): array
    {
        $workshop = $this->workshopById((string) ($booking['workshopId'] ?? ''));
        $service = $workshop ? $this->serviceForWorkshop($workshop, (string) ($booking['serviceId'] ?? '')) : null;
        if (! $workshop || ! $service) {
            throw new RuntimeException('Ustaxona yoki xizmat topilmadi');
        }

        $dateTime = CarbonImmutable::parse($dateTimeRaw);
        $availableSlots = $this->slotTimesForDate($workshop, $service, $dateTime->startOfDay(), (string) ($booking['id'] ?? ''));
        if (! in_array($dateTime->format('H:i'), $availableSlots, true)) {
            throw new RuntimeException('Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
        }

        $booking['previousDateTime'] = $booking['dateTime'];
        $booking['dateTime'] = $dateTime->toIso8601String();
        $booking['status'] = 'rescheduled';
        $booking['rescheduledAt'] = now()->toIso8601String();
        $booking['rescheduledByRole'] = $actorRole;
        $booking['completedAt'] = null;
        $booking['cancelReasonId'] = '';
        $booking['cancelledByRole'] = '';
        $booking['cancelledAt'] = null;

        return $booking;
    }

    private function mutateBooking(string $bookingId, callable $callback): array
    {
        $bookings = $this->rawBookings();

        foreach ($bookings as $index => $booking) {
            if (($booking['id'] ?? '') !== $bookingId) {
                continue;
            }

            $bookings[$index] = $callback($booking);
            $this->saveBookings($bookings);

            return $this->enrichBooking($bookings[$index]);
        }

        throw new RuntimeException('Buyurtma topilmadi');
    }

    private function ensureMutableStatus(array $booking): void
    {
        $status = (string) ($booking['status'] ?? 'upcoming');
        if (! in_array($status, ['upcoming', 'accepted', 'rescheduled'], true)) {
            throw new RuntimeException('Bu holatdagi buyurtmani o‘zgartirib bo‘lmaydi');
        }
    }

    private function serviceForWorkshop(array $workshop, string $serviceId): ?array
    {
        foreach (($workshop['services'] ?? []) as $service) {
            if (($service['id'] ?? '') === $serviceId) {
                return $service;
            }
        }

        return null;
    }

    private function scheduleForWorkshop(array $workshop): array
    {
        $schedule = $workshop['schedule'] ?? [];

        return [
            'openingTime' => (string) ($schedule['openingTime'] ?? '09:00'),
            'closingTime' => (string) ($schedule['closingTime'] ?? '19:00'),
            'breakStartTime' => (string) ($schedule['breakStartTime'] ?? '13:00'),
            'breakEndTime' => (string) ($schedule['breakEndTime'] ?? '14:00'),
            'closedWeekdays' => array_values($schedule['closedWeekdays'] ?? [7]),
        ];
    }

    private function slotTimesForDate(array $workshop, array $service, CarbonImmutable $day, ?string $ignoreBookingId): array
    {
        $schedule = $this->scheduleForWorkshop($workshop);
        if (in_array($day->dayOfWeekIso, $schedule['closedWeekdays'], true)) {
            return [];
        }

        $duration = max(30, (int) ($service['durationMinutes'] ?? 30));
        $opening = $this->dayTime($day, $schedule['openingTime']);
        $closing = $this->dayTime($day, $schedule['closingTime']);
        $breakStart = trim($schedule['breakStartTime']) !== '' ? $this->dayTime($day, $schedule['breakStartTime']) : null;
        $breakEnd = trim($schedule['breakEndTime']) !== '' ? $this->dayTime($day, $schedule['breakEndTime']) : null;

        $active = array_filter($this->rawBookings(), function (array $booking) use ($workshop, $day, $ignoreBookingId): bool {
            if (($booking['workshopId'] ?? '') !== ($workshop['id'] ?? '')) {
                return false;
            }
            if ($ignoreBookingId !== null && ($booking['id'] ?? '') === $ignoreBookingId) {
                return false;
            }

            $status = (string) ($booking['status'] ?? 'upcoming');
            if (! in_array($status, ['upcoming', 'accepted', 'rescheduled'], true)) {
                return false;
            }

            return CarbonImmutable::parse((string) ($booking['dateTime'] ?? now()->toIso8601String()))
                ->format('Y-m-d') === $day->format('Y-m-d');
        });

        $slots = [];
        for ($cursor = $opening; $cursor->lt($closing); $cursor = $cursor->addMinutes(30)) {
            $end = $cursor->addMinutes($duration);
            if ($end->gt($closing)) {
                continue;
            }

            if ($breakStart && $breakEnd && $this->overlaps($cursor, $end, $breakStart, $breakEnd)) {
                continue;
            }

            $conflict = false;
            foreach ($active as $booking) {
                $bookingStart = CarbonImmutable::parse((string) ($booking['dateTime'] ?? now()->toIso8601String()));
                $bookingService = $this->serviceForWorkshop($workshop, (string) ($booking['serviceId'] ?? ''));
                $bookingDuration = max(30, (int) ($bookingService['durationMinutes'] ?? 30));
                $bookingEnd = $bookingStart->addMinutes($bookingDuration);

                if ($this->overlaps($cursor, $end, $bookingStart, $bookingEnd)) {
                    $conflict = true;
                    break;
                }
            }

            if (! $conflict) {
                $slots[] = $cursor->format('H:i');
            }
        }

        return $slots;
    }

    private function activeBookingCount(string $workshopId, CarbonImmutable $day): int
    {
        return count(array_filter($this->rawBookings(), function (array $booking) use ($workshopId, $day): bool {
            if (($booking['workshopId'] ?? '') !== $workshopId) {
                return false;
            }

            $status = (string) ($booking['status'] ?? 'upcoming');
            if (! in_array($status, ['upcoming', 'accepted', 'rescheduled'], true)) {
                return false;
            }

            return CarbonImmutable::parse((string) ($booking['dateTime'] ?? now()->toIso8601String()))
                ->format('Y-m-d') === $day->format('Y-m-d');
        }));
    }

    private function firstAvailableOffsetAtOrAfter(
        array $workshop,
        array $service,
        CarbonImmutable $threshold,
        string $excludeBookingId,
        int $requestedOffset,
        int $maxOffset
    ): int {
        for ($offset = $requestedOffset; $offset <= $maxOffset; $offset++) {
            if ($this->dayHasAvailableRescheduleSlots($workshop, $service, $threshold, $excludeBookingId, $offset)) {
                return $offset;
            }
        }

        return $requestedOffset;
    }

    private function previousAvailableOffset(
        array $workshop,
        array $service,
        CarbonImmutable $threshold,
        string $excludeBookingId,
        int $fromOffset
    ): ?int {
        for ($offset = $fromOffset - 1; $offset >= 0; $offset--) {
            if ($this->dayHasAvailableRescheduleSlots($workshop, $service, $threshold, $excludeBookingId, $offset)) {
                return $offset;
            }
        }

        return null;
    }

    private function nextAvailableOffset(
        array $workshop,
        array $service,
        CarbonImmutable $threshold,
        string $excludeBookingId,
        int $fromOffset,
        int $maxOffset
    ): ?int {
        for ($offset = $fromOffset + 1; $offset <= $maxOffset; $offset++) {
            if ($this->dayHasAvailableRescheduleSlots($workshop, $service, $threshold, $excludeBookingId, $offset)) {
                return $offset;
            }
        }

        return null;
    }

    private function dayHasAvailableRescheduleSlots(
        array $workshop,
        array $service,
        CarbonImmutable $threshold,
        string $excludeBookingId,
        int $offset
    ): bool {
        $date = $threshold->startOfDay()->addDays($offset);
        $slots = $this->slotTimesForDate($workshop, $service, $date, $excludeBookingId);

        foreach ($slots as $slot) {
            [$hours, $minutes] = array_map('intval', explode(':', $slot));
            $slotDateTime = $date->setTime($hours, $minutes);
            if ($offset === 0 && ! $slotDateTime->gt($threshold)) {
                continue;
            }

            return true;
        }

        return false;
    }

    private function incrementWorkshopReviewStats(string $workshopId, int $rating): void
    {
        $workshops = $this->rawWorkshops();
        foreach ($workshops as $index => $workshop) {
            if (($workshop['id'] ?? '') !== $workshopId) {
                continue;
            }

            $currentCount = (int) ($workshop['reviewCount'] ?? 0);
            $currentRating = (float) ($workshop['rating'] ?? 0);
            $nextCount = $currentCount + 1;
            $nextRating = $nextCount === 0
                ? $rating
                : (($currentRating * $currentCount) + $rating) / $nextCount;

            $workshops[$index]['reviewCount'] = $nextCount;
            $workshops[$index]['rating'] = round($nextRating, 1);
            $this->store->writeArray(config('ustatop.workshops_file'), array_values($workshops));

            return;
        }
    }

    private function syncWorkshopLocation(array $workshop): void
    {
        $locations = $this->store->readArray(config('ustatop.workshop_locations_file'));
        $latitude = $workshop['latitude'] ?? null;
        $longitude = $workshop['longitude'] ?? null;

        if ($latitude === null || $longitude === null) {
            unset($locations[$workshop['id']]);
            $this->store->writeArray(config('ustatop.workshop_locations_file'), $locations);

            return;
        }

        $locations[$workshop['id']] = [
            'latitude' => (float) $latitude,
            'longitude' => (float) $longitude,
        ];
        $this->store->writeArray(config('ustatop.workshop_locations_file'), $locations);
    }

    private function defaultOwnerAccessCode(string $workshopId): string
    {
        if (preg_match('/(\d{4})$/', $workshopId, $matches) === 1) {
            return $matches[1];
        }

        return '0000';
    }

    private function dropSessionsForUser(string $userId): void
    {
        $sessions = array_values(array_filter(
            $this->authSessions(),
            fn (array $session): bool => ($session['userId'] ?? '') !== $userId
        ));

        $this->saveAuthSessions($sessions);
    }

    private function dayTime(CarbonImmutable $day, string $time): CarbonImmutable
    {
        [$hour, $minute] = array_pad(explode(':', $time), 2, '00');

        return $day->setTime((int) $hour, (int) $minute);
    }

    private function overlaps(
        CarbonImmutable $startA,
        CarbonImmutable $endA,
        CarbonImmutable $startB,
        CarbonImmutable $endB
    ): bool {
        return $startA->lt($endB) && $startB->lt($endA);
    }

    private function id(string $prefix): string
    {
        return $prefix.'-'.now()->format('Uu').'-'.random_int(1000, 9999);
    }
}
