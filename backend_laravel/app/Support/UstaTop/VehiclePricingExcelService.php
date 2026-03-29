<?php

namespace App\Support\UstaTop;

use Illuminate\Http\UploadedFile;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use RuntimeException;

class VehiclePricingExcelService
{
    private const SHEET_PRICING = 'pricing_matrix';
    private const SHEET_INFO = 'instructions';

    public function buildWorkbook(array $workshop): string
    {
        $spreadsheet = new Spreadsheet();
        $pricingSheet = $spreadsheet->getActiveSheet();
        $pricingSheet->setTitle(self::SHEET_PRICING);

        $headers = ['service_id', 'service_name', 'catalog_vehicle_id', 'brand', 'model', 'vehicle_type_id', 'price_uzs'];
        $pricingSheet->fromArray($headers, null, 'A1');

        $row = 2;
        $rules = array_values($workshop['vehiclePricingRules'] ?? []);

        foreach (array_values($workshop['services'] ?? []) as $service) {
            foreach (VehicleCatalog::entries() as $vehicle) {
                $rule = $this->findRule($rules, (string) ($service['id'] ?? ''), $vehicle['id'], $vehicle['brand'], $vehicle['model']);
                $pricingSheet->fromArray([
                    (string) ($service['id'] ?? ''),
                    (string) ($service['name'] ?? ''),
                    $vehicle['id'],
                    $vehicle['brand'],
                    $vehicle['model'],
                    $vehicle['vehicleTypeId'],
                    Money::displayAmount((int) ($rule['price'] ?? $service['price'] ?? 0)),
                ], null, 'A'.$row);
                $row++;
            }
        }

        foreach ($rules as $rule) {
            if (trim((string) ($rule['catalogVehicleId'] ?? '')) !== '') {
                continue;
            }

            $service = $this->serviceById($workshop, (string) ($rule['serviceId'] ?? ''));
            if ($service === null) {
                continue;
            }

            $pricingSheet->fromArray([
                (string) ($service['id'] ?? ''),
                (string) ($service['name'] ?? ''),
                '',
                (string) ($rule['vehicleBrand'] ?? ''),
                (string) ($rule['vehicleModel'] ?? ''),
                (string) ($rule['vehicleTypeId'] ?? ''),
                Money::displayAmount((int) ($rule['price'] ?? 0)),
            ], null, 'A'.$row);
            $row++;
        }

        foreach (range('A', 'G') as $column) {
            $pricingSheet->getColumnDimension($column)->setAutoSize(true);
        }

        $infoSheet = $spreadsheet->createSheet();
        $infoSheet->setTitle(self::SHEET_INFO);
        $infoSheet->fromArray([
            ['Usta Top vehicle pricing template'],
            ['1. pricing_matrix ichida price_uzs ustunini to‘liq UZS qiymatida kiriting.'],
            ['2. catalog_vehicle_id bo‘sh bo‘lsa, brand + model + vehicle_type_id bilan custom model qo‘shishingiz mumkin.'],
            ['3. service_id va price_uzs majburiy. Masalan: 100000 yoki 150000 UZS.'],
        ], null, 'A1');
        $infoSheet->getColumnDimension('A')->setWidth(120);

        $writer = new Xlsx($spreadsheet);
        ob_start();
        $writer->save('php://output');

        return (string) ob_get_clean();
    }

    public function parseWorkbook(UploadedFile $file, array $workshop): array
    {
        if (! $file->isValid()) {
            throw new RuntimeException('Excel faylni yuklab bo‘lmadi');
        }

        $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getRealPath());
        $sheet = $spreadsheet->getSheetByName(self::SHEET_PRICING) ?? $spreadsheet->getSheet(0);

        if ($sheet === null) {
            throw new RuntimeException('Excel ichida pricing_matrix sheet topilmadi');
        }

        $highestColumn = Coordinate::columnIndexFromString($sheet->getHighestColumn());
        $headerIndex = [];
        for ($column = 1; $column <= $highestColumn; $column++) {
            $value = trim((string) $sheet->getCell($this->cellAddress($column, 1))->getFormattedValue());
            if ($value !== '') {
                $headerIndex[strtolower($value)] = $column;
            }
        }

