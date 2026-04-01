<?php

namespace App\Console\Commands;

use App\Support\UstaTop\JsonFileStore;
use App\Support\UstaTop\UstaTopSqliteBackupManager;
use Illuminate\Console\Command;

class UstaTopRestoreStorageCommand extends Command
{
    protected $signature = 'ustatop:restore-storage {backup} {--force}';

    protected $description = 'Restore the local UstaTop SQLite database from a backup file.';

    public function __construct(
        private readonly JsonFileStore $store,
        private readonly UstaTopSqliteBackupManager $backupManager,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $backupPath = (string) $this->argument('backup');
        $targetPath = $this->store->sqlitePath();

        if (! $this->option('force') && ! $this->confirm('SQLite bazani restore qilaymi? Joriy holat backup qilinadi.')) {
            $this->warn('Restore bekor qilindi.');

            return self::INVALID;
        }

        JsonFileStore::clearSqliteConnectionCache($targetPath);
        $result = $this->backupManager->restore($backupPath, $targetPath);
        JsonFileStore::clearSqliteConnectionCache($targetPath);

        $this->info('UstaTop database restored: '.$result['restored_path']);
        if ($result['pre_restore_backup_path'] !== '') {
            $this->line('Pre-restore backup: '.$result['pre_restore_backup_path']);
        }

        return self::SUCCESS;
    }
}
