<?php

namespace App\Support\UstaTop;

use Carbon\CarbonImmutable;
use RuntimeException;

class SmsVerificationService
{
    private const PURPOSE_REGISTER = 'register';
    private const PURPOSE_PASSWORD_RESET = 'password_reset';
    private const CODE_LENGTH = 6;
    private const EXPIRES_IN_SECONDS = 300;
    private const RESEND_AFTER_SECONDS = 60;
    private const MAX_ATTEMPTS = 5;

    public function __construct(
        private readonly JsonFileStore $store,
        private readonly SmsGateway $smsGateway,
        private readonly UstaTopRepository $repository,
    ) {
    }

    public function sendRegistrationCode(string $phone): array
    {
        $normalizedPhone = $this->normalizePhone($phone);
        if ($this->repository->hasUserWithPhone($normalizedPhone)) {
            throw new RuntimeException('Bu telefon raqam bilan akkaunt allaqachon mavjud');
        }

        return $this->sendCode($normalizedPhone, self::PURPOSE_REGISTER);
    }

    public function verifyRegistrationCode(
        string $fullName,
        string $phone,
        string $password,
        string $code
    ): array {
        $normalizedPhone = $this->normalizePhone($phone);
        if ($this->repository->hasUserWithPhone($normalizedPhone)) {
            throw new RuntimeException('Bu telefon raqam bilan akkaunt allaqachon mavjud');
        }

        $this->consumeCode($normalizedPhone, self::PURPOSE_REGISTER, $code);
        $user = $this->repository->createUser(trim($fullName), $normalizedPhone, $password);
        $auth = $this->repository->login($user['phone'], $user['password']);

        if (! is_array($auth)) {
            throw new RuntimeException('Akkaunt yaratildi, lekin kirib bo‘lmadi');
        }

        return [
            'token' => $auth['token'],
            'refreshToken' => 'refresh-'.$auth['token'],
            'expiresAt' => now()->addDays(30)->toIso8601String(),
            'user' => $auth['user'],
        ];
    }

    public function sendPasswordResetCode(string $phone): array
    {
        $normalizedPhone = $this->normalizePhone($phone);
        if (! $this->repository->hasUserWithPhone($normalizedPhone)) {
            throw new RuntimeException('Bu telefon raqam bilan akkaunt topilmadi');
        }

        return $this->sendCode($normalizedPhone, self::PURPOSE_PASSWORD_RESET);
    }

    public function verifyPasswordResetCode(string $phone, string $newPassword, string $code): void
    {
        $normalizedPhone = $this->normalizePhone($phone);
        if (! $this->repository->hasUserWithPhone($normalizedPhone)) {
            throw new RuntimeException('Bu telefon raqam bilan akkaunt topilmadi');
        }

        $this->consumeCode($normalizedPhone, self::PURPOSE_PASSWORD_RESET, $code);
        $this->repository->resetPassword($normalizedPhone, $newPassword);
    }

    private function sendCode(string $phone, string $purpose): array
    {
        $now = CarbonImmutable::now(config('app.timezone'));
        $verifications = $this->rawVerifications();
        $index = $this->verificationIndex($verifications, $phone, $purpose);
        $existing = $index === null ? null : $verifications[$index];

        if ($existing !== null) {
            $resendAvailableAt = $this->parseTime((string) ($existing['resendAvailableAt'] ?? ''));
            if ($resendAvailableAt !== null && $now->lt($resendAvailableAt)) {
                $seconds = $resendAvailableAt->diffInSeconds($now);
                throw new RuntimeException("Kodni qayta yuborish uchun {$seconds} soniya kuting");
            }
        }

        $code = $this->generateCode();
        $sendResult = $this->smsGateway->sendOtp($phone, $purpose, $code);

        $record = [
            'id' => (string) ($existing['id'] ?? ('otp-'.now()->format('Uu'))),
            'phone' => $phone,
            'purpose' => $purpose,
            'codeHash' => $this->hashCode($phone, $purpose, $code),
            'expiresAt' => $now->addSeconds(self::EXPIRES_IN_SECONDS)->toIso8601String(),
            'resendAvailableAt' => $now->addSeconds(self::RESEND_AFTER_SECONDS)->toIso8601String(),
            'attempts' => 0,
            'maxAttempts' => self::MAX_ATTEMPTS,
            'verifiedAt' => null,
            'provider' => (string) ($sendResult['driver'] ?? 'unknown'),
            'providerRequestId' => (string) ($sendResult['requestId'] ?? ''),
            'createdAt' => (string) ($existing['createdAt'] ?? $now->toIso8601String()),
            'updatedAt' => $now->toIso8601String(),
        ];

        if ($index === null) {
            $verifications[] = $record;
        } else {
            $verifications[$index] = $record;
        }

        $this->saveVerifications($verifications);

        $response = [
            'ok' => true,
            'purpose' => $purpose,
            'expiresAt' => $record['expiresAt'],
            'resendAvailableAt' => $record['resendAvailableAt'],
            'channel' => 'sms',
            'driver' => $record['provider'],
        ];

        if (($sendResult['debugCode'] ?? null) !== null) {
            $response['debugCode'] = (string) $sendResult['debugCode'];
        }

        return $response;
    }

