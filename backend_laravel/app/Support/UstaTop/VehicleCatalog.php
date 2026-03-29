<?php

namespace App\Support\UstaTop;

final class VehicleCatalog
{
    /**
     * @return array<int, array{id: string, brand: string, model: string, vehicleTypeId: string, popularityRank: int, isUzbekistanGm: bool}>
     */
    public static function entries(): array
    {
        return [
            ['id' => 'chevrolet-cobalt', 'brand' => 'Chevrolet', 'model' => 'Cobalt', 'vehicleTypeId' => 'sedan', 'popularityRank' => 1, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-damas', 'brand' => 'Chevrolet', 'model' => 'Damas', 'vehicleTypeId' => 'minivan', 'popularityRank' => 2, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-tracker', 'brand' => 'Chevrolet', 'model' => 'Tracker', 'vehicleTypeId' => 'crossover', 'popularityRank' => 3, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-gentra', 'brand' => 'Chevrolet', 'model' => 'Gentra', 'vehicleTypeId' => 'sedan', 'popularityRank' => 4, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-lacetti', 'brand' => 'Chevrolet', 'model' => 'Lacetti', 'vehicleTypeId' => 'sedan', 'popularityRank' => 5, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-onix', 'brand' => 'Chevrolet', 'model' => 'Onix', 'vehicleTypeId' => 'sedan', 'popularityRank' => 6, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-spark', 'brand' => 'Chevrolet', 'model' => 'Spark', 'vehicleTypeId' => 'compact', 'popularityRank' => 7, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-malibu', 'brand' => 'Chevrolet', 'model' => 'Malibu', 'vehicleTypeId' => 'sedan', 'popularityRank' => 8, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-nexia-3', 'brand' => 'Chevrolet', 'model' => 'Nexia 3', 'vehicleTypeId' => 'sedan', 'popularityRank' => 9, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-labo', 'brand' => 'Chevrolet', 'model' => 'Labo', 'vehicleTypeId' => 'pickup', 'popularityRank' => 10, 'isUzbekistanGm' => true],
            ['id' => 'daewoo-matiz', 'brand' => 'Daewoo', 'model' => 'Matiz', 'vehicleTypeId' => 'compact', 'popularityRank' => 11, 'isUzbekistanGm' => true],
            ['id' => 'daewoo-nexia', 'brand' => 'Daewoo', 'model' => 'Nexia', 'vehicleTypeId' => 'sedan', 'popularityRank' => 12, 'isUzbekistanGm' => true],
            ['id' => 'chevrolet-captiva', 'brand' => 'Chevrolet', 'model' => 'Captiva', 'vehicleTypeId' => 'suv', 'popularityRank' => 13, 'isUzbekistanGm' => false],
            ['id' => 'kia-k5', 'brand' => 'Kia', 'model' => 'K5', 'vehicleTypeId' => 'sedan', 'popularityRank' => 14, 'isUzbekistanGm' => false],
            ['id' => 'kia-sportage', 'brand' => 'Kia', 'model' => 'Sportage', 'vehicleTypeId' => 'suv', 'popularityRank' => 15, 'isUzbekistanGm' => false],
            ['id' => 'hyundai-tucson', 'brand' => 'Hyundai', 'model' => 'Tucson', 'vehicleTypeId' => 'suv', 'popularityRank' => 16, 'isUzbekistanGm' => false],
            ['id' => 'hyundai-elantra', 'brand' => 'Hyundai', 'model' => 'Elantra', 'vehicleTypeId' => 'sedan', 'popularityRank' => 17, 'isUzbekistanGm' => false],
            ['id' => 'toyota-camry', 'brand' => 'Toyota', 'model' => 'Camry', 'vehicleTypeId' => 'sedan', 'popularityRank' => 18, 'isUzbekistanGm' => false],
            ['id' => 'byd-song-plus', 'brand' => 'BYD', 'model' => 'Song Plus', 'vehicleTypeId' => 'suv', 'popularityRank' => 19, 'isUzbekistanGm' => false],
            ['id' => 'chery-tiggo-7-pro', 'brand' => 'Chery', 'model' => 'Tiggo 7 Pro', 'vehicleTypeId' => 'crossover', 'popularityRank' => 20, 'isUzbekistanGm' => false],
            ['id' => 'haval-jolion', 'brand' => 'Haval', 'model' => 'Jolion', 'vehicleTypeId' => 'crossover', 'popularityRank' => 21, 'isUzbekistanGm' => false],
        ];
    }

    public static function byId(string $id): ?array
    {
        $normalizedId = trim($id);
        foreach (self::entries() as $entry) {
            if ($entry['id'] === $normalizedId) {
                return $entry;
            }
        }

        return null;
    }

    public static function normalizeBrand(string $value): string
    {
        return trim(preg_replace('/\s+/', ' ', $value) ?? '');
    }

    public static function normalizeModel(string $value): string
    {
        return trim(preg_replace('/\s+/', ' ', $value) ?? '');
    }
}
