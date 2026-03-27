<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use Illuminate\Support\HtmlString;
use RuntimeException;

class AdminController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
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
                $services = collect($workshop['services'] ?? [])
                    ->map(fn (array $service): string => '<li>'.e($service['name']).' - '.e((string) ($service['price'] ?? 0)).'</li>')
                    ->implode('');

                return '
                    <article class="card">
                        <h2>'.e($workshop['name']).'</h2>
                        <p><strong>Usta:</strong> '.e((string) ($workshop['master'] ?? '')).'</p>
                        <p><strong>Manzil:</strong> '.e((string) ($workshop['address'] ?? '')).'</p>
                        <p><strong>Access code:</strong> '.e((string) ($workshop['ownerAccessCode'] ?? '')).'</p>
                        <p><a href="/admin/bookings?workshop='.urlencode((string) $workshop['id']).'">Zakazlarni ko‘rish</a></p>
                        <ul>'.$services.'</ul>
                    </article>
                ';
            })
            ->implode('');

        return response($this->page('Admin workshops', '
            <div class="nav">
                <a href="/admin/workshops">Ustaxonalar</a>
                <a href="/admin/bookings">Zakazlar</a>
                <form method="post" action="/admin/logout">'.$this->csrf().'<button type="submit">Chiqish</button></form>
            </div>
            <h1>Ustaxonalar</h1>
            '.$items.'
        '));
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
                    <p><strong>Vaqt:</strong> '.e((string) $booking['dateTime']).'</p>
                    <p><strong>Status:</strong> '.e((string) $booking['status']).'</p>
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
            <div class="nav">
                <a href="/admin/workshops">Ustaxonalar</a>
                <a href="/admin/bookings">Zakazlar</a>
                <form method="post" action="/admin/logout">'.$this->csrf().'<button type="submit">Chiqish</button></form>
            </div>
            <h1>Zakazlar</h1>
            '.$items.'
        '));
    }

    public function updateBookingStatus(Request $request, string $id)
    {
        if (! $this->isAdmin($request)) {
            return redirect('/admin/login');
        }

        try {
            $this->repository->updateBookingStatus(
                $id,
                (string) $request->input('bookingStatus'),
                [
                    'scheduledAt' => (string) $request->input('scheduledAt'),
                    'cancelReasonId' => (string) $request->input('cancellationReasonId'),
                    'actorRole' => 'admin',
                ]
            );
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Zakaz holati yangilandi');
    }

    private function isAdmin(Request $request): bool
    {
        return (bool) $request->session()->get('ustatop_admin');
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
                .nav{display:flex;gap:12px;align-items:center;margin-bottom:20px}
                .nav form{margin:0}
                .card{background:#fff;border:1px solid #ddd;border-radius:16px;padding:16px;margin-bottom:16px}
                form{display:grid;gap:10px;max-width:420px}
                input,select,button{padding:10px;border-radius:10px;border:1px solid #cfcfcf}
                button{cursor:pointer}
                .flash{padding:12px;border-radius:12px;margin-bottom:16px}
                .flash.error{background:#fee2e2}
                .flash.success{background:#dcfce7}
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
