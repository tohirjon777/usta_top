<?php

namespace Tests\Concerns;

use Illuminate\Support\Facades\File;

trait UsesIsolatedUstaTopData
{
    private string $ustatopTempDir;

    protected function setUpUstaTopData(): void
    {
        $this->ustatopTempDir = sys_get_temp_dir().'/ustatop-laravel-'.bin2hex(random_bytes(8));
        $dataDir = $this->ustatopTempDir.'/data';
        $storageDir = $this->ustatopTempDir.'/storage/app/ustatop';

        File::ensureDirectoryExists($dataDir);
        File::ensureDirectoryExists($storageDir);

        foreach ([
            'users.json',
            'workshops.json',
            'bookings.json',
            'reviews.json',
            'booking_messages.json',
            'workshop_locations.json',
        ] as $file) {
            copy(base_path('data/'.$file), $dataDir.'/'.$file);
        }

        config()->set('ustatop.data_dir', $dataDir);
        config()->set('ustatop.users_file', $dataDir.'/users.json');
        config()->set('ustatop.workshops_file', $dataDir.'/workshops.json');
        config()->set('ustatop.bookings_file', $dataDir.'/bookings.json');
        config()->set('ustatop.reviews_file', $dataDir.'/reviews.json');
        config()->set('ustatop.booking_messages_file', $dataDir.'/booking_messages.json');
        config()->set('ustatop.workshop_locations_file', $dataDir.'/workshop_locations.json');
        config()->set('ustatop.auth_sessions_file', $storageDir.'/auth_sessions.json');
    }

    protected function tearDownUstaTopData(): void
    {
        if (isset($this->ustatopTempDir) && $this->ustatopTempDir !== '') {
            File::deleteDirectory($this->ustatopTempDir);
        }
    }
}
