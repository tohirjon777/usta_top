<?php

namespace App\Console\Commands;

use App\Support\UstaTop\JsonFileStore;
use App\Support\UstaTop\TelegramBotService;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopNotificationsService;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;
use RuntimeException;

class TelegramPollCommand extends Command
{
    protected $signature = 'ustatop:telegram-poll {--once : Process one updates batch and exit}';

    protected $description = 'Process Telegram callback actions for Usta Top bookings';

    public function __construct(
        private readonly TelegramBotService $telegramBot,
        private readonly UstaTopRepository $repository,
        private readonly JsonFileStore $store,
        private readonly WorkshopNotificationsService $notifications,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        if (! $this->telegramBot->isConfigured()) {
            $this->line('Telegram token yo‘q, poller o‘tkazib yuborildi.');

            return self::SUCCESS;
        }

        do {
            $this->processBatch();
            if ($this->option('once')) {
                break;
            }
            sleep(3);
        } while (true);

        return self::SUCCESS;
    }

    private function processBatch(): void
    {
        $state = $this->store->readArray(config('ustatop.telegram_sync_state_file'));
        $offset = isset($state['offset']) ? (int) $state['offset'] : null;

        try {
            $updates = $this->telegramBot->getUpdates($offset, 50);
        } catch (\Throwable $error) {
            report($error);

            return;
        }

        foreach ($updates as $update) {
            $updateId = (int) ($update['update_id'] ?? 0);
            if ($updateId > 0) {
                $state['offset'] = $updateId + 1;
                $this->store->writeArray(config('ustatop.telegram_sync_state_file'), $state);
            }

            $callback = $update['callback_query'] ?? null;
            if (is_array($callback)) {
                $this->handleCallbackQuery($callback);
                continue;
            }

            $message = $update['message'] ?? null;
            if (is_array($message)) {
                $this->handleMessage($message);
            }
        }
    }

    private function handleMessage(array $message): void
    {
        try {
            $text = trim((string) ($message['text'] ?? ''));
            $chatId = trim((string) (($message['chat']['id'] ?? '')));
            if ($text === '' || $chatId === '') {
                return;
            }

            if (str_starts_with($text, '/start ')) {
                $this->handleStartLinkMessage($message, $chatId, $text);

                return;
            }

            $replyToMessage = $message['reply_to_message'] ?? null;
            if (! is_array($replyToMessage)) {
                return;
            }

            $reviewId = $this->extractReviewId((string) ($replyToMessage['text'] ?? ''));
            if ($reviewId === '') {
                return;
            }

            $review = $this->repository->reviewById($reviewId);
            if (! $review) {
                return;
            }

            $workshop = $this->repository->workshopById((string) ($review['workshopId'] ?? ''));
            if (! $workshop) {
                return;
            }

            if (trim((string) ($workshop['telegramChatId'] ?? '')) !== $chatId) {
                return;
            }

            $updatedReview = $this->repository->replyReview($reviewId, $text, 'owner_telegram');
            $replyToMessageId = (int) ($replyToMessage['message_id'] ?? 0);
            if ($replyToMessageId > 0) {
                $this->telegramBot->editMessageText(
                    $chatId,
                    $replyToMessageId,
                    $this->notifications->reviewText($workshop, $updatedReview),
                );
            }

            $this->telegramBot->sendMessage(
                $chatId,
                $this->notifications->reviewReplySavedText($workshop, $updatedReview),
            );
        } catch (\Throwable $error) {
            report($error);
        }
    }

