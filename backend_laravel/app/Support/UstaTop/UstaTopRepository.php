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
        $workshops = $this->store->readArray(config('ustatop.workshops_file'));
        $locations = $this->store->readArray(config('ustatop.workshop_locations_file'));

        return array_map(function (array $workshop) use ($locations): array {
            $location = Arr::get($locations, $workshop['id'], []);

            if (! isset($workshop['latitude']) && isset($location['latitude'])) {
                $workshop['latitude'] = $location['latitude'];
            }

            if (! isset($workshop['longitude']) && isset($location['longitude'])) {
                $workshop['longitude'] = $location['longitude'];
            }

            $workshop['services'] = array_values($workshop['services'] ?? []);

            return $workshop;
        }, array_values($workshops));
    }

    public function workshopById(string $workshopId): ?array
    {
        foreach ($this->listWorkshops() as $workshop) {
            if (($workshop['id'] ?? '') === $workshopId) {
                return $workshop;
            }
        }

        return null;
    }

    public function workshopByOwnerAccess(string $workshopId, string $accessCode): ?array
    {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            return null;
        }

        return trim((string) ($workshop['ownerAccessCode'] ?? '')) === trim($accessCode)
            ? $workshop
            : null;
    }

    public function authUserFromToken(?string $token): ?array
    {
        if (! $token) {
            return null;
        }

        $sessions = $this->store->readArray(config('ustatop.auth_sessions_file'));
        foreach ($sessions as $session) {
            if (($session['token'] ?? '') !== $token) {
                continue;
            }

            return $this->userById((string) ($session['userId'] ?? ''));
        }

        return null;
    }

    public function createUser(string $fullName, string $phone, string $password): array
    {
        $users = $this->users();
        foreach ($users as $user) {
            if (($user['phone'] ?? '') === $phone) {
                throw new RuntimeException('Bu telefon raqam bilan akkaunt allaqachon mavjud');
            }
        }

        $created = [
            'id' => $this->id('u'),
            'fullName' => $fullName,
            'phone' => $phone,
            'password' => $password,
        ];

        $users[] = $created;
        $this->saveUsers($users);

        return $created;
    }

    public function login(string $phone, string $password): ?array
    {
        foreach ($this->users() as $user) {
            if (($user['phone'] ?? '') !== $phone || ($user['password'] ?? '') !== $password) {
                continue;
            }

            $token = 'token-'.Str::lower(Str::random(24));
            $sessions = $this->store->readArray(config('ustatop.auth_sessions_file'));
            $sessions[] = [
                'token' => $token,
                'userId' => $user['id'],
                'createdAt' => now()->toIso8601String(),
            ];
            $this->store->writeArray(config('ustatop.auth_sessions_file'), array_values($sessions));

            return [
                'token' => $token,
                'user' => $this->publicUser($user),
            ];
        }

        return null;
    }

    public function bookingsForUser(string $userId): array
    {
        $items = array_filter($this->bookings(), fn (array $booking): bool => ($booking['userId'] ?? '') === $userId);

        usort($items, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values($items);
    }

    public function bookingsForWorkshop(string $workshopId): array
    {
        $items = array_filter($this->bookings(), fn (array $booking): bool => ($booking['workshopId'] ?? '') === $workshopId);

        usort($items, fn (array $a, array $b): int => strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? '')));

        return array_values($items);
    }

    public function createBooking(array $user, array $payload): array
    {
        $workshopId = trim((string) ($payload['workshopId'] ?? ''));
        $serviceId = trim((string) ($payload['serviceId'] ?? ''));
        $vehicleModel = trim((string) ($payload['vehicleModel'] ?? ''));
        $vehicleTypeId = trim((string) ($payload['vehicleTypeId'] ?? 'sedan'));
        $dateTimeRaw = trim((string) ($payload['dateTime'] ?? ''));
        $paymentMethod = trim((string) ($payload['paymentMethod'] ?? 'cash'));

        if ($workshopId === '' || $serviceId === '' || $vehicleModel === '' || $dateTimeRaw === '') {
            throw new RuntimeException('workshopId, serviceId, vehicleModel va dateTime kerak');
        }

        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Ustaxona topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $dateTime = CarbonImmutable::parse($dateTimeRaw);
        $availableSlots = $this->slotTimesForDate($workshop, $service, $dateTime->startOfDay(), null);
        if (! in_array($dateTime->format('H:i'), $availableSlots, true)) {
            throw new RuntimeException('Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
        }

        $basePrice = (int) ($service['price'] ?? $workshop['startingPrice'] ?? 0);
        $prepaymentPercent = (int) ($service['prepaymentPercent'] ?? 0);
        $prepaymentAmount = (int) ceil(($basePrice * $prepaymentPercent) / 100);
        $isTestCard = $paymentMethod === 'test_card';

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
            'vehicleModel' => $vehicleModel,
            'vehicleTypeId' => $vehicleTypeId,
            'dateTime' => $dateTime->toIso8601String(),
            'basePrice' => $basePrice,
            'price' => $basePrice,
            'status' => 'upcoming',
            'createdAt' => now()->toIso8601String(),
            'prepaymentPercent' => $prepaymentPercent,
            'prepaymentAmount' => $prepaymentAmount,
            'remainingAmount' => max(0, $basePrice - $prepaymentAmount),
            'paymentStatus' => $prepaymentPercent > 0
                ? ($isTestCard ? 'paid' : 'pending')
                : 'not_required',
            'paymentMethod' => $paymentMethod,
            'paidAt' => $prepaymentPercent > 0 && $isTestCard ? now()->toIso8601String() : null,
        ];

        $bookings = $this->bookings();
        $bookings[] = $booking;
        $this->saveBookings($bookings);

        return $booking;
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

            $workshop = $this->workshopById((string) ($booking['workshopId'] ?? ''));
            $service = $workshop ? $this->serviceForWorkshop($workshop, (string) ($booking['serviceId'] ?? '')) : null;
            if (! $workshop || ! $service) {
                throw new RuntimeException('Ustaxona yoki xizmat topilmadi');
            }

            $dateTime = CarbonImmutable::parse($dateTimeRaw);
            $availableSlots = $this->slotTimesForDate($workshop, $service, $dateTime->startOfDay(), $booking['id']);
            if (! in_array($dateTime->format('H:i'), $availableSlots, true)) {
                throw new RuntimeException('Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
            }

            $booking['previousDateTime'] = $booking['dateTime'];
            $booking['dateTime'] = $dateTime->toIso8601String();
            $booking['status'] = 'rescheduled';
            $booking['rescheduledAt'] = now()->toIso8601String();
            $booking['rescheduledByRole'] = 'customer';
            $booking['completedAt'] = null;
            $booking['cancelReasonId'] = '';
            $booking['cancelledByRole'] = '';
            $booking['cancelledAt'] = null;

            return $booking;
        });
    }

    public function updateBookingStatus(string $bookingId, string $status, array $options = []): array
    {
        return $this->mutateBooking($bookingId, function (array $booking) use ($status, $options): array {
            $status = trim($status);
            if (! in_array($status, ['accepted', 'rescheduled', 'completed', 'cancelled'], true)) {
                throw new RuntimeException('Noto‘g‘ri status');
            }

            if ($status === 'rescheduled') {
                $dateTimeRaw = trim((string) ($options['scheduledAt'] ?? ''));
                if ($dateTimeRaw === '') {
                    throw new RuntimeException('Ko‘chirish uchun yangi vaqtni tanlang');
                }

                $workshop = $this->workshopById((string) ($booking['workshopId'] ?? ''));
                $service = $workshop ? $this->serviceForWorkshop($workshop, (string) ($booking['serviceId'] ?? '')) : null;
                if (! $workshop || ! $service) {
                    throw new RuntimeException('Ustaxona yoki xizmat topilmadi');
                }

                $dateTime = CarbonImmutable::parse($dateTimeRaw);
                $availableSlots = $this->slotTimesForDate($workshop, $service, $dateTime->startOfDay(), $booking['id']);
                if (! in_array($dateTime->format('H:i'), $availableSlots, true)) {
                    throw new RuntimeException('Tanlangan vaqt band bo‘lib qoldi. Boshqa vaqt tanlang');
                }

                $booking['previousDateTime'] = $booking['dateTime'];
                $booking['dateTime'] = $dateTime->toIso8601String();
                $booking['status'] = 'rescheduled';
                $booking['rescheduledAt'] = now()->toIso8601String();
                $booking['rescheduledByRole'] = (string) ($options['actorRole'] ?? 'admin');
                $booking['completedAt'] = null;
                $booking['cancelReasonId'] = '';
                $booking['cancelledByRole'] = '';
                $booking['cancelledAt'] = null;

                return $booking;
            }

            $booking['status'] = $status;

            if ($status === 'accepted') {
                $booking['completedAt'] = null;
                $booking['cancelReasonId'] = '';
                $booking['cancelledByRole'] = '';
                $booking['cancelledAt'] = null;
            }

            if ($status === 'completed') {
                $booking['completedAt'] = now()->toIso8601String();
                $booking['cancelReasonId'] = '';
                $booking['cancelledByRole'] = '';
                $booking['cancelledAt'] = null;
            }

            if ($status === 'cancelled') {
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

    public function availabilityCalendar(string $workshopId, string $serviceId, int $days = 14): array
    {
        $items = [];
        $nearestDate = null;
        $nearestTime = '';

        for ($offset = 0; $offset < $days; $offset++) {
            $day = now()->addDays($offset)->startOfDay();
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

    public function priceQuote(string $workshopId, string $serviceId): array
    {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $service = $this->serviceForWorkshop($workshop, $serviceId);
        if (! $service) {
            throw new RuntimeException('Xizmat topilmadi');
        }

        $price = (int) ($service['price'] ?? $workshop['startingPrice'] ?? 0);
        $prepaymentPercent = (int) ($service['prepaymentPercent'] ?? 0);
        $prepaymentAmount = (int) ceil(($price * $prepaymentPercent) / 100);

        return [
            'basePrice' => $price,
            'price' => $price,
            'prepaymentPercent' => $prepaymentPercent,
            'prepaymentAmount' => $prepaymentAmount,
            'remainingAmount' => max(0, $price - $prepaymentAmount),
            'serviceDurationMinutes' => max(30, (int) ($service['durationMinutes'] ?? 30)),
        ];
    }

    public function createReview(array $user, string $workshopId, array $payload): array
    {
        $workshop = $this->workshopById($workshopId);
        if (! $workshop) {
            throw new RuntimeException('Servis topilmadi');
        }

        $review = [
            'id' => $this->id('r'),
            'workshopId' => $workshopId,
            'userId' => $user['id'],
            'customerName' => $user['fullName'],
            'serviceId' => (string) ($payload['serviceId'] ?? ''),
            'rating' => max(1, min(5, (int) ($payload['rating'] ?? 5))),
            'comment' => trim((string) ($payload['comment'] ?? '')),
            'bookingId' => trim((string) ($payload['bookingId'] ?? '')),
            'createdAt' => now()->toIso8601String(),
        ];

        $reviews = $this->store->readArray(config('ustatop.reviews_file'));
        $reviews[] = $review;
        $this->store->writeArray(config('ustatop.reviews_file'), array_values($reviews));

        return $review;
    }

    public function publicUser(array $user): array
    {
        return [
            'id' => $user['id'],
            'fullName' => $user['fullName'],
            'phone' => $user['phone'],
        ];
    }

    private function users(): array
    {
        return array_values($this->store->readArray(config('ustatop.users_file')));
    }

    private function bookings(): array
    {
        return array_values($this->store->readArray(config('ustatop.bookings_file')));
    }

    private function saveUsers(array $users): void
    {
        $this->store->writeArray(config('ustatop.users_file'), array_values($users));
    }

    private function saveBookings(array $bookings): void
    {
        $this->store->writeArray(config('ustatop.bookings_file'), array_values($bookings));
    }

    private function userById(string $userId): ?array
    {
        foreach ($this->users() as $user) {
            if (($user['id'] ?? '') === $userId) {
                return $user;
            }
        }

        return null;
    }

    private function mutateBooking(string $bookingId, callable $callback): array
    {
        $bookings = $this->bookings();

        foreach ($bookings as $index => $booking) {
            if (($booking['id'] ?? '') !== $bookingId) {
                continue;
            }

            $bookings[$index] = $callback($booking);
            $this->saveBookings($bookings);

            return $bookings[$index];
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

        $active = array_filter($this->bookings(), function (array $booking) use ($workshop, $day, $ignoreBookingId): bool {
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
        return count(array_filter($this->bookings(), function (array $booking) use ($workshopId, $day): bool {
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
