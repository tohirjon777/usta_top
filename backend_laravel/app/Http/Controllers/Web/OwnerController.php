<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\Money;
use App\Support\UstaTop\TelegramBotService;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopImageStorage;
use App\Support\UstaTop\WorkshopNotificationsService;
use Illuminate\Http\Request;
use Illuminate\Support\HtmlString;
use RuntimeException;

class OwnerController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly TelegramBotService $telegramBot,
        private readonly WorkshopNotificationsService $notifications,
        private readonly WorkshopImageStorage $imageStorage,
    ) {
    }

    public function entry()
    {
        return redirect('/owner/bookings');
    }

    public function loginPage()
    {
        $options = collect($this->repository->listWorkshops())
            ->map(fn (array $workshop): string => '<option value="'.e((string) $workshop['id']).'">'.e((string) $workshop['name']).'</option>')
            ->implode('');

        return response($this->page('Owner login', '
            <h1>Owner login</h1>
            <form method="post" action="/owner/login">
                '.$this->csrf().'
                <label>Ustaxona</label>
                <select name="workshopId">'.$options.'</select>
                <label>Access code</label>
                <input type="password" name="accessCode">
                <button type="submit">Kirish</button>
            </form>
        '));
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
        $bookings = $this->repository->bookingsForWorkshop($workshopId);
        $reviews = array_values(array_filter(
            $this->repository->listAdminReviews(),
            fn (array $review): bool => ($review['workshopId'] ?? '') === $workshopId
        ));

        $items = collect($bookings)->map(function (array $booking): string {
            return '
                <article class="card">
                    <h2>'.e((string) $booking['serviceName']).'</h2>
                    <p><strong>Mijoz:</strong> '.e((string) $booking['customerName']).' ('.e((string) $booking['customerPhone']).')</p>
                    <p><strong>Mashina:</strong> '.e((string) ($booking['vehicleModel'] ?? '')).'</p>
                    <p><strong>Vaqt:</strong> '.e((string) $booking['dateTime']).'</p>
                    <p><strong>Status:</strong> '.e((string) $booking['status']).'</p>
                    <p><strong>Narx:</strong> '.e(Money::formatUzs((int) ($booking['price'] ?? 0))).'</p>
                    <p><strong>Avans:</strong> '.e(Money::formatUzs((int) ($booking['prepaymentAmount'] ?? 0))).'</p>
                    '.(($booking['acceptedAt'] ?? '') !== '' ? '<p><strong>Qabul qilingan vaqt:</strong> '.e((string) $booking['acceptedAt']).'</p>' : '').'
                    '.(($booking['previousDateTime'] ?? '') !== '' ? '<p><strong>Oldingi vaqt:</strong> '.e((string) $booking['previousDateTime']).'</p>' : '').'
                    '.(($booking['rescheduledByRole'] ?? '') !== '' ? '<p><strong>Ko‘chirdi:</strong> '.e((string) $booking['rescheduledByRole']).'</p>' : '').'
                    '.(($booking['rescheduledAt'] ?? '') !== '' ? '<p><strong>Ko‘chirilgan vaqt:</strong> '.e((string) $booking['rescheduledAt']).'</p>' : '').'
                    '.(($booking['completedAt'] ?? '') !== '' ? '<p><strong>Yakunlangan vaqt:</strong> '.e((string) $booking['completedAt']).'</p>' : '').'
                    '.(($booking['cancelledAt'] ?? '') !== '' ? '<p><strong>Bekor qilingan vaqt:</strong> '.e((string) $booking['cancelledAt']).'</p>' : '').'
                    '.(($booking['cancelReasonId'] ?? '') !== '' ? '<p><strong>Sabab:</strong> '.e((string) $booking['cancelReasonId']).'</p>' : '').'
                    <form method="post" action="/owner/bookings/'.urlencode((string) $booking['id']).'/status">
                        '.$this->csrf().'
                        <select name="bookingStatus">
                            <option value="accepted">Qabul qilindi</option>
                            <option value="completed">Yakunlandi</option>
                            <option value="cancelled">Bekor qilindi</option>
                            <option value="rescheduled">Ko‘chirildi</option>
                        </select>
                        <input type="datetime-local" name="scheduledAt">
                        <input type="text" name="cancellationReasonId" placeholder="workshop_busy">
                        <button type="submit">Saqlash</button>
                    </form>
                </article>
            ';
        })->implode('');

        $serviceCards = collect($workshop['services'] ?? [])->map(function (array $service): string {
            return '
                <article class="card">
                    <h2>'.e((string) $service['name']).'</h2>
                    <form method="post" action="/owner/services/'.urlencode((string) $service['id']).'/price">
                        '.$this->csrf().'
                        <div class="grid-two">
                            <div>
                                <label>Narx</label>
                                <input type="number" min="0" name="price" value="'.e(Money::inputValue((int) ($service['price'] ?? 0))).'">
                            </div>
                            <div>
                                <label>Davomiyligi (min)</label>
                                <input type="number" min="15" step="5" name="durationMinutes" value="'.e((string) ($service['durationMinutes'] ?? 30)).'">
                            </div>
                        </div>
                        <label>Avans foizi</label>
                        <input type="number" min="0" max="100" name="prepaymentPercent" value="'.e((string) ($service['prepaymentPercent'] ?? 0)).'">
                        <button type="submit">Yangilash</button>
                    </form>
                </article>
            ';
        })->implode('');

        $reviewCards = collect($reviews)->map(function (array $review): string {
            return '
                <article class="card">
                    <h2>'.e((string) ($review['serviceName'] ?? '')).'</h2>
                    <p><strong>Mijoz:</strong> '.e((string) ($review['customerName'] ?? '')).'</p>
                    <p><strong>Baho:</strong> '.e((string) ($review['rating'] ?? '')).'/5</p>
                    <p>'.nl2br(e((string) ($review['comment'] ?? ''))).'</p>
                    '.(trim((string) ($review['ownerReply'] ?? '')) !== '' ? '<p><strong>Javob:</strong> '.nl2br(e((string) ($review['ownerReply'] ?? ''))).'</p>' : '').'
                    <form method="post" action="/owner/reviews/'.urlencode((string) $review['id']).'/reply">
                        '.$this->csrf().'
                        <textarea name="reply" placeholder="Mijozga javob yozing"></textarea>
                        <button type="submit">Javob yuborish</button>
                    </form>
                </article>
            ';
        })->implode('');

        $telegramCard = '
            <article class="card">
                <h2>Telegram</h2>
                <p><strong>Bot holati:</strong> '.e($this->telegramBot->isConfigured() ? 'yoqilgan' : 'o‘chiq').'</p>
                <p><strong>Chat ID:</strong> '.e((string) (($workshop['telegramChatId'] ?? '') !== '' ? $workshop['telegramChatId'] : 'ulmagan')).'</p>
                '.(($workshop['telegramLinkCode'] ?? '') !== '' ? '<p><strong>Bog‘lash kodi:</strong> '.e((string) $workshop['telegramLinkCode']).'</p><p class="muted">Telegram botga `/start '.e((string) $workshop['telegramLinkCode']).'` yuboring.</p>' : '').'
                <div class="grid-two">
                    <form method="post" action="/owner/telegram/generate">
                        '.$this->csrf().'
                        <button type="submit">'.(($workshop['telegramLinkCode'] ?? '') !== '' ? 'Yangi kod yaratish' : 'Bog‘lash kodini yaratish').'</button>
                    </form>
                    <form method="post" action="/owner/telegram/check">
                        '.$this->csrf().'
                        <button type="submit">Tekshirish</button>
                    </form>
                </div>
                <form method="post" action="/owner/telegram/disconnect">
                    '.$this->csrf().'
                    <button type="submit">Telegramni uzish</button>
                </form>
            </article>
        ';

        $imageCard = '
            <article class="card">
                <h2>Ustaxona rasmi</h2>
                '.$this->workshopImagePreview($workshop).'
                <form method="post" action="/owner/workshop/image" enctype="multipart/form-data">
                    '.$this->csrf().'
                    <label>Rasm URL</label>
                    <input type="url" name="imageUrl" value="'.e((string) ($workshop['imageUrl'] ?? '')).'" placeholder="https://example.com/ustaxona.jpg">
                    <label>Yoki yangi rasm fayli</label>
                    <input type="file" name="imageFile" accept="image/*">
                    <label class="checkbox-row"><input type="checkbox" name="removeImage" value="1"> Rasmni olib tashlash</label>
                    <button type="submit">Rasmni saqlash</button>
                </form>
            </article>
        ';

        return response($this->page('Owner bookings', '
            <div class="nav">
                <strong>'.e((string) ($workshop['name'] ?? 'Ustaxona')).'</strong>
                <form method="post" action="/owner/logout">'.$this->csrf().'<button type="submit">Chiqish</button></form>
            </div>
            '.$imageCard.'
            '.$telegramCard.'
            <h1>Zakazlar</h1>
            '.$items.'
            <h1>Xizmatlar</h1>
            '.$serviceCards.'
            <h1>Sharhlar</h1>
            '.$reviewCards.'
        '));
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

    private function workshopImagePreview(array $workshop): string
    {
        $imageUrl = trim((string) ($workshop['imageUrl'] ?? ''));
        if ($imageUrl === '') {
            return '
                <div class="image-preview empty">
                    <div class="image-placeholder">Rasm yo‘q</div>
                    <div>
                        <strong>Joriy rasm</strong>
                        <p class="muted">Ustaxona uchun rasm URL kiriting yoki fayl yuklang.</p>
                    </div>
                </div>
            ';
        }

        return '
            <div class="image-preview">
                <img src="'.e($imageUrl).'" alt="'.e((string) ($workshop['name'] ?? 'Ustaxona')).'">
                <div>
                    <strong>Joriy rasm</strong>
                    <p class="muted">'.e($imageUrl).'</p>
                </div>
            </div>
        ';
    }

    private function page(string $title, string $body): string
    {
        $flash = '';
        if (session('error')) {
            $flash .= '<div class="flash error">'.e((string) session('error')).'</div>';
        }
        if (session('success')) {
            $flash .= '<div class="flash success">'.e((string) session('success')).'</div>';
        }

        return '<!doctype html>
        <html lang="uz">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>'.e($title).'</title>
            <style>
                body{font-family:ui-sans-serif,system-ui,sans-serif;max-width:1100px;margin:0 auto;padding:24px;background:#f6f4ef;color:#1c1c1c}
                .nav{display:flex;gap:12px;align-items:center;margin-bottom:20px;flex-wrap:wrap}
                .nav form{margin:0}
                .card{background:#fff;border:1px solid #ddd;border-radius:16px;padding:16px;margin-bottom:16px}
                form{display:grid;gap:10px}
                input,select,button,textarea{padding:10px;border-radius:10px;border:1px solid #cfcfcf;font:inherit}
                textarea{min-height:92px}
                button{cursor:pointer}
                .muted{color:#666;font-size:14px}
                .flash{padding:12px;border-radius:12px;margin-bottom:16px}
                .flash.error{background:#fee2e2}
                .flash.success{background:#dcfce7}
                .grid-two{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
                .image-preview{display:flex;gap:14px;align-items:center;padding:12px;border:1px dashed #d6d0c5;border-radius:14px;background:#fcfaf6;margin-bottom:14px}
                .image-preview img,.image-placeholder{width:88px;height:88px;border-radius:18px;object-fit:cover;background:#ece6dc;display:flex;align-items:center;justify-content:center;color:#8a6f3a;font-weight:700}
                .image-preview.empty{background:#faf7f1}
                @media (max-width:720px){.grid-two{grid-template-columns:1fr}}
            </style>
        </head>
        <body>'.$flash.$body.'</body>
        </html>';
    }

    private function csrf(): HtmlString
    {
        return new HtmlString('<input type="hidden" name="_token" value="'.csrf_token().'">');
    }
}
