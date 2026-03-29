<?php

namespace App\Support\UstaTop;

use Carbon\CarbonImmutable;
use RuntimeException;

class WorkshopNotificationsService
{
    public function __construct(
        private readonly TelegramBotService $telegramBot,
    ) {
    }

    public function isConfigured(): bool
    {
        return $this->telegramBot->isConfigured();
    }

    public function sendTestNotification(array $workshop): void
    {
        $this->sendToWorkshop($workshop, implode("\n", [
            'Usta Top Telegram ulanishi tayyor.',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Workshop ID: '.($workshop['id'] ?? ''),
            '',
            'Bu test xabar. Endi yangi zakazlar va status o‘zgarishlari shu chatga keladi.',
        ]));
    }

    public function sendNewBookingNotification(array $workshop, array $booking): void
    {
        $this->sendToWorkshop(
            $workshop,
            $this->newBookingText($workshop, $booking, includeStatus: true),
            $this->bookingActionMarkup($booking)
        );
    }

    public function sendBookingStatusNotification(array $workshop, array $booking, string $actor): void
    {
        $this->sendToWorkshop($workshop, $this->bookingStatusText($workshop, $booking, $actor));
    }

    public function sendNewReviewNotification(array $workshop, array $review): void
    {
        $this->sendToWorkshop($workshop, $this->reviewText($workshop, $review));
    }

    public function newBookingText(array $workshop, array $booking, bool $includeStatus = false): string
    {
        $lines = [
            'Usta Top: yangi zakaz tushdi',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Zakaz ID: '.($booking['id'] ?? ''),
            'Mijoz: '.($booking['customerName'] ?? '—'),
            'Telefon: '.($booking['customerPhone'] ?? '—'),
            'Xizmat: '.($booking['serviceName'] ?? '—'),
            'Mashina: '.($booking['vehicleModel'] ?? '—'),
            'Vaqt: '.$this->formatDateTime((string) ($booking['dateTime'] ?? '')),
            'Narx: '.Money::formatUzs((int) ($booking['price'] ?? 0)),
        ];

        if ($includeStatus) {
            $lines[] = 'Holat: '.($booking['status'] ?? '—');
        }

        return implode("\n", $lines);
    }

    public function bookingStatusText(array $workshop, array $booking, string $actor): string
    {
        $lines = [
            'Usta Top: zakaz statusi yangilandi',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Zakaz ID: '.($booking['id'] ?? ''),
            'Holat: '.($booking['status'] ?? '—'),
            'Kim o‘zgartirdi: '.$actor,
            'Mijoz: '.($booking['customerName'] ?? '—'),
            'Telefon: '.($booking['customerPhone'] ?? '—'),
            'Xizmat: '.($booking['serviceName'] ?? '—'),
            'Mashina: '.($booking['vehicleModel'] ?? '—'),
            'Vaqt: '.$this->formatDateTime((string) ($booking['dateTime'] ?? '')),
            'Narx: '.Money::formatUzs((int) ($booking['price'] ?? 0)),
        ];

        if (! empty($booking['previousDateTime'])) {
            $lines[] = 'Oldingi vaqt: '.($booking['previousDateTime'] ?? '');
        }
        if (! empty($booking['cancelReasonId'])) {
            $lines[] = 'Bekor qilish sababi: '.($booking['cancelReasonId'] ?? '');
        }

        return implode("\n", $lines);
    }

    public function reviewText(array $workshop, array $review, bool $includeOwnerReply = true): string
    {
        $lines = [
            'Usta Top: yangi sharh qoldirildi',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Sharh ID: '.($review['id'] ?? ''),
            'Mijoz: '.($review['customerName'] ?? '—'),
            'Xizmat: '.($review['serviceName'] ?? '—'),
            'Baho: '.($review['rating'] ?? '—').'/5',
            'Sharh vaqti: '.$this->formatDateTime((string) ($review['createdAt'] ?? '')),
            'Sharh: '.($review['comment'] ?? '—'),
        ];

        $ownerReply = trim((string) ($review['ownerReply'] ?? ''));
        if ($includeOwnerReply && $ownerReply !== '') {
            $lines[] = 'Usta javobi: '.$ownerReply;
            $ownerReplyAt = trim((string) ($review['ownerReplyAt'] ?? ''));
            if ($ownerReplyAt !== '') {
                $lines[] = 'Javob vaqti: '.$this->formatDateTime($ownerReplyAt);
            }
        } else {
            $lines[] = '';
            $lines[] = 'Javob berish uchun shu xabarga reply yozing.';
        }

        return implode("\n", $lines);
    }

    public function reviewReplySavedText(array $workshop, array $review): string
    {
        return implode("\n", [
            'Usta Top: sharhga javob saqlandi',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Sharh ID: '.($review['id'] ?? ''),
            'Mijoz: '.($review['customerName'] ?? '—'),
            'Xizmat: '.($review['serviceName'] ?? '—'),
            'Javob: '.($review['ownerReply'] ?? '—'),
        ]);
    }

