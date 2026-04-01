@extends('layouts.ustatop-public', ['pageClass' => 'customer-workshop-page'])

@section('content')
    <section class="detail-hero">
        <div class="hero-card">
            <div class="eyebrow">Ustaxona sahifasi</div>
            <h1 style="margin-bottom:10px;">{{ $workshop['name'] }}</h1>
            <p>{{ $workshop['description'] ?: 'Ushbu ustaxona uchun tavsif tez orada yangilanadi.' }}</p>
            <div class="badge-row" style="margin-top:18px;">
                <span class="pill {{ $workshop['isOpen'] ? 'status-open' : 'status-closed' }}">{{ $workshop['isOpen'] ? 'Hozir ochiq' : 'Hozir yopiq' }}</span>
                @if($workshop['badge'])
                    <span class="pill">{{ $workshop['badge'] }}</span>
                @endif
                <span class="pill muted">⭐ {{ $workshop['rating'] }} · {{ $workshop['reviewCount'] }} sharh</span>
                <span class="pill muted">{{ $workshop['distanceKm'] }} km</span>
                <span class="pill muted">Boshlanishi: {{ $workshop['startingPriceLabel'] }}</span>
            </div>
            <div class="hero-actions">
                @if($workshop['routeUrl'])
                    <a class="button" href="{{ $workshop['routeUrl'] }}" target="_blank" rel="noreferrer">Marshrut</a>
                @endif
                <a class="button-secondary" href="/">Orqaga</a>
            </div>
        </div>
        <div class="cover">
            @if($workshop['imageUrl'])
                <img src="{{ $workshop['imageUrl'] }}" alt="{{ $workshop['name'] }}">
            @else
                {{ strtoupper(mb_substr($workshop['name'], 0, 2)) }}
            @endif
        </div>
    </section>

    <section class="detail-grid">
        <div class="service-grid">
            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Online bron</h2>
                        <p>Bo‘sh vaqtlarni ko‘rib, shu sahifaning o‘zida buyurtma qiling.</p>
                    </div>
                </div>

                @if(!$currentCustomer)
                    <div class="service-card">
                        <p class="workshop-copy" style="margin:0 0 14px;">Bron qilish uchun avval mijoz kabinetiga kiring.</p>
                        <a class="button" href="/customer/login">Kirish / Ro‘yxatdan o‘tish</a>
                    </div>
                @else
                    <form method="post" action="/customer/workshops/{{ urlencode($workshop['id']) }}/book" class="form-grid js-booking-form">
                        @csrf
                        <label class="field">
                            <span>Xizmat</span>
                            <select name="serviceId" id="bookingService" required>
                                <option value="">Xizmatni tanlang</option>
                                @foreach($workshop['services'] as $service)
                                    <option value="{{ $service['id'] }}"
                                            data-name="{{ $service['name'] }}"
                                            data-price="{{ $service['price'] }}"
                                            data-price-label="{{ $service['priceLabel'] }}"
                                            data-duration="{{ $service['durationMinutes'] }}"
                                            data-prepayment="{{ $service['prepaymentPercent'] }}">
                                        {{ $service['name'] }} · {{ $service['priceLabel'] }}
                                    </option>
                                @endforeach
                            </select>
                        </label>

                        @if(!empty($savedVehicles))
                            <label class="field">
                                <span>Saqlangan mashina</span>
                                <select id="savedVehicleSelect">
                                    <option value="">Tanlamaslik</option>
                                    @foreach($savedVehicles as $vehicle)
                                        <option value="{{ json_encode($vehicle) }}">
                                            {{ trim(($vehicle['brand'] ?? '').' '.($vehicle['model'] ?? '')) ?: 'Mashina' }}
                                        </option>
                                    @endforeach
                                </select>
                            </label>
                        @endif

                        <div class="inline-grid">
                            <label class="field">
                                <span>Brend</span>
                                <input type="text" name="vehicleBrand" id="vehicleBrand" placeholder="Chevrolet" required>
                            </label>
                            <label class="field">
                                <span>Model</span>
                                <input type="text" name="vehicleModelName" id="vehicleModelName" placeholder="Cobalt" required>
                            </label>
                        </div>

                        <label class="field">
                            <span>Mashina turi</span>
                            <select name="vehicleTypeId" id="vehicleTypeId" required>
                                @foreach($vehicleTypes as $vehicleType)
                                    <option value="{{ $vehicleType['id'] }}">{{ $vehicleType['label'] }}</option>
                                @endforeach
                            </select>
                        </label>

                        <div class="inline-grid">
                            <label class="field">
                                <span>Sana</span>
                                <input type="date" name="bookingDate" id="bookingDate" min="{{ now()->format('Y-m-d') }}" required>
                            </label>
                            <label class="field">
                                <span>Vaqt</span>
                                <select name="bookingTime" id="bookingTime" required>
                                    <option value="">Avval sana tanlang</option>
                                </select>
                            </label>
                        </div>

                        <div id="bookingAvailabilityHint" class="helper-text">
                            Xizmat va sanani tanlaganingizdan keyin bo‘sh slotlar shu yerda chiqadi.
                        </div>

                        <label class="field">
                            <span>To‘lov usuli</span>
                            <select name="paymentMethod" id="paymentMethod" required>
                                @foreach($paymentMethods as $method)
                                    <option value="{{ $method['id'] }}">{{ $method['label'] }}</option>
                                @endforeach
                            </select>
                        </label>

                        @if(!empty($savedCards))
                            <div class="helper-text" id="savedCardsHint">
                                Saqlangan kartalar: {{ $savedCardsLabel }}
                            </div>
                        @endif

                        <div class="quote-card" id="bookingQuote">
                            <strong>Narx xulosasi</strong>
                            <div class="quote-row"><span>Bazaviy narx</span><span id="quoteBase">—</span></div>
                            <div class="quote-row"><span>Yakuniy narx</span><span id="quotePrice">—</span></div>
                            <div class="quote-row"><span>Avans</span><span id="quotePrepayment">—</span></div>
                            <div class="quote-row"><span>Qolgan to‘lov</span><span id="quoteRemaining">—</span></div>
                            <div class="quote-row"><span>Davomiylik</span><span id="quoteDuration">—</span></div>
                        </div>

                        <button class="button button-block" type="submit">Bron qilish</button>
                    </form>
                @endif
            </div>

            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Xizmatlar</h2>
                        <p>Ustaxona uchun belgilangan xizmat narxlari shu yerda ko‘rinadi.</p>
                    </div>
                </div>
                <div class="service-grid">
                    @foreach($workshop['services'] as $service)
                        <article class="service-card">
                            <div class="badge-row" style="justify-content:space-between; align-items:center;">
                                <strong>{{ $service['name'] }}</strong>
                                <span class="pill">{{ $service['priceLabel'] }}</span>
                            </div>
                            <p class="workshop-copy" style="margin-top:10px;">Davomiyligi: {{ $service['durationMinutes'] }} daqiqa</p>
                        </article>
                    @endforeach
                </div>
            </div>

            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Sharhlar</h2>
                        <p>Mijozlar fikri va ustaxona javoblari.</p>
                    </div>
                </div>
                <div class="review-list">
                    @forelse($workshop['reviews'] as $review)
                        <article class="review-card">
                            <div class="badge-row" style="justify-content:space-between;">
                                <strong>{{ $review['customerName'] }}</strong>
                                <span class="pill muted">⭐ {{ $review['rating'] }}</span>
                            </div>
                            <p class="workshop-copy" style="margin-top:10px;">{{ $review['comment'] ?: 'Sharh matni yo‘q.' }}</p>
                            @if($review['ownerReply'])
                                <div class="review-reply">
                                    <strong>Ustaxona javobi</strong>
                                    <p style="margin:8px 0 0;">{{ $review['ownerReply'] }}</p>
                                </div>
                            @endif
                        </article>
                    @empty
                        <div class="review-card">Hozircha sharhlar yo‘q.</div>
                    @endforelse
                </div>
            </div>
        </div>

        <div class="service-grid">
            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Lokatsiya</h2>
                        <p>Ustaxona belgilangani xarita nuqtasi.</p>
                    </div>
                </div>
                <div class="map-shell is-compact">
                    <div id="detailMap"></div>
                </div>
                <div class="meta-row" style="margin-top:14px;">
                    <span class="pill muted">{{ $workshop['address'] ?: 'Manzil ko‘rsatilmagan' }}</span>
                    @if($workshop['routeUrl'])
                        <a class="button" href="{{ $workshop['routeUrl'] }}" target="_blank" rel="noreferrer">Google Maps’da ochish</a>
                    @endif
                </div>
            </div>

            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Ish vaqti</h2>
                        <p>Jadval ustaxonaning amaldagi ish vaqtiga asoslanadi.</p>
                    </div>
                </div>
                <div class="schedule-card">
                    <div class="badge-row"><span class="pill">Ochilish: {{ $workshop['schedule']['openingTime'] }}</span><span class="pill">Yopilish: {{ $workshop['schedule']['closingTime'] }}</span></div>
                    <div class="badge-row" style="margin-top:10px;"><span class="pill muted">Tanaffus: {{ $workshop['schedule']['breakStartTime'] }} - {{ $workshop['schedule']['breakEndTime'] }}</span></div>
                    <div class="badge-row" style="margin-top:10px;"><span class="pill muted">Dam olish: {{ implode(', ', $workshop['schedule']['closedLabels']) }}</span></div>
                </div>
            </div>

            <div class="card">
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Yana ustaxona ko‘rish</h2>
                        <p>Saytdagi boshqa variantlar.</p>
                    </div>
                </div>
                <div class="related-grid">
                    @foreach($relatedWorkshops as $related)
                        <a class="related-card" href="{{ $related['detailUrl'] }}">
                            <strong>{{ $related['name'] }}</strong>
                            <p class="workshop-copy" style="margin-top:8px;">{{ $related['description'] }}</p>
                            <div class="badge-row">
                                <span class="pill muted">⭐ {{ $related['rating'] }}</span>
                                <span class="pill muted">{{ $related['startingPriceLabel'] }}</span>
                            </div>
                        </a>
                    @endforeach
                </div>
            </div>
        </div>
    </section>
@endsection

@section('scripts')
    <script id="customer-workshop-data" type="application/json">{!! json_encode([
        'workshop' => $workshop,
        'savedVehicles' => $savedVehicles,
        'savedCards' => $savedCards,
        'currentCustomer' => $currentCustomer,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) !!}</script>
    <script src="{{ asset('site-assets/customer-workshop.js') }}"></script>
@endsection
