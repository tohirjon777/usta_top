<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use RuntimeException;

class BookingController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
    ) {
    }

    public function index(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        return response()->json([
            'data' => $this->repository->bookingsForUser($user['id']),
        ]);
    }

    public function store(Request $request)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->createBooking($user, $request->all()),
            ], 201);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function cancel(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->cancelBookingForUser($user['id'], $id),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function reschedule(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->rescheduleBookingForUser(
                    $user['id'],
                    $id,
                    trim((string) $request->input('dateTime'))
                ),
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
