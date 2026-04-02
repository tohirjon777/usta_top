<?php

namespace App\Support\UstaTop;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use RuntimeException;

class CustomerAvatarStorage
{
    private const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

    public function storeUploadedAvatar(UploadedFile $file, ?string $currentUrl = null): string
    {
        if (! $file->isValid()) {
            throw new RuntimeException('Avatar rasmini yuklab bo‘lmadi');
        }

        $mimeType = (string) ($file->getMimeType() ?? '');
        if (! str_starts_with($mimeType, 'image/')) {
            throw new RuntimeException('Faqat rasm fayllarini yuklash mumkin');
        }

        if (($file->getSize() ?? 0) > self::MAX_FILE_SIZE_BYTES) {
            throw new RuntimeException('Avatar rasmi 5 MB dan oshmasligi kerak');
        }

        $extension = $file->guessExtension() ?: $file->extension() ?: 'jpg';
        $filename = 'customer-'.now()->format('YmdHis').'-'.Str::lower(Str::random(12)).'.'.$extension;
        $directory = $this->directory();

        if (! is_dir($directory) && ! @mkdir($directory, 0775, true) && ! is_dir($directory)) {
            throw new RuntimeException('Avatar papkasini yaratib bo‘lmadi');
        }

        $file->move($directory, $filename);
        $this->deleteByUrl($currentUrl);

        return '/media/customers/'.$filename;
    }

    public function deleteByUrl(?string $value): void
    {
        $path = $this->pathForUrl($value);
        if ($path !== null && is_file($path)) {
            @unlink($path);
        }
    }

    public function absolutePathForFilename(string $filename): ?string
    {
        $safeFilename = basename(trim($filename));
        if ($safeFilename === '' || $safeFilename !== trim($filename)) {
            return null;
        }

        if (! preg_match('/^[A-Za-z0-9._-]+$/', $safeFilename)) {
            return null;
        }

        $path = $this->directory().DIRECTORY_SEPARATOR.$safeFilename;

        return is_file($path) ? $path : null;
    }

    private function pathForUrl(?string $value): ?string
    {
        $filename = $this->relativeFilename($value);
        if ($filename === null) {
            return null;
        }

        return $this->directory().DIRECTORY_SEPARATOR.$filename;
    }

    private function relativeFilename(?string $value): ?string
    {
        $path = trim((string) parse_url((string) $value, PHP_URL_PATH));
        if ($path === '') {
            return null;
        }

        if (! preg_match('#^/media/customers/([A-Za-z0-9._-]+)$#', $path, $matches)) {
            return null;
        }

        return $matches[1] ?? null;
    }

    private function directory(): string
    {
        return (string) config('ustatop.customer_avatars_dir', storage_path('app/ustatop/customer-avatars'));
    }
}
