<?php

namespace App\Support\UstaTop;

use Carbon\CarbonImmutable;
use RuntimeException;

class AdminAnalyticsService
{
    public function __construct(
        private readonly UstaTopRepository $repository,
    ) {
    }

    public function buildDashboard(?string $workshopId, string $range, ?string $fromInput, ?string $toInput): array
    {
        [$from, $to, $resolvedRange] = $this->resolveRange($range, $fromInput, $toInput);

        $selectedWorkshopId = trim((string) $workshopId);
        $workshops = $this->repository->listWorkshops();
        $workshopOptions = array_map(
            fn (array $workshop): array => [
                'id' => (string) ($workshop['id'] ?? ''),
                'name' => (string) ($workshop['name'] ?? 'Ustaxona'),
            ],
            $workshops
        );

        $bookings = array_values(array_filter(
            $this->repository->allBookings(),
            fn (array $booking): bool => $selectedWorkshopId === ''
                || (string) ($booking['workshopId'] ?? '') === $selectedWorkshopId
        ));

        $reviews = array_values(array_filter(
            $this->repository->listAdminReviews(),
            fn (array $review): bool => $selectedWorkshopId === ''
                || (string) ($review['workshopId'] ?? '') === $selectedWorkshopId
        ));

        $scheduledBookings = array_values(array_filter(
            $bookings,
            fn (array $booking): bool => $this->dateInRange($booking['dateTime'] ?? null, $from, $to)
        ));
        $createdBookings = array_values(array_filter(
            $bookings,
            fn (array $booking): bool => $this->dateInRange($booking['createdAt'] ?? null, $from, $to)
        ));
        $rangeReviews = array_values(array_filter(
            $reviews,
            fn (array $review): bool => $this->dateInRange($review['createdAt'] ?? null, $from, $to)
        ));

        $activeRevenueBookings = array_values(array_filter(
            $scheduledBookings,
            fn (array $booking): bool => (string) ($booking['status'] ?? '') !== 'cancelled'
        ));

        $metrics = [
            [
                'label' => 'Jami zakazlar',
                'value' => number_format(count($scheduledBookings), 0, '.', ' '),
                'hint' => $this->periodLabel($from, $to).' bo‘yicha rejalashtirilgan bronlar',
            ],
            [
                'label' => 'Yangi bronlar',
                'value' => number_format(count($createdBookings), 0, '.', ' '),
                'hint' => 'Shu davrda yaratilgan zakazlar',
            ],
            [
                'label' => 'Qabul qilingan',
                'value' => number_format($this->statusCount($scheduledBookings, 'accepted'), 0, '.', ' '),
                'hint' => 'Usta yoki admin tasdiqlagan bronlar',
            ],
            [
                'label' => 'Yakunlangan',
                'value' => number_format($this->statusCount($scheduledBookings, 'completed'), 0, '.', ' '),
                'hint' => 'Muvaffaqiyatli tugagan xizmatlar',
            ],
            [
                'label' => 'Bekor qilingan',
                'value' => number_format($this->statusCount($scheduledBookings, 'cancelled'), 0, '.', ' '),
                'hint' => 'Ushbu davrda bekor bo‘lgan bronlar',
            ],
            [
                'label' => 'Potensial tushum',
                'value' => Money::formatUzs($this->sumField($activeRevenueBookings, 'price')),
                'hint' => 'Bekor qilinmagan bronlar summasi',
            ],
            [
                'label' => 'Yig‘ilgan avans',
                'value' => Money::formatUzs($this->sumField(
                    array_values(array_filter(
                        $scheduledBookings,
                        fn (array $booking): bool => (string) ($booking['paymentStatus'] ?? '') === 'paid'
                    )),
                    'prepaymentAmount'
                )),
                'hint' => 'To‘langan avanslarning jami',
            ],
            [
                'label' => 'O‘rtacha chek',
                'value' => Money::formatUzs($this->averageField($activeRevenueBookings, 'price')),
                'hint' => 'Bekor qilinmagan bronlar o‘rtachasi',
            ],
        ];

        $reviewMetrics = [
            [
                'label' => 'Sharhlar',
                'value' => number_format(count($rangeReviews), 0, '.', ' '),
                'hint' => 'Tanlangan davrda qoldirilgan sharhlar',
            ],
            [
                'label' => 'O‘rtacha baho',
                'value' => count($rangeReviews) === 0
                    ? '0.0'
                    : number_format($this->averageField($rangeReviews, 'rating', 1), 1, '.', ' '),
                'hint' => 'Foydalanuvchi baholari o‘rtachasi',
            ],
            [
                'label' => 'Javob berilgan',
                'value' => number_format(count(array_filter(
                    $rangeReviews,
                    fn (array $review): bool => trim((string) ($review['ownerReply'] ?? '')) !== ''
                )), 0, '.', ' '),
                'hint' => 'Owner javob qaytargan sharhlar',
            ],
            [
                'label' => 'Yashirilgan',
                'value' => number_format(count(array_filter(
                    $rangeReviews,
                    fn (array $review): bool => ($review['isHidden'] ?? false) === true
                )), 0, '.', ' '),
                'hint' => 'Moderatsiyaga tushgan sharhlar',
            ],
        ];

        return [
            'filters' => [
                'range' => $resolvedRange,
                'from' => $from->format('Y-m-d'),
                'to' => $to->format('Y-m-d'),
                'workshopId' => $selectedWorkshopId,
                'workshops' => $workshopOptions,
            ],
            'periodLabel' => $this->periodLabel($from, $to),
            'metrics' => $metrics,
            'reviewMetrics' => $reviewMetrics,
            'bookingsChart' => $this->dailyBookingsChart($from, $to, $scheduledBookings, $createdBookings),
            'revenueChart' => $this->dailyRevenueChart($from, $to, $activeRevenueBookings),
            'statusBreakdown' => $this->statusBreakdown($scheduledBookings),
            'topWorkshops' => $this->topDimension($scheduledBookings, 'workshopName', 'price'),
            'topServices' => $this->topDimension($scheduledBookings, 'serviceName', 'price'),
            'topVehicles' => $this->topDimension($scheduledBookings, 'vehicleModel', 'price'),
            'cancelReasons' => $this->cancelReasons($scheduledBookings),
            'ratings' => $this->topRatings($workshops, $selectedWorkshopId),
            'exportRows' => $this->exportRows($scheduledBookings),
        ];
    }

