<?php

namespace Tests\Unit;

use App\Support\UstaTop\JsonFileStore;
use PHPUnit\Framework\TestCase;

class JsonFileStoreTest extends TestCase
{
    private string $tempDir;
    private array $originalEnv = [];

    protected function setUp(): void
    {
        parent::setUp();

        $this->tempDir = sys_get_temp_dir().'/ustatop-json-store-'.bin2hex(random_bytes(6));
        mkdir($this->tempDir, 0777, true);
    }

    protected function tearDown(): void
    {
        $this->restoreEnv('USTATOP_STORAGE_DRIVER');
        $this->restoreEnv('USTATOP_SQLITE_FILE');
        $this->deleteDirectory($this->tempDir);

        parent::tearDown();
    }

    public function test_it_writes_and_reads_arrays(): void
    {
        $store = new JsonFileStore();
        $path = $this->tempDir.'/data.json';
        $payload = [
            ['id' => 'w-1', 'name' => 'Turbo Usta Servis'],
        ];

        $store->writeArray($path, $payload);

        $this->assertSame($payload, $store->readArray($path));
    }

    public function test_it_recovers_from_corrupt_json_file(): void
    {
        $store = new JsonFileStore();
        $path = $this->tempDir.'/broken.json';
        file_put_contents($path, '{broken json');

        $result = $store->readArray($path, [['id' => 'fallback']]);

        $this->assertSame([['id' => 'fallback']], $result);
        $this->assertSame(
            [['id' => 'fallback']],
            json_decode((string) file_get_contents($path), true)
        );

        $corruptCopies = glob($path.'.corrupt.*');
        $this->assertIsArray($corruptCopies);
        $this->assertNotEmpty($corruptCopies);
    }

    public function test_it_persists_arrays_in_sqlite_mode(): void
    {
        $sqlitePath = $this->tempDir.'/storage/app/ustatop/ustatop.sqlite';
        $path = $this->tempDir.'/data/users.json';
        $payload = [
            ['id' => 'u-1', 'fullName' => 'Toxirjon'],
        ];

        $this->setEnv('USTATOP_STORAGE_DRIVER', 'sqlite');
        $this->setEnv('USTATOP_SQLITE_FILE', $sqlitePath);

        $store = new JsonFileStore();
        $store->writeArray($path, $payload);

        $this->assertFileExists($sqlitePath);
        $this->assertSame($payload, $store->readArray($path));
    }

    private function setEnv(string $name, string $value): void
    {
        if (! array_key_exists($name, $this->originalEnv)) {
            $existingValue = getenv($name);
            $this->originalEnv[$name] = $existingValue === false ? null : $existingValue;
        }

        putenv($name.'='.$value);
    }

    private function restoreEnv(string $name): void
    {
        if (! array_key_exists($name, $this->originalEnv)) {
            return;
        }

        $value = $this->originalEnv[$name];
        if ($value === null) {
            putenv($name);
        } else {
            putenv($name.'='.$value);
        }
    }

    private function deleteDirectory(string $directory): void
    {
        if (! is_dir($directory)) {
            return;
        }

        $items = scandir($directory);
        if ($items === false) {
            return;
        }

        foreach ($items as $item) {
            if ($item === '.' || $item === '..') {
                continue;
            }

            $path = $directory.'/'.$item;
            if (is_dir($path)) {
                $this->deleteDirectory($path);
            } else {
                @unlink($path);
            }
        }

        @rmdir($directory);
    }
}
