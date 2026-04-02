<?php

namespace App\Support\UstaTop;

use PDO;
use RuntimeException;

class JsonFileStore
{
    private const SQLITE_TABLE = 'ustatop_json_documents';
    private const DATABASE_TABLE = 'ustatop_json_documents';
    /**
     * @var array<string, PDO>
     */
    private static array $sqliteConnections = [];
    /**
     * @var array<string, PDO>
     */
    private static array $databaseConnections = [];

    public function readArray(string $path, array $default = []): array
    {
        return match ($this->storageDriver()) {
            'sqlite' => $this->readArrayFromSqlite($path, $default),
            'database' => $this->readArrayFromDatabase($path, $default),
            default => $this->readArrayFromFile($path, $default),
        };
    }

    public function writeArray(string $path, array $data): void
    {
        match ($this->storageDriver()) {
            'sqlite' => $this->writeArrayToSqlite($path, $data),
            'database' => $this->writeArrayToDatabase($path, $data),
            default => $this->writeArrayToFile($path, $data),
        };
    }

    public function sqlitePath(): string
    {
        return $this->configuredSqlitePath();
    }

    public function ensureStorageReady(): void
    {
        match ($this->storageDriver()) {
            'sqlite' => $this->ensureSqliteReady(),
            'database' => $this->ensureDatabaseReady(),
            default => null,
        };
    }

    public function storageDriverName(): string
    {
        return $this->storageDriver();
    }

    public function storageLocationDescription(): string
    {
        return match ($this->storageDriver()) {
            'sqlite' => $this->configuredSqlitePath(),
            'database' => sprintf(
                '%s:%s',
                $this->databaseConnectionName(),
                $this->databaseTableName()
            ),
            default => 'json-files',
        };
    }

    public function ensureSqliteReady(): void
    {
        $this->sqliteConnection();
    }

    public function ensureDatabaseReady(): void
    {
        $this->databaseConnection();
    }

    public static function clearSqliteConnectionCache(?string $sqlitePath = null): void
    {
        if ($sqlitePath === null) {
            self::$sqliteConnections = [];

            return;
        }

        unset(self::$sqliteConnections[$sqlitePath]);
    }

    public static function clearDatabaseConnectionCache(?string $cacheKey = null): void
    {
        if ($cacheKey === null) {
            self::$databaseConnections = [];

            return;
        }

        unset(self::$databaseConnections[$cacheKey]);
    }

    public function syncFilesToStorage(array $paths): void
    {
        if (! in_array($this->storageDriver(), ['sqlite', 'database'], true)) {
            return;
        }

        foreach ($paths as $path) {
            $normalizedPath = trim((string) $path);
            if ($normalizedPath === '') {
                continue;
            }

            $this->readArray($normalizedPath, []);
        }
    }