    /**
     * @return array{0: CarbonImmutable, 1: CarbonImmutable, 2: string}
     */
    private function resolveRange(string $range, ?string $fromInput, ?string $toInput): array
    {
        $today = CarbonImmutable::now(config('app.timezone'))->startOfDay();
        $normalizedRange = in_array($range, ['today', '7d', '30d', 'custom'], true) ? $range : '7d';

        return match ($normalizedRange) {
            'today' => [$today, $today, $normalizedRange],
            '30d' => [$today->subDays(29), $today, $normalizedRange],
            'custom' => $this->customRange($fromInput, $toInput),
            default => [$today->subDays(6), $today, '7d'],
        };
    }

    /**
     * @return array{0: CarbonImmutable, 1: CarbonImmutable, 2: string}
     */
    private function customRange(?string $fromInput, ?string $toInput): array
    {
        $today = CarbonImmutable::now(config('app.timezone'))->startOfDay();

        try {
            $from = trim((string) $fromInput) !== ''
                ? CarbonImmutable::parse((string) $fromInput, config('app.timezone'))->startOfDay()
                : $today->subDays(6);
            $to = trim((string) $toInput) !== ''
                ? CarbonImmutable::parse((string) $toInput, config('app.timezone'))->startOfDay()
                : $today;
        } catch (\Throwable $error) {
            throw new RuntimeException('Sana formati noto‘g‘ri');
        }

        if ($to->lt($from)) {
            [$from, $to] = [$to, $from];
        }

        return [$from, $to, 'custom'];
    }

