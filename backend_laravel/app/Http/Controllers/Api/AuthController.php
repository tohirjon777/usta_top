<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\CustomerAvatarStorage;
use App\Support\UstaTop\SmsVerificationService;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use RuntimeException;

class AuthController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly SmsVerificationService $smsVerificationService,
        private readonly CustomerAvatarStorage $avatarStorage,
    ) {}

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
            $code = trim((string) $request->input('code'));
            if ($code === '') {
                throw new RuntimeException('Tasdiqlash kodi kerak. Avval /auth/register/send-code orqali SMS kod oling');
            }

            return response()->json([
                'data' => [
                    ...$this->smsVerificationService->verifyRegistrationCode(
                        trim((string) $request->input('fullName')),
                        trim((string) $request->input('phone')),
                        (string) $request->input('password'),
                        $code
                    ),
                ],
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function sendRegisterCode(Request $request)
    {
        try {
            return response()->json([
                'data' => $this->smsVerificationService->sendRegistrationCode(
                    trim((string) $request->input('phone'))
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function verifyRegisterCode(Request $request)
    {
        try {
            return response()->json([
                'data' => $this->smsVerificationService->verifyRegistrationCode(
                    trim((string) $request->input('fullName')),
                    trim((string) $request->input('phone')),
                    (string) $request->input('password'),
                    trim((string) $request->input('code'))
                ),
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

    public function forgotPassword(Request $request)
    {
        try {
            $code = trim((string) $request->input('code'));
            if ($code === '') {
                throw new RuntimeException('Tasdiqlash kodi kerak. Avval /auth/password/send-code orqali SMS kod oling');
            }

            $this->smsVerificationService->verifyPasswordResetCode(
                trim((string) $request->input('phone')),
                (string) $request->input('newPassword'),
                $code
            );

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function sendPasswordResetCode(Request $request)
    {
        try {
            return response()->json([
                'data' => $this->smsVerificationService->sendPasswordResetCode(
                    trim((string) $request->input('phone'))
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function verifyPasswordResetCode(Request $request)
    {
        try {
            $this->smsVerificationService->verifyPasswordResetCode(
                trim((string) $request->input('phone')),
                (string) $request->input('newPassword'),
                trim((string) $request->input('code'))
            );

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function updateMe(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->updateUserProfile(
                    (string) $user['id'],
                    trim((string) $request->input('fullName')),
                    trim((string) $request->input('phone'))
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function updateAvatar(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        if (! $request->hasFile('avatar')) {
            return response()->json(['error' => 'Avatar rasmi yuborilmadi'], 400);
        }

        try {
            $avatarUrl = $this->avatarStorage->storeUploadedAvatar(
                $request->file('avatar'),
                (string) ($user['avatarUrl'] ?? '')
            );

            return response()->json([
                'data' => $this->repository->updateUserAvatarUrl(
                    (string) $user['id'],
                    $avatarUrl
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function deleteMe(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $this->avatarStorage->deleteByUrl((string) ($user['avatarUrl'] ?? ''));
            $this->repository->deleteUserAccount((string) $user['id']);

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function addPaymentCard(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->addPaymentCard(
                    (string) $user['id'],
                    $request->all()
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function updatePaymentCard(Request $request, string $cardId)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->updatePaymentCard(
                    (string) $user['id'],
                    $cardId,
                    $request->all()
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function deletePaymentCard(Request $request, string $cardId)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->deletePaymentCard(
                    (string) $user['id'],
                    $cardId
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function updatePassword(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $this->repository->changePassword(
                (string) $user['id'],
                (string) $request->input('currentPassword'),
                (string) $request->input('newPassword')
            );

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function registerPushToken(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $this->repository->registerPushToken(
                (string) $user['id'],
                trim((string) $request->input('token')),
                trim((string) $request->input('platform'))
            );

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function unregisterPushToken(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $this->repository->unregisterPushToken(
                (string) $user['id'],
                trim((string) $request->input('token'))
            );

            return response()->json(['data' => ['ok' => true]]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function sendTestPush(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->sendTestPush((string) $user['id']),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    private function userFromRequest(Request $request): ?array
    {
        $token = trim(str_replace('Bearer', '', (string) $request->header('Authorization')));

        return $this->repository->authUserFromToken($token);
    }
}
