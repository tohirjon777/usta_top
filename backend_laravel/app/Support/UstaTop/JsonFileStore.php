<?php

namespace App\Support\UstaTop;

use PDO;
use RuntimeException;

class JsonFileStore
{
    private const SQLITE_TABLE = 'ustatop_json_documents';
    /**
     * @var array<string, PDO>
     */
    private static array $sqliteConnections = [];

    public function readArray(string $path, array $default = []): array
    {
        if ($this->storageDriver() === 'sqlite') {
            return $this->readArrayFromSqlite($path, $default);
        }

        return $this->readArrayFromFile($path, $default);
    }

    public function writeArray(string $path, array $data): void
    {
        if ($this->storageDriver() === 'sqlite') {
            $this->writeArrayToSqlite($path, $data);

            return;
        }

        $this->writeArrayToFile($path, $data);
    }

    public function sqlitePath(): string
    {
        return $this->configuredSqlitePath();
    }

    public function ensureSqliteReady(): void
    {
        $this->sqliteConnection();
    }

    public static function clearSqliteConnectionCache(?string $sqlitePath = null): void
    {
        if ($sqlitePath === null) {
            self::$sqliteConnections = [];

            return;
        }

        unset(self::$sqliteConnections[$sqlitePath]);
    }

    public function syncFilesToSqlite(array $paths): void
    {
        if ($this->storageDriver() !== 'sqlite') {
            return;
        }

        foreach ($paths as $path) {
            $normalizedPath = trim((string) $path);
            if ($normalizedPath === '') {
                continue;
            }

            $this->readArrayFromSqlite($normalizedPath, []);
        }
    }

    private function readArrayFromSqlite(string $path, array $default): array
    {
        $pdo = $this->sqliteConnection();
        $key = $this->documentKey($path);
        $statement = $pdo->prepare('SELECT payload FROM '.self::SQLITE_TABLE.' WHERE document_key = :key LIMIT 1');
        $statement->execute(['key' => $key]);
        $payload = $statement->fetchColumn();

        if (is_string($payload)) {
            $decoded = json_decode($payload, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                return $decoded;
            }

            $this->quarantineCorruptFile($path, $payload);
            $this->writeArrayToSqlite($path, $default);

            return $default;
        }

        if (is_file($path)) {
            $decoded = $this->decodeFileContents($path, $default);
            $this->writeArrayToSqlite($path, $decoded);

            return $decoded;
        }

        $this->writeArrayToSqlite($path, $default);

        return $default;
    }

    private function writeArrayToSqlite(string $path, array $data): void
    {
        $pdo = $this->sqliteConnection();
        $encoded = $this->encodeArray($path, $data);
        $statement = $pdo->prepare(
            'INSERT INTO '.self::SQLITE_TABLE.' (document_key, payload, updated_at)
             VALUES (:key, :payload, :updated_at)
             ON CONFLICT(document_key) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at'
        );
        $statement->execute([
            'key' => $this->documentKey($path),
            'payload' => $encoded,
            'updated_at' => date(DATE_ATOM),
        ]);
    }

    private function sqliteConnection(): PDO
    {
        $sqlitePath = $this->configuredSqlitePath();
        if (isset(self::$sqliteConnections[$sqlitePath])) {
            return self::$sqliteConnections[$sqlitePath];
        }

        $directory = dirname($sqlitePath);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }
        if (! file_exists($sqlitePath)) {
            touch($sqlitePath);
        }

        $pdo = new PDO('sqlite:'.$sqlitePath);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS '.self::SQLITE_TABLE.' (
                document_key TEXT PRIMARY KEY,
                payload TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )'
        );

        self::$sqliteConnections[$sqlitePath] = $pdo;

        return $pdo;
    }

    private function configuredSqlitePath(): string
    {
        $path = $this->config('ustatop.sqlite_file')
            ?? getenv('USTATOP_SQLITE_FILE')
            ?: dirname(__DIR__, 3).'/storage/app/ustatop/ustatop.sqlite';

        $path = (string) $path;

        if ($path !== '' && ! str_starts_with($path, '/')) {
            $basePath = function_exists('base_path')
                ? base_path()
                : dirname(__DIR__, 3);

            return rtrim($basePath, '/').'/'.ltrim($path, '/');
        }

        return $path;
    }

    private function storageDriver(): string
    {
        $driver = $this->config('ustatop.storage_driver') ?? getenv('USTATOP_STORAGE_DRIVER') ?: 'file';

        return strtolower(trim((string) $driver)) === 'sqlite' ? 'sqlite' : 'file';
    }

    private function config(string $key): mixed
    {
        if (function_exists('config')) {
            try {
                return config($key);
            } catch (\Throwable) {
                return null;
            }
        }

        return null;
    }

    private function documentKey(string $path): string
    {
        $realPath = realpath($path);

        return $realPath !== false ? $realPath : $path;
    }

    private function readArrayFromFile(string $path, array $default = []): array
    {
        $this->ensureFile($path, $default);

        $handle = fopen($path, 'rb');
        if ($handle === false) {
            throw new RuntimeException('JSON faylni o‘qib bo‘lmadi: '.$path);
        }

        try {
            if (! flock($handle, LOCK_SH)) {
                throw new RuntimeException('JSON faylni o‘qish uchun lock olib bo‘lmadi: '.$path);
            }

            $contents = stream_get_contents($handle);
            flock($handle, LOCK_UN);
        } finally {
            fclose($handle);
        }

        $decoded = json_decode((string) $contents, true);

        if (json_last_error() !== JSON_ERROR_NONE || ! is_array($decoded)) {
            $this->quarantineCorruptFile($path, (string) $contents);
            $this->writeArrayToFile($path, $default);

            return $default;
        }

        return $decoded;
    }

    private function writeArrayToFile(string $path, array $data): void
    {
        $directory = dirname($path);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }

        $encoded = $this->encodeArray($path, $data);

        $temporaryPath = sprintf(
            '%s/.%s.%s.tmp',
            $directory,
            basename($path),
            bin2hex(random_bytes(6))
        );

        $written = file_put_contents($temporaryPath, $encoded, LOCK_EX);
        if ($written === false) {
            @unlink($temporaryPath);
            throw new RuntimeException('JSON vaqtinchalik faylini yozib bo‘lmadi: '.$temporaryPath);
        }

        if (! @rename($temporaryPath, $path)) {
            @unlink($temporaryPath);
            throw new RuntimeException('JSON faylini atomik almashtirib bo‘lmadi: '.$path);
        }
    }

    private function ensureFile(string $path, array $default): void
    {
        $directory = dirname($path);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }

        if (! file_exists($path)) {
            $this->writeArrayToFile($path, $default);
        }
    }

    private function encodeArray(string $path, array $data): string
    {
        $encoded = json_encode(
            $data,
            JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
        );

        if (! is_string($encoded)) {
            throw new RuntimeException('JSON encode qilishda xatolik yuz berdi: '.$path);
        }

        return $encoded;
    }

    private function decodeFileContents(string $path, array $default): array
    {
        $contents = (string) @file_get_contents($path);
        $decoded = json_decode($contents, true);

        if (json_last_error() !== JSON_ERROR_NONE || ! is_array($decoded)) {
            $this->quarantineCorruptFile($path, $contents);

            return $default;
        }

        return $decoded;
    }

    private function quarantineCorruptFile(string $path, string $contents): void
    {
        if (trim($contents) === '') {
            return;
        }

        $corruptPath = sprintf('%s.corrupt.%s', $path, date('Ymd-His'));

        @file_put_contents($corruptPath, $contents, LOCK_EX);
    }
}
