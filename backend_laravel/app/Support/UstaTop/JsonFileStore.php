<?php

namespace App\Support\UstaTop;

use RuntimeException;

class JsonFileStore
{
    public function readArray(string $path, array $default = []): array
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
            $this->writeArray($path, $default);

            return $default;
        }

        return $decoded;
    }

    public function writeArray(string $path, array $data): void
    {
        $directory = dirname($path);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }

        $encoded = json_encode(
            $data,
            JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
        );

        if (! is_string($encoded)) {
            throw new RuntimeException('JSON encode qilishda xatolik yuz berdi: '.$path);
        }

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
            $this->writeArray($path, $default);
        }
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
