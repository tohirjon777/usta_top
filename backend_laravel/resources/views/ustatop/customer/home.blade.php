@extends('layouts.ustatop-public', ['pageClass' => 'customer-home-page'])

@section('content')
    <section class="hero">
        <div class="hero-card">
            <div class="eyebrow">API bilan ishlaydigan customer website</div>
            <h1>Yaqin ustaxonani toping, xaritada ko‘ring va yo‘lga chiqing.</h1>
            <p>
                Usta Top endi mijozlar uchun ham web’da ishlaydi. Xizmatlarni solishtiring, ustaxona tavsifini ko‘ring,
                xaritada marker ustiga bosing va marshrutni bir tugma bilan oching.
            </p>
            <div class="hero-actions">
                <a class="button" href="#discover">Ustaxonalarni ko‘rish</a>
                <a class="button-secondary" href="#map">Xaritani ochish</a>
                @if($currentCustomer)
                    <a class="button-secondary" href="/customer/account">Mening kabinetim</a>
                @else
                    <a class="button-secondary" href="/customer/login">Kirish / Ro‘yxatdan o‘tish</a>
                @endif
            </div>
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value">{{ $stats['workshops'] }}</div>
                    <div class="stat-label">Faol ustaxona</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{{ $stats['openNow'] }}</div>
                    <div class="stat-label">Hozir ochiq</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{{ $stats['services'] }}</div>
                    <div class="stat-label">Xizmat turi</div>
                </div>
            </div>
        </div>
        <aside class="hero-card hero-side">
            <h2>Saytda nimalar bor</h2>
            <div class="feature-list">
                <div class="feature"><strong>Xarita preview:</strong> marker bosilganda ustaxona tavsifi va marshruti chiqadi.</div>
                <div class="feature"><strong>Doimiy yangilanadi:</strong> ustaxona ma’lumoti saytda hamisha eng so‘nggi holatda ko‘rinadi.</div>
                <div class="feature"><strong>Customer-friendly:</strong> mobilga mos, silliq va premium landing ko‘rinishi.</div>
            </div>
        </aside>
    </section>

    <section id="discover">
        <div class="section-title">
            <div>
                <h2>Ustaxonalar katalogi</h2>
                <p>Qidiruv, xizmat bo‘yicha filter va xarita bilan ishlaydigan public page.</p>
            </div>
        </div>

        <div class="grid-2">
            <div class="card">
                <div class="filters">
                    <input id="searchInput" type="search" placeholder="Nom, manzil yoki tavsif bo‘yicha qidiring">
                    <select id="serviceFilter">
                        <option value="">Barcha xizmatlar</option>
                        @foreach($services as $service)
                            <option value="{{ $service }}">{{ $service }}</option>
                        @endforeach
                    </select>
                    <label class="checkbox-pill">
                        <input id="openOnly" type="checkbox" style="width:auto;">
                        Faqat ochiq
                    </label>
                </div>

                <div id="workshopList" class="list">
                    @foreach($featuredWorkshops as $workshop)
                        <article class="workshop-card">
                            <div class="workshop-image">
                                @if($workshop['imageUrl'])
                                    <img src="{{ $workshop['imageUrl'] }}" alt="{{ $workshop['name'] }}">
                                @else
                                    {{ strtoupper(mb_substr($workshop['name'], 0, 2)) }}
                                @endif
                            </div>
                            <div>
                                <div class="badge-row">
                                    <span class="pill {{ $workshop['isOpen'] ? 'status-open' : 'status-closed' }}">
                                        {{ $workshop['isOpen'] ? 'Ochiq' : 'Yopiq' }}
                                    </span>
                                    @if($workshop['badge'])
                                        <span class="pill">{{ $workshop['badge'] }}</span>
                                    @endif
                                    <span class="pill muted">⭐ {{ $workshop['rating'] }} · {{ $workshop['reviewCount'] }} sharh</span>
                                </div>
                                <h3 class="workshop-title">{{ $workshop['name'] }}</h3>
                                <p class="workshop-copy">{{ $workshop['description'] }}</p>
                            </div>
                        </article>
                    @endforeach
                </div>
            </div>

            <div class="card" id="map">
                <div class="map-shell">
                    <div id="workshopMap"></div>
                    <div id="mapPanel" class="map-panel is-hidden" aria-hidden="true"></div>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('scripts')
    <script id="customer-home-data" type="application/json">{!! json_encode([
        'apiEndpoint' => $apiEndpoint,
        'initialWorkshops' => $initialWorkshops,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) !!}</script>
    <script src="{{ asset('site-assets/customer-home.js') }}"></script>
@endsection
