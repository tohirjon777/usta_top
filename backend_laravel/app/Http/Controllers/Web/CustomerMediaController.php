<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\CustomerAvatarStorage;
use Illuminate\Http\Response;

class CustomerMediaController extends Controller
{
    public function __construct(
        private readonly CustomerAvatarStorage $avatarStorage,
    ) {
    }

    public function showCustomerAvatar(string $filename)
    {
        $path = $this->avatarStorage->absolutePathForFilename($filename);
        if ($path === null) {
            abort(Response::HTTP_NOT_FOUND);
        }

        return response()->file($path, [
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
