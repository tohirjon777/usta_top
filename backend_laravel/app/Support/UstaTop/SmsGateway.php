<?php

namespace App\Support\UstaTop;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class SmsGateway
{
    public function sendOtp(string $phone, string $purpose, string $code): array
    {
        $driver = strtolower(trim((string) config('services.sms.driver', 'log')));

        return match ($driver) {
            'devsms' => $this->sendViaDevSms($phone, $purpose, $code),
            'log' => $this->sendViaLog($phone, $purpose, $code),
            default => throw new RuntimeException('SMS driver noto‘g‘ri sozlangan'),
        };
    }

    private function sendViaDevSms(string $phone, string $purpose, string $code): array
    {
        $token = trim((string) config('services.sms.bearer_token', ''));
        if ($token === '') {
            throw new RuntimeException('SMS token sozlanmagan');
        }

        $baseUrl = rtrim((string) config('services.sms.base_url', 'https://devsms.uz/api'), '/');
        $serviceName = trim((string) config('services.sms.service_name', 'Usta Top'));
        $templateType = match ($purpose) {
            'register' => 3,
            'password_reset' => 2,
            default => 1,
        };

        $response = Http::withToken($token)
            ->acceptJson()
            ->asJson()
            ->timeout(20)
            ->post($baseUrl.'/send_sms.php', [
                'phone' => $this->normalizePhone($phone),
                'type' => 'universal_otp',
                'template_type' => $templateType,
                'service_name' => $serviceName,
                'otp_code' => $code,
            ]);

        $payload = $response->json();
        if (! $response->successful() || ! is_array($payload) || ($payload['success'] ?? false) !== true) {
            $message = is_array($payload) ? (string) ($payload['error'] ?? $payload['message'] ?? '') : '';
            throw new RuntimeException($message !== '' ? $message : 'SMS yuborib bo‘lmadi');
        }

        return [
            'driver' => 'devsms',
            'message' => (string) ($payload['message'] ?? 'SMS yuborildi'),
            'requestId' => (string) (($payload['data']['request_id'] ?? '') ?: ($payload['data']['sms_id'] ?? '')),
            'debugCode' => null,
        ];
    }

    private function sendViaLog(string $phone, string $purpose, string $code): array
    {
        Log::info('UstaTop SMS OTP (log driver)', [
            'phone' => $phone,
            'purpose' => $purpose,
            'code' => $code,
        ]);

        return [
            'driver' => 'log',
            'message' => 'SMS test rejimida logga yozildi',
            'requestId' => 'log-'.now()->format('Uu'),
            'debugCode' => app()->environment('local', 'testing') ? $code : null,
        ];
    }

    private function normalizePhone(string $phone): string
    {
        return preg_replace('/\D+/', '', $phone) ?? '';
    }
}
