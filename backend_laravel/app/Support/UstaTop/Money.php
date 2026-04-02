<?php

namespace App\Support\UstaTop;

final class Money
{
    public static function displayAmount(int $amount): int
    {
        $absolute = abs($amount);
        if ($absolute === 0) {
            return 0;
        }

        if ($absolute < 1000) {
            return $amount * 1000;
        }

        return $amount;
    }

    public static function inputValue(int $amount): string
    {
        return (string) self::displayAmount($amount);
    }

    public static function formatUzs(int $amount): string
    {
        $normalized = self::displayAmount($amount);
        $sign = $normalized < 0 ? '-' : '';
        $digits = (string) abs($normalized);
        $formatted = '';

        $length = strlen($digits);
        for ($index = 0; $index < $length; $index++) {
            if ($index > 0 && (($length - $index) % 3) === 0) {
                $formatted .= ' ';
            }
            $formatted .= $digits[$index];
        }

        return $sign.$formatted." so'm";
    }

    public static function parseStoredAmount(string $raw): ?int
    {
        $value = trim($raw);
        if ($value === '') {
            return null;
        }

        $lower = mb_strtolower($value);
        $usesLegacyThousands = preg_match('/\d\s*k\b|\dk\b/u', $lower) === 1;
        $digitsOnly = preg_replace('/[^0-9]/', '', $lower) ?? '';
        if ($digitsOnly === '') {
            return null;
        }

        $parsed = (int) $digitsOnly;
        if ($parsed === 0) {
            return 0;
        }

        if ($usesLegacyThousands || $parsed < 1000) {
            return $parsed;
        }

        if (($parsed % 1000) !== 0) {
            return null;
        }

        return intdiv($parsed, 1000);
    }
}
