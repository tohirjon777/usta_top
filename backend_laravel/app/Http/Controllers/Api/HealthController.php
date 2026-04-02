<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\JsonFileStore;

class HealthController extends Controller
{
    public function __construct(
        private readonly JsonFileStore $store,
    ) {
    }

    public function __invoke()
    {
        return response()->json([
            'ok' => true,
            'environment' => app()->environment(),
            'storageDriver' => $this->store->storageDriverName(),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