    public function syncFilesToSqlite(array $paths): void
    {
        $this->syncFilesToStorage($paths);
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

    private function readArrayFromDatabase(string $path, array $default): array
    {
        $pdo = $this->databaseConnection();
        $statement = $pdo->prepare(
            'SELECT payload FROM '.$this->databaseTableName().' WHERE document_hash = :hash LIMIT 1'
        );
        $statement->execute(['hash' => $this->documentHash($path)]);
        $payload = $statement->fetchColumn();

        if (is_string($payload)) {
            $decoded = json_decode($payload, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                return $decoded;
            }

            $this->quarantineCorruptFile($path, $payload);
            $this->writeArrayToDatabase($path, $default);

            return $default;
        }

        if (is_file($path)) {
            $decoded = $this->decodeFileContents($path, $default);
            $this->writeArrayToDatabase($path, $decoded);

            return $decoded;
        }

        $this->writeArrayToDatabase($path, $default);

        return $default;
    }

    private function writeArrayToDatabase(string $path, array $data): void
    {
        $pdo = $this->databaseConnection();
        $encoded = $this->encodeArray($path, $data);
        $driver = $this->databasePdoDriver($pdo);
        $table = $this->databaseTableName();

        $sql = match ($driver) {
            'mysql', 'mariadb' => 'INSERT INTO '.$table.' (document_hash, document_key, payload, updated_at)
                VALUES (:hash, :key, :payload, :updated_at)
                ON DUPLICATE KEY UPDATE
                    document_key = VALUES(document_key),
                    payload = VALUES(payload),
                    updated_at = VALUES(updated_at)',
            default => 'INSERT INTO '.$table.' (document_hash, document_key, payload, updated_at)
                VALUES (:hash, :key, :payload, :updated_at)
                ON CONFLICT(document_hash) DO UPDATE SET
                    document_key = excluded.document_key,
                    payload = excluded.payload,
                    updated_at = excluded.updated_at',
        };

        $statement = $pdo->prepare($sql);
        $statement->execute([
            'hash' => $this->documentHash($path),
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

    private function databaseConnection(): PDO
    {
        $settings = $this->databaseConnectionSettings();
        $cacheKey = $this->databaseConnectionCacheKey($settings);
        if (isset(self::$databaseConnections[$cacheKey])) {
            return self::$databaseConnections[$cacheKey];
        }

        $pdo = match ($settings['driver']) {
            'pgsql' => new PDO(
                sprintf(
                    'pgsql:host=%s;port=%s;dbname=%s',
                    $settings['host'],
                    $settings['port'],
                    $settings['database']
                ),
                $settings['username'],
                $settings['password']
            ),
            'mysql', 'mariadb' => new PDO(
                sprintf(
                    'mysql:host=%s;port=%s;dbname=%s;charset=%s',
                    $settings['host'],
                    $settings['port'],
                    $settings['database'],
                    $settings['charset']
                ),
                $settings['username'],
                $settings['password']
            ),
            'sqlite' => new PDO('sqlite:'.$settings['database']),
            default => throw new RuntimeException('Qo‘llab-quvvatlanmaydigan storage DB driver: '.$settings['driver']),
        };

        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->ensureDatabaseTableReady($pdo, $settings['driver']);

        self::$databaseConnections[$cacheKey] = $pdo;

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
        $normalized = strtolower(trim((string) $driver));

        return match ($normalized) {
            'sqlite' => 'sqlite',
            'database', 'db', 'pgsql', 'postgres', 'postgresql', 'mysql', 'mariadb' => 'database',
            default => 'file',
        };
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

    private function documentHash(string $path): string
    {
        return hash('sha256', $this->documentKey($path));
    }

    private function databaseConnectionName(): string
    {
        $configured = $this->config('ustatop.storage_db_connection')
            ?? getenv('USTATOP_STORAGE_DB_CONNECTION')
            ?: $this->config('database.default')
            ?? getenv('DB_CONNECTION')
            ?: 'sqlite';

        return trim((string) $configured) !== '' ? trim((string) $configured) : 'sqlite';
    }

    private function databaseTableName(): string
    {
        $configured = $this->config('ustatop.storage_db_table')
            ?? getenv('USTATOP_STORAGE_DB_TABLE')
            ?: self::DATABASE_TABLE;

        return trim((string) $configured) !== '' ? trim((string) $configured) : self::DATABASE_TABLE;
    }

    private function databaseConnectionSettings(): array
    {
        $connectionName = $this->databaseConnectionName();
        $connectionConfig = $this->config('database.connections.'.$connectionName);
        if (! is_array($connectionConfig)) {
            $connectionConfig = $this->fallbackDatabaseConnectionConfig($connectionName);
        }

        $driver = strtolower(trim((string) ($connectionConfig['driver'] ?? $connectionName)));

        $settings = [
            'name' => $connectionName,
            'driver' => $driver,
            'host' => (string) ($connectionConfig['host'] ?? '127.0.0.1'),
            'port' => (string) ($connectionConfig['port'] ?? ($driver === 'pgsql' ? '5432' : '3306')),
            'database' => (string) ($connectionConfig['database'] ?? ''),
            'username' => (string) ($connectionConfig['username'] ?? ''),
            'password' => (string) ($connectionConfig['password'] ?? ''),
            'charset' => (string) ($connectionConfig['charset'] ?? 'utf8mb4'),
        ];

        if ($settings['driver'] === 'sqlite') {
            $settings['database'] = $this->normalizeSqlitePath($settings['database']);
            $directory = dirname($settings['database']);
            if (! is_dir($directory)) {
                mkdir($directory, 0777, true);
            }
            if (! file_exists($settings['database'])) {
                touch($settings['database']);
            }
        }

        if ($settings['database'] === '') {
            throw new RuntimeException('Storage database sozlamasi topilmadi: '.$connectionName);
        }

        return $settings;
    }

    private function fallbackDatabaseConnectionConfig(string $connectionName): array
    {
        return match ($connectionName) {
            'pgsql', 'postgres', 'postgresql' => [
                'driver' => 'pgsql',
                'host' => getenv('DB_HOST') ?: '127.0.0.1',
                'port' => getenv('DB_PORT') ?: '5432',
                'database' => getenv('DB_DATABASE') ?: '',
                'username' => getenv('DB_USERNAME') ?: '',
                'password' => getenv('DB_PASSWORD') ?: '',
                'charset' => getenv('DB_CHARSET') ?: 'utf8',
            ],
            'mysql', 'mariadb' => [
                'driver' => $connectionName,
                'host' => getenv('DB_HOST') ?: '127.0.0.1',
                'port' => getenv('DB_PORT') ?: '3306',
                'database' => getenv('DB_DATABASE') ?: '',
                'username' => getenv('DB_USERNAME') ?: '',
                'password' => getenv('DB_PASSWORD') ?: '',
                'charset' => getenv('DB_CHARSET') ?: 'utf8mb4',
            ],
            default => [
                'driver' => 'sqlite',
                'database' => getenv('DB_DATABASE') ?: $this->configuredSqlitePath(),
            ],
        };
    }

    private function normalizeSqlitePath(string $path): string
    {
        if ($path !== '' && ! str_starts_with($path, '/')) {
            $basePath = function_exists('base_path')
                ? base_path()
                : dirname(__DIR__, 3);

            return rtrim($basePath, '/').'/'.ltrim($path, '/');
        }

        return $path;
    }

    private function databaseConnectionCacheKey(array $settings): string
    {
        return hash('sha256', json_encode([
            'name' => $settings['name'],
            'driver' => $settings['driver'],
            'host' => $settings['host'],
            'port' => $settings['port'],
            'database' => $settings['database'],
            'username' => $settings['username'],
        ], JSON_THROW_ON_ERROR));
    }

    private function ensureDatabaseTableReady(PDO $pdo, string $driver): void
    {
        $table = $this->databaseTableName();

        $sql = match ($driver) {
            'mysql', 'mariadb' => 'CREATE TABLE IF NOT EXISTS '.$table.' (
                document_hash VARCHAR(64) PRIMARY KEY,
                document_key TEXT NOT NULL,
                payload LONGTEXT NOT NULL,
                updated_at VARCHAR(64) NOT NULL
            )',
            default => 'CREATE TABLE IF NOT EXISTS '.$table.' (
                document_hash VARCHAR(64) PRIMARY KEY,
                document_key TEXT NOT NULL,
                payload TEXT NOT NULL,
                updated_at VARCHAR(64) NOT NULL
            )',
        };

        $pdo->exec($sql);
    }

    private function databasePdoDriver(PDO $pdo): string
    {
        return strtolower((string) $pdo->getAttribute(PDO::ATTR_DRIVER_NAME));
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
