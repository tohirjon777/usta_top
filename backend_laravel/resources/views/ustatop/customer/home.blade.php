@extends('layouts.ustatop-public', ['pageClass' => 'customer-home-page'])

@section('content')
    <section class="launch-hero">
        <div class="hero-copy reveal">
            <div class="eyebrow">AutoMaster mijozlar sayti</div>
            <h1>Avtomobil xizmatini tez toping, ustani chaqiring va yo‘lga qayting.</h1>
            <p>
                AutoMaster yaqin ustaxonalar, favqulodda yordam, marshrut, bron qilish va cashback imkoniyatlarini
                bitta qulay mijoz tajribasiga jamlaydi.
            </p>
            <div class="hero-actions">
                <a class="button" href="#discover">Ustaxonalarni ko‘rish</a>
                <a class="button-secondary" href="#emergency">Tezkor yordam</a>
                <a class="button-secondary" href="#map">Xaritani ochish</a>
                @if($currentCustomer)
                    <a class="button-secondary" href="/customer/account">Mening kabinetim</a>
                @else
                    <a class="button-secondary" href="/customer/login">Kirish / Ro‘yxatdan o‘tish</a>
                @endif
            </div>
            <div class="stats hero-stats">
                <div class="stat-card reveal">
                    <div class="stat-value" data-count="{{ $stats['workshops'] }}">{{ $stats['workshops'] }}</div>
                    <div class="stat-label">Faol ustaxona</div>
                </div>
                <div class="stat-card reveal">
                    <div class="stat-value" data-count="{{ $stats['openNow'] }}">{{ $stats['openNow'] }}</div>
                    <div class="stat-label">Hozir ochiq</div>
                </div>
                <div class="stat-card reveal">
                    <div class="stat-value" data-count="{{ $stats['services'] }}">{{ $stats['services'] }}</div>
                    <div class="stat-label">Xizmat turi</div>
                </div>
            </div>
        </div>

        <div class="app-showcase reveal" aria-label="AutoMaster ilovasi preview">
            <div class="phone-frame">
                <div class="phone-top">
                    <img src="{{ asset('site-assets/automaster-logo.png') }}" alt="AutoMaster">
                    <div>
                        <strong>AutoMaster</strong>
                        <span>Yaqin servislar onlayn</span>
                    </div>
                </div>
                <div class="route-preview">
                    <div class="route-grid"></div>
                    <span class="route-pin route-pin-a"></span>
                    <span class="route-pin route-pin-b"></span>
                    <span class="route-line"></span>
                    <span class="route-car">AM</span>
                </div>
                <div class="phone-card phone-card-primary">
                    <span>Tezkor xizmat</span>
                    <strong>Balon almashtirish</strong>
                    <small>Taxminiy kelish: 12 daqiqa</small>
                </div>
                <div class="phone-service-row">
                    <span>Ustaxona</span>
                    <span>Yoqilg‘i</span>
                    <span>Cashback</span>
                </div>
                <div class="phone-card">
                    <span>Keyingi buyurtma uchun</span>
                    <strong>Cashback hisobga tushadi</strong>
                </div>
            </div>
        </div>
    </section>

    <section class="trust-strip reveal" aria-label="AutoMaster imkoniyatlari">
        <div class="trust-item">
            <strong>Real ma’lumot</strong>
            <span>Ustaxona, xizmat va narxlar serverdan yangilanadi.</span>
        </div>
        <div class="trust-item">
            <strong>Marshrut bir tugmada</strong>
            <span>Xaritadan tanlang va yo‘lni darhol oching.</span>
        </div>
        <div class="trust-item">
            <strong>Mobilga tayyor</strong>
            <span>Telefon ekranida tez qidirish va bron qilish qulay.</span>
        </div>
    </section>

    <section id="emergency" class="service-section">
        <div class="section-title reveal">
            <div>
                <h2>Favqulodda holatda tez yordam</h2>
                <p>Yo‘lda qolib ketgan mijoz uchun kerakli xizmatlar alohida ko‘rinadi.</p>
            </div>
        </div>

        <div class="emergency-grid">
            <article class="feature-card reveal">
                <div class="feature-icon">01</div>
                <h3>Balon almashtirish</h3>
                <p>Joylashuv bo‘yicha yaqin ustani topish, marshrut va xizmat tafsilotlarini ko‘rish.</p>
            </article>
            <article class="feature-card reveal">
                <div class="feature-icon">02</div>
                <h3>Ko‘chma yoqilg‘i</h3>
                <p>Yoqilg‘i tugaganda xizmat chaqirish uchun mijozga sodda va tezkor oqim.</p>
            </article>
            <article class="feature-card reveal">
                <div class="feature-icon">03</div>
                <h3>Ustaxona bron qilish</h3>
                <p>Bo‘sh vaqt, xizmat turi va transport ma’lumotlari asosida bron berish.</p>
            </article>
        </div>
    </section>

    <section id="cashback" class="cashback-band reveal">
        <div>
            <span class="eyebrow">Sinov cashback tizimi</span>
            <h2>Xizmat bajarilgandan keyin cashback avtomatik hisobga tushadi.</h2>
            <p>
                Mijoz keyingi safar buyurtma berayotganda yig‘ilgan cashbackni ishlatishi mumkin.
                Karta kiritilmagan bo‘lsa, to‘lov bosqichida karta qo‘shish eslatiladi.
            </p>
        </div>
        <div class="cashback-meter" aria-hidden="true">
            <div class="cashback-ring">
                <span>3%</span>
            </div>
            <div class="cashback-flow">
                <span>To‘lov</span>
                <span>Bajarildi</span>
                <span>Cashback</span>
            </div>
        </div>
    </section>

    <section class="steps-section">
        <div class="section-title reveal">
            <div>
                <h2>Mijoz uchun oddiy jarayon</h2>
                <p>AutoMaster sayti va ilovasi bir xil server ma’lumotlari bilan ishlaydi.</p>
            </div>
        </div>
        <div class="steps-grid">
            <div class="step-item reveal"><strong>1</strong><span>Xizmat yoki ustaxonani tanlang.</span></div>
            <div class="step-item reveal"><strong>2</strong><span>Xaritadan joylashuv va masofani ko‘ring.</span></div>
            <div class="step-item reveal"><strong>3</strong><span>Bron qiling yoki tezkor yordam so‘rang.</span></div>
            <div class="step-item reveal"><strong>4</strong><span>Xizmat tugagach cashback hisobga tushadi.</span></div>
        </div>
    </section>

    <section id="discover" class="catalog-section">
        <div class="section-title">
            <div>
                <h2>Ustaxonalar katalogi</h2>
                <p>Qidiruv, xizmat bo‘yicha filter va xarita orqali yaqin ustaxonani tanlang.</p>
            </div>
        </div>

        <div class="grid-2">
            <div class="card reveal">
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

            <div class="card reveal" id="map">
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
