<?php

namespace Tests\Feature;

use App\Support\UstaTop\JsonFileStore;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopStorageCommandTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    private string $backupPath;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
        $this->backupPath = $this->ustatopTempDir.'/backups/test-backup.sqlite';
    }

    protected function tearDown(): void
    {
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_backup_command_creates_sqlite_backup(): void
    {
        $this->artisan('ustatop:bootstrap-storage')
            ->assertSuccessful();

        $this->artisan('ustatop:backup-storage', [
            '--path' => $this->backupPath,
        ])->assertSuccessful();

        $this->assertFileExists($this->backupPath);
        $this->assertGreaterThan(0, filesize($this->backupPath));
    }

    public function test_restore_command_restores_previous_state(): void
    {
        $store = app(JsonFileStore::class);
        $usersPath = config('ustatop.users_file');

        $this->artisan('ustatop:bootstrap-storage')
            ->assertSuccessful();

        $originalUsers = $store->readArray($usersPath, []);
        $this->assertNotEmpty($originalUsers);

        $this->artisan('ustatop:backup-storage', [
            '--path' => $this->backupPath,
        ])->assertSuccessful();

        $updatedUsers = $originalUsers;
        $updatedUsers[] = [
            'id' => 'u-test-restore',
            'fullName' => 'Backup Restore Test',
            'phone' => '+998900000001',
            'password' => 'secret123',
            'savedVehicles' => [],
            'savedPaymentCards' => [],
        ];
        $store->writeArray($usersPath, $updatedUsers);

        $this->assertCount(count($originalUsers) + 1, $store->readArray($usersPath, []));

        $this->artisan('ustatop:restore-storage', [
            'backup' => $this->backupPath,
            '--force' => true,
        ])->assertSuccessful();

        $restoredUsers = app(JsonFileStore::class)->readArray($usersPath, []);
        $this->assertCount(count($originalUsers), $restoredUsers);
        $this->assertFalse(collect($restoredUsers)->contains(fn (array $user): bool => ($user['id'] ?? '') === 'u-test-restore'));
    }
}
