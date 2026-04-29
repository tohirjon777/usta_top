@extends('layouts.ustatop-panel')

@section('content')
    <div class="nav">
        <a href="/admin/workshops" class="active">Ustaxonalar</a>
        <a href="/admin/bookings">Zakazlar</a>
        <a href="/admin/analytics">Statistika</a>
        <span class="spacer"></span>
        <span class="muted">Telegram: {{ $telegramConfigured ? 'yoqilgan' : 'o‘chiq' }}</span>
        <form method="post" action="/admin/logout">
            @csrf
            <button type="submit" class="button-secondary">Chiqish</button>
        </form>
    </div>

    <h1>Ustaxonalar</h1>

    <article class="card">
        <h2>Yangi ustaxona</h2>
        <form method="post" action="/admin/workshops" enctype="multipart/form-data">
            @csrf
            <label>Nomi</label>
            <input type="text" name="name" value="">
            <label>Usta</label>
            <input type="text" name="master" value="">
            <h3>Lokatsiya</h3>
            @include('ustatop.partials.panel-location-picker', [
                'pickerId' => 'adminWorkshopCreateMap',
                'addressValue' => '',
                'latitudeValue' => '',
                'longitudeValue' => '',
                'routeUrl' => '',
            ])
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
            <div class="grid-two">
                <div>
                    <label>Ish boshlanishi</label>
                    <input type="time" name="openingTime" value="09:00">
                </div>
                <div>
                    <label>Ish tugashi</label>
                    <input type="time" name="closingTime" value="19:00">
                </div>
            </div>
            <div class="grid-two">
                <div>
                    <label>Tanaffus boshlanishi</label>
                    <input type="time" name="breakStartTime" value="13:00">
                </div>
                <div>
                    <label>Tanaffus tugashi</label>
                    <input type="time" name="breakEndTime" value="14:00">
                </div>
            </div>
            <label>Dam olish kunlari (1-7, vergul bilan)</label>
            <input type="text" name="closedWeekdays" value="7" placeholder="7">
            <label class="checkbox-row"><input type="checkbox" name="isOpen" value="1" checked> Ustaxona ochiq</label>
            <label>Xizmatlar</label>
            <textarea name="servicesText" rows="5" placeholder="srv-1|Kompyuter diagnostika|120000|35|0"></textarea>
            <p class="hint">Har qatorda: serviceId | nomi | narxi(UZS) | davomiyligi(minut) | avans foizi</p>
            <button type="submit">Yaratish</button>
        </form>
    </article>

    @foreach ($workshops as $workshop)
        <article class="card">
            <div class="card-head">
                <div>
                    <h2>{{ $workshop['name'] }}</h2>
                    <p class="muted">ID: {{ $workshop['id'] }} · Access code: {{ $workshop['ownerAccessCode'] ?? '' }}</p>
                </div>
                <a class="ghost-link" href="/admin/bookings?workshop={{ urlencode((string) $workshop['id']) }}">Zakazlar</a>
            </div>

            <form method="post" action="/admin/workshops/{{ urlencode((string) $workshop['id']) }}/update" enctype="multipart/form-data">
                @csrf
                <div class="image-preview {{ empty($workshop['imageUrl']) ? 'empty' : '' }}">
                    @if (!empty($workshop['imageUrl']))
                        <img src="{{ $workshop['imageUrl'] }}" alt="{{ $workshop['name'] }}">
                    @else
                        <div class="image-placeholder">Rasm yo‘q</div>
                    @endif
                    <div>
                        <strong>Joriy rasm</strong>
                        <p class="muted">{{ !empty($workshop['imageUrl']) ? $workshop['imageUrl'] : 'Public URL kiriting yoki fayl yuklang.' }}</p>
                    </div>
                </div>

                <label>Nomi</label>
                <input type="text" name="name" value="{{ $workshop['name'] }}">
                <label>Usta</label>
                <input type="text" name="master" value="{{ $workshop['master'] ?? '' }}">
                <h3>Lokatsiya</h3>
                @include('ustatop.partials.panel-location-picker', [
                    'pickerId' => 'adminWorkshopMap-'.preg_replace('/[^A-Za-z0-9_-]+/', '-', (string) ($workshop['id'] ?? 'workshop')),
                    'addressValue' => $workshop['address'] ?? '',
                    'latitudeValue' => $workshop['latitude'] ?? '',
                    'longitudeValue' => $workshop['longitude'] ?? '',
                    'routeUrl' => isset($workshop['latitude'], $workshop['longitude']) && $workshop['latitude'] !== null && $workshop['longitude'] !== null
                        ? 'https://yandex.com/maps/?rtext=~'.(float) $workshop['latitude'].','.(float) $workshop['longitude'].'&rtt=auto'
                        : '',
                ])
                <label>Tavsif</label>
                <textarea name="description">{{ $workshop['description'] ?? '' }}</textarea>
                <label>Badge</label>
                <input type="text" name="badge" value="{{ $workshop['badge'] ?? '' }}">
                <label>Rasm URL</label>
                <input type="url" name="imageUrl" value="{{ $workshop['imageUrl'] ?? '' }}" placeholder="https://example.com/ustaxona.jpg">
                <label>Yoki rasm fayli</label>
                <input type="file" name="imageFile" accept="image/*">
                <label class="checkbox-row"><input type="checkbox" name="removeImage" value="1"> Rasmni olib tashlash</label>
                <div class="grid-two">
                    <div>
                        <label>Starting price</label>
                        <input type="number" min="0" name="startingPrice" value="{{ $workshop['startingPriceInput'] }}">
                    </div>
                    <div>
                        <label>Owner access code</label>
                        <input type="text" name="ownerAccessCode" value="{{ $workshop['ownerAccessCode'] ?? '' }}">
                    </div>
                </div>
                <label>Telegram chat ID</label>
                <input type="text" name="telegramChatId" value="{{ $workshop['telegramChatId'] ?? '' }}" placeholder="-1001234567890">
                <div class="grid-two">
                    <div>
                        <label>Ish boshlanishi</label>
                        <input type="time" name="openingTime" value="{{ $workshop['schedule']['openingTime'] ?? '09:00' }}">
                    </div>
                    <div>
                        <label>Ish tugashi</label>
                        <input type="time" name="closingTime" value="{{ $workshop['schedule']['closingTime'] ?? '19:00' }}">
                    </div>
                </div>
                <div class="grid-two">
                    <div>
                        <label>Tanaffus boshlanishi</label>
                        <input type="time" name="breakStartTime" value="{{ $workshop['schedule']['breakStartTime'] ?? '13:00' }}">
                    </div>
                    <div>
                        <label>Tanaffus tugashi</label>
                        <input type="time" name="breakEndTime" value="{{ $workshop['schedule']['breakEndTime'] ?? '14:00' }}">
                    </div>
                </div>
                <label>Dam olish kunlari (1-7, vergul bilan)</label>
                <input type="text" name="closedWeekdays" value="{{ $workshop['closedWeekdaysCsv'] }}" placeholder="7">
                <label class="checkbox-row"><input type="checkbox" name="isOpen" value="1" @checked($workshop['isOpen'] ?? false)> Ustaxona ochiq</label>
                <label>Xizmatlar</label>
                <textarea name="servicesText" rows="5" placeholder="srv-1|Kompyuter diagnostika|120000|35|0">{{ $workshop['servicesText'] }}</textarea>
                <p class="hint">Har qatorda: serviceId | nomi | narxi(UZS) | davomiyligi(minut) | avans foizi</p>
                <div class="actions">
                    <button type="submit">Saqlash</button>
                </div>
            </form>

            <form method="post" action="/admin/workshops/{{ urlencode((string) $workshop['id']) }}/telegram/test">
                @csrf
                <button type="submit" class="button-secondary">Telegram test</button>
            </form>

            <div class="actions">
                <a class="ghost-link" href="/admin/workshops/{{ urlencode((string) $workshop['id']) }}/vehicle-pricing/template.xlsx">Excel template</a>
            </div>

            <form method="post" action="/admin/workshops/{{ urlencode((string) $workshop['id']) }}/vehicle-pricing/import" enctype="multipart/form-data">
                @csrf
                <label>Excel narxlar (.xlsx)</label>
                <input type="file" name="pricingFile" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">
                <button type="submit">Excel yuklash</button>
            </form>

            <form method="post" action="/admin/workshops/{{ urlencode((string) $workshop['id']) }}/delete" onsubmit="return confirm('Rostdan ham o‘chirasizmi?')">
                @csrf
                <button class="danger" type="submit">O‘chirish</button>
            </form>
        </article>
    @endforeach
@endsection
