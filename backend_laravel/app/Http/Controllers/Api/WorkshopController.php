<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use RuntimeException;

class WorkshopController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
    ) {
    }

    public function index()
    {
        return response()->json([
            'data' => $this->repository->listWorkshops(),
        ]);
    }

    public function show(string $id)
    {
        $workshop = $this->repository->workshopById($id);
        if (! $workshop) {
            return response()->json(['error' => 'Servis topilmadi'], 404);
        }

        return response()->json(['data' => $workshop]);
    }

    public function availability(Request $request, string $id)
    {
        try {
            return response()->json([
                'data' => $this->repository->availability(
                    $id,
                    trim((string) $request->query('serviceId')),
                    trim((string) $request->query('date'))
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function availabilityCalendar(Request $request, string $id)
    {
        try {
            return response()->json([
                'data' => $this->repository->availabilityCalendar(
                    $id,
                    trim((string) $request->query('serviceId')),
                    (int) $request->query('days', 14)
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function priceQuote(Request $request, string $id)
    {
        try {
            return response()->json([
                'data' => $this->repository->priceQuote(
                    $id,
                    trim((string) $request->query('serviceId'))
                ),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function createReview(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->createReview($user, $id, $request->all()),
            ], 201);
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
