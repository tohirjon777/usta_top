@extends('layouts.ustatop-panel')

@section('content')
    <div class="nav">
        <a href="/admin/workshops">Ustaxonalar</a>
        <a href="/admin/bookings" class="active">Zakazlar</a>
        <a href="/admin/analytics">Statistika</a>
        <span class="spacer"></span>
        <span class="muted">Telegram: {{ $telegramConfigured ? 'yoqilgan' : 'o‘chiq' }}</span>
        <form method="post" action="/admin/logout">
            @csrf
            <button type="submit" class="button-secondary">Chiqish</button>
        </form>
    </div>

    <h1>Zakazlar</h1>

    @forelse ($bookings as $booking)
        <article class="card">
            <h2>{{ $booking['workshopName'] }} · {{ $booking['serviceName'] }}</h2>
            <p><strong>Mijoz:</strong> {{ $booking['customerName'] }} ({{ $booking['customerPhone'] }})</p>
            <p><strong>Mashina:</strong> {{ $booking['vehicleModel'] ?? '' }}</p>
            <p><strong>Vaqt:</strong> {{ $booking['dateTime'] }}</p>
            <p><strong>Status:</strong> {{ $booking['status'] }}</p>
            <p><strong>Narx:</strong> {{ $booking['priceLabel'] }}</p>
            <p><strong>Avans:</strong> {{ $booking['prepaymentLabel'] }}</p>
            @if (!empty($booking['acceptedAt']))<p><strong>Qabul qilingan vaqt:</strong> {{ $booking['acceptedAt'] }}</p>@endif
            @if (!empty($booking['previousDateTime']))<p><strong>Oldingi vaqt:</strong> {{ $booking['previousDateTime'] }}</p>@endif
            @if (!empty($booking['rescheduledByRole']))<p><strong>Ko‘chirdi:</strong> {{ $booking['rescheduledByRole'] }}</p>@endif
            @if (!empty($booking['rescheduledAt']))<p><strong>Ko‘chirilgan vaqt:</strong> {{ $booking['rescheduledAt'] }}</p>@endif
            @if (!empty($booking['completedAt']))<p><strong>Yakunlangan vaqt:</strong> {{ $booking['completedAt'] }}</p>@endif
            @if (!empty($booking['cancelledAt']))<p><strong>Bekor qilingan vaqt:</strong> {{ $booking['cancelledAt'] }}</p>@endif
            @if (!empty($booking['cancelReasonId']))<p><strong>Sabab:</strong> {{ $booking['cancelReasonId'] }}</p>@endif

            <form method="post" action="/admin/bookings/{{ urlencode((string) $booking['id']) }}/status">
                @csrf
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
    @empty
        <article class="card empty-state">
            <h2>Zakaz topilmadi</h2>
            <p class="muted">Hozircha bu filter bo‘yicha buyurtma yo‘q.</p>
        </article>
    @endforelse
@endsection
