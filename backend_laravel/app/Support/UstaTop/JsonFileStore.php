<?php

namespace App\Support\UstaTop;

class JsonFileStore
{
    public function readArray(string $path, array $default = []): array
    {
        $this->ensureFile($path, $default);

        $decoded = json_decode((string) file_get_contents($path), true);

        return is_array($decoded) ? $decoded : $default;
    }

    public function writeArray(string $path, array $data): void
    {
        $directory = dirname($path);
        if (! is_dir($directory)) {
            mkdir($directory, 0777, true);
        }

        file_put_contents(
            $path,
            json_encode(
                $data,
                JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
            )
        );
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
}