    public function bookingRescheduleSelectionText(array $workshop, array $booking, array $page): string
    {
        $suggestions = $page['slots'] ?? [];
        $suggestionsText = $suggestions === []
            ? ($page['isClosedDay'] ?? false
                ? 'Bu kun dam olish kuni.'
                : 'Bu kunda bo‘sh slot topilmadi.')
            : implode("\n", array_map(
                fn (string $slot): string => '• '.$this->formatDateTime($slot),
                $suggestions
            ));

        return implode("\n", [
            'Usta Top: yangi vaqtni tanlang',
            '',
            'Ustaxona: '.($workshop['name'] ?? ''),
            'Zakaz ID: '.($booking['id'] ?? ''),
            'Mijoz: '.($booking['customerName'] ?? '—'),
            'Xizmat: '.($booking['serviceName'] ?? '—'),
            'Joriy vaqt: '.$this->formatDateTime((string) ($booking['dateTime'] ?? '')),
            'Ko‘rsatilayotgan kun: '.$this->formatDate((string) ($page['date'] ?? '')),
            '',
            $suggestionsText,
        ]);
    }

    public function bookingActionMarkup(array $booking): ?array
    {
        $status = (string) ($booking['status'] ?? 'upcoming');
        if (in_array($status, ['completed', 'cancelled'], true)) {
            return null;
        }

        return [
            'inline_keyboard' => [
                array_values(array_filter([
                    in_array($status, ['upcoming', 'rescheduled'], true) ? [
                        'text' => 'Qabul qilindi',
                        'callback_data' => 'a:'.trim((string) ($booking['id'] ?? '')),
                    ] : null,
                    [
                        'text' => 'Ko‘chirish',
                        'callback_data' => 'r:'.trim((string) ($booking['id'] ?? '')),
                    ],
                ])),
                [
                    [
                        'text' => 'Bajardim',
                        'callback_data' => 'd:'.trim((string) ($booking['id'] ?? '')),
                    ],
                ],
                [
                    [
                        'text' => 'Bekor: jadval band',
                        'callback_data' => 'c:wb:'.trim((string) ($booking['id'] ?? '')),
                    ],
                    [
                        'text' => 'Bekor: usta yo‘q',
                        'callback_data' => 'c:mu:'.trim((string) ($booking['id'] ?? '')),
                    ],
                ],
                [
                    [
                        'text' => 'Bekor: ustaxona yopiq',
                        'callback_data' => 'c:wc:'.trim((string) ($booking['id'] ?? '')),
                    ],
                    [
                        'text' => 'Bekor: qism yo‘q',
                        'callback_data' => 'c:mp:'.trim((string) ($booking['id'] ?? '')),
                    ],
                ],
            ],
        ];
    }

    public function bookingRescheduleOptionsMarkup(array $booking, array $page): array
    {
        $rows = array_map(function (string $slot) use ($booking): array {
            return [[
                'text' => $this->formatSlotButton($slot),
                'callback_data' => 's:'.$this->slotCode($slot).':'.trim((string) ($booking['id'] ?? '')),
            ]];
        }, $page['slots'] ?? []);

        $navigationRow = array_values(array_filter([
            ($page['prevOffset'] ?? null) !== null ? [
                'text' => 'Oldingi kun',
                'callback_data' => 'r:'.(int) $page['prevOffset'].':'.trim((string) ($booking['id'] ?? '')),
            ] : null,
            ($page['nextOffset'] ?? null) !== null ? [
                'text' => 'Keyingi kun',
                'callback_data' => 'r:'.(int) $page['nextOffset'].':'.trim((string) ($booking['id'] ?? '')),
            ] : null,
        ]));

        if ($navigationRow !== []) {
            $rows[] = $navigationRow;
        }

        $rows[] = [[
            'text' => 'Ortga',
            'callback_data' => 'b:'.trim((string) ($booking['id'] ?? '')),
        ]];

        return ['inline_keyboard' => $rows];
    }

    private function sendToWorkshop(array $workshop, string $text, ?array $replyMarkup = null): void
    {
        if (! $this->telegramBot->isConfigured()) {
            throw new RuntimeException('Telegram bot token sozlanmagan');
        }

        $chatId = trim((string) ($workshop['telegramChatId'] ?? ''));
        if ($chatId === '') {
            throw new RuntimeException('Ustaxona uchun Telegram chat ID kiritilmagan');
        }

        if ($replyMarkup !== null) {
            $this->telegramBot->sendMessageWithMarkup($chatId, $text, $replyMarkup);
            return;
        }

        $this->telegramBot->sendMessage($chatId, $text);
    }

    private function formatDateTime(string $raw): string
    {
        if (trim($raw) === '') {
            return '—';
        }

        try {
            return CarbonImmutable::parse($raw)
                ->setTimezone(config('app.timezone'))
                ->format('Y-m-d H:i');
        } catch (\Throwable) {
            return $raw;
        }
    }

    private function formatSlotButton(string $raw): string
    {
        if (trim($raw) === '') {
            return '—';
        }

        try {
            return CarbonImmutable::parse($raw)
                ->setTimezone(config('app.timezone'))
                ->format('d.m H:i');
        } catch (\Throwable) {
            return $raw;
        }
    }

    private function formatDate(string $raw): string
    {
        if (trim($raw) === '') {
            return '—';
        }

        try {
            return CarbonImmutable::parse($raw)
                ->setTimezone(config('app.timezone'))
                ->format('Y-m-d');
        } catch (\Throwable) {
            return $raw;
        }
    }

    private function slotCode(string $raw): string
    {
        return CarbonImmutable::parse($raw)
            ->setTimezone(config('app.timezone'))
            ->format('YmdHi');
    }
}
