@extends('layouts.ustatop-public', ['pageClass' => 'customer-account-page'])

@section('content')
    <section class="account-hero">
        <div class="hero-card">
            <div class="eyebrow">Mening kabinetim</div>
            <div class="account-hero__identity">
                <div class="account-avatar">
                    @if(!empty($currentCustomer['avatarUrl']))
                        <img src="{{ $currentCustomer['avatarUrl'] }}" alt="{{ $currentCustomer['fullName'] ?? 'Mijoz' }}">
                    @else
                        {{ strtoupper(mb_substr($currentCustomer['fullName'] ?? 'M', 0, 1)) }}
                    @endif
                </div>
                <div>
                    <h1>{{ $currentCustomer['fullName'] ?? 'Mijoz' }}</h1>
                    <p>
                        Telefon: {{ $currentCustomer['phone'] ?? '—' }}. Bu yerdan profilni yangilaysiz, kartalarni saqlaysiz,
                        bronlarni boshqarasiz va ustaxona bilan yozishasiz.
                    </p>
                </div>
            </div>
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value">{{ count($bookings) }}</div>
                    <div class="stat-label">Jami bron</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{{ count($currentCustomer['savedPaymentCards'] ?? []) }}</div>
                    <div class="stat-label">Saqlangan karta</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{{ count($currentCustomer['savedVehicles'] ?? []) }}</div>
                    <div class="stat-label">Saqlangan mashina</div>
                </div>
            </div>
        </div>
        <div class="hero-card hero-side">
            <h2>Tezkor havolalar</h2>
            <div class="feature-list">
                <a class="feature" href="#bookings"><strong>Bronlar:</strong> vaqtni ko‘chirish, bekor qilish, tasdiqlash.</a>
                <a class="feature" href="#cards"><strong>Kartalar:</strong> test karta qo‘shish va tahrirlash.</a>
                <a class="feature" href="#profile"><strong>Profil:</strong> ism, telefon va parolni yangilash.</a>
                <a class="feature" href="/account/delete"><strong>Akkaunt:</strong> account va shaxsiy ma’lumotlarni o‘chirish.</a>
            </div>
        </div>
    </section>

    <section class="account-grid">
        <div class="service-grid">
            <article id="profile" class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Profil</h2>
                        <p>Asosiy mijoz ma’lumotlarini yangilang.</p>
                    </div>
                </div>
                <form method="post" action="/customer/profile" class="form-grid">
                    @csrf
                    <label class="field">
                        <span>To‘liq ism</span>
                        <input type="text" name="fullName" value="{{ $currentCustomer['fullName'] ?? '' }}" required>
                    </label>
                    <label class="field">
                        <span>Telefon</span>
                        <input type="text" name="phone" value="{{ $currentCustomer['phone'] ?? '' }}" required>
                    </label>
                    <button class="button" type="submit">Profilni saqlash</button>
                </form>
                <form method="post" action="/customer/avatar" class="form-grid" enctype="multipart/form-data" style="margin-top:16px;">
                    @csrf
                    <label class="field">
                        <span>Avatar rasmi</span>
                        <input type="file" name="avatar" accept="image/*" required>
                    </label>
                    <button class="button-secondary" type="submit">Avatarni yangilash</button>
                </form>
            </article>

            <article class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Parol</h2>
                        <p>Xavfsizlik uchun parolingizni yangilang.</p>
                    </div>
                </div>
                <form method="post" action="/customer/password" class="form-grid">
                    @csrf
                    <label class="field">
                        <span>Joriy parol</span>
                        <input type="password" name="currentPassword" required>
                    </label>
                    <label class="field">
                        <span>Yangi parol</span>
                        <input type="password" name="newPassword" required>
                    </label>
                    <button class="button" type="submit">Parolni yangilash</button>
                </form>
            </article>

            @if(!empty($currentCustomer['savedVehicles']))
                <article class="card">
                    <div class="section-title" style="margin-top:0;">
                        <div>
                            <h2>Saqlangan mashinalar</h2>
                            <p>Ilova va web bookinglarda ishlatiladigan mashinalaringiz.</p>
                        </div>
                    </div>
                    <div class="tag-cloud">
                        @foreach($currentCustomer['savedVehicles'] as $vehicle)
                            <span class="pill muted">
                                {{ trim(($vehicle['brand'] ?? '').' '.($vehicle['model'] ?? '')) ?: 'Mashina' }}
                            </span>
                        @endforeach
                    </div>
                </article>
            @endif
        </div>

        <div class="service-grid">
            <article id="cards" class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Saqlangan kartalar</h2>
                        <p>Test karta bilan bronni tezroq rasmiylashtirish uchun kartalaringizni saqlang.</p>
                    </div>
                </div>

                <form method="post" action="/customer/cards" class="form-grid card-form">
                    @csrf
                    <label class="field">
                        <span>Karta brendi</span>
                        <input type="text" name="brand" placeholder="Uzcard / Humo / Visa" required>
                    </label>
                    <label class="field">
                        <span>Karta raqami</span>
                        <input type="text" name="cardNumber" placeholder="8600 1234 5678 9012" required>
                    </label>
                    <label class="field">
                        <span>Karta egasi</span>
                        <input type="text" name="holderName" placeholder="Toxirjon Aliyev" required>
                    </label>
                    <div class="inline-grid">
                        <label class="field">
                            <span>Oy</span>
                            <input type="number" name="expiryMonth" min="1" max="12" placeholder="12" required>
                        </label>
                        <label class="field">
                            <span>Yil</span>
                            <input type="number" name="expiryYear" min="2026" max="2099" placeholder="2028" required>
                        </label>
                    </div>
                    <label class="checkbox-pill">
                        <input type="checkbox" name="isDefault" value="1" style="width:auto;">
                        Asosiy karta qilish
                    </label>
                    <button class="button" type="submit">Kartani qo‘shish</button>
                </form>

                <div class="saved-card-list">
                    @forelse($currentCustomer['savedPaymentCards'] ?? [] as $card)
                        <details class="saved-card-item">
                            <summary>
                                <div>
                                    <strong>{{ $card['brand'] }}</strong>
                                    <div class="workshop-copy">{{ $card['maskedNumber'] }} · {{ $card['holderName'] }}</div>
                                </div>
                                <div class="badge-row">
                                    @if($card['isDefault'])
                                        <span class="pill">Asosiy</span>
                                    @endif
                                    <span class="pill muted">{{ $card['expiryLabel'] }}</span>
                                </div>
                            </summary>
                            <div class="details-body">
                                <form method="post" action="/customer/cards/{{ urlencode($card['id']) }}/update" class="form-grid">
                                    @csrf
                                    <label class="field">
                                        <span>Karta brendi</span>
                                        <input type="text" name="brand" value="{{ $card['brand'] }}" required>
                                    </label>
                                    <label class="field">
                                        <span>Yangi karta raqami</span>
                                        <input type="text" name="cardNumber" placeholder="8600 1234 5678 9012">
                                    </label>
                                    <label class="field">
                                        <span>Karta egasi</span>
                                        <input type="text" name="holderName" value="{{ $card['holderName'] }}" required>
                                    </label>
                                    <div class="inline-grid">
                                        <label class="field">
                                            <span>Oy</span>
                                            <input type="number" name="expiryMonth" min="1" max="12" value="{{ substr($card['expiryLabel'], 0, 2) }}" required>
                                        </label>
                                        <label class="field">
                                            <span>Yil</span>
                                            <input type="number" name="expiryYear" min="2026" max="2099" value="20{{ substr($card['expiryLabel'], -2) }}" required>
                                        </label>
                                    </div>
                                    <label class="checkbox-pill">
                                        <input type="checkbox" name="isDefault" value="1" style="width:auto;" {{ $card['isDefault'] ? 'checked' : '' }}>
                                        Asosiy karta
                                    </label>
                                    <div class="actions-row">
                                        <button class="button-secondary" type="submit">Kartani yangilash</button>
                                    </div>
                                </form>
                                <form method="post" action="/customer/cards/{{ urlencode($card['id']) }}/delete" class="inline-form">
                                    @csrf
                                    <button class="button-danger" type="submit">Kartani o‘chirish</button>
                                </form>
                            </div>
                        </details>
                    @empty
                        <div class="service-card">Hozircha saqlangan kartalar yo‘q.</div>
                    @endforelse
                </div>
            </article>
        </div>
    </section>

    <section id="bookings">
        <div class="section-title">
            <div>
                <h2>Mening bronlarim</h2>
                <p>Bron, ko‘chirish, sharh va xabarlar shu yerda boshqariladi.</p>
            </div>
        </div>

        <div class="list">
            @forelse($bookings as $booking)
                <article class="booking-card" id="booking-{{ $booking['id'] }}">
                    <div class="booking-card__header">
                        <div>
                            <div class="badge-row">
                                <span class="pill">{{ $booking['statusLabel'] }}</span>
                                <span class="pill muted">{{ $booking['dateTimeLabel'] }}</span>
                                <span class="pill muted">{{ $booking['serviceName'] ?? 'Xizmat' }}</span>
                            </div>
                            <h3 class="workshop-title">{{ $booking['workshopName'] ?? 'Ustaxona' }}</h3>
                            <p class="workshop-copy">
                                {{ $booking['vehicleModel'] ?? 'Mashina' }} · {{ $booking['priceLabel'] }}
                                @if(!empty($booking['acceptedAtLabel']))
                                    · Qabul qilingan: {{ $booking['acceptedAtLabel'] }}
                                @endif
                                @if(!empty($booking['rescheduledAtLabel']))
                                    · Ko‘chirilgan: {{ $booking['rescheduledAtLabel'] }}
                                @endif
                                @if(!empty($booking['rescheduledByLabel']))
                                    · Ko‘chirdi: {{ $booking['rescheduledByLabel'] }}
                                @endif
                                @if(!empty($booking['previousDateTimeLabel']))
                                    · Oldingi vaqt: {{ $booking['previousDateTimeLabel'] }}
                                @endif
                                @if(!empty($booking['completedAtLabel']))
                                    · Yakunlangan: {{ $booking['completedAtLabel'] }}
                                @endif
                                @if(!empty($booking['cancelledAtLabel']))
                                    · Bekor qilingan: {{ $booking['cancelledAtLabel'] }}
                                @endif
                            </p>
                        </div>
                        <div class="booking-card__price">
                            <div class="stat-value">{{ $booking['priceLabel'] }}</div>
                            <div class="stat-label">Avans: {{ $booking['prepaymentLabel'] }} · Qolgan: {{ $booking['remainingLabel'] }}</div>
                        </div>
                    </div>

                    <div class="actions-row booking-actions">
                        <a class="button-secondary" href="{{ $booking['detailUrl'] }}">Ustaxona sahifasi</a>
                        @if($booking['canAcceptRescheduled'])
                            <form method="post" action="/customer/bookings/{{ urlencode($booking['id']) }}/accept-reschedule" class="inline-form">
                                @csrf
                                <button class="button" type="submit">Ko‘chirilgan vaqtni tasdiqlash</button>
                            </form>
                        @endif
                        @if($booking['canCancel'])
                            <form method="post" action="/customer/bookings/{{ urlencode($booking['id']) }}/cancel" class="inline-form">
                                @csrf
                                <button class="button-danger" type="submit">Bronni bekor qilish</button>
                            </form>
                        @endif
                    </div>

                    <div class="booking-card__grid">
                        @if($booking['canReschedule'])
                            <details class="booking-panel">
                                <summary>Vaqtni ko‘chirish</summary>
                                <div class="details-body">
                                    <form method="post"
                                          action="/customer/bookings/{{ urlencode($booking['id']) }}/reschedule"
                                          class="form-grid js-reschedule-form"
                                          data-workshop-id="{{ $booking['workshopId'] }}"
                                          data-service-id="{{ $booking['serviceId'] }}"
                                          data-time-target="reschedule-time-{{ $booking['id'] }}"
                                          data-hint-target="reschedule-hint-{{ $booking['id'] }}">
                                        @csrf
                                        <label class="field">
                                            <span>Yangi sana</span>
                                            <input type="date" name="bookingDate" min="{{ now()->format('Y-m-d') }}" required>
                                        </label>
                                        <label class="field">
                                            <span>Yangi vaqt</span>
                                            <select id="reschedule-time-{{ $booking['id'] }}" name="bookingTime" required>
                                                <option value="">Avval sanani tanlang</option>
                                            </select>
                                        </label>
                                        <div id="reschedule-hint-{{ $booking['id'] }}" class="helper-text">
                                            Bo‘sh slotlar tanlangan sana bo‘yicha yuklanadi.
                                        </div>
                                        <button class="button-secondary" type="submit">Ko‘chirishni saqlash</button>
                                    </form>
                                </div>
                            </details>
                        @endif

                        <details class="booking-panel">
                            <summary>Xabarlar ({{ count($booking['messages']) }})</summary>
                            <div class="details-body">
                                <div class="message-list">
                                    @forelse($booking['messages'] as $message)
                                        <div class="message-bubble {{ $message['senderRole'] === 'customer' ? 'is-self' : '' }}">
                                            <strong>{{ $message['senderLabel'] }}</strong>
                                            <p>{{ $message['text'] }}</p>
                                            <span>{{ $message['createdAtLabel'] }}</span>
                                        </div>
                                    @empty
                                        <div class="service-card">Hozircha xabarlar yo‘q.</div>
                                    @endforelse
                                </div>
                                <form method="post" action="/customer/bookings/{{ urlencode($booking['id']) }}/messages" class="form-grid">
                                    @csrf
                                    <label class="field">
                                        <span>Yangi xabar</span>
                                        <textarea name="text" rows="4" placeholder="Ustaxonaga yuboriladigan xabaringiz..." required></textarea>
                                    </label>
                                    <button class="button-secondary" type="submit">Xabar yuborish</button>
                                </form>
                            </div>
                        </details>

                        @if($booking['canReview'])
                            <details class="booking-panel">
                                <summary>Sharh qoldirish</summary>
                                <div class="details-body">
                                    <form method="post" action="/customer/workshops/{{ urlencode($booking['workshopId']) }}/reviews" class="form-grid">
                                        @csrf
                                        <input type="hidden" name="bookingId" value="{{ $booking['id'] }}">
                                        <input type="hidden" name="serviceId" value="{{ $booking['serviceId'] }}">
                                        <label class="field">
                                            <span>Baho</span>
                                            <select name="rating" required>
                                                <option value="5">5 - Juda zo‘r</option>
                                                <option value="4">4 - Yaxshi</option>
                                                <option value="3">3 - O‘rtacha</option>
                                                <option value="2">2 - Past</option>
                                                <option value="1">1 - Yomon</option>
                                            </select>
                                        </label>
                                        <label class="field">
                                            <span>Sharh matni</span>
                                            <textarea name="comment" rows="4" placeholder="Xizmat haqida fikringizni yozing"></textarea>
                                        </label>
                                        <button class="button" type="submit">Sharh yuborish</button>
                                    </form>
                                </div>
                            </details>
                        @endif
                    </div>
                </article>
            @empty
                <div class="card">Hozircha bronlar yo‘q. Ustaxona katalogidan birinchi buyurtmangizni yarating.</div>
            @endforelse
        </div>
    </section>
@endsection

@section('scripts')
    <script id="customer-account-data" type="application/json">{!! json_encode([
        'bookings' => $bookings,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) !!}</script>
    <script src="{{ asset('site-assets/customer-account.js') }}"></script>
@endsection