    private function handleCallbackQuery(array $callback): void
    {
        $callbackId = trim((string) ($callback['id'] ?? ''));
        $data = trim((string) ($callback['data'] ?? ''));
        $message = $callback['message'] ?? null;
        $chatId = is_array($message) ? trim((string) (($message['chat']['id'] ?? ''))) : '';
        $messageId = is_array($message) ? (int) ($message['message_id'] ?? 0) : 0;

        if ($callbackId === '' || $data === '') {
            return;
        }

        try {
            $parts = explode(':', $data);
            $action = $parts[0] ?? '';
            $bookingId = '';
            $cancelReasonId = '';
            $scheduledAt = '';
            $pageOffset = 0;

            if ($action === 'a' || $action === 'd' || $action === 'b') {
                $bookingId = $parts[1] ?? '';
            } elseif ($action === 'r') {
                if (count($parts) >= 3) {
                    $pageOffset = max(0, (int) ($parts[1] ?? 0));
                    $bookingId = $parts[2] ?? '';
                } else {
                    $bookingId = $parts[1] ?? '';
                }
            } elseif ($action === 'c') {
                $cancelReasonId = $this->mapCancellationReason($parts[1] ?? '');
                $bookingId = $parts[2] ?? '';
            } elseif ($action === 's') {
                $scheduledAt = $this->parseSlotCode($parts[1] ?? '');
                $bookingId = $parts[2] ?? '';
            } else {
                $this->telegramBot->answerCallbackQuery($callbackId, 'Bu tugma hali Laravelga ko‘chirilmagan');

                return;
            }

            $booking = $this->repository->bookingById(trim($bookingId));
            if (! $booking) {
                throw new RuntimeException('Zakaz topilmadi');
            }

            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if (! $workshop) {
                throw new RuntimeException('Ustaxona topilmadi');
            }

            if ($chatId === '' || trim((string) ($workshop['telegramChatId'] ?? '')) !== $chatId) {
                throw new RuntimeException('Bu chat ushbu ustaxonaga ulanmagan');
            }

            if ($action === 'r') {
                $page = $this->repository->rescheduleSlotPage(
                    (string) ($workshop['id'] ?? ''),
                    (string) ($booking['serviceId'] ?? ''),
                    (string) ($booking['dateTime'] ?? ''),
                    (string) ($booking['id'] ?? ''),
                    $pageOffset,
                );

                $this->telegramBot->editMessageText(
                    $chatId,
                    $messageId,
                    $this->notifications->bookingRescheduleSelectionText($workshop, $booking, $page),
                    $this->notifications->bookingRescheduleOptionsMarkup($booking, $page),
                );
                $this->telegramBot->answerCallbackQuery(
                    $callbackId,
                    ($page['slots'] ?? []) === [] ? 'Bu kun uchun bo‘sh slot yo‘q' : 'Yangi vaqtni tanlang'
                );

                return;
            }

            if ($action === 'b') {
                $this->refreshBookingMessage($chatId, $messageId, $workshop, $booking);
                $this->telegramBot->answerCallbackQuery($callbackId, 'Asosiy tugmalar qaytarildi');

                return;
            }

            $updated = match ($action) {
                'a' => $this->repository->updateBookingStatus((string) $booking['id'], 'accepted', [
                    'actorRole' => 'owner_telegram',
                ]),
                'd' => $this->repository->updateBookingStatus((string) $booking['id'], 'completed', [
                    'actorRole' => 'owner_telegram',
                ]),
                'c' => $this->repository->updateBookingStatus((string) $booking['id'], 'cancelled', [
                    'actorRole' => 'owner_telegram',
                    'cancelReasonId' => $cancelReasonId,
                ]),
                's' => $this->repository->updateBookingStatus((string) $booking['id'], 'rescheduled', [
                    'actorRole' => 'owner_telegram',
                    'scheduledAt' => $scheduledAt,
                ]),
            };

            $this->telegramBot->answerCallbackQuery($callbackId, match ($action) {
                'a' => 'Zakaz qabul qilindi',
                'd' => 'Zakaz bajarildi deb belgilandi',
                'c' => 'Zakaz bekor qilindi',
                's' => 'Zakaz yangi vaqtga ko‘chirildi',
            });

            $this->refreshBookingMessage($chatId, $messageId, $workshop, $updated);
        } catch (\Throwable $error) {
            report($error);
            try {
                $this->telegramBot->answerCallbackQuery($callbackId, $error->getMessage());
            } catch (\Throwable) {
            }
        }
    }

    private function refreshBookingMessage(string $chatId, int $messageId, array $workshop, array $booking): void
    {
        if ($messageId <= 0) {
            return;
        }

        $this->telegramBot->editMessageText(
            $chatId,
            $messageId,
            $this->notifications->newBookingText($workshop, $booking, includeStatus: true),
            $this->notifications->bookingActionMarkup($booking),
        );

        if (in_array((string) ($booking['status'] ?? ''), ['completed', 'cancelled'], true)) {
            $this->telegramBot->editMessageReplyMarkup($chatId, $messageId);
        }
    }

    private function handleStartLinkMessage(array $message, string $chatId, string $text): void
    {
        $parts = preg_split('/\s+/', $text);
        $code = trim((string) ($parts[1] ?? ''));
        if ($code === '') {
            return;
        }

        $workshop = $this->repository->workshopByTelegramLinkCode($code);
        if (! $workshop) {
            return;
        }

        $chatLabel = trim((string) (($message['chat']['title'] ?? $message['chat']['username'] ?? $message['chat']['first_name'] ?? '')));

        $this->repository->updateWorkshop((string) ($workshop['id'] ?? ''), [
            'telegramChatId' => $chatId,
            'telegramChatLabel' => $chatLabel,
            'telegramLinkCode' => '',
        ]);

        $this->telegramBot->sendMessage(
            $chatId,
            'Usta Top: Telegram ushbu ustaxonaga muvaffaqiyatli ulandi.',
        );
    }

    private function mapCancellationReason(string $shortCode): string
    {
        return match (trim($shortCode)) {
            'wb' => 'workshop_busy',
            'mu' => 'master_unavailable',
            'wc' => 'workshop_closed',
            'mp' => 'missing_parts',
            'cr' => 'customer_request',
            default => 'workshop_busy',
        };
    }

    private function parseSlotCode(string $code): string
    {
        $normalized = trim($code);
        if (! preg_match('/^\d{12}$/', $normalized)) {
            throw new RuntimeException('Yangi vaqt topilmadi');
        }

        $dateTime = CarbonImmutable::createFromFormat(
            'YmdHi',
            $normalized,
            config('app.timezone')
        );

        if (! $dateTime) {
            throw new RuntimeException('Yangi vaqt topilmadi');
        }

        return $dateTime->utc()->toIso8601String();
    }

    private function extractReviewId(string $text): string
    {
        if (preg_match('/Sharh ID:\s*([A-Za-z0-9._-]+)/u', $text, $matches) !== 1) {
            return '';
        }

        return trim((string) ($matches[1] ?? ''));
    }
}
