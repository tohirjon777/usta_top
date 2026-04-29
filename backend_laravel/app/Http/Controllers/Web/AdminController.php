<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\AdminAnalyticsService;
use App\Support\UstaTop\Money;
use App\Support\UstaTop\TelegramBotService;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\VehiclePricingExcelService;
use App\Support\UstaTop\WorkshopImageStorage;
use App\Support\UstaTop\WorkshopNotificationsService;
use Illuminate\Http\Request;
use RuntimeException;

class AdminController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly AdminAnalyticsService $analytics,
        private readonly TelegramBotService $telegramBot,
        private readonly WorkshopNotificationsService $notifications,
        private readonly WorkshopImageStorage $imageStorage,
        private readonly VehiclePricingExcelService $vehiclePricingExcel,
    ) {
    }

    public function entry()
    {
        return redirect('/admin/workshops');
    }

    public function loginPage()
    {
        return view('ustatop.admin.login', [
            'title' => 'Admin login',
            'username' => (string) config('ustatop.admin_username'),
        ]);
    }

    public function login(Request $request)
    {
        if (
            $request->input('username') !== config('ustatop.admin_username')
            || $request->input('password') !== config('ustatop.admin_password')
        ) {
            return redirect('/admin/login')->with('error', 'Login yoki parol noto‘g‘ri');
        }

        $request->session()->put('ustatop_admin', true);

        return redirect('/admin/workshops');
    }

    public function logout(Request $request)
    {
        $request->session()->forget('ustatop_admin');

        return redirect('/admin/login');
    }

    public function workshopsPage(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshops = collect($this->repository->listWorkshops())
            ->map(function (array $workshop): array {
                $closedWeekdays = array_map('intval', $workshop['schedule']['closedWeekdays'] ?? []);
                $workshop['closedWeekdaysCsv'] = implode(',', $closedWeekdays);
                $workshop['servicesText'] = implode("\n", array_map(
                    fn (array $service): string => implode('|', [
                        $service['id'] ?? '',
                        $service['name'] ?? '',
                        Money::inputValue((int) ($service['price'] ?? 0)),
                        $service['durationMinutes'] ?? 30,
                        $service['prepaymentPercent'] ?? 0,
                    ]),
                    $workshop['services'] ?? []
                ));
                $workshop['startingPriceInput'] = Money::inputValue((int) ($workshop['startingPrice'] ?? 0));

                return $workshop;
            })
            ->values()
            ->all();

        return view('ustatop.admin.workshops', [
            'title' => 'Admin workshops',
            'workshops' => $workshops,
            'telegramConfigured' => $this->telegramBot->isConfigured(),
            'panelYandexMapsApiKey' => $this->yandexMapsApiKey(),
        ]);
    }

    public function createWorkshop(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $this->repository->createWorkshop(
                $this->parseWorkshopPayload($request, null)
            );
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect('/admin/workshops')->with('success', 'Ustaxona yaratildi');
    }

    public function updateWorkshop(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $currentWorkshop = $this->repository->workshopById($id);
            $this->repository->updateWorkshop(
                $id,
                $this->parseWorkshopPayload($request, $currentWorkshop)
            );
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect('/admin/workshops')->with('success', 'Ustaxona yangilandi');
    }

    public function deleteWorkshop(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $this->repository->deleteWorkshop($id);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect('/admin/workshops')->with('success', 'Ustaxona o‘chirildi');
    }

    public function bookingsPage(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshopId = trim((string) $request->query('workshop'));
        $bookings = $workshopId !== ''
            ? $this->repository->bookingsForWorkshop($workshopId)
            : collect($this->repository->listWorkshops())
                ->flatMap(fn (array $workshop): array => $this->repository->bookingsForWorkshop((string) $workshop['id']))
                ->values()
                ->all();

        $bookings = collect($bookings)->map(function (array $booking): array {
            $booking['priceLabel'] = Money::formatUzs((int) ($booking['price'] ?? 0));
            $booking['prepaymentLabel'] = Money::formatUzs((int) ($booking['prepaymentAmount'] ?? 0));

            return $booking;
        })->values()->all();

        return view('ustatop.admin.bookings', [
            'title' => 'Admin bookings',
            'bookings' => $bookings,
            'telegramConfigured' => $this->telegramBot->isConfigured(),
        ]);
    }

    public function reviewsPage(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        return redirect('/admin/workshops')->with('success', 'Sharhlar endi owner panelda ko‘rinadi');
    }

    public function downloadVehiclePricingTemplate(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshop = $this->repository->workshopById($id);
        if (! $workshop) {
            return redirect('/admin/workshops')->with('error', 'Ustaxona topilmadi');
        }

        $filename = 'vehicle-pricing-'.preg_replace('/[^A-Za-z0-9_-]+/', '-', strtolower((string) ($workshop['name'] ?? 'workshop'))).'.xlsx';

        return response(
            $this->vehiclePricingExcel->buildWorkbook($workshop),
            200,
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="'.$filename.'"',
            ]
        );
    }

    public function importVehiclePricing(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshop = $this->repository->workshopById($id);
        if (! $workshop) {
            return redirect('/admin/workshops')->with('error', 'Ustaxona topilmadi');
        }

        try {
            $file = $request->file('pricingFile');
            if ($file === null) {
                throw new RuntimeException('Excel fayl tanlanmagan');
            }

            $rules = $this->vehiclePricingExcel->parseWorkbook($file, $workshop);
            $this->repository->updateWorkshop($id, $this->parseWorkshopPayload($request, $workshop) + [
                'vehiclePricingRules' => $rules,
            ]);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Excel narxlari yuklandi');
    }

    public function analyticsPage(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $dashboard = $this->analytics->buildDashboard(
                $request->query('workshop'),
                (string) $request->query('range', '7d'),
                $request->query('from'),
                $request->query('to'),
            );
        } catch (RuntimeException $exception) {
            return redirect('/admin/bookings')->with('error', $exception->getMessage());
        }

        $filters = $dashboard['filters'];

        return view('ustatop.admin.analytics', [
            'title' => 'Admin analytics',
            'telegramConfigured' => $this->telegramBot->isConfigured(),
            'filters' => $filters,
            'periodLabel' => (string) ($dashboard['periodLabel'] ?? ''),
            'metrics' => $dashboard['metrics'] ?? [],
            'bookingsChart' => $dashboard['bookingsChart'] ?? [],
            'revenueChart' => $dashboard['revenueChart'] ?? [],
            'statusBreakdown' => $dashboard['statusBreakdown'] ?? [],
            'reviewMetrics' => $dashboard['reviewMetrics'] ?? [],
            'topWorkshops' => $dashboard['topWorkshops'] ?? [],
            'topServices' => $dashboard['topServices'] ?? [],
            'topVehicles' => $dashboard['topVehicles'] ?? [],
            'cancelReasons' => $dashboard['cancelReasons'] ?? [],
            'ratings' => $dashboard['ratings'] ?? [],
            'exportQuery' => [
                'range' => $filters['range'] ?? '7d',
                'workshop' => $filters['workshopId'] ?? '',
                'from' => $filters['from'] ?? '',
                'to' => $filters['to'] ?? '',
            ],
        ]);
    }

    public function exportAnalyticsCsv(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $dashboard = $this->analytics->buildDashboard(
            $request->query('workshop'),
            (string) $request->query('range', '7d'),
            $request->query('from'),
            $request->query('to'),
        );

        $rows = $dashboard['exportRows'] ?? [];
        $stream = fopen('php://temp', 'r+');
        fwrite($stream, "\xEF\xBB\xBF");
        fputcsv($stream, [
            'booking_id',
            'created_at',
            'scheduled_at',
            'workshop',
            'service',
            'customer',
            'phone',
            'vehicle',
            'status',
            'accepted_at',
            'rescheduled_at',
            'previous_datetime',
            'completed_at',
            'cancelled_at',
            'cancel_reason',
            'price_uzs',
            'prepayment_uzs',
            'payment_status',
            'payment_method',
        ]);

        foreach ($rows as $row) {
            fputcsv($stream, $row);
        }

        rewind($stream);
        $csv = stream_get_contents($stream) ?: '';
        fclose($stream);

        $filename = 'admin-analytics-'.now()->format('Ymd-His').'.csv';

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="'.$filename.'"',
        ]);
    }

    public function hideReview(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $this->repository->setReviewHidden($id, true);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect('/admin/reviews')->with('success', 'Sharh yashirildi');
    }

    public function unhideReview(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $this->repository->setReviewHidden($id, false);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect('/admin/reviews')->with('success', 'Sharh qayta ko‘rsatildi');
    }

    public function remindReview(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $review = $this->repository->reviewById($id);
            if ($review === null) {
                throw new RuntimeException('Sharh topilmadi');
            }

            if (($review['isHidden'] ?? false) === true) {
                throw new RuntimeException('Yashirilgan sharh uchun eslatma yuborib bo‘lmaydi');
            }

            if (trim((string) ($review['ownerReply'] ?? '')) !== '') {
                throw new RuntimeException('Bu sharhga allaqachon javob berilgan');
            }

            $workshop = $this->repository->workshopById((string) ($review['workshopId'] ?? ''));
            if ($workshop === null) {
                throw new RuntimeException('Ustaxona topilmadi');
            }

            $this->notifications->sendReviewReplyReminder($workshop, $review);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        } catch (\Throwable $error) {
            report($error);

            return redirect()->back()->with('error', 'Ownerga eslatma yuborilmadi');
        }

        return redirect()->back()->with('success', 'Ownerga sharh eslatmasi yuborildi');
    }

    public function updateWorkshopLocation(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshop = $this->repository->workshopById($id);
        if ($workshop === null) {
            return redirect('/admin/workshops')->with('error', 'Ustaxona topilmadi');
        }

        try {
            $this->repository->updateWorkshop($id, [
                'name' => $workshop['name'] ?? '',
                'master' => $workshop['master'] ?? '',
                'address' => $workshop['address'] ?? '',
                'description' => $workshop['description'] ?? '',
                'badge' => $workshop['badge'] ?? '',
                'imageUrl' => $workshop['imageUrl'] ?? '',
                'startingPrice' => $workshop['startingPrice'] ?? 0,
                'ownerAccessCode' => $workshop['ownerAccessCode'] ?? '',
                'telegramChatId' => $workshop['telegramChatId'] ?? '',
                'telegramChatLabel' => $workshop['telegramChatLabel'] ?? '',
                'telegramLinkCode' => $workshop['telegramLinkCode'] ?? '',
                'isOpen' => $workshop['isOpen'] ?? true,
                'services' => $workshop['services'] ?? [],
                'schedule' => $workshop['schedule'] ?? [],
                'vehiclePricingRules' => $workshop['vehiclePricingRules'] ?? [],
                'latitude' => trim((string) $request->input('latitude')),
                'longitude' => trim((string) $request->input('longitude')),
            ]);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Lokatsiya yangilandi');
    }

    public function updateBookingStatus(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $booking = $this->repository->updateBookingStatus(
                $id,
                (string) $request->input('bookingStatus'),
                [
                    'scheduledAt' => (string) $request->input('scheduledAt'),
                    'cancelReasonId' => (string) $request->input('cancellationReasonId'),
                    'actorRole' => 'admin',
                ]
            );
            $workshop = $this->repository->workshopById((string) ($booking['workshopId'] ?? ''));
            if ($workshop !== null) {
                try {
                    $this->notifications->sendBookingStatusNotification($workshop, $booking, 'admin');
                } catch (\Throwable $error) {
                    report($error);
                }
            }
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Zakaz holati yangilandi');
    }

    private function parseWorkshopPayload(Request $request, ?array $currentWorkshop): array
    {
        return [
            'name' => trim((string) $request->input('name')),
            'master' => trim((string) $request->input('master')),
            'address' => trim((string) $request->input('address')),
            'description' => trim((string) $request->input('description')),
            'badge' => trim((string) $request->input('badge')),
            'imageUrl' => $this->resolveWorkshopImage($request, $currentWorkshop),
            'latitude' => trim((string) $request->input('latitude')),
            'longitude' => trim((string) $request->input('longitude')),
            'startingPrice' => Money::parseStoredAmount((string) $request->input('startingPrice', '0')) ?? 0,
            'ownerAccessCode' => trim((string) $request->input('ownerAccessCode')),
            'telegramChatId' => trim((string) $request->input('telegramChatId')),
            'telegramChatLabel' => trim((string) $request->input('telegramChatId')) !== ''
                ? trim((string) $request->input('telegramChatId'))
                : '',
            'telegramLinkCode' => trim((string) $request->input('telegramChatId')) !== ''
                ? ''
                : null,
            'isOpen' => $request->boolean('isOpen'),
            'services' => $this->parseServicesText((string) $request->input('servicesText')),
            'schedule' => $this->parseSchedule($request),
        ];
    }

    private function parseSchedule(Request $request): array
    {
        $openingTime = trim((string) $request->input('openingTime', '09:00'));
        $closingTime = trim((string) $request->input('closingTime', '19:00'));
        $breakStartTime = trim((string) $request->input('breakStartTime', '13:00'));
        $breakEndTime = trim((string) $request->input('breakEndTime', '14:00'));
        $closedWeekdays = array_values(array_unique(array_filter(array_map(
            static fn (string $value): int => (int) trim($value),
            preg_split('/\s*,\s*/', trim((string) $request->input('closedWeekdays', '7'))) ?: []
        ), static fn (int $weekday): bool => $weekday >= 1 && $weekday <= 7)));

        foreach ([$openingTime, $closingTime, $breakStartTime, $breakEndTime] as $time) {
            if ($time !== '' && preg_match('/^([01]\d|2[0-3]):([0-5]\d)$/', $time) !== 1) {
                throw new RuntimeException('Vaqt formati noto‘g‘ri');
            }
        }

        return [
            'openingTime' => $openingTime !== '' ? $openingTime : '09:00',
            'closingTime' => $closingTime !== '' ? $closingTime : '19:00',
            'breakStartTime' => $breakStartTime,
            'breakEndTime' => $breakEndTime,
            'closedWeekdays' => $closedWeekdays === [] ? [7] : $closedWeekdays,
        ];
    }

    private function resolveWorkshopImage(Request $request, ?array $currentWorkshop): string
    {
        $currentImageUrl = trim((string) ($currentWorkshop['imageUrl'] ?? ''));

        if ($request->boolean('removeImage')) {
            $this->imageStorage->deleteByUrl($currentImageUrl);

            return '';
        }

        $uploadedImage = $request->file('imageFile');
        if ($uploadedImage !== null) {
            return $this->imageStorage->storeUploadedImage($uploadedImage, $currentImageUrl);
        }

        $imageUrl = trim((string) $request->input('imageUrl'));
        if ($imageUrl === '') {
            return $currentImageUrl;
        }

        return $this->imageStorage->normalizeStoredUrl($imageUrl);
    }

    public function sendTelegramTest(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        $workshop = $this->repository->workshopById($id);
        if (! $workshop) {
            return redirect()->back()->with('error', 'Ustaxona topilmadi');
        }

        try {
            $this->notifications->sendTestNotification($workshop);
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Telegram test xabari yuborildi');
    }

    private function parseServicesText(string $raw): array
    {
        $items = [];
        $lines = preg_split('/\r\n|\r|\n/', trim($raw));

        foreach ($lines as $line) {
            $line = trim((string) $line);
            if ($line === '') {
                continue;
            }

            $parts = array_map('trim', explode('|', $line));
            $hasExplicitId = count($parts) >= 5;
            $id = $hasExplicitId ? ($parts[0] ?? '') : '';
            $name = $hasExplicitId ? ($parts[1] ?? '') : ($parts[0] ?? '');
            if ($name === '') {
                continue;
            }

            $items[] = [
                'id' => trim($id) !== ''
                    ? trim($id)
                    : 'srv-'.now()->format('Uu').'-'.random_int(1000, 9999),
                'name' => $name,
                'price' => isset($parts[$hasExplicitId ? 2 : 1])
                    ? (Money::parseStoredAmount((string) $parts[$hasExplicitId ? 2 : 1]) ?? 0)
                    : 0,
                'durationMinutes' => isset($parts[$hasExplicitId ? 3 : 2]) ? max(15, (int) $parts[$hasExplicitId ? 3 : 2]) : 30,
                'prepaymentPercent' => isset($parts[$hasExplicitId ? 4 : 3]) ? max(0, min(100, (int) $parts[$hasExplicitId ? 4 : 3])) : 0,
            ];
        }

        return $items;
    }

    private function servicesText(array $services): string
    {
        $lines = array_map(
            fn (array $service): string => implode('|', [
                $service['id'] ?? '',
                $service['name'] ?? '',
                Money::inputValue((int) ($service['price'] ?? 0)),
                $service['durationMinutes'] ?? 30,
                $service['prepaymentPercent'] ?? 0,
            ]),
            $services
        );

        return e(implode("\n", $lines));
    }

    private function isAdmin(Request $request): bool
    {
        return (bool) $request->session()->get('ustatop_admin');
    }

    private function yandexMapsApiKey(): string
    {
        return trim((string) config('services.yandex_maps.js_api_key', ''));
    }
}
