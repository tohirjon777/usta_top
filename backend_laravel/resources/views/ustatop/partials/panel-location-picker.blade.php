@php
    $pickerId = $pickerId ?? ('location-picker-'.uniqid());
    $addressName = $addressName ?? 'address';
    $addressValue = (string) ($addressValue ?? '');
    $latitudeName = $latitudeName ?? 'latitude';
    $latitudeValue = $latitudeValue ?? '';
    $longitudeName = $longitudeName ?? 'longitude';
    $longitudeValue = $longitudeValue ?? '';
    $routeUrl = trim((string) ($routeUrl ?? ''));
    $pickerHelp = $pickerHelp ?? 'Xaritada nuqtani bosing, qidiruvdan foydalaning yoki marker’ni sudrab aniq joyni tanlang.';
    $hasCoordinates = $latitudeValue !== null && $latitudeValue !== '' && $longitudeValue !== null && $longitudeValue !== '';
@endphp

<div class="map-picker" data-location-picker>
    <div class="map-picker-toolbar">
        <p class="muted">{{ $pickerHelp }}</p>
        <button type="button" class="button-secondary" data-map-clear>Belgini tozalash</button>
    </div>

    @if (!empty($panelYandexMapsApiKey ?? ''))
        <div id="{{ $pickerId }}" class="map-picker-canvas" data-map-canvas aria-label="Ustaxona xaritasi"></div>
    @else
        <p class="muted"><code>YANDEX_MAPS_JS_API_KEY</code> sozlanmagan. Xarita chiqishi uchun key qo‘shing.</p>
    @endif

    <label>Manzil</label>
    <input
        type="text"
        name="{{ $addressName }}"
        value="{{ $addressValue }}"
        placeholder="Toshkent, Chilonzor, ..."
        data-map-address
    >

    <div class="map-picker-meta">
        <p class="muted" data-map-status>{{ $hasCoordinates ? 'Lokatsiya tanlangan. Saqlashni unutmang.' : 'Lokatsiya hali tanlanmagan.' }}</p>
        <a
            class="ghost-link"
            href="{{ $routeUrl !== '' ? $routeUrl : '#' }}"
            data-map-route
            target="_blank"
            rel="noreferrer"
            @if ($routeUrl === '') hidden @endif
        >
            Yandex Maps’da ochish
        </a>
    </div>

    <input type="hidden" name="{{ $latitudeName }}" value="{{ $latitudeValue }}" data-map-lat>
    <input type="hidden" name="{{ $longitudeName }}" value="{{ $longitudeValue }}" data-map-lng>
</div>
