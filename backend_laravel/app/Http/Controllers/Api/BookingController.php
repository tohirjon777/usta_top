<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopNotificationsService;
use Illuminate\Http\Request;
use RuntimeException;

class BookingController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly WorkshopNotificationsService $notifications,
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
            $booking = $this->repository->createBooking($user, $request->all());
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendNewBookingNotification($workshop, $booking);
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return response()->json([
                'data' => $booking,
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
            $booking = $this->repository->rescheduleBookingForUser(
                $user['id'],
                $id,
                trim((string) $request->input('dateTime'))
            );
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendBookingStatusNotification($workshop, $booking, 'customer');
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return response()->json([
                'data' => $booking,
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function acceptRescheduled(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $booking = $this->repository->acceptRescheduledBookingForUser(
                (string) $user['id'],
                $id
            );
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendBookingStatusNotification($workshop, $booking, 'customer');
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return response()->json(['data' => $booking]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function messages(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->fetchBookingMessagesForCustomer((string) $user['id'], $id),
            ]);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function sendMessage(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            return response()->json([
                'data' => $this->repository->createBookingMessageForCustomer(
                    $user,
                    $id,
                    trim((string) $request->input('text'))
                ),
            ], 201);
        } catch (RuntimeException $exception) {
            return response()->json(['error' => $exception->getMessage()], 400);
        }
    }

    public function markMessagesRead(Request $request, string $id)
    {
        $user = $this->userFromRequest($request);
        if (! $user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $this->repository->markBookingMessagesReadForCustomer((string) $user['id'], $id);

            return response()->json(['data' => ['ok' => true]]);
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