    private function periodLabel(CarbonImmutable $from, CarbonImmutable $to): string
    {
        if ($from->equalTo($to)) {
            return $from->format('d.m.Y');
        }

        return $from->format('d.m.Y').' - '.$to->format('d.m.Y');
    }

    private function dateInRange(mixed $rawValue, CarbonImmutable $from, CarbonImmutable $to): bool
    {
        $value = trim((string) $rawValue);
        if ($value === '') {
            return false;
        }

        $date = CarbonImmutable::parse($value)->setTimezone(config('app.timezone'));

        return ! $date->lt($from) && ! $date->gt($to->endOfDay());
    }

    private function statusCount(array $bookings, string $status): int
    {
        return count(array_filter(
            $bookings,
            fn (array $booking): bool => (string) ($booking['status'] ?? '') === $status
        ));
    }

    private function sumField(array $items, string $field): int
    {
        return (int) array_reduce(
            $items,
            fn (int $carry, array $item): int => $carry + (int) ($item[$field] ?? 0),
            0
        );
    }

    private function averageField(array $items, string $field, int $precision = 0): int|float
    {
        if ($items === []) {
            return 0;
        }

        $average = $this->sumField($items, $field) / count($items);
        if ($precision <= 0) {
            return (int) round($average);
        }

        return round($average, $precision);
    }

    private function dailyBookingsChart(CarbonImmutable $from, CarbonImmutable $to, array $scheduledBookings, array $createdBookings): array
    {
        $series = [];
        $cursor = $from;

        while (! $cursor->gt($to)) {
            $key = $cursor->format('Y-m-d');
            $scheduledCount = count(array_filter($scheduledBookings, function (array $booking) use ($key): bool {
                return CarbonImmutable::parse((string) ($booking['dateTime'] ?? now()->toIso8601String()))
                    ->setTimezone(config('app.timezone'))
                    ->format('Y-m-d') === $key;
            }));
            $createdCount = count(array_filter($createdBookings, function (array $booking) use ($key): bool {
                return CarbonImmutable::parse((string) ($booking['createdAt'] ?? now()->toIso8601String()))
                    ->setTimezone(config('app.timezone'))
                    ->format('Y-m-d') === $key;
            }));

            $series[] = [
                'label' => $cursor->format('d.m'),
                'value' => $scheduledCount,
                'meta' => $createdCount.' yangi',
            ];

            $cursor = $cursor->addDay();
        }

        return $series;
    }

    private function dailyRevenueChart(CarbonImmutable $from, CarbonImmutable $to, array $bookings): array
    {
        $series = [];
        $cursor = $from;

        while (! $cursor->gt($to)) {
            $key = $cursor->format('Y-m-d');
            $revenue = $this->sumField(
                array_values(array_filter($bookings, function (array $booking) use ($key): bool {
                    return CarbonImmutable::parse((string) ($booking['dateTime'] ?? now()->toIso8601String()))
                        ->setTimezone(config('app.timezone'))
                        ->format('Y-m-d') === $key;
                })),
                'price'
            );

            $series[] = [
                'label' => $cursor->format('d.m'),
                'value' => $revenue,
                'meta' => Money::formatUzs($revenue),
            ];

            $cursor = $cursor->addDay();
        }

        return $series;
    }

    private function statusBreakdown(array $bookings): array
    {
        $labels = [
            'upcoming' => 'Kutilmoqda',
            'accepted' => 'Qabul qilindi',
            'rescheduled' => 'Ko‘chirildi',
            'completed' => 'Yakunlandi',
            'cancelled' => 'Bekor qilindi',
        ];

        $result = [];
        foreach ($labels as $status => $label) {
            $count = $this->statusCount($bookings, $status);
            $result[] = [
                'label' => $label,
                'value' => $count,
                'meta' => $count === 0 ? '0 ta' : $count.' ta',
            ];
        }

        return $result;
    }

