<?php

namespace App\Console\Commands;

use App\Support\UstaTop\JsonFileStore;
use Illuminate\Console\Command;

class UstaTopBootstrapStorageCommand extends Command
{
    protected $signature = 'ustatop:bootstrap-storage';

    protected $description = 'Initialize configured UstaTop storage and import existing seed JSON data.';

    public function __construct(
        private readonly JsonFileStore $store,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $this->store->ensureStorageReady();
        $this->store->syncFilesToStorage([
            config('ustatop.users_file'),
            config('ustatop.workshops_file'),
            config('ustatop.bookings_file'),
            config('ustatop.cashback_transactions_file'),
            config('ustatop.reviews_file'),
            config('ustatop.booking_messages_file'),
            config('ustatop.workshop_locations_file'),
            config('ustatop.auth_sessions_file'),
            config('ustatop.sms_verifications_file'),
            config('ustatop.telegram_sync_state_file'),
        ]);

        $this->info(
            'UstaTop storage ready ['.$this->store->storageDriverName().']: '
            .$this->store->storageLocationDescription()
        );

        return self::SUCCESS;
    }
}
