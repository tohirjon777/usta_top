<?php

namespace App\Support\UstaTop;

use Illuminate\Support\Facades\DB;
use RuntimeException;

class UstaTopDoctor
{
    public function __construct(
        private readonly JsonFileStore $store,
        private readonly TelegramBotService $telegramBot,
    ) {
    }

    /**
     * @return array<int, array{key:string,label:string,status:string,message:string}>
     */
    public function checks(): array
    {
        return [
            $this->appKeyCheck(),
            $this->appUrlCheck(),
            $this->databaseCheck(),
            $this->storageCheck(),
            $this->workshopImagesCheck(),
            $this->telegramCheck(),
            $this->smsCheck(),
            $this->queueCheck(),
        ];
    }

    /**
     * @return array{
     *   ok: bool,
     *   hasWarnings: bool,
     *   checks: array<int, array{key:string,label:string,status:string,message:string}>
     * }
     */
    public function summary(bool $strict = false): array
    {
        $checks = $this->checks();
        $hasFailures = collect($checks)->contains(
            fn (array $check): bool => $check['status'] === 'fail'
        );
        $hasWarnings = collect($checks)->contains(
            fn (array $check): bool => $check['status'] === 'warn'
        );

        return [
            'ok' => ! $hasFailures && (! $strict || ! $hasWarnings),
            'hasWarnings' => $hasWarnings,
            'checks' => $checks,
        ];
    }

    private function appKeyCheck(): array
    {
        $appKey = trim((string) config('app.key', ''));

        if ($appKey === '') {
            return $this->fail('app_key', 'APP key', 'APP_KEY sozlanmagan');
        }

        return $this->pass('app_key', 'APP key', 'APP_KEY mavjud');
    }

    private function appUrlCheck(): array
    {
        $appUrl = trim((string) config('app.url', ''));
        if ($appUrl === '') {
            return $this->warn('app_url', 'APP URL', 'APP_URL bo‘sh');
        }

        if (app()->environment('production') && preg_match('#(127\.0\.0\.1|localhost)#i', $appUrl)) {
            return $this->warn('app_url', 'APP URL', 'Production uchun APP_URL hali lokal manzilda');
        }

        return $this->pass('app_url', 'APP URL', $appUrl);
    }

    private function databaseCheck(): array
    {
        try {
            $connectionName = (string) config('database.default');
            $this->prepareDatabaseConnection($connectionName);
            DB::connection($connectionName)->getPdo();

            return $this->pass(
                'database',
                'Laravel DB',
                'Ulandi: '.$connectionName
            );
        } catch (\Throwable $error) {
            return $this->fail(
                'database',
                'Laravel DB',
                'DB ulanishida xato: '.$error->getMessage()
            );
        }
    }

    private function prepareDatabaseConnection(string $connectionName): void
    {
        $connection = config('database.connections.'.$connectionName);
        if (! is_array($connection)) {
            return;
        }

        $driver = strtolower(trim((string) ($connection['driver'] ?? '')));
        if ($driver !== 'sqlite') {
            return;
        }

        $database = trim((string) ($connection['database'] ?? ''));
        if ($database === '' || $database === ':memory:') {
            return;
        }

        $path = $this->normalizeSqlitePath($database);
        $directory = dirname($path);
        if (! is_dir($directory) && ! @mkdir($directory, 0775, true) && ! is_dir($directory)) {
            throw new RuntimeException('SQLite papkasini yaratib bo‘lmadi: '.$directory);
        }

        if (! file_exists($path) && ! @touch($path)) {
            throw new RuntimeException('SQLite faylini yaratib bo‘lmadi: '.$path);
        }

        config()->set('database.connections.'.$connectionName.'.database', $path);
    }

    private function normalizeSqlitePath(string $path): string
    {
        if ($path !== '' && ! str_starts_with($path, '/')) {
            return base_path(ltrim($path, '/'));
        }

        return $path;
    }

    private function storageCheck(): array
    {
        try {
            $this->store->ensureStorageReady();

            return $this->pass(
                'storage',
                'UstaTop storage',
                '['.$this->store->storageDriverName().'] '.$this->store->storageLocationDescription()
            );
        } catch (\Throwable $error) {
            return $this->fail(
                'storage',
                'UstaTop storage',
                'Storage tayyor emas: '.$error->getMessage()
            );
        }
    }

    private function workshopImagesCheck(): array
    {
        $directory = (string) config('ustatop.workshop_images_dir');
        if ($directory === '') {
            return $this->fail('workshop_images', 'Workshop rasmlari', 'Rasm papkasi sozlanmagan');
        }

        if (! is_dir($directory) && ! @mkdir($directory, 0775, true) && ! is_dir($directory)) {
            return $this->fail('workshop_images', 'Workshop rasmlari', 'Papka yaratib bo‘lmadi: '.$directory);
        }

        if (! is_writable($directory)) {
            return $this->fail('workshop_images', 'Workshop rasmlari', 'Papka yozishga yaroqsiz: '.$directory);
        }

        return $this->pass('workshop_images', 'Workshop rasmlari', $directory);
    }

    private function telegramCheck(): array
    {
        if (! $this->telegramBot->isConfigured()) {
            return $this->warn('telegram', 'Telegram bot', 'TELEGRAM_BOT_TOKEN sozlanmagan');
        }

        return $this->pass('telegram', 'Telegram bot', 'Token sozlangan');
    }

    private function smsCheck(): array
    {
        $driver = strtolower(trim((string) config('services.sms.driver', 'log')));

        return match ($driver) {
            'log' => $this->warn('sms', 'SMS driver', 'LOG/test rejimida ishlayapti'),
            'devsms' => $this->devSmsCheck(),
            default => $this->fail('sms', 'SMS driver', 'Noma’lum SMS driver: '.$driver),
        };
    }

    private function devSmsCheck(): array
    {
        $token = trim((string) config('services.sms.bearer_token', ''));
        if ($token === '') {
            return $this->fail('sms', 'SMS driver', 'DevSMS token sozlanmagan');
        }

        return $this->pass('sms', 'SMS driver', 'DevSMS tayyor');
    }

    private function queueCheck(): array
    {
        $queueConnection = strtolower(trim((string) config('queue.default', 'sync')));

        if (app()->environment('production') && $queueConnection === 'sync') {
            return $this->warn('queue', 'Queue', 'Production uchun queue hali sync rejimda');
        }

        return $this->pass('queue', 'Queue', 'Queue connection: '.$queueConnection);
    }

    private function pass(string $key, string $label, string $message): array
    {
        return [
            'key' => $key,
            'label' => $label,
            'status' => 'pass',
            'message' => $message,
        ];
    }

    private function warn(string $key, string $label, string $message): array
    {
        return [
            'key' => $key,
            'label' => $label,
            'status' => 'warn',
            'message' => $message,
        ];
    }

    private function fail(string $key, string $label, string $message): array
    {
        return [
            'key' => $key,
            'label' => $label,
            'status' => 'fail',
            'message' => $message,
        ];
    }
}
