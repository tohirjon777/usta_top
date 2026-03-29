@extends('layouts.ustatop-panel')

@section('content')
    <div class="nav">
        <a href="/admin/workshops">Ustaxonalar</a>
        <a href="/admin/bookings">Zakazlar</a>
        <a href="/admin/analytics" class="active">Statistika</a>
        <span class="spacer"></span>
        <span class="muted">Telegram: {{ $telegramConfigured ? 'yoqilgan' : 'o‘chiq' }}</span>
        <form method="post" action="/admin/logout">
            @csrf
            <button type="submit" class="button-secondary">Chiqish</button>
        </form>
    </div>

    <div class="hero">
        <div>
            <h1>Statistika</h1>
            <p class="muted">Admin uchun booking, tushum, sharh va ustaxona kesimlari bir joyda.</p>
        </div>
        <a class="ghost-link" href="/admin/analytics/export.csv?{{ http_build_query($exportQuery) }}">CSV yuklab olish</a>
    </div>

    <article class="card">
        <form method="get" action="/admin/analytics" class="filter-grid">
            <div>
                <label>Davr</label>
                <select name="range">
                    <option value="today" @selected(($filters['range'] ?? '') === 'today')>Bugun</option>
                    <option value="7d" @selected(($filters['range'] ?? '') === '7d')>7 kun</option>
                    <option value="30d" @selected(($filters['range'] ?? '') === '30d')>30 kun</option>
                    <option value="custom" @selected(($filters['range'] ?? '') === 'custom')>Custom</option>
                </select>
            </div>
            <div>
                <label>Ustaxona</label>
                <select name="workshop">
                    <option value="">Barchasi</option>
                    @foreach ($filters['workshops'] ?? [] as $workshop)
                        <option value="{{ $workshop['id'] }}" @selected(($filters['workshopId'] ?? '') === ($workshop['id'] ?? ''))>{{ $workshop['name'] ?? 'Ustaxona' }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label>Dan</label>
                <input type="date" name="from" value="{{ $filters['from'] ?? '' }}">
            </div>
            <div>
                <label>Gacha</label>
                <input type="date" name="to" value="{{ $filters['to'] ?? '' }}">
            </div>
            <div class="actions">
                <button type="submit">Qo‘llash</button>
            </div>
        </form>
        <p class="hint">Faol davr: {{ $periodLabel }}</p>
    </article>

    <section class="metrics-grid">
        @foreach ($metrics as $metric)
            <article class="metric-card">
                <div class="metric-label">{{ $metric['label'] ?? '' }}</div>
                <div class="metric-value">{{ $metric['value'] ?? '0' }}</div>
                <div class="metric-hint">{{ $metric['hint'] ?? '' }}</div>
            </article>
        @endforeach
    </section>

    <section class="section-grid">
        @foreach ([
            ['title' => 'Kunlik zakazlar', 'subtitle' => 'Rejalashtirilgan bronlar va yangi yaratilgan zakazlar', 'items' => $bookingsChart, 'currency' => false],
            ['title' => 'Kunlik tushum', 'subtitle' => 'Bekor qilinmagan bronlar summasi', 'items' => $revenueChart, 'currency' => true],
        ] as $chart)
            @php
                $maxValue = max(array_map(fn ($item) => max(0, (int) ($item['value'] ?? 0)), $chart['items'] ?: [['value' => 0]]));
            @endphp
            <article class="card">
                <h2>{{ $chart['title'] }}</h2>
                <p class="muted">{{ $chart['subtitle'] }}</p>
                <div class="chart-list">
                    @foreach ($chart['items'] as $item)
                        @php
                            $value = max(0, (int) ($item['value'] ?? 0));
                            $percent = $maxValue > 0 ? (int) round(($value / $maxValue) * 100) : 0;
                        @endphp
                        <div class="chart-row">
                            <div class="chart-head">
                                <strong>{{ $item['label'] ?? '' }}</strong>
                                <span class="summary-value">{{ $item['meta'] ?? '' }}</span>
                            </div>
                            <div class="bar-track">
                                <div class="bar-fill" style="width: {{ $percent }}%"></div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </article>
        @endforeach
    </section>

    <section class="section-grid">
        <article class="card">
            <h2>Status taqsimoti</h2>
            <p class="muted">Holatlar bo‘yicha kesim</p>
            <div class="summary-list">
                @foreach ($statusBreakdown as $item)
                    <div class="summary-row">
                        <div class="summary-head">
                            <strong>{{ $item['label'] ?? '' }}</strong>
                            <span class="summary-value">{{ $item['value'] ?? '' }}</span>
                        </div>
                        @if (!empty($item['meta']))
                            <p class="muted">{{ $item['meta'] }}</p>
                        @endif
                    </div>
                @endforeach
            </div>
        </article>

        <article class="card">
            <h2>Sharh statistikasi</h2>
            <p class="muted">Foydalanuvchi fikr-mulohazalari</p>
            <div class="metrics-grid">
                @foreach ($reviewMetrics as $metric)
                    <article class="metric-card">
                        <div class="metric-label">{{ $metric['label'] ?? '' }}</div>
                        <div class="metric-value">{{ $metric['value'] ?? '0' }}</div>
                        <div class="metric-hint">{{ $metric['hint'] ?? '' }}</div>
                    </article>
                @endforeach
            </div>
        </article>
    </section>

    <section class="section-grid">
        @foreach ([
            ['title' => 'Top ustaxonalar', 'subtitle' => 'Eng ko‘p bron tushgan nuqtalar', 'items' => $topWorkshops],
            ['title' => 'Top xizmatlar', 'subtitle' => 'Qaysi xizmatlarga talab kuchli', 'items' => $topServices],
            ['title' => 'Top mashinalar', 'subtitle' => 'Eng ko‘p kelgan model va brendlar', 'items' => $topVehicles],
            ['title' => 'Bekor qilish sabablari', 'subtitle' => 'Qaysi sabablar ko‘proq uchrayapti', 'items' => $cancelReasons],
        ] as $list)
            <article class="card">
                <h2>{{ $list['title'] }}</h2>
                <p class="muted">{{ $list['subtitle'] }}</p>
                <div class="summary-list">
                    @forelse ($list['items'] as $item)
                        <div class="summary-row">
                            <div class="summary-head">
                                <strong>{{ $item['label'] ?? '' }}</strong>
                                <span class="summary-value">{{ $item['value'] ?? '' }}</span>
                            </div>
                            @if (!empty($item['meta']))
                                <p class="muted">{{ $item['meta'] }}</p>
                            @endif
                        </div>
                    @empty
                        <p class="muted">Hozircha ma’lumot yo‘q.</p>
                    @endforelse
                </div>
            </article>
        @endforeach
    </section>

    <section class="section-grid single">
        <article class="card">
            <h2>Reytinglar</h2>
            <p class="muted">Bahosi yuqori ustaxonalar</p>
            <div class="summary-list">
                @forelse ($ratings as $item)
                    <div class="summary-row">
                        <div class="summary-head">
                            <strong>{{ $item['label'] ?? '' }}</strong>
                            <span class="summary-value">{{ $item['value'] ?? '' }}</span>
                        </div>
                        @if (!empty($item['meta']))
                            <p class="muted">{{ $item['meta'] }}</p>
                        @endif
                    </div>
                @empty
                    <p class="muted">Hozircha ma’lumot yo‘q.</p>
                @endforelse
            </div>
        </article>
    </section>
@endsection
