<?php

namespace Tests\Feature;

use App\Support\UstaTop\JsonFileStore;
use Illuminate\Support\Facades\Artisan;
use Tests\Concerns\UsesIsolatedUstaTopData;
use Tests\TestCase;

class UstaTopDoctorCommandTest extends TestCase
{
    use UsesIsolatedUstaTopData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpUstaTopData();
        JsonFileStore::clearSqliteConnectionCache();
        JsonFileStore::clearDatabaseConnectionCache();
        config()->set('app.key', 'base64:test-key-for-doctor-command');
        config()->set('services.sms.driver', 'log');
        config()->set('ustatop.workshop_images_dir', $this->ustatopTempDir.'/storage/app/ustatop/workshop-images');
    }

    protected function tearDown(): void
    {
        $this->tearDownUstaTopData();
        parent::tearDown();
    }

    public function test_doctor_command_runs_successfully_with_local_defaults(): void
    {
        $this->artisan('ustatop:doctor')
            ->expectsOutputToContain('UstaTop Doctor')
            ->assertSuccessful();
    }

    public function test_doctor_command_can_output_json(): void
    {
        $status = Artisan::call('ustatop:doctor', ['--json' => true]);
        $output = trim(Artisan::output());

        $this->assertSame(0, $status);

        $decoded = json_decode($output, true);
        $this->assertIsArray($decoded);
        $this->assertArrayHasKey('ok', $decoded);
        $this->assertArrayHasKey('checks', $decoded);
    }
}
