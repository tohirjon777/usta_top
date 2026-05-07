<?php

namespace Tests\Concerns;

use App\Support\UstaTop\JsonFileStore;
use Illuminate\Support\Facades\File;

trait UsesIsolatedUstaTopData
{
    protected string $ustatopTempDir;
    protected string $ustatopSqlitePath;

    protected function setUpUstaTopData(): void
    {
        $this->ustatopTempDir = sys_get_temp_dir().'/ustatop-laravel-'.bin2hex(random_bytes(8));
        $dataDir = $this->ustatopTempDir.'/data';
        $storageDir = $this->ustatopTempDir.'/storage/app/ustatop';
        $this->ustatopSqlitePath = $storageDir.'/ustatop.sqlite';

        File::ensureDirectoryExists($dataDir);
        File::ensureDirectoryExists($storageDir);

        JsonFileStore::clearSqliteConnectionCache();
        JsonFileStore::clearDatabaseConnectionCache();

        $this->writeFixtureJson($dataDir.'/users.json', $this->seedUsers());
        $this->writeFixtureJson($dataDir.'/workshops.json', $this->seedWorkshops());
        $this->writeFixtureJson($dataDir.'/bookings.json', $this->seedBookings());
        $this->writeFixtureJson($dataDir.'/cashback_transactions.json', []);
        $this->writeFixtureJson($dataDir.'/reviews.json', []);
        $this->writeFixtureJson($dataDir.'/booking_messages.json', []);
        $this->writeFixtureJson($dataDir.'/workshop_locations.json', $this->seedWorkshopLocations());

        config()->set('ustatop.data_dir', $dataDir);
        config()->set('ustatop.storage_driver', 'sqlite');
        config()->set('ustatop.sqlite_file', $this->ustatopSqlitePath);
        config()->set('ustatop.users_file', $dataDir.'/users.json');
        config()->set('ustatop.workshops_file', $dataDir.'/workshops.json');
        config()->set('ustatop.bookings_file', $dataDir.'/bookings.json');
        config()->set('ustatop.cashback_transactions_file', $dataDir.'/cashback_transactions.json');
        config()->set('ustatop.reviews_file', $dataDir.'/reviews.json');
        config()->set('ustatop.booking_messages_file', $dataDir.'/booking_messages.json');
        config()->set('ustatop.workshop_locations_file', $dataDir.'/workshop_locations.json');
        config()->set('ustatop.auth_sessions_file', $storageDir.'/auth_sessions.json');
        config()->set('ustatop.sms_verifications_file', $storageDir.'/sms_verifications.json');
        config()->set('ustatop.telegram_sync_state_file', $storageDir.'/telegram_sync_state.json');
        config()->set('ustatop.workshop_images_dir', $storageDir.'/workshop-images');
        config()->set('ustatop.customer_avatars_dir', $storageDir.'/customer-avatars');
        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', $this->ustatopSqlitePath);
    }

    protected function tearDownUstaTopData(): void
    {
        if (isset($this->ustatopTempDir) && $this->ustatopTempDir !== '') {
            File::deleteDirectory($this->ustatopTempDir);
        }

        JsonFileStore::clearSqliteConnectionCache();
        JsonFileStore::clearDatabaseConnectionCache();
    }

    private function writeFixtureJson(string $path, array $data): void
    {
        File::put(
            $path,
            json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
        );
    }

    private function seedUsers(): array
    {
        return [[
            'id' => 'u-seed-1',
            'fullName' => 'Seed Customer',
            'phone' => '+998900000111',
            'password' => password_hash('secret123', PASSWORD_BCRYPT),
            'avatarUrl' => '',
            'pushTokens' => [],
            'savedVehicles' => [],
            'paymentCards' => [],
        ]];
    }

