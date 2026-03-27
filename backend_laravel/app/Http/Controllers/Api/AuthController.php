<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use RuntimeException;

class AuthController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
    ) {
    }

    public function login(Request $request)
    {
        $auth = $this->repository->login(
            trim((string) $request->input('phone')),
            (string) $request->input('password')
        );

        if (! $auth) {
            return response()->json(['error' => 'Telefon yoki parol noto‘g‘ri'], 401);
        }

        return response()->json([
            'data' => [
                'token' => $auth['token'],
                'refreshToken' => 'refresh-'.$auth['token'],
                'expiresAt' => now()->addDays(30)->toIso8601String(),
                'user' => $auth['user'],
            ],
        ]);
    }

    public function register(Request $request)
    {
        try {
            $user = $this->repository->createUser(
                trim((string) $request->input('fullName')),
                trim((string) $request->input('phone')),
                (string) $request->input('password')
            );
            $auth = $this->repository->login($user['phone'], $user['password']);

            return response()->json([
                'data' => [
                    'token' => $auth['token'],
                    'refreshToken' => 'refresh-'.$auth['token'],
                    'expiresAt' => now()->addDays(30)->toIso8601String(),
                    'user' => $auth['user'],
                ],
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function me(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        return response()->json(['data' => $this->repository->publicUser($user)]);
    }

    private function userFromRequest(Request $request): ?array
    {
        $token = trim(str_replace('Bearer', '', (string) $request->header('Authorization')));

        return $this->repository->authUserFromToken($token);
    }
}
