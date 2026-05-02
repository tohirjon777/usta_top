<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopNotificationsService;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use RuntimeException;

class WorkshopController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly WorkshopNotificationsService $notifications,
    ) {
    }

    public function index()
    {
        return $this->freshJson([
            'data' => $this->repository->listWorkshops(),
        ]);
    }

    public function show(string $id)
    {
        $workshop = $this->repository->workshopById($id);
        if (! $workshop) {
            return response()->json(['error' => 'Servis topilmadi'], 404);
        }

        return $this->freshJson(['data' => $workshop]);
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
            $fromRaw = trim((string) $request->query('from'));
            return response()->json([
                'data' => $this->repository->availabilityCalendar(
                    $id,
                    trim((string) $request->query('serviceId')),
                    $fromRaw === ''
                        ? CarbonImmutable::now()->startOfDay()
                        : CarbonImmutable::parse($fromRaw)->startOfDay(),
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
                    trim((string) $request->query('serviceId')),
                    trim((string) $request->query('catalogVehicleId')),
                    trim((string) $request->query('vehicleBrand')),
                    trim((string) $request->query('vehicleModelName')),
                    trim((string) $request->query('vehicleTypeId'))
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
            $result = $this->repository->createReview($user, $id, $request->all());
            $workshop = $result['workshop'] ?? null;
            $review = $result['review'] ?? null;
            if (is_array($workshop) && is_array($review)) {
                try {
                    $this->notifications->sendNewReviewNotification($workshop, $review);
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return response()->json([
                'data' => $workshop,
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

    private function freshJson(array $payload, int $status = 200): JsonResponse
    {
        return response()
            ->json($payload, $status)
            ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0');
    }
}
