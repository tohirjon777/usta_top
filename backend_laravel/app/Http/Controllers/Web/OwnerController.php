<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Support\UstaTop\UstaTopRepository;
use Illuminate\Http\Request;
use Illuminate\Support\HtmlString;
use RuntimeException;

class OwnerController extends Controller
{
    public function __construct(
        private readonly UstaTopRepository $repository,
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

        $items = collect($bookings)->map(function (array $booking): string {
            return '
                <article class="card">
                    <h2>'.e((string) $booking['serviceName']).'</h2>
                    <p><strong>Mijoz:</strong> '.e((string) $booking['customerName']).' ('.e((string) $booking['customerPhone']).')</p>
                    <p><strong>Vaqt:</strong> '.e((string) $booking['dateTime']).'</p>
                    <p><strong>Status:</strong> '.e((string) $booking['status']).'</p>
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

        return response($this->page('Owner bookings', '
            <div class="nav">
                <strong>'.e((string) ($workshop['name'] ?? 'Ustaxona')).'</strong>
                <form method="post" action="/owner/logout">'.$this->csrf().'<button type="submit">Chiqish</button></form>
            </div>
            <h1>Zakazlar</h1>
            '.$items.'
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
            $this->repository->updateBookingStatus(
                $id,
                (string) $request->input('bookingStatus'),
                [
                    'scheduledAt' => (string) $request->input('scheduledAt'),
                    'cancelReasonId' => (string) $request->input('cancellationReasonId'),
                    'actorRole' => 'owner_panel',
                ]
            );
        } catch (RuntimeException $exception) {
            return redirect()->back()->with('error', $exception->getMessage());
        }

        return redirect()->back()->with('success', 'Zakaz holati yangilandi');
    }

    private function ownerWorkshopId(Request $request): string
    {
        return (string) $request->session()->get('ustatop_owner_workshop_id', '');
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
