@extends('layouts.ustatop-panel')

@section('content')
    <div class="nav">
        <strong>{{ $workshop['name'] ?? 'Ustaxona' }}</strong>
        <span class="spacer"></span>
        <form method="post" action="/owner/logout">
            @csrf
            <button type="submit" class="button-secondary">Chiqish</button>
        </form>
    </div>

    <article class="card">
        <h2>Ustaxona rasmi</h2>
        <div class="image-preview {{ empty($workshop['imageUrl']) ? 'empty' : '' }}">
            @if (!empty($workshop['imageUrl']))
                <img src="{{ $workshop['imageUrl'] }}" alt="{{ $workshop['name'] ?? 'Ustaxona' }}">
            @else
                <div class="image-placeholder">Rasm yo‘q</div>
            @endif
            <div>
                <strong>Joriy rasm</strong>
                <p class="muted">{{ !empty($workshop['imageUrl']) ? $workshop['imageUrl'] : 'Ustaxona uchun rasm URL kiriting yoki fayl yuklang.' }}</p>
            </div>
        </div>
        <form method="post" action="/owner/workshop/image" enctype="multipart/form-data">
            @csrf
            <label>Rasm URL</label>
            <input type="url" name="imageUrl" value="{{ $workshop['imageUrl'] ?? '' }}" placeholder="https://example.com/ustaxona.jpg">
            <label>Yoki yangi rasm fayli</label>
            <input type="file" name="imageFile" accept="image/*">
            <label class="checkbox-row"><input type="checkbox" name="removeImage" value="1"> Rasmni olib tashlash</label>
            <button type="submit">Rasmni saqlash</button>
        </form>
    </article>

    <article class="card">
        <div class="card-head">
            <div>
                <h2>Lokatsiya</h2>
                <p class="muted">Ustaxona lokatsiyasini faqat xarita orqali tanlang.</p>
            </div>
        </div>

        <form method="post" action="/owner/workshop/location">
            @csrf
            @include('ustatop.partials.panel-location-picker', [
                'pickerId' => 'ownerWorkshopMap',
                'addressValue' => $workshop['address'] ?? '',
                'latitudeValue' => $workshop['latitude'] ?? '',
                'longitudeValue' => $workshop['longitude'] ?? '',
                'routeUrl' => $workshopRouteUrl ?? '',
            ])
            <button type="submit">Lokatsiyani saqlash</button>
        </form>
    </article>

    <article class="card">
        <h2>Telegram</h2>
        <p><strong>Bot holati:</strong> {{ $telegramConfigured ? 'yoqilgan' : 'o‘chiq' }}</p>
        <p><strong>Chat ID:</strong> {{ !empty($workshop['telegramChatId']) ? $workshop['telegramChatId'] : 'ulanmagan' }}</p>
        @if (!empty($workshop['telegramChatId']))
            <p class="muted">Telegram ulangan va siz uni o‘zingiz uzmaguningizcha saqlanib turadi.</p>
        @endif
        @if (!empty($workshop['telegramLinkCode']))
            <p><strong>Bog‘lash kodi:</strong> {{ $workshop['telegramLinkCode'] }}</p>
            <p class="muted">Telegram botga <code>/start {{ $workshop['telegramLinkCode'] }}</code> yuboring.</p>
        @endif
        <div class="grid-two">
            <form method="post" action="/owner/telegram/generate">
                @csrf
                <button type="submit">{{ !empty($workshop['telegramLinkCode']) ? 'Yangi kod yaratish' : 'Bog‘lash kodini yaratish' }}</button>
            </form>
            <form method="post" action="/owner/telegram/check">
                @csrf
                <button type="submit" class="button-secondary">Tekshirish</button>
            </form>
        </div>
        <form method="post" action="/owner/telegram/disconnect">
            @csrf
            <button type="submit" class="button-danger">Telegramni uzish</button>
        </form>
    </article>

    <article class="card">
        <h2>Ish jadvali</h2>
        <form method="post" action="/owner/schedule">
            @csrf
            <div class="grid-two">
                <div>
                    <label>Ish boshlanishi</label>
                    <input type="time" name="openingTime" value="{{ $schedule['openingTime'] ?? '09:00' }}">
                </div>
                <div>
                    <label>Ish tugashi</label>
                    <input type="time" name="closingTime" value="{{ $schedule['closingTime'] ?? '19:00' }}">
                </div>
            </div>
            <div class="grid-two">
                <div>
                    <label>Tanaffus boshlanishi</label>
                    <input type="time" name="breakStartTime" value="{{ $schedule['breakStartTime'] ?? '13:00' }}">
                </div>
                <div>
                    <label>Tanaffus tugashi</label>
                    <input type="time" name="breakEndTime" value="{{ $schedule['breakEndTime'] ?? '14:00' }}">
                </div>
            </div>
            <label>Dam olish kunlari</label>
            <div class="grid-two">
                @foreach ($weekdayOptions as $weekday => $label)
                    <label class="checkbox-row"><input type="checkbox" name="closedWeekdays[]" value="{{ $weekday }}" @checked(in_array($weekday, $closedWeekdays, true))> {{ $label }}</label>
                @endforeach
            </div>
            <button type="submit">Jadvalni saqlash</button>
        </form>
    </article>

    <article class="card">
        <h2>Mashina bo‘yicha narxlar</h2>
        <p class="muted">Hozir saqlangan qoidalar: {{ $pricingRuleCount }} ta</p>
        <div class="grid-two">
            <a class="ghost-link" href="/owner/vehicle-pricing/template.xlsx">Excel template yuklab olish</a>
            <span class="muted">Template’ni yuklab, narxlarni yangilab qayta yuklang.</span>
        </div>
        <form method="post" action="/owner/vehicle-pricing/import" enctype="multipart/form-data">
            @csrf
            <label>Excel fayl (.xlsx)</label>
            <input type="file" name="pricingFile" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">
            <button type="submit">Excel narxlarni yuklash</button>
        </form>
    </article>

    <h1>Sharhlar</h1>
    <p class="muted">Bu yerda faqat sizning ustaxonangizga yozilgan sharhlar ko‘rinadi. Telegramdan ham shu sharhlarga javob qaytarishingiz mumkin.</p>
    @forelse ($reviews as $review)
        <article class="card">
            <h2>{{ $review['serviceName'] ?? '' }}</h2>
            <p><strong>Mijoz:</strong> {{ $review['customerName'] ?? '' }}</p>
            <p><strong>Baho:</strong> {{ $review['rating'] ?? '' }}/5</p>
            <p><strong>Sharh vaqti:</strong> {{ $review['createdAt'] ?? '' }}</p>
            <p>{{ $review['comment'] ?? '' }}</p>
            @if (!empty($review['ownerReply']))
                <p><strong>Javob:</strong> {{ $review['ownerReply'] }}</p>
                <p class="muted">Manba: {{ $review['ownerReplySource'] ?? 'owner_panel' }}</p>
            @else
                <p class="muted">Telegram xabariga reply yozish yoki shu yerdan javob qoldirish mumkin.</p>
            @endif
            <form method="post" action="/owner/reviews/{{ urlencode((string) $review['id']) }}/reply">
                @csrf
                <textarea name="reply" placeholder="Mijozga javob yozing"></textarea>
                <button type="submit">Javob yuborish</button>
            </form>
        </article>
    @empty
        <article class="card empty-state">
            <h2>Sharhlar yo‘q</h2>
            <p class="muted">Hozircha bu ustaxona uchun sharh qoldirilmagan.</p>
        </article>
    @endforelse

    <h1>Zakazlar</h1>
    @forelse ($bookings as $booking)
        <article class="card">
            <h2>{{ $booking['serviceName'] }}</h2>
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

            <form method="post" action="/owner/bookings/{{ urlencode((string) $booking['id']) }}/status">
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
            <h2>Zakazlar yo‘q</h2>
            <p class="muted">Hozircha bu ustaxona uchun buyurtma ko‘rinmadi.</p>
        </article>
    @endforelse

    <h1>Xizmatlar</h1>
    @foreach ($services as $service)
        <article class="card">
            <h2>{{ $service['name'] }}</h2>
            <form method="post" action="/owner/services/{{ urlencode((string) $service['id']) }}/price">
                @csrf
                <div class="grid-two">
                    <div>
                        <label>Narx</label>
                        <input type="number" min="0" name="price" value="{{ $service['priceInput'] }}">
                    </div>
                    <div>
                        <label>Davomiyligi (min)</label>
                        <input type="number" min="15" step="5" name="durationMinutes" value="{{ $service['durationMinutes'] ?? 30 }}">
                    </div>
                </div>
                <label>Avans foizi</label>
                <input type="number" min="0" max="100" name="prepaymentPercent" value="{{ $service['prepaymentPercent'] ?? 0 }}">
                <button type="submit">Yangilash</button>
            </form>
        </article>
    @endforeach

@endsection
