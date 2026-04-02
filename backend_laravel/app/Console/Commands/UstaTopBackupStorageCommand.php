<?php

namespace App\Console\Commands;

use App\Support\UstaTop\JsonFileStore;
use App\Support\UstaTop\UstaTopSqliteBackupManager;
use Illuminate\Console\Command;

class UstaTopBackupStorageCommand extends Command
{
    protected $signature = 'ustatop:backup-storage {--path=}';

    protected $description = 'Create a backup copy of the local UstaTop SQLite database.';

    public function __construct(
        private readonly JsonFileStore $store,
        private readonly UstaTopSqliteBackupManager $backupManager,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        if ($this->store->storageDriverName() !== 'sqlite') {
            $this->error('Bu backup command hozir faqat SQLite storage uchun. PostgreSQL/MySQL uchun pg_dump yoki provider-native backup ishlating.');

            return self::FAILURE;
        }

        $sourcePath = $this->store->sqlitePath();
        $destinationPath = (string) ($this->option('path') ?: $this->defaultBackupPath($sourcePath));

        $createdBackupPath = $this->backupManager->backup($sourcePath, $destinationPath);

        $this->info('UstaTop backup created: '.$createdBackupPath);

        return self::SUCCESS;
    }

    private function defaultBackupPath(string $sqlitePath): string
    {
        return dirname($sqlitePath).'/backups/ustatop-backup-'.date('Ymd-His').'.sqlite';
    }
}
