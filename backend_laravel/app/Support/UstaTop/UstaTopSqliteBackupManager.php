<?php

namespace App\Support\UstaTop;

use RuntimeException;
use SQLite3;

class UstaTopSqliteBackupManager
{
    public function backup(string $sourcePath, string $destinationPath): string
    {
        $sourcePath = $this->normalizePath($sourcePath);
        $destinationPath = $this->normalizePath($destinationPath);

        if (! is_file($sourcePath)) {
            throw new RuntimeException('SQLite baza fayli topilmadi: '.$sourcePath);
        }

        $this->ensureDirectory(dirname($destinationPath));

        if (class_exists(SQLite3::class)) {
            $source = new SQLite3($sourcePath, SQLITE3_OPEN_READONLY);
            $destination = new SQLite3($destinationPath, SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);

            try {
                $source->busyTimeout(5000);
                $destination->busyTimeout(5000);

                if (! $source->backup($destination)) {
                    throw new RuntimeException('SQLite backup bajarilmadi.');
                }
            } finally {
                $destination->close();
                $source->close();
            }
        } else {
            if (! @copy($sourcePath, $destinationPath)) {
                throw new RuntimeException('SQLite backup faylini nusxalab bo‘lmadi.');
            }
        }

        $this->assertValidBackup($destinationPath);

        return $destinationPath;
    }

    public function restore(string $backupPath, string $targetPath): array
    {
        $backupPath = $this->normalizePath($backupPath);
        $targetPath = $this->normalizePath($targetPath);

        if (! is_file($backupPath)) {
            throw new RuntimeException('Restore uchun backup fayli topilmadi: '.$backupPath);
        }

        $this->assertValidBackup($backupPath);
        $this->ensureDirectory(dirname($targetPath));

        $preRestoreBackupPath = dirname($targetPath).'/backups/pre-restore-'.date('Ymd-His').'.sqlite';
        if (is_file($targetPath)) {
            $this->backup($targetPath, $preRestoreBackupPath);
        } else {
            $preRestoreBackupPath = '';
        }

        if (is_file($targetPath) && ! @unlink($targetPath)) {
            throw new RuntimeException('Eski SQLite faylini o‘chirib bo‘lmadi: '.$targetPath);
        }

        $restoredPath = $this->backup($backupPath, $targetPath);

        return [
            'restored_path' => $restoredPath,
            'pre_restore_backup_path' => $preRestoreBackupPath,
        ];
    }

    public function assertValidBackup(string $path): void
    {
        $path = $this->normalizePath($path);

        if (! is_file($path)) {
            throw new RuntimeException('SQLite backup fayli topilmadi: '.$path);
        }

        if (! class_exists(SQLite3::class)) {
            return;
        }

        $database = new SQLite3($path, SQLITE3_OPEN_READONLY);

        try {
            $database->busyTimeout(5000);
            $result = $database->querySingle(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'ustatop_json_documents'"
            );

            if ($result !== 'ustatop_json_documents') {
                throw new RuntimeException('Backup fayli UstaTop SQLite bazasi emas: '.$path);
            }
        } finally {
            $database->close();
        }
    }

    private function ensureDirectory(string $directory): void
    {
        if (! is_dir($directory) && ! @mkdir($directory, 0777, true) && ! is_dir($directory)) {
            throw new RuntimeException('Papka yaratib bo‘lmadi: '.$directory);
        }
    }

    private function normalizePath(string $path): string
    {
        if ($path !== '' && ! str_starts_with($path, '/')) {
            return base_path($path);
        }

        return $path;
    }
}
