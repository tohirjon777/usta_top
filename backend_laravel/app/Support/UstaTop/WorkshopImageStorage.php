<?php

namespace App\Support\UstaTop;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use RuntimeException;

class WorkshopImageStorage
{
    private const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

    public function storeUploadedImage(UploadedFile $file, ?string $currentUrl = null): string
    {
        if (! $file->isValid()) {
            throw new RuntimeException('Rasmni yuklab bo‘lmadi');
        }

        $mimeType = (string) ($file->getMimeType() ?? '');
        if (! str_starts_with($mimeType, 'image/')) {
            throw new RuntimeException('Faqat rasm fayllarini yuklash mumkin');
        }

        if (($file->getSize() ?? 0) > self::MAX_FILE_SIZE_BYTES) {
            throw new RuntimeException('Rasm hajmi 5 MB dan oshmasligi kerak');
        }

        $extension = $file->guessExtension() ?: $file->extension() ?: 'jpg';
        $filename = 'workshop-'.now()->format('YmdHis').'-'.Str::lower(Str::random(12)).'.'.$extension;
        $directory = $this->directory();

        if (! is_dir($directory) && ! @mkdir($directory, 0775, true) && ! is_dir($directory)) {
            throw new RuntimeException('Rasm papkasini yaratib bo‘lmadi');
        }

        $file->move($directory, $filename);
        $this->deleteByUrl($currentUrl);

        return '/media/workshops/'.$filename;
    }

    public function normalizeStoredUrl(?string $value): string
    {
        $url = trim((string) $value);
        if ($url === '') {
            return '';
        }

        if ($this->relativeFilename($url) !== null) {
            return $url;
        }

        if (filter_var($url, FILTER_VALIDATE_URL) === false) {
            throw new RuntimeException('Rasm manzili noto‘g‘ri');
        }

        $scheme = strtolower((string) parse_url($url, PHP_URL_SCHEME));
        if (! in_array($scheme, ['http', 'https'], true)) {
            throw new RuntimeException('Rasm manzili http yoki https bo‘lishi kerak');
        }

        return $url;
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

        if (! preg_match('#^/media/workshops/([A-Za-z0-9._-]+)$#', $path, $matches)) {
            return null;
        }

        return $matches[1] ?? null;
    }

    private function directory(): string
    {
        return (string) config('ustatop.workshop_images_dir', storage_path('app/ustatop/workshop-images'));
    }
}