        $serviceIdColumn = $headerIndex['service_id'] ?? null;
        $catalogVehicleIdColumn = $headerIndex['catalog_vehicle_id'] ?? null;
        $brandColumn = $headerIndex['brand'] ?? null;
        $modelColumn = $headerIndex['model'] ?? null;
        $vehicleTypeColumn = $headerIndex['vehicle_type_id'] ?? null;
        $priceColumn = $headerIndex['price_uzs'] ?? $headerIndex['price'] ?? null;

        if ($serviceIdColumn === null || $priceColumn === null) {
            throw new RuntimeException('Excel sarlavhasi noto‘g‘ri. service_id va price_uzs ustunlari kerak.');
        }

        $highestRow = $sheet->getHighestDataRow();
        $rules = [];

        for ($row = 2; $row <= $highestRow; $row++) {
            $serviceId = trim((string) $sheet->getCell($this->cellAddress($serviceIdColumn, $row))->getFormattedValue());
            $catalogVehicleId = $catalogVehicleIdColumn === null ? '' : trim((string) $sheet->getCell($this->cellAddress($catalogVehicleIdColumn, $row))->getFormattedValue());
            $brand = $brandColumn === null ? '' : trim((string) $sheet->getCell($this->cellAddress($brandColumn, $row))->getFormattedValue());
            $model = $modelColumn === null ? '' : trim((string) $sheet->getCell($this->cellAddress($modelColumn, $row))->getFormattedValue());
            $vehicleTypeId = $vehicleTypeColumn === null ? 'sedan' : trim((string) $sheet->getCell($this->cellAddress($vehicleTypeColumn, $row))->getFormattedValue());
            $priceRaw = trim((string) $sheet->getCell($this->cellAddress($priceColumn, $row))->getFormattedValue());

            if ($serviceId === '' && $catalogVehicleId === '' && $brand === '' && $model === '' && $priceRaw === '') {
                continue;
            }

            if ($this->serviceById($workshop, $serviceId) === null) {
                throw new RuntimeException('Noma’lum service_id: '.$serviceId);
            }

            $price = Money::parseStoredAmount($priceRaw);
            if ($price === null || $price < 0) {
                throw new RuntimeException('Narx noto‘g‘ri: '.$priceRaw);
            }

            $catalogVehicle = VehicleCatalog::byId($catalogVehicleId);
            $resolvedBrand = $catalogVehicle['brand'] ?? VehicleCatalog::normalizeBrand($brand);
            $resolvedModel = $catalogVehicle['model'] ?? VehicleCatalog::normalizeModel($model);
            $resolvedType = trim((string) ($catalogVehicle['vehicleTypeId'] ?? $vehicleTypeId));

            if ($catalogVehicle === null && ($resolvedBrand === '' || $resolvedModel === '')) {
                throw new RuntimeException('Custom model uchun brand va model majburiy (service_id: '.$serviceId.').');
            }

            $key = $serviceId.'|'.($catalogVehicle['id'] ?? strtolower($resolvedBrand.'|'.$resolvedModel));
            $rules[$key] = [
                'serviceId' => $serviceId,
                'catalogVehicleId' => (string) ($catalogVehicle['id'] ?? ''),
                'vehicleBrand' => $resolvedBrand,
                'vehicleModel' => $resolvedModel,
                'vehicleTypeId' => $resolvedType !== '' ? $resolvedType : 'sedan',
                'price' => $price,
            ];
        }

        return array_values($rules);
    }

    private function serviceById(array $workshop, string $serviceId): ?array
    {
        foreach (array_values($workshop['services'] ?? []) as $service) {
            if ((string) ($service['id'] ?? '') === $serviceId) {
                return $service;
            }
        }

        return null;
    }

    private function findRule(array $rules, string $serviceId, string $catalogVehicleId, string $brand, string $model): ?array
    {
        foreach ($rules as $rule) {
            if ((string) ($rule['serviceId'] ?? '') !== $serviceId) {
                continue;
            }

            if (trim((string) ($rule['catalogVehicleId'] ?? '')) !== '') {
                if ((string) ($rule['catalogVehicleId'] ?? '') === $catalogVehicleId) {
                    return $rule;
                }

                continue;
            }

            if (
                strcasecmp((string) ($rule['vehicleBrand'] ?? ''), $brand) === 0
                && strcasecmp((string) ($rule['vehicleModel'] ?? ''), $model) === 0
            ) {
                return $rule;
            }
        }

        return null;
    }

    private function cellAddress(int $column, int $row): string
    {
        return Coordinate::stringFromColumnIndex($column).$row;
    }
}
