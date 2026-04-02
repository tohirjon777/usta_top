<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    public function test_health_endpoint_returns_ok_payload(): void
    {
        $response = $this->get('/health');

        $response
            ->assertOk()
            ->assertJsonPath('ok', true)
            ->assertJsonPath('storageDriver', fn ($value) => is_string($value) && $value !== '')
            ->assertJsonPath('environment', fn ($value) => is_string($value) && $value !== '');
    }
}