    private function seedWorkshops(): array
    {
        return [
            [
                'id' => 'w-0',
                'name' => 'Express Avto',
                'master' => 'Sardor Usta',
                'rating' => 4.5,
                'reviewCount' => 4,
                'address' => 'Toshkent, Yunusobod',
                'description' => 'Tezkor avto xizmatlar.',
                'distanceKm' => 3.4,
                'latitude' => 41.3651,
                'longitude' => 69.2887,
                'isOpen' => true,
                'badge' => 'Tezkor',
                'imageUrl' => '',
                'ownerAccessCode' => '0000',
                'startingPrice' => 90,
                'services' => [[
                    'id' => 'srv-0',
                    'name' => 'Tezkor ko‘rik',
                    'price' => 90,
                    'durationMinutes' => 30,
                    'prepaymentPercent' => 0,
                ]],
                'schedule' => [
                    'openingTime' => '09:00',
                    'closingTime' => '18:00',
                    'breakStartTime' => '13:00',
                    'breakEndTime' => '14:00',
                    'closedWeekdays' => [7],
                ],
                'vehiclePricingRules' => [],
                'telegramChatId' => '',
                'telegramChatLabel' => '',
                'telegramLinkCode' => '',
            ],
            [
                'id' => 'w-1',
                'name' => 'Turbo Usta Servis',
                'master' => 'Olim Usta',
                'rating' => 4.9,
                'reviewCount' => 12,
                'address' => 'Toshkent, Chilonzor',
                'description' => 'Diagnostika va servis ishlari bir joyda.',
                'distanceKm' => 1.2,
                'latitude' => 41.2857,
                'longitude' => 69.2034,
                'isOpen' => true,
                'badge' => 'TOP',
                'imageUrl' => '',
                'ownerAccessCode' => '1111',
                'startingPrice' => 120,
                'services' => [
                    [
                        'id' => 'srv-1',
                        'name' => 'Kompyuter diagnostika',
                        'price' => 120,
                        'durationMinutes' => 30,
                        'prepaymentPercent' => 0,
                    ],
                    [
                        'id' => 'srv-2',
                        'name' => 'Moy va filtr almashtirish',
                        'price' => 180,
                        'durationMinutes' => 60,
                        'prepaymentPercent' => 0,
                    ],
                ],
                'schedule' => [
                    'openingTime' => '09:00',
                    'closingTime' => '19:00',
                    'breakStartTime' => '13:00',
                    'breakEndTime' => '14:00',
                    'closedWeekdays' => [7],
                ],
                'vehiclePricingRules' => [],
                'telegramChatId' => '',
                'telegramChatLabel' => '',
                'telegramLinkCode' => '',
            ],
        ];
    }

    private function seedBookings(): array
    {
        return [[
            'id' => 'b-seed-1',
            'userId' => 'u-seed-1',
            'customerName' => 'Seed Customer',
            'customerPhone' => '+998900000111',
            'workshopId' => 'w-1',
            'workshopName' => 'Turbo Usta Servis',
            'masterName' => 'Olim Usta',
            'serviceId' => 'srv-1',
            'serviceName' => 'Kompyuter diagnostika',
            'vehicleModel' => 'Chevrolet Cobalt',
            'vehicleTypeId' => 'sedan',
            'catalogVehicleId' => 'chevrolet_cobalt',
            'vehicleBrand' => 'Chevrolet',
            'vehicleModelName' => 'Cobalt',
            'isCustomVehicle' => false,
            'dateTime' => '2026-03-31T05:00:00Z',
            'basePrice' => 120,
            'price' => 120,
            'status' => 'upcoming',
            'createdAt' => '2026-03-30T04:00:00Z',
            'prepaymentPercent' => 0,
            'prepaymentAmount' => 0,
            'remainingAmount' => 120,
            'paymentStatus' => 'not_required',
            'paymentMethod' => 'cash',
            'paidAt' => null,
            'reviewId' => '',
            'reviewSubmittedAt' => null,
        ]];
    }

    private function seedWorkshopLocations(): array
    {
        return [
            'w-0' => [
                'latitude' => 41.3651,
                'longitude' => 69.2887,
            ],
            'w-1' => [
                'latitude' => 41.2857,
                'longitude' => 69.2034,
            ],
        ];
    }
}
