<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\Money;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopNotificationsService;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Str;
use RuntimeException;

class CustomerWebsiteController extends Controller
{
    private const CUSTOMER_SESSION_TOKEN = 'ustatop_customer_token';

    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly WorkshopNotificationsService $notifications,
    ) {
    }

    public function home(Request $request)
    {
        $workshops = collect($this->repository->listWorkshops())
            ->map(fn (array $workshop): array => $this->presentWorkshopSummary($workshop))
            ->sortByDesc(fn (array $workshop): string => sprintf(
                '%d-%04d-%04d',
                $workshop['isOpen'] ? 1 : 0,
                (int) round(((float) ($workshop['rating'] ?? 0)) * 100),
                (int) round(1000 - (((float) ($workshop['distanceKm'] ?? 0)) * 10))
            ))
            ->values();

        $services = $workshops
            ->flatMap(fn (array $workshop): array => array_map(
                fn (array $service): string => (string) ($service['name'] ?? ''),
                $workshop['services'] ?? []
            ))
            ->filter()
            ->unique()
            ->sort()
            ->values()
            ->all();

        return view('ustatop.customer.home', [
            'title' => 'Usta Top',
            'currentCustomer' => $this->presentCustomer($this->currentCustomer($request)),
            'initialWorkshops' => $workshops->all(),
            'featuredWorkshops' => $workshops->take(3)->all(),
            'services' => $services,
            'stats' => [
                'workshops' => $workshops->count(),
                'openNow' => $workshops->where('isOpen', true)->count(),
                'services' => $services ? count($services) : $workshops->sum(fn (array $workshop): int => count($workshop['services'] ?? [])),
            ],
            'apiEndpoint' => '/workshops',
        ]);
    }

    public function workshop(Request $request, string $id)
    {
        $workshop = $this->repository->workshopById($id);
        abort_unless($workshop !== null, 404);

        $presented = $this->presentWorkshopDetail($workshop);
        $related = collect($this->repository->listWorkshops())
            ->reject(fn (array $item): bool => ($item['id'] ?? '') === $id)
            ->map(fn (array $item): array => $this->presentWorkshopSummary($item))
            ->take(3)
            ->values()
            ->all();
        $customer = $this->currentCustomer($request);

        return view('ustatop.customer.workshop', [
            'title' => ($presented['name'] ?? 'Usta Top').' | Usta Top',
            'currentCustomer' => $this->presentCustomer($customer),
            'workshop' => $presented,
            'relatedWorkshops' => $related,
            'vehicleTypes' => $this->vehicleTypes(),
            'paymentMethods' => $this->paymentMethods(),
            'savedVehicles' => array_values($customer['savedVehicles'] ?? []),
            'savedCards' => array_values($customer['paymentCards'] ?? []),
            'savedCardsLabel' => implode(', ', array_map(
                fn (array $card): string => trim((string) ($card['brand'] ?? 'Card').' '.(string) ($card['maskedNumber'] ?? '')),
                array_values($customer['paymentCards'] ?? [])
            )),
        ]);
    }

    public function loginPage(Request $request)
    {
        if ($this->currentCustomer($request)) {
            return redirect('/customer/account');
        }

        return view('ustatop.customer.auth', [
            'title' => 'Mijoz kirish | Usta Top',
            'currentCustomer' => null,
        ]);
    }

    public function login(Request $request)
    {
        $auth = $this->repository->login(
            trim((string) $request->input('phone')),
            (string) $request->input('password')
        );

        if (! $auth) {
            return redirect('/customer/login')->with('error', 'Telefon yoki parol noto‘g‘ri');
        }

        $request->session()->put(self::CUSTOMER_SESSION_TOKEN, (string) $auth['token']);

        return redirect($this->pullIntendedPath($request, '/customer/account'))
            ->with('success', 'Muvaffaqiyatli kirdingiz');
    }

    public function register(Request $request)
    {
        try {
            $user = $this->repository->createUser(
                trim((string) $request->input('fullName')),
                trim((string) $request->input('phone')),
                (string) $request->input('password')
            );
            $auth = $this->repository->login((string) $user['phone'], (string) $user['password']);
            if (! $auth) {
                throw new RuntimeException('Akkaunt yaratildi, lekin avtomatik kirib bo‘lmadi');
            }

            $request->session()->put(self::CUSTOMER_SESSION_TOKEN, (string) $auth['token']);

            return redirect($this->pullIntendedPath($request, '/customer/account'))
                ->with('success', 'Akkaunt yaratildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/login')->with('error', $exception->getMessage());
        }
    }

    public function logout(Request $request)
    {
        $request->session()->forget(self::CUSTOMER_SESSION_TOKEN);
        $request->session()->forget('ustatop_customer_intended');

        return redirect('/')->with('success', 'Hisobdan chiqdingiz');
    }

    public function accountPage(Request $request)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        $bookings = collect($this->repository->bookingsForUser((string) $customer['id']))
            ->map(fn (array $booking): array => $this->presentBooking($customer, $booking))
            ->values()
            ->all();

        return view('ustatop.customer.account', [
            'title' => 'Mening kabinetim | Usta Top',
            'currentCustomer' => $this->presentCustomer($customer),
            'bookings' => $bookings,
            'vehicleTypes' => $this->vehicleTypes(),
            'paymentMethods' => $this->paymentMethods(),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->updateUserProfile(
                (string) $customer['id'],
                trim((string) $request->input('fullName')),
                trim((string) $request->input('phone'))
            );

            return redirect('/customer/account#profile')->with('success', 'Profil yangilandi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#profile')->with('error', $exception->getMessage());
        }
    }

    public function updatePassword(Request $request)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $newPassword = (string) $request->input('newPassword');
            $this->repository->changePassword(
                (string) $customer['id'],
                (string) $request->input('currentPassword'),
                $newPassword
            );

            $auth = $this->repository->login((string) $customer['phone'], $newPassword);
            if ($auth) {
                $request->session()->put(self::CUSTOMER_SESSION_TOKEN, (string) $auth['token']);
            }

            return redirect('/customer/account#profile')->with('success', 'Parol yangilandi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#profile')->with('error', $exception->getMessage());
        }
    }

    public function addCard(Request $request)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->addPaymentCard((string) $customer['id'], $request->all());

            return redirect('/customer/account#cards')->with('success', 'Karta qo‘shildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#cards')->with('error', $exception->getMessage());
        }
    }

    public function updateCard(Request $request, string $cardId)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->updatePaymentCard((string) $customer['id'], $cardId, $request->all());

            return redirect('/customer/account#cards')->with('success', 'Karta yangilandi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#cards')->with('error', $exception->getMessage());
        }
    }

    public function deleteCard(Request $request, string $cardId)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->deletePaymentCard((string) $customer['id'], $cardId);

            return redirect('/customer/account#cards')->with('success', 'Karta o‘chirildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#cards')->with('error', $exception->getMessage());
        }
    }

    public function createBooking(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request, '/workshop/'.$id);
        }

        try {
            $booking = $this->repository->createBooking($customer, $this->bookingPayload($request, $id));
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendNewBookingNotification($workshop, $booking);
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return redirect('/customer/account#booking-'.$booking['id'])
                ->with('success', 'Buyurtma muvaffaqiyatli yaratildi');
        } catch (RuntimeException $exception) {
            return redirect('/workshop/'.$id)->with('error', $exception->getMessage());
        }
    }

    public function cancelBooking(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->cancelBookingForUser((string) $customer['id'], $id);

            return redirect('/customer/account#booking-'.$id)->with('success', 'Buyurtma bekor qilindi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#booking-'.$id)->with('error', $exception->getMessage());
        }
    }

    public function rescheduleBooking(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $dateTime = $this->combineDateAndTime(
                trim((string) $request->input('bookingDate')),
                trim((string) $request->input('bookingTime'))
            );
            $this->repository->rescheduleBookingForUser((string) $customer['id'], $id, $dateTime);

            return redirect('/customer/account#booking-'.$id)->with('success', 'Buyurtma ko‘chirildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#booking-'.$id)->with('error', $exception->getMessage());
        }
    }

    public function acceptRescheduled(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $booking = $this->repository->acceptRescheduledBookingForUser((string) $customer['id'], $id);
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendBookingStatusNotification($workshop, $booking, 'customer');
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            return redirect('/customer/account#booking-'.$id)->with('success', 'Ko‘chirilgan vaqt tasdiqlandi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#booking-'.$id)->with('error', $exception->getMessage());
        }
    }

    public function sendMessage(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $this->repository->createBookingMessageForCustomer(
                $customer,
                $id,
                trim((string) $request->input('text'))
            );

            return redirect('/customer/account#booking-'.$id)->with('success', 'Xabar yuborildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account#booking-'.$id)->with('error', $exception->getMessage());
        }
    }

    public function createReview(Request $request, string $id)
    {
        $customer = $this->currentCustomer($request);
        if (! $customer) {
            return $this->redirectToLogin($request);
        }

        try {
            $result = $this->repository->createReview($customer, $id, $request->all());
            if (is_array($result['workshop'] ?? null) && is_array($result['review'] ?? null)) {
                try {
                    $this->notifications->sendNewReviewNotification($result['workshop'], $result['review']);
                } catch (\Throwable $error) {
                    report($error);
                }
            }

            $bookingId = trim((string) $request->input('bookingId'));

            return redirect('/customer/account'.($bookingId !== '' ? '#booking-'.$bookingId : ''))
                ->with('success', 'Sharhingiz yuborildi');
        } catch (RuntimeException $exception) {
            return redirect('/customer/account')->with('error', $exception->getMessage());
        }
    }

    private function bookingPayload(Request $request, string $workshopId): array
    {
        $vehicleBrand = trim((string) $request->input('vehicleBrand'));
        $vehicleModelName = trim((string) $request->input('vehicleModelName'));

        return [
            'workshopId' => $workshopId,
            'serviceId' => trim((string) $request->input('serviceId')),
            'vehicleBrand' => $vehicleBrand,
            'vehicleModelName' => $vehicleModelName,
            'vehicleModel' => trim(implode(' ', array_filter([$vehicleBrand, $vehicleModelName]))),
            'catalogVehicleId' => trim((string) $request->input('catalogVehicleId')),
            'isCustomVehicle' => true,
            'vehicleTypeId' => trim((string) $request->input('vehicleTypeId')),
            'dateTime' => $this->combineDateAndTime(
                trim((string) $request->input('bookingDate')),
                trim((string) $request->input('bookingTime'))
            ),
            'paymentMethod' => trim((string) $request->input('paymentMethod')),
        ];
    }

    private function combineDateAndTime(string $date, string $time): string
    {
        if ($date === '' || $time === '') {
            throw new RuntimeException('Sana va vaqtni tanlang');
        }

        return CarbonImmutable::createFromFormat(
            'Y-m-d H:i',
            $date.' '.$time,
            config('app.timezone')
        )->toIso8601String();
    }

    private function redirectToLogin(Request $request, ?string $intended = null): RedirectResponse
    {
        $request->session()->put(
            'ustatop_customer_intended',
            $intended ?? $request->fullUrl()
        );

        return redirect('/customer/login')->with('error', 'Avval tizimga kiring');
    }

    private function pullIntendedPath(Request $request, string $fallback): string
    {
        $intended = (string) $request->session()->pull('ustatop_customer_intended', $fallback);

        return $intended !== '' ? $intended : $fallback;
    }

    private function currentCustomer(Request $request): ?array
    {
        $token = trim((string) $request->session()->get(self::CUSTOMER_SESSION_TOKEN, ''));
        if ($token === '') {
            return null;
        }

        return $this->repository->authUserFromToken($token);
    }

    private function presentCustomer(?array $customer): ?array
    {
        if ($customer === null) {
            return null;
        }

        $public = $this->repository->publicUser($customer);
        $public['savedPaymentCards'] = array_values(array_map(function (array $card): array {
            return [
                'id' => (string) ($card['id'] ?? ''),
                'brand' => (string) ($card['brand'] ?? 'Card'),
                'maskedNumber' => (string) ($card['maskedNumber'] ?? ''),
                'holderName' => (string) ($card['holderName'] ?? ''),
                'expiryLabel' => sprintf('%02d/%s', (int) ($card['expiryMonth'] ?? 0), substr((string) ($card['expiryYear'] ?? ''), -2)),
                'isDefault' => (bool) ($card['isDefault'] ?? false),
            ];
        }, $public['savedPaymentCards'] ?? []));

        return $public;
    }

    private function presentBooking(array $customer, array $booking): array
    {
        $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
        $messages = $this->repository->fetchBookingMessagesForCustomer((string) $customer['id'], (string) ($booking['id'] ?? ''));
        $status = (string) ($booking['status'] ?? 'upcoming');
        $booking['statusLabel'] = $this->bookingStatusLabel($status);
        $booking['dateTimeLabel'] = $this->dateTimeLabel((string) ($booking['dateTime'] ?? ''));
        $booking['previousDateTimeLabel'] = $this->dateTimeLabel((string) ($booking['previousDateTime'] ?? ''));
        $booking['acceptedAtLabel'] = $this->dateTimeLabel((string) ($booking['acceptedAt'] ?? ''));
        $booking['completedAtLabel'] = $this->dateTimeLabel((string) ($booking['completedAt'] ?? ''));
        $booking['cancelledAtLabel'] = $this->dateTimeLabel((string) ($booking['cancelledAt'] ?? ''));
        $booking['rescheduledAtLabel'] = $this->dateTimeLabel((string) ($booking['rescheduledAt'] ?? ''));
        $booking['priceLabel'] = Money::formatUzs((int) ($booking['price'] ?? 0));
        $booking['prepaymentLabel'] = Money::formatUzs((int) ($booking['prepaymentAmount'] ?? 0));
        $booking['remainingLabel'] = Money::formatUzs((int) ($booking['remainingAmount'] ?? 0));
        $booking['canCancel'] = in_array($status, ['upcoming', 'accepted', 'rescheduled'], true);
        $booking['canReschedule'] = in_array($status, ['upcoming', 'accepted', 'rescheduled'], true);
        $booking['canAcceptRescheduled'] = $status === 'rescheduled' && (($booking['rescheduledByRole'] ?? '') !== 'customer');
        $booking['canReview'] = $status === 'completed' && trim((string) ($booking['reviewId'] ?? '')) === '';
        $booking['detailUrl'] = $workshop ? '/workshop/'.urlencode((string) ($workshop['id'] ?? '')) : '/';
        $booking['messages'] = array_values(array_map(function (array $message): array {
            return [
                'senderRole' => (string) ($message['senderRole'] ?? ''),
                'senderLabel' => ($message['senderRole'] ?? '') === 'customer' ? 'Siz' : 'Ustaxona',
                'text' => (string) ($message['text'] ?? ''),
                'createdAtLabel' => $this->dateTimeLabel((string) ($message['createdAt'] ?? '')),
            ];
        }, $messages));

        return $booking;
    }

    private function presentWorkshopSummary(array $workshop): array
    {
        $services = array_values(array_map(function (array $service): array {
            return [
                'id' => (string) ($service['id'] ?? ''),
                'name' => (string) ($service['name'] ?? ''),
                'price' => (int) ($service['price'] ?? 0),
                'priceLabel' => Money::formatUzs((int) ($service['price'] ?? 0)),
                'durationMinutes' => (int) ($service['durationMinutes'] ?? 30),
                'prepaymentPercent' => (int) ($service['prepaymentPercent'] ?? 0),
            ];
        }, $workshop['services'] ?? []));

        $latitude = isset($workshop['latitude']) ? (float) $workshop['latitude'] : null;
        $longitude = isset($workshop['longitude']) ? (float) $workshop['longitude'] : null;

        return [
            'id' => (string) ($workshop['id'] ?? ''),
            'name' => (string) ($workshop['name'] ?? ''),
            'master' => (string) ($workshop['master'] ?? ''),
            'description' => Str::limit(trim((string) ($workshop['description'] ?? '')), 160),
            'fullDescription' => trim((string) ($workshop['description'] ?? '')),
            'address' => (string) ($workshop['address'] ?? ''),
            'badge' => trim((string) ($workshop['badge'] ?? '')),
            'isOpen' => (bool) ($workshop['isOpen'] ?? false),
            'rating' => number_format((float) ($workshop['rating'] ?? 0), 1),
            'reviewCount' => (int) ($workshop['reviewCount'] ?? 0),
            'distanceKm' => number_format((float) ($workshop['distanceKm'] ?? 0), 1),
            'startingPrice' => (int) ($workshop['startingPrice'] ?? 0),
            'startingPriceLabel' => Money::formatUzs((int) ($workshop['startingPrice'] ?? 0)),
            'imageUrl' => trim((string) ($workshop['imageUrl'] ?? '')),
            'services' => $services,
            'serviceNames' => array_values(array_map(fn (array $service): string => $service['name'], array_slice($services, 0, 4))),
            'latitude' => $latitude,
            'longitude' => $longitude,
            'routeUrl' => ($latitude !== null && $longitude !== null)
                ? 'https://www.google.com/maps/dir/?api=1&destination='.$latitude.','.$longitude
                : null,
            'detailUrl' => '/workshop/'.urlencode((string) ($workshop['id'] ?? '')),
        ];
    }

    private function presentWorkshopDetail(array $workshop): array
    {
        $summary = $this->presentWorkshopSummary($workshop);
        $schedule = $workshop['schedule'] ?? [];
        $closed = array_map('intval', $schedule['closedWeekdays'] ?? [7]);

        $summary['description'] = trim((string) ($workshop['description'] ?? ''));
        $summary['reviews'] = array_values(array_map(function (array $review): array {
            return [
                'id' => (string) ($review['id'] ?? ''),
                'customerName' => (string) ($review['customerName'] ?? 'Mijoz'),
                'rating' => (int) ($review['rating'] ?? 0),
                'comment' => trim((string) ($review['comment'] ?? '')),
                'createdAtLabel' => $this->dateTimeLabel((string) ($review['createdAt'] ?? '')),
                'ownerReply' => trim((string) ($review['ownerReply'] ?? '')),
            ];
        }, $workshop['reviews'] ?? []));
        $summary['schedule'] = [
            'openingTime' => (string) ($schedule['openingTime'] ?? '09:00'),
            'closingTime' => (string) ($schedule['closingTime'] ?? '19:00'),
            'breakStartTime' => (string) ($schedule['breakStartTime'] ?? '13:00'),
            'breakEndTime' => (string) ($schedule['breakEndTime'] ?? '14:00'),
            'closedLabels' => array_values(array_map(
                fn (int $day): string => $this->weekdayLabel($day),
                $closed
            )),
        ];

        return $summary;
    }

    private function bookingStatusLabel(string $status): string
    {
        return match ($status) {
            'accepted' => 'Qabul qilindi',
            'rescheduled' => 'Ko‘chirildi',
            'completed' => 'Yakunlandi',
            'cancelled' => 'Bekor qilindi',
            default => 'Kutilmoqda',
        };
    }

    private function dateTimeLabel(string $value): string
    {
        if (trim($value) === '') {
            return '';
        }

        return CarbonImmutable::parse($value)
            ->setTimezone(config('app.timezone'))
            ->format('d.m.Y H:i');
    }

    private function paymentMethods(): array
    {
        return [
            ['id' => 'cash', 'label' => 'Naqd'],
            ['id' => 'test_card', 'label' => 'Test karta'],
        ];
    }

    private function vehicleTypes(): array
    {
        return [
            ['id' => 'compact', 'label' => 'Kompakt'],
            ['id' => 'sedan', 'label' => 'Sedan'],
            ['id' => 'crossover', 'label' => 'Crossover'],
            ['id' => 'suv', 'label' => 'SUV'],
            ['id' => 'pickup', 'label' => 'Pickup'],
            ['id' => 'minivan', 'label' => 'Minivan'],
        ];
    }

    private function weekdayLabel(int $day): string
    {
        return match ($day) {
            1 => 'Dushanba',
            2 => 'Seshanba',
            3 => 'Chorshanba',
            4 => 'Payshanba',
            5 => 'Juma',
            6 => 'Shanba',
            default => 'Yakshanba',
        };
    }
}