    private function consumeCode(string $phone, string $purpose, string $code): void
    {
        $verifications = $this->rawVerifications();
        $index = $this->verificationIndex($verifications, $phone, $purpose);
        if ($index === null) {
            throw new RuntimeException('Tasdiqlash kodi topilmadi');
        }

        $verification = $verifications[$index];
        $now = CarbonImmutable::now(config('app.timezone'));
        $expiresAt = $this->parseTime((string) ($verification['expiresAt'] ?? ''));
        if ($expiresAt === null || $now->gte($expiresAt)) {
            unset($verifications[$index]);
            $this->saveVerifications($verifications);
            throw new RuntimeException('Tasdiqlash kodi muddati tugagan');
        }

        $attempts = (int) ($verification['attempts'] ?? 0);
        $maxAttempts = max(1, (int) ($verification['maxAttempts'] ?? self::MAX_ATTEMPTS));
        $hashMatches = hash_equals(
            (string) ($verification['codeHash'] ?? ''),
            $this->hashCode($phone, $purpose, trim($code))
        );

        if (! $hashMatches) {
            $attempts++;
            $verification['attempts'] = $attempts;
            $verification['updatedAt'] = $now->toIso8601String();

            if ($attempts >= $maxAttempts) {
                unset($verifications[$index]);
            } else {
                $verifications[$index] = $verification;
            }

            $this->saveVerifications($verifications);
            throw new RuntimeException('Tasdiqlash kodi noto‘g‘ri');
        }

        unset($verifications[$index]);
        $this->saveVerifications($verifications);
    }

    private function rawVerifications(): array
    {
        return array_values($this->store->readArray(config('ustatop.sms_verifications_file')));
    }

    private function saveVerifications(array $verifications): void
    {
        $this->store->writeArray(config('ustatop.sms_verifications_file'), array_values($verifications));
    }

    private function verificationIndex(array $verifications, string $phone, string $purpose): ?int
    {
        foreach ($verifications as $index => $verification) {
            if (
                $this->normalizePhone((string) ($verification['phone'] ?? '')) === $phone
                && (string) ($verification['purpose'] ?? '') === $purpose
            ) {
                return $index;
            }
        }

        return null;
    }

    private function hashCode(string $phone, string $purpose, string $code): string
    {
        $appKey = (string) config('app.key', 'ustatop');

        return hash('sha256', $appKey.'|'.$phone.'|'.$purpose.'|'.trim($code));
    }

    private function normalizePhone(string $phone): string
    {
        return preg_replace('/\s+/', '', trim($phone)) ?? '';
    }

    private function parseTime(string $value): ?CarbonImmutable
    {
        if (trim($value) === '') {
            return null;
        }

        return CarbonImmutable::parse($value)->setTimezone(config('app.timezone'));
    }

    private function generateCode(): string
    {
        return str_pad((string) random_int(0, 999999), self::CODE_LENGTH, '0', STR_PAD_LEFT);
    }
}
