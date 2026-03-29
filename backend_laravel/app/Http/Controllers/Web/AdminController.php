<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\AdminAnalyticsService;
use App\Support\UstaTop\Money;
use App\Support\UstaTop\TelegramBotService;
use App\Support\UstaTop\UstaTopRepository;
use App\Support\UstaTop\WorkshopImageStorage;
use App\Support\UstaTop\WorkshopNotificationsService;
use Illuminate\Http\Request;
use Illuminate\Support\HtmlString;
use RuntimeException;

class AdminController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
        private readonly AdminAnalyticsService $analytics,
        private readonly TelegramBotService $telegramBot,
        private readonly WorkshopNotificationsService $notifications,
        private readonly WorkshopImageStorage $imageStorage,
    ) {
    }

    public function entry()
    {
        return redirect('/admin/workshops');
    }

    public function loginPage()
    {
        return response($this->page('Admin login', '
            <h1>Admin login</h1>
            <form method="post" action="/admin/login">
                '.$this->csrf().'
                <label>Username</label>
                <input type="text" name="username" value="'.e(config('ustatop.admin_username')).'">
                <label>Password</label>
                <input type="password" name="password" value="">
                <button type="submit">Kirish</button>
            </form>
        '));
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

        $items = collect($this->repository->listWorkshops())
            ->map(function (array $workshop): string {
                $imagePreview = $this->workshopImagePreview($workshop, 'Joriy rasm');
                return '
                    <article class="card">
                        <div class="card-head">
                            <div>
                                <h2>'.e($workshop['name']).'</h2>
                                <p class="muted">ID: '.e((string) $workshop['id']).' · Access code: '.e((string) ($workshop['ownerAccessCode'] ?? '')).'</p>
                            </div>
                            <a class="ghost-link" href="/admin/bookings?workshop='.urlencode((string) $workshop['id']).'">Zakazlar</a>
                        </div>
                        <form method="post" action="/admin/workshops/'.urlencode((string) $workshop['id']).'/update" enctype="multipart/form-data">
                            '.$this->csrf().'
                            '.$imagePreview.'
                            <label>Nomi</label>
                            <input type="text" name="name" value="'.e((string) $workshop['name']).'">
                            <label>Usta</label>
                            <input type="text" name="master" value="'.e((string) ($workshop['master'] ?? '')).'">
                            <label>Manzil</label>
                            <input type="text" name="address" value="'.e((string) ($workshop['address'] ?? '')).'">
                            <label>Tavsif</label>
                            <textarea name="description">'.e((string) ($workshop['description'] ?? '')).'</textarea>
                            <label>Badge</label>
                            <input type="text" name="badge" value="'.e((string) ($workshop['badge'] ?? '')).'">
                            <label>Rasm URL</label>
                            <input type="url" name="imageUrl" value="'.e((string) ($workshop['imageUrl'] ?? '')).'" placeholder="https://example.com/ustaxona.jpg">
                            <label>Yoki rasm fayli</label>
                            <input type="file" name="imageFile" accept="image/*">
                            <label class="checkbox-row"><input type="checkbox" name="removeImage" value="1"> Rasmni olib tashlash</label>
                            <div class="grid-two">
                                <div>
                                    <label>Latitude</label>
                                    <input type="number" step="0.000001" name="latitude" value="'.e((string) ($workshop['latitude'] ?? '')).'">
                                </div>
                                <div>
                                    <label>Longitude</label>
                                    <input type="number" step="0.000001" name="longitude" value="'.e((string) ($workshop['longitude'] ?? '')).'">
                                </div>
                            </div>
                            <div class="grid-two">
                                <div>
                                    <label>Starting price</label>
                                    <input type="number" min="0" name="startingPrice" value="'.e(Money::inputValue((int) ($workshop['startingPrice'] ?? 0))).'">
                                </div>
                                <div>
                                    <label>Owner access code</label>
                                    <input type="text" name="ownerAccessCode" value="'.e((string) ($workshop['ownerAccessCode'] ?? '')).'">
                                </div>
                            </div>
                            <label>Telegram chat ID</label>
                            <input type="text" name="telegramChatId" value="'.e((string) ($workshop['telegramChatId'] ?? '')).'" placeholder="-1001234567890">
                            <label class="checkbox-row"><input type="checkbox" name="isOpen" value="1" '.(($workshop['isOpen'] ?? false) ? 'checked' : '').'> Ustaxona ochiq</label>
                            <label>Xizmatlar</label>
                            <textarea name="servicesText" rows="5" placeholder="srv-1|Kompyuter diagnostika|120000|35|0">'.$this->servicesText($workshop['services'] ?? []).'</textarea>
                            <p class="hint">Har qatorda: serviceId | nomi | narxi(UZS) | davomiyligi(minut) | avans foizi</p>
                            <div class="actions">
                                <button type="submit">Saqlash</button>
                            </div>
                        </form>
                        <form method="post" action="/admin/workshops/'.urlencode((string) $workshop['id']).'/telegram/test">
                            '.$this->csrf().'
                            <button type="submit">Telegram test</button>
                        </form>
                        <form method="post" action="/admin/workshops/'.urlencode((string) $workshop['id']).'/delete" onsubmit="return confirm(\'Rostdan ham o‘chirasizmi?\')">
                            '.$this->csrf().'
                            <button class="danger" type="submit">O‘chirish</button>
                        </form>
                    </article>
                ';
            })
            ->implode('');

        return response($this->page('Admin workshops', '
            '.$this->nav().'
            <h1>Ustaxonalar</h1>
            <article class="card">
                <h2>Yangi ustaxona</h2>
                <form method="post" action="/admin/workshops" enctype="multipart/form-data">
                    '.$this->csrf().'
                    <label>Nomi</label>
                    <input type="text" name="name" value="">
                    <label>Usta</label>
                    <input type="text" name="master" value="">
                    <label>Manzil</label>
                    <input type="text" name="address" value="">
                    <label>Tavsif</label>
                    <textarea name="description"></textarea>
                    <label>Badge</label>
                    <input type="text" name="badge" value="">
                    <label>Rasm URL</label>
                    <input type="url" name="imageUrl" value="" placeholder="https://example.com/ustaxona.jpg">
                    <label>Yoki rasm fayli</label>
                    <input type="file" name="imageFile" accept="image/*">
                    <div class="grid-two">
                        <div>
                            <label>Latitude</label>
                            <input type="number" step="0.000001" name="latitude" value="">
                        </div>
                        <div>
                            <label>Longitude</label>
                            <input type="number" step="0.000001" name="longitude" value="">
                        </div>
                    </div>
                    <div class="grid-two">
                        <div>
                            <label>Starting price</label>
                            <input type="number" min="0" name="startingPrice" value="100000">
                        </div>
                        <div>
                            <label>Owner access code</label>
                            <input type="text" name="ownerAccessCode" value="">
                        </div>
                    </div>
                    <label>Telegram chat ID</label>
                    <input type="text" name="telegramChatId" value="" placeholder="-1001234567890">
                    <label class="checkbox-row"><input type="checkbox" name="isOpen" value="1" checked> Ustaxona ochiq</label>
                    <label>Xizmatlar</label>
                    <textarea name="servicesText" rows="5" placeholder="srv-1|Kompyuter diagnostika|120000|35|0"></textarea>
                    <p class="hint">Har qatorda: serviceId | nomi | narxi(UZS) | davomiyligi(minut) | avans foizi</p>
                    <button type="submit">Yaratish</button>
                </form>
            </article>
            '.$items.'
        '));
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

        $items = collect($bookings)->map(function (array $booking): string {
            return '
                <article class="card">
                    <h2>'.e((string) $booking['workshopName']).' · '.e((string) $booking['serviceName']).'</h2>
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
                    <form method="post" action="/admin/bookings/'.urlencode((string) $booking['id']).'/status">
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

        return response($this->page('Admin bookings', '
            '.$this->nav().'
            <h1>Zakazlar</h1>
            '.$items.'
        '));
    }

    public function reviewsPage(Request $request)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        return redirect('/admin/workshops')->with('success', 'Sharhlar endi owner panelda ko‘rinadi');
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
        $workshopOptions = collect($filters['workshops'] ?? [])
            ->map(function (array $workshop) use ($filters): string {
                $selected = ((string) ($filters['workshopId'] ?? '')) === (string) ($workshop['id'] ?? '') ? 'selected' : '';

                return '<option value="'.e((string) ($workshop['id'] ?? '')).'" '.$selected.'>'.e((string) ($workshop['name'] ?? 'Ustaxona')).'</option>';
            })
            ->implode('');

        $query = http_build_query([
            'range' => $filters['range'] ?? '7d',
            'workshop' => $filters['workshopId'] ?? '',
            'from' => $filters['from'] ?? '',
            'to' => $filters['to'] ?? '',
        ]);

        return response($this->page('Admin analytics', '
            '.$this->nav().'
            <div class="hero">
                <div>
                    <h1>Statistika</h1>
                    <p class="muted">Admin uchun booking, tushum, sharh va ustaxona kesimlari bir joyda.</p>
                </div>
                <a class="ghost-link" href="/admin/analytics/export.csv?'.$query.'">CSV yuklab olish</a>
            </div>
            <article class="card">
                <form method="get" action="/admin/analytics" class="filter-grid">
                    <div>
                        <label>Davr</label>
                        <select name="range">
                            <option value="today" '.(($filters['range'] ?? '') === 'today' ? 'selected' : '').'>Bugun</option>
                            <option value="7d" '.(($filters['range'] ?? '') === '7d' ? 'selected' : '').'>7 kun</option>
                            <option value="30d" '.(($filters['range'] ?? '') === '30d' ? 'selected' : '').'>30 kun</option>
                            <option value="custom" '.(($filters['range'] ?? '') === 'custom' ? 'selected' : '').'>Custom</option>
                        </select>
                    </div>
                    <div>
                        <label>Ustaxona</label>
                        <select name="workshop">
                            <option value="">Barchasi</option>
                            '.$workshopOptions.'
                        </select>
                    </div>
                    <div>
                        <label>Dan</label>
                        <input type="date" name="from" value="'.e((string) ($filters['from'] ?? '')).'">
                    </div>
                    <div>
                        <label>Gacha</label>
                        <input type="date" name="to" value="'.e((string) ($filters['to'] ?? '')).'">
                    </div>
                    <div class="actions">
                        <button type="submit">Qo‘llash</button>
                    </div>
                </form>
                <p class="hint">Faol davr: '.e((string) ($dashboard['periodLabel'] ?? '')).'</p>
            </article>
            <section class="metrics-grid">
                '.$this->metricsHtml($dashboard['metrics'] ?? []).'
            </section>
            <section class="section-grid">
                '.$this->chartCardHtml('Kunlik zakazlar', 'Rejalashtirilgan bronlar va yangi yaratilgan zakazlar', $dashboard['bookingsChart'] ?? [], false).'
                '.$this->chartCardHtml('Kunlik tushum', 'Bekor qilinmagan bronlar summasi', $dashboard['revenueChart'] ?? [], true).'
            </section>
            <section class="section-grid">
                '.$this->summaryListHtml('Status taqsimoti', 'Holatlar bo‘yicha kesim', $dashboard['statusBreakdown'] ?? [], false).'
                '.$this->metricsCardHtml('Sharh statistikasi', 'Foydalanuvchi fikr-mulohazalari', $dashboard['reviewMetrics'] ?? []).'
            </section>
            <section class="section-grid">
                '.$this->summaryListHtml('Top ustaxonalar', 'Eng ko‘p bron tushgan nuqtalar', $dashboard['topWorkshops'] ?? [], true).'
                '.$this->summaryListHtml('Top xizmatlar', 'Qaysi xizmatlarga talab kuchli', $dashboard['topServices'] ?? [], true).'
            </section>
            <section class="section-grid">
                '.$this->summaryListHtml('Top mashinalar', 'Eng ko‘p kelgan model va brendlar', $dashboard['topVehicles'] ?? [], true).'
                '.$this->summaryListHtml('Bekor qilish sabablari', 'Qaysi sabablar ko‘proq uchrayapti', $dashboard['cancelReasons'] ?? [], false).'
            </section>
            <section class="section-grid single">
                '.$this->summaryListHtml('Reytinglar', 'Bahosi yuqori ustaxonalar', $dashboard['ratings'] ?? [], false).'
            </section>
        '));
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

    private function workshopImagePreview(array $workshop, string $title): string
    {
        $imageUrl = trim((string) ($workshop['imageUrl'] ?? ''));
        if ($imageUrl === '') {
            return '
                <div class="image-preview empty">
                    <div class="image-placeholder">Rasm yo‘q</div>
                    <div>
                        <strong>'.e($title).'</strong>
                        <p class="muted">Public URL kiriting yoki fayl yuklang.</p>
                    </div>
                </div>
            ';
        }

        return '
            <div class="image-preview">
                <img src="'.e($imageUrl).'" alt="'.e((string) ($workshop['name'] ?? 'Ustaxona')).'">
                <div>
                    <strong>'.e($title).'</strong>
                    <p class="muted">'.e($imageUrl).'</p>
                </div>
            </div>
        ';
    }

    private function isAdmin(Request $request): bool
    {
        return (bool) $request->session()->get('ustatop_admin');
    }

    private function nav(): string
    {
        return '
            <div class="nav">
                <a href="/admin/workshops">Ustaxonalar</a>
                <a href="/admin/bookings">Zakazlar</a>
                <a href="/admin/analytics">Statistika</a>
                <span class="muted">Telegram: '.e($this->telegramBot->isConfigured() ? 'yoqilgan' : 'o‘chiq').'</span>
                <form method="post" action="/admin/logout">'.$this->csrf().'<button type="submit">Chiqish</button></form>
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
                body{font-family:ui-sans-serif,system-ui,sans-serif;max-width:1180px;margin:0 auto;padding:24px;background:#f6f4ef;color:#1c1c1c}
                .nav{display:flex;gap:12px;align-items:center;margin-bottom:20px;flex-wrap:wrap}
                .nav form{margin:0}
                .card{background:#fff;border:1px solid #ddd;border-radius:16px;padding:16px;margin-bottom:16px}
                .card-head{display:flex;justify-content:space-between;gap:16px;align-items:flex-start}
                .hero{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;margin-bottom:16px;flex-wrap:wrap}
                form{display:grid;gap:10px}
                textarea{min-height:92px}
                input,select,textarea,button{padding:10px;border-radius:10px;border:1px solid #cfcfcf;font:inherit}
                button{cursor:pointer}
                .flash{padding:12px;border-radius:12px;margin-bottom:16px}
                .flash.error{background:#fee2e2}
                .flash.success{background:#dcfce7}
                .grid-two{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
                .filter-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px;align-items:end}
                .metrics-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px;margin-bottom:16px}
                .metric-card{background:#fff;border:1px solid #ddd;border-radius:16px;padding:16px}
                .metric-label{font-size:13px;color:#6b6b6b;text-transform:uppercase;letter-spacing:.04em}
                .metric-value{font-size:28px;font-weight:800;margin:8px 0 6px}
                .metric-hint{font-size:13px;color:#6b6b6b}
                .section-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px;margin-bottom:16px}
                .section-grid.single{grid-template-columns:1fr}
                .chart-list,.summary-list{display:grid;gap:12px}
                .chart-row,.summary-row{display:grid;gap:8px}
                .chart-head,.summary-head{display:flex;justify-content:space-between;gap:12px;align-items:center}
                .bar-track{height:10px;border-radius:999px;background:#ece7dc;overflow:hidden}
                .bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#0f766e,#14b8a6)}
                .summary-value{font-weight:700}
                .actions{display:flex;gap:10px;flex-wrap:wrap}
                .hint,.muted{color:#666;font-size:14px}
                .checkbox-row{display:flex;gap:8px;align-items:center}
                .ghost-link{padding:10px 12px;border:1px solid #ddd;border-radius:10px;text-decoration:none}
                .danger{background:#8b1e1e;color:#fff;border-color:#8b1e1e}
                .image-preview{display:flex;gap:14px;align-items:center;padding:12px;border:1px dashed #d6d0c5;border-radius:14px;background:#fcfaf6;margin-bottom:14px}
                .image-preview img,.image-placeholder{width:88px;height:88px;border-radius:18px;object-fit:cover;background:#ece6dc;display:flex;align-items:center;justify-content:center;color:#8a6f3a;font-weight:700}
                .image-preview.empty{background:#faf7f1}
                @media (max-width:960px){.metrics-grid,.section-grid,.filter-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
                @media (max-width:720px){.grid-two,.metrics-grid,.section-grid,.filter-grid{grid-template-columns:1fr}}
            </style>
        </head>
        <body>'.$flash.$body.'</body>
        </html>';
    }

    private function metricsHtml(array $metrics): string
    {
        return collect($metrics)->map(function (array $metric): string {
            return '
                <article class="metric-card">
                    <div class="metric-label">'.e((string) ($metric['label'] ?? '')).'</div>
                    <div class="metric-value">'.e((string) ($metric['value'] ?? '0')).'</div>
                    <div class="metric-hint">'.e((string) ($metric['hint'] ?? '')).'</div>
                </article>
            ';
        })->implode('');
    }

    private function metricsCardHtml(string $title, string $subtitle, array $metrics): string
    {
        return '
            <article class="card">
                <h2>'.e($title).'</h2>
                <p class="muted">'.e($subtitle).'</p>
                <div class="metrics-grid">
                    '.$this->metricsHtml($metrics).'
                </div>
            </article>
        ';
    }

    private function chartCardHtml(string $title, string $subtitle, array $items, bool $currencyMeta): string
    {
        $maxValue = max(array_map(
            fn (array $item): int => max(0, (int) ($item['value'] ?? 0)),
            $items === [] ? [['value' => 0]] : $items
        ));

        $rows = collect($items)->map(function (array $item) use ($maxValue, $currencyMeta): string {
            $value = max(0, (int) ($item['value'] ?? 0));
            $percent = $maxValue > 0 ? (int) round(($value / $maxValue) * 100) : 0;
            $meta = (string) ($item['meta'] ?? '');

            return '
                <div class="chart-row">
                    <div class="chart-head">
                        <strong>'.e((string) ($item['label'] ?? '')).'</strong>
                        <span class="summary-value">'.e($currencyMeta ? Money::formatUzs($value) : (string) $value).'</span>
                    </div>
                    <div class="bar-track"><div class="bar-fill" style="width: '.$percent.'%"></div></div>
                    <div class="muted">'.e($meta).'</div>
                </div>
            ';
        })->implode('');

        return '
            <article class="card">
                <h2>'.e($title).'</h2>
                <p class="muted">'.e($subtitle).'</p>
                <div class="chart-list">'.$rows.'</div>
            </article>
        ';
    }

    private function summaryListHtml(string $title, string $subtitle, array $items, bool $showRevenue): string
    {
        $maxValue = max(array_map(
            fn (array $item): int|float => max(0, (float) ($item['value'] ?? 0)),
            $items === [] ? [['value' => 0]] : $items
        ));

        $rows = collect($items)->map(function (array $item) use ($maxValue, $showRevenue): string {
            $value = (float) ($item['value'] ?? 0);
            $percent = $maxValue > 0 ? (int) round(($value / $maxValue) * 100) : 0;
            $meta = trim((string) ($item['meta'] ?? ''));
            $revenue = $showRevenue && array_key_exists('revenue', $item)
                ? Money::formatUzs((int) ($item['revenue'] ?? 0))
                : '';

            return '
                <div class="summary-row">
                    <div class="summary-head">
                        <strong>'.e((string) ($item['label'] ?? '')).'</strong>
                        <span class="summary-value">'.e(is_float($value) && floor($value) !== $value ? number_format($value, 1, '.', ' ') : (string) ((int) $value === $value ? (int) $value : $value)).'</span>
                    </div>
                    <div class="bar-track"><div class="bar-fill" style="width: '.$percent.'%"></div></div>
                    <div class="muted">'.e(trim($meta.' '.($revenue !== '' ? '· '.$revenue : ''))).'</div>
                </div>
            ';
        })->implode('');

        return '
            <article class="card">
                <h2>'.e($title).'</h2>
                <p class="muted">'.e($subtitle).'</p>
                <div class="summary-list">'.$rows.'</div>
            </article>
        ';
    }

    private function csrf(): HtmlString
    {
        return new HtmlString('<input type="hidden" name="_token" value="'.csrf_token().'">');
    }
}
