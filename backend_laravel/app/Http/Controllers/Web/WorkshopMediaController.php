<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\WorkshopImageStorage;
use Illuminate\Http\Response;

class WorkshopMediaController extends Controller
{
    public function __construct(
        private readonly WorkshopImageStorage $imageStorage,
    ) {
    }

    public function showWorkshopImage(string $filename)
    {
        $path = $this->imageStorage->absolutePathForFilename($filename);
        if ($path === null) {
            abort(Response::HTTP_NOT_FOUND);
        }

        return response()->file($path, [
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