    private function topDimension(array $bookings, string $labelField, string $revenueField): array
    {
        $groups = [];
        foreach ($bookings as $booking) {
            $label = trim((string) ($booking[$labelField] ?? ''));
            if ($label === '') {
                $label = 'Noma’lum';
            }

            if (! array_key_exists($label, $groups)) {
                $groups[$label] = [
                    'label' => $label,
                    'value' => 0,
                    'revenue' => 0,
                ];
            }

            $groups[$label]['value']++;
            if ((string) ($booking['status'] ?? '') !== 'cancelled') {
                $groups[$label]['revenue'] += (int) ($booking[$revenueField] ?? 0);
            }
        }

        usort($groups, function (array $a, array $b): int {
            $valueCompare = $b['value'] <=> $a['value'];
            if ($valueCompare !== 0) {
                return $valueCompare;
            }

            return $b['revenue'] <=> $a['revenue'];
        });

        return array_slice(array_values($groups), 0, 5);
    }

    private function cancelReasons(array $bookings): array
    {
        $groups = [];
        foreach ($bookings as $booking) {
            if ((string) ($booking['status'] ?? '') !== 'cancelled') {
                continue;
            }

            $reason = trim((string) ($booking['cancelReasonId'] ?? ''));
            if ($reason === '') {
                $reason = 'Sabab ko‘rsatilmagan';
            }

            if (! array_key_exists($reason, $groups)) {
                $groups[$reason] = [
                    'label' => $reason,
                    'value' => 0,
                    'meta' => '',
                ];
            }

            $groups[$reason]['value']++;
        }

        usort($groups, fn (array $a, array $b): int => $b['value'] <=> $a['value']);

        return array_values($groups);
    }

    private function topRatings(array $workshops, string $selectedWorkshopId): array
    {
        $items = array_values(array_filter(
            $workshops,
            fn (array $workshop): bool => $selectedWorkshopId === ''
                || (string) ($workshop['id'] ?? '') === $selectedWorkshopId
        ));

        usort($items, function (array $a, array $b): int {
            $ratingCompare = ((float) ($b['rating'] ?? 0)) <=> ((float) ($a['rating'] ?? 0));
            if ($ratingCompare !== 0) {
                return $ratingCompare;
            }

            return ((int) ($b['reviewCount'] ?? 0)) <=> ((int) ($a['reviewCount'] ?? 0));
        });

        return array_slice(array_map(function (array $workshop): array {
            return [
                'label' => (string) ($workshop['name'] ?? 'Ustaxona'),
                'value' => (float) ($workshop['rating'] ?? 0),
                'meta' => ((int) ($workshop['reviewCount'] ?? 0)).' sharh',
            ];
        }, $items), 0, 5);
    }

    private function exportRows(array $bookings): array
    {
        return array_map(function (array $booking): array {
            return [
                'booking_id' => (string) ($booking['id'] ?? ''),
                'created_at' => (string) ($booking['createdAt'] ?? ''),
                'scheduled_at' => (string) ($booking['dateTime'] ?? ''),
                'workshop' => (string) ($booking['workshopName'] ?? ''),
                'service' => (string) ($booking['serviceName'] ?? ''),
                'customer' => (string) ($booking['customerName'] ?? ''),
                'phone' => (string) ($booking['customerPhone'] ?? ''),
                'vehicle' => (string) ($booking['vehicleModel'] ?? ''),
                'status' => (string) ($booking['status'] ?? ''),
                'accepted_at' => (string) ($booking['acceptedAt'] ?? ''),
                'rescheduled_at' => (string) ($booking['rescheduledAt'] ?? ''),
                'previous_datetime' => (string) ($booking['previousDateTime'] ?? ''),
                'completed_at' => (string) ($booking['completedAt'] ?? ''),
                'cancelled_at' => (string) ($booking['cancelledAt'] ?? ''),
                'cancel_reason' => (string) ($booking['cancelReasonId'] ?? ''),
                'price_uzs' => Money::displayAmount((int) ($booking['price'] ?? 0)),
                'prepayment_uzs' => Money::displayAmount((int) ($booking['prepaymentAmount'] ?? 0)),
                'payment_status' => (string) ($booking['paymentStatus'] ?? ''),
                'payment_method' => (string) ($booking['paymentMethod'] ?? ''),
            ];
        }, $bookings);
    }
}
