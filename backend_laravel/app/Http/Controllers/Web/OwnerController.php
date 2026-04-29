<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\Money;
use App\Support\UstaTop\TelegramBotService;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopImageStorage;
use App\Support\UstaTop\WorkshopNotificationsService;
use App\Support\UstaTop\VehiclePricingExcelService;
use Illuminate\Http\Request;
use RuntimeException;

class OwnerController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly TelegramBotService $telegramBot,
        private readonly WorkshopNotificationsService $notifications,
        private readonly WorkshopImageStorage $imageStorage,
        private readonly VehiclePricingExcelService $vehiclePricingExcel,
    ) {
    }

    public function entry()
    {
        return redirect('/owner/bookings');
    }

    public function loginPage()
    {
        return view('ustatop.owner.login', [
            'title' => 'Owner login',
            'workshops' => $this->repository->listWorkshops(),
        ]);
    }

    public function login(Request $request)
    {
        $workshop = $this->repository->workshopByOwnerAccess(
            (string) $request->input('workshopId'),
            (string) $request->input('accessCode')
        );

        if (! $workshop) {
            return redirect('/owner/login')->with('error', 'Ustaxona yoki access code noto‘g‘ri');
        }

        $request->session()->put('ustatop_owner_workshop_id', $workshop['id']);

        return redirect('/owner/bookings');
    }

    public function logout(Request $request)
    {
        $request->session()->forget('ustatop_owner_workshop_id');

        return redirect('/owner/login');
    }

    public function bookingsPage(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }
        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }
        $bookings = $this->repository->bookingsForWorkshop($workshopId);
        $reviews = array_values(array_filter(
            $this->repository->listAdminReviews(),
            fn (array $review): bool => ($review['workshopId'] ?? '') === $workshopId
        ));
        usort($reviews, function (array $a, array $b): int {
            $aHasReply = trim((string) ($a['ownerReply'] ?? '')) !== '';
            $bHasReply = trim((string) ($b['ownerReply'] ?? '')) !== '';
            if ($aHasReply !== $bHasReply) {
                return $aHasReply <=> $bHasReply;
            }

            return strcmp((string) ($b['createdAt'] ?? ''), (string) ($a['createdAt'] ?? ''));
        });

        $schedule = $workshop['schedule'] ?? [];
        $closedWeekdays = array_map('intval', $schedule['closedWeekdays'] ?? []);
        $weekdayOptions = [
            1 => 'Dushanba',
            2 => 'Seshanba',
            3 => 'Chorshanba',
            4 => 'Payshanba',
            5 => 'Juma',
            6 => 'Shanba',
            7 => 'Yakshanba',
        ];
        $pricingRuleCount = count(array_values($workshop['vehiclePricingRules'] ?? []));

        $bookings = collect($bookings)->map(function (array $booking): array {
            $booking['priceLabel'] = Money::formatUzs((int) ($booking['price'] ?? 0));
            $booking['prepaymentLabel'] = Money::formatUzs((int) ($booking['prepaymentAmount'] ?? 0));

            return $booking;
        })->values()->all();

        $services = collect($workshop['services'] ?? [])->map(function (array $service): array {
            $service['priceInput'] = Money::inputValue((int) ($service['price'] ?? 0));

            return $service;
        })->values()->all();

        return view('ustatop.owner.bookings', [
            'title' => 'Owner bookings',
            'workshop' => $workshop,
            'bookings' => $bookings,
            'reviews' => $reviews,
            'services' => $services,
            'schedule' => $schedule,
            'closedWeekdays' => $closedWeekdays,
            'weekdayOptions' => $weekdayOptions,
            'pricingRuleCount' => $pricingRuleCount,
            'telegramConfigured' => $this->telegramBot->isConfigured(),
            'panelYandexMapsApiKey' => $this->yandexMapsApiKey(),
            'workshopRouteUrl' => $this->workshopRouteUrl($workshop),
        ]);
    }

    public function updateStatus(Request $request, string $id)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }
        $booking = collect($this->repository->bookingsForWorkshop($workshopId))
            ->first(fn (array $item): bool => ($item['id'] ?? '') === $id);
        if (! $booking) {
            return redirect()->back()->with('error', 'Zakaz topilmadi');
        }

        try {
            $updated = $this->repository->updateBookingStatus(
                $id,
                (string) $request->input('bookingStatus'),
                [
                    'scheduledAt' => (string) $request->input('scheduledAt'),
                    'cancelReasonId' => (string) $request->input('cancellationReasonId'),
                    'actorRole' => 'owner_panel',
                ]
            );
            if ($workshop = $this->repository->workshopById($workshopId)) {
                try {
                    $this->notifications->sendBookingStatusNotification($workshop, $updated, 'owner_panel');
                } catch (\Throwable $error) {
                    report($error);
                }
            }
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Zakaz holati yangilandi');
    }

    public function updateService(Request $request, string $id)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        $services = array_map(function (array $service) use ($id, $request): array {
            if (($service['id'] ?? '') !== $id) {
                return $service;
            }

            $service['price'] = Money::parseStoredAmount((string) $request->input(
                'price',
                Money::inputValue((int) ($service['price'] ?? 0))
            )) ?? (int) ($service['price'] ?? 0);
            $service['durationMinutes'] = max(15, (int) $request->input('durationMinutes', $service['durationMinutes'] ?? 30));
            $service['prepaymentPercent'] = max(0, min(100, (int) $request->input('prepaymentPercent', $service['prepaymentPercent'] ?? 0)));

            return $service;
        }, $workshop['services'] ?? []);

        try {
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'services' => $services,
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Xizmat yangilandi');
    }

    public function replyReview(Request $request, string $id)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $review = collect($this->repository->listAdminReviews())
            ->first(fn (array $item): bool => ($item['id'] ?? '') === $id && ($item['workshopId'] ?? '') === $workshopId);
        if (! $review) {
            return redirect()->back()->with('error', 'Sharh topilmadi');
        }

        try {
            $this->repository->replyReview($id, (string) $request->input('reply'), 'owner_panel');
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Sharhga javob saqlandi');
    }

    public function generateTelegramLinkCode(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'telegramLinkCode' => 'UT-'.strtoupper(substr(bin2hex(random_bytes(4)), 0, 8)),
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Telegram bog‘lash kodi yaratildi');
    }

    public function checkTelegramLink(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        if (! $this->telegramBot->isConfigured()) {
            return redirect()->back()->with('error', 'Telegram bot token sozlanmagan');
        }

        $code = trim((string) ($workshop['telegramLinkCode'] ?? ''));
        if ($code === '') {
            return redirect()->back()->with('error', 'Avval bog‘lash kodini yarating');
        }

        try {
            $match = collect($this->telegramBot->getUpdates())
                ->map(function (array $update): ?array {
                    $message = $update['message'] ?? null;
                    if (! is_array($message)) {
                        return null;
                    }

                    return [
                        'text' => trim((string) ($message['text'] ?? '')),
                        'chatId' => (string) (($message['chat']['id'] ?? '')),
                        'chatLabel' => trim((string) (($message['chat']['title'] ?? $message['chat']['username'] ?? $message['chat']['first_name'] ?? ''))),
                    ];
                })
                ->first(fn (?array $item): bool => is_array($item) && $item['text'] === '/start '.$code);

            if (! is_array($match) || trim((string) ($match['chatId'] ?? '')) === '') {
                return redirect()->back()->with('error', 'Botda hali bu kod bilan xabar topilmadi');
            }

            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'telegramChatId' => trim((string) $match['chatId']),
                'telegramChatLabel' => trim((string) $match['chatLabel']),
                'telegramLinkCode' => '',
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Telegram muvaffaqiyatli ulandi');
    }

    public function disconnectTelegram(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'telegramChatId' => '',
                'telegramChatLabel' => '',
                'telegramLinkCode' => '',
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Telegram ulanishi uzildi');
    }

    public function downloadVehiclePricingTemplate(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
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

    public function importVehiclePricing(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $file = $request->file('pricingFile');
            if ($file === null) {
                throw new RuntimeException('Excel fayl tanlanmagan');
            }

            $rules = $this->vehiclePricingExcel->parseWorkbook($file, $workshop);
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'vehiclePricingRules' => $rules,
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Excel narxlari yuklandi');
    }

    public function updateSchedule(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $schedule = $this->parseSchedule($request);
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'schedule' => $schedule,
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Ish jadvali saqlandi');
    }

    public function updateWorkshopImage(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'imageUrl' => $this->resolveWorkshopImage($request, $workshop),
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Ustaxona rasmi yangilandi');
    }

    public function updateWorkshopLocation(Request $request)
    {
        $workshopId = $this->ownerWorkshopId($request);
        if ($workshopId === '') {
            return redirect('/owner/login');
        }

        $workshop = $this->repository->workshopById($workshopId);
        if (! $workshop) {
            return redirect('/owner/login');
        }

        try {
            $latitude = trim((string) $request->input('latitude'));
            $longitude = trim((string) $request->input('longitude'));

            if (($latitude === '') xor ($longitude === '')) {
                throw new RuntimeException('Latitude va longitude ikkalasi ham to‘ldirilishi kerak');
            }

            if ($latitude !== '' && (! is_numeric($latitude) || (float) $latitude < -90 || (float) $latitude > 90)) {
                throw new RuntimeException('Latitude -90 va 90 oralig‘ida bo‘lishi kerak');
            }

            if ($longitude !== '' && (! is_numeric($longitude) || (float) $longitude < -180 || (float) $longitude > 180)) {
                throw new RuntimeException('Longitude -180 va 180 oralig‘ida bo‘lishi kerak');
            }

            $this->repository->updateWorkshop($workshopId, $this->workshopPayload($workshop, [
                'address' => trim((string) $request->input('address', (string) ($workshop['address'] ?? ''))),
                'latitude' => $latitude,
                'longitude' => $longitude,
            ]));
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Lokatsiya yangilandi');
    }

    private function ownerWorkshopId(Request $request): string
    {
        return (string) $request->session()->get('ustatop_owner_workshop_id', '');
    }

    private function workshopPayload(array $workshop, array $overrides = []): array
    {
        return array_merge([
            'name' => $workshop['name'] ?? '',
            'master' => $workshop['master'] ?? '',
            'address' => $workshop['address'] ?? '',
            'description' => $workshop['description'] ?? '',
            'badge' => $workshop['badge'] ?? '',
            'imageUrl' => $workshop['imageUrl'] ?? '',
            'latitude' => $workshop['latitude'] ?? '',
            'longitude' => $workshop['longitude'] ?? '',
            'startingPrice' => $workshop['startingPrice'] ?? 0,
            'ownerAccessCode' => $workshop['ownerAccessCode'] ?? '',
            'isOpen' => $workshop['isOpen'] ?? true,
            'services' => $workshop['services'] ?? [],
            'schedule' => $workshop['schedule'] ?? [],
            'vehiclePricingRules' => $workshop['vehiclePricingRules'] ?? [],
            'telegramChatId' => $workshop['telegramChatId'] ?? '',
            'telegramChatLabel' => $workshop['telegramChatLabel'] ?? '',
            'telegramLinkCode' => $workshop['telegramLinkCode'] ?? '',
        ], $overrides);
    }

    private function resolveWorkshopImage(Request $request, array $workshop): string
    {
        $currentImageUrl = trim((string) ($workshop['imageUrl'] ?? ''));

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

    private function parseSchedule(Request $request): array
    {
        $openingTime = trim((string) $request->input('openingTime', '09:00'));
        $closingTime = trim((string) $request->input('closingTime', '19:00'));
        $breakStartTime = trim((string) $request->input('breakStartTime', '13:00'));
        $breakEndTime = trim((string) $request->input('breakEndTime', '14:00'));
        $closedWeekdays = array_values(array_unique(array_filter(array_map(
            static fn (mixed $value): int => (int) $value,
            (array) $request->input('closedWeekdays', [7])
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

    private function yandexMapsApiKey(): string
    {
        return trim((string) config('services.yandex_maps.js_api_key', ''));
    }

    private function workshopRouteUrl(array $workshop): ?string
    {
        if (! isset($workshop['latitude'], $workshop['longitude'])) {
            return null;
        }

        return 'https://yandex.com/maps/?rtext=~'.(float) $workshop['latitude'].','.(float) $workshop['longitude'].'&rtt=auto';
    }
}
