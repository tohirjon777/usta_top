<?php

namespace App\Support\UstaTop;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class TelegramBotService
{
    public function isConfigured(): bool
    {
        return trim((string) config('services.telegram.bot_token')) !== '';
    }

    public function sendMessage(string $chatId, string $text): void
    {
        $this->post('sendMessage', [
            'chat_id' => trim($chatId),
            'text' => trim($text),
            'disable_web_page_preview' => true,
        ]);
    }

    public function sendMessageWithMarkup(string $chatId, string $text, array $replyMarkup): void
    {
        $this->post('sendMessage', [
            'chat_id' => trim($chatId),
            'text' => trim($text),
            'disable_web_page_preview' => true,
            'reply_markup' => $replyMarkup,
        ]);
    }

    public function getMe(): array
    {
        $decoded = $this->get('getMe');
        $result = $decoded['result'] ?? null;
        if (! is_array($result)) {
            throw new RuntimeException('Telegram bot ma’lumoti topilmadi');
        }

        return $result;
    }

    public function getUpdates(?int $offset = null, int $limit = 100): array
    {
        $decoded = $this->get('getUpdates', array_filter([
            'offset' => $offset,
            'limit' => $limit,
        ], static fn ($value) => $value !== null));

        $result = $decoded['result'] ?? [];
        if (! is_array($result)) {
            return [];
        }

        return array_values(array_filter($result, 'is_array'));
    }

    public function answerCallbackQuery(string $callbackQueryId, ?string $text = null): void
    {
        $payload = ['callback_query_id' => trim($callbackQueryId)];
        if ($text !== null && trim($text) !== '') {
            $payload['text'] = trim($text);
        }

        $this->post('answerCallbackQuery', $payload);
    }

    public function editMessageText(string $chatId, int $messageId, string $text, ?array $replyMarkup = null): void
    {
        $payload = [
            'chat_id' => trim($chatId),
            'message_id' => $messageId,
            'text' => trim($text),
            'disable_web_page_preview' => true,
        ];

        if ($replyMarkup !== null) {
            $payload['reply_markup'] = $replyMarkup;
        }

        $this->post('editMessageText', $payload);
    }

    public function editMessageReplyMarkup(string $chatId, int $messageId, ?array $replyMarkup = null): void
    {
        $payload = [
            'chat_id' => trim($chatId),
            'message_id' => $messageId,
        ];

        if ($replyMarkup !== null) {
            $payload['reply_markup'] = $replyMarkup;
        }

        $this->post('editMessageReplyMarkup', $payload);
    }

    private function get(string $method, array $query = []): array
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Telegram bot token sozlanmagan');
        }

        $response = Http::timeout(8)
            ->acceptJson()
            ->get($this->methodUrl($method), $query);

        return $this->decodeResponse($response->status(), $response->json());
    }

    private function post(string $method, array $payload): array
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Telegram bot token sozlanmagan');
        }

        $response = Http::timeout(8)
            ->acceptJson()
            ->asJson()
            ->post($this->methodUrl($method), $payload);

        return $this->decodeResponse($response->status(), $response->json());
    }

    private function decodeResponse(int $statusCode, mixed $decoded): array
    {
        if ($statusCode < 200 || $statusCode >= 300) {
            throw new RuntimeException('Telegram API xatoligi: HTTP '.$statusCode);
        }

        if (! is_array($decoded)) {
            throw new RuntimeException('Telegram javobi kutilgan formatda emas');
        }

        if (($decoded['ok'] ?? false) !== true) {
            $message = $decoded['description'] ?? 'Telegram so‘rovi bajarilmadi';
            throw new RuntimeException((string) $message);
        }

        return $decoded;
    }

    private function methodUrl(string $method): string
    {
        $token = trim((string) config('services.telegram.bot_token'));

        return 'https://api.telegram.org/bot'.$token.'/'.$method;
    }
}
