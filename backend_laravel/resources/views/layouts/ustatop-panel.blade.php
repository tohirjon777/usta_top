<!doctype html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'AutoMaster Panel' }}</title>
    @php($panelYandexMapsApiKey = trim((string) ($panelYandexMapsApiKey ?? '')))
    @if ($panelYandexMapsApiKey !== '')
        <script src="https://api-maps.yandex.ru/2.1/?apikey={{ urlencode($panelYandexMapsApiKey) }}&lang=ru_RU" type="text/javascript"></script>
    @endif
    <style>
        :root {
            color-scheme: light only;
            --bg: #f6f4ef;
            --card: #ffffff;
            --line: #ddd;
            --line-strong: #c9c9c9;
            --text: #1c1c1c;
            --muted: #666;
            --accent: #0f766e;
            --accent-soft: #14b8a6;
            --danger: #8b1e1e;
            --warning: #9a5b00;
            --success-bg: #dcfce7;
            --error-bg: #fee2e2;
            --radius: 16px;
            --shadow: 0 16px 42px rgba(17, 24, 39, 0.06);
        }

        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: radial-gradient(circle at top left, rgba(20, 184, 166, 0.08), transparent 24%), var(--bg);
            color: var(--text);
            font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        .page {
            max-width: 1220px;
            margin: 0 auto;
            padding: 24px 20px 48px;
        }

        .nav {
            display: flex;
            gap: 12px;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .nav a,
        .nav button,
        .ghost-link,
        .pill-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 14px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.82);
            color: var(--text);
            text-decoration: none;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
        }

        .nav a.active {
            border-color: transparent;
            background: linear-gradient(135deg, var(--accent), var(--accent-soft));
            color: white;
        }

        .nav form { margin: 0; }
        .nav .spacer { flex: 1 1 auto; }
        .nav .muted { margin-left: auto; }

        .hero,
        .card,
        .metric-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
        }

        .card,
        .metric-card {
            padding: 16px;
            margin-bottom: 16px;
        }

        .hero {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            align-items: flex-start;
            flex-wrap: wrap;
            padding: 18px;
            margin-bottom: 16px;
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.95), rgba(243, 250, 249, 0.98));
        }

        .card-head,
        .chart-head,
        .summary-head {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
        }

        h1, h2, h3, p { margin: 0; }
        h1 { margin-bottom: 12px; font-size: 32px; }
        h2 { font-size: 22px; margin-bottom: 10px; }
        h3 { font-size: 17px; }

        form { display: grid; gap: 10px; }
        label { font-weight: 600; font-size: 14px; }
        textarea { min-height: 92px; resize: vertical; }
        input, select, button, textarea {
            padding: 10px 12px;
            border-radius: 10px;
            border: 1px solid #cfcfcf;
            font: inherit;
            width: 100%;
            background: white;
        }

        input:focus,
        select:focus,
        textarea:focus {
            outline: none;
            border-color: rgba(15, 118, 110, 0.5);
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.12);
        }

        button {
            cursor: pointer;
            background: linear-gradient(135deg, var(--accent), var(--accent-soft));
            color: white;
            border-color: transparent;
            font-weight: 700;
        }

        .button-secondary,
        .ghost-link {
            background: rgba(255, 255, 255, 0.85);
            color: var(--text);
            border-color: var(--line);
        }

        .danger,
        .button-danger {
            background: var(--danger);
            color: white;
            border-color: var(--danger);
        }

        .warning-btn {
            background: var(--warning);
            color: white;
            border-color: var(--warning);
        }

        .flash {
            padding: 12px 14px;
            border-radius: 12px;
            margin-bottom: 16px;
            font-weight: 600;
        }

        .flash.error { background: var(--error-bg); }
        .flash.success { background: var(--success-bg); }

        .grid-two {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }

        .filter-grid {
            display: grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 12px;
            align-items: end;
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 16px;
        }

        .metric-label {
            font-size: 13px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .metric-value {
            font-size: 28px;
            font-weight: 800;
            margin: 8px 0 6px;
        }

        .metric-hint, .muted, .hint {
            color: var(--muted);
            font-size: 14px;
            line-height: 1.55;
        }

        .section-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 16px;
        }

        .section-grid.single {
            grid-template-columns: 1fr;
        }

        .chart-list,
        .summary-list {
            display: grid;
            gap: 12px;
            margin-top: 14px;
        }

        .chart-row,
        .summary-row {
            display: grid;
            gap: 8px;
        }

        .bar-track {
            height: 10px;
            border-radius: 999px;
            background: #ece7dc;
            overflow: hidden;
        }

        .bar-fill {
            height: 100%;
            border-radius: 999px;
            background: linear-gradient(90deg, var(--accent), var(--accent-soft));
        }

        .summary-value {
            font-weight: 700;
        }

        .actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        .checkbox-row {
            display: flex;
            gap: 8px;
            align-items: center;
        }

        .checkbox-row input[type="checkbox"] {
            width: auto;
        }

        .image-preview {
            display: flex;
            gap: 14px;
            align-items: center;
            padding: 12px;
            border: 1px dashed #d6d0c5;
            border-radius: 14px;
            background: #fcfaf6;
            margin-bottom: 14px;
        }

        .image-preview img,
        .image-placeholder {
            width: 88px;
            height: 88px;
            border-radius: 18px;
            object-fit: cover;
            background: #ece6dc;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #8a6f3a;
            font-weight: 700;
            flex-shrink: 0;
        }

        .image-preview.empty {
            background: #faf7f1;
        }

        .map-picker {
            display: grid;
            gap: 12px;
            margin-bottom: 14px;
        }

        .map-picker-toolbar,
        .map-picker-meta {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
        }

        .map-picker-canvas {
            width: 100%;
            height: 320px;
            border-radius: 18px;
            overflow: hidden;
            border: 1px solid var(--line-strong);
            background: #ece6dc;
        }

        .map-picker-toolbar button {
            width: auto;
        }

        .map-picker-meta .ghost-link {
            width: auto;
        }

        .login-shell {
            max-width: 520px;
            margin: 0 auto;
            padding-top: 80px;
        }

        .empty-state {
            text-align: center;
            padding: 22px;
        }

        @media (max-width: 960px) {
            .metrics-grid,
            .section-grid,
            .filter-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 720px) {
            .page { padding: 18px 14px 36px; }
            .grid-two,
            .metrics-grid,
            .section-grid,
            .filter-grid {
                grid-template-columns: 1fr;
            }
            .hero,
            .card-head,
            .chart-head,
            .summary-head {
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    <main class="page">
        @if (session('error'))
            <div class="flash error">{{ session('error') }}</div>
        @endif
        @if (session('success'))
            <div class="flash success">{{ session('success') }}</div>
        @endif

        @yield('content')
</main>
<script>
    (() => {
        const pageKey = `ustatop:panel:${window.location.pathname}${window.location.search}`;
        const scrollKey = `${pageKey}:scrollY`;
        const actionKey = `${pageKey}:action`;

        if ('scrollRestoration' in history) {
            history.scrollRestoration = 'manual';
        }

        const restorePosition = () => {
            const savedAction = sessionStorage.getItem(actionKey);
            const savedScroll = sessionStorage.getItem(scrollKey);

            if (!savedAction && !savedScroll) {
                return;
            }

            let restored = false;
            if (savedAction) {
                const matchingForm = Array.from(document.forms).find((form) => form.getAttribute('action') === savedAction);
                const target = matchingForm
                    ? (matchingForm.closest('.card, .metric-card, .hero, article') || matchingForm)
                    : null;
                if (target) {
                    target.scrollIntoView({ block: 'start' });
                    window.scrollBy(0, -16);
                    restored = true;
                }
            }

            if (!restored && savedScroll) {
                const top = Number(savedScroll);
                if (!Number.isNaN(top)) {
                    window.scrollTo({ top, left: 0, behavior: 'auto' });
                }
            }

            sessionStorage.removeItem(actionKey);
            sessionStorage.removeItem(scrollKey);
        };

        window.addEventListener('load', () => {
            window.requestAnimationFrame(() => {
                window.requestAnimationFrame(restorePosition);
            });
        });

        document.addEventListener('submit', (event) => {
            const form = event.target;
            if (!(form instanceof HTMLFormElement)) {
                return;
            }

            sessionStorage.setItem(scrollKey, String(window.scrollY));
            sessionStorage.setItem(actionKey, form.getAttribute('action') || '');
        });
    })();

    (() => {
        if (!window.ymaps || typeof window.ymaps.ready !== 'function') {
            return;
        }

        const pickers = Array.from(document.querySelectorAll('[data-location-picker]'));
        if (!pickers.length) {
            return;
        }

        const defaultCenter = [41.311081, 69.240562];
        const parseCoord = (value) => {
            const number = Number.parseFloat(String(value ?? '').trim());

            return Number.isFinite(number) ? number : null;
        };
        const normalizeCoords = (coords) => [
            Number(coords[0].toFixed(6)),
            Number(coords[1].toFixed(6)),
        ];
        const routeUrl = (coords) => `https://yandex.com/maps/?rtext=~${coords[0]},${coords[1]}&rtt=auto`;

        window.ymaps.ready(() => {
            pickers.forEach((picker, index) => {
                const canvas = picker.querySelector('[data-map-canvas]');
                const addressInput = picker.querySelector('[data-map-address]');
                const latInput = picker.querySelector('[data-map-lat]');
                const lngInput = picker.querySelector('[data-map-lng]');
                const clearButton = picker.querySelector('[data-map-clear]');
                const statusNode = picker.querySelector('[data-map-status]');
                const routeLink = picker.querySelector('[data-map-route]');

                if (!(canvas instanceof HTMLElement) || !(latInput instanceof HTMLInputElement) || !(lngInput instanceof HTMLInputElement)) {
                    return;
                }

                if (!canvas.id) {
                    canvas.id = `ustatopPanelMap${index + 1}`;
                }

                const currentCoords = () => {
                    const lat = parseCoord(latInput.value);
                    const lng = parseCoord(lngInput.value);

                    return lat === null || lng === null ? null : [lat, lng];
                };

                const setStatus = (message) => {
                    if (statusNode) {
                        statusNode.textContent = message;
                    }
                };

                const updateRouteLink = (coords) => {
                    if (!routeLink) {
                        return;
                    }

                    if (!coords) {
                        routeLink.hidden = true;
                        routeLink.setAttribute('href', '#');
                        return;
                    }

                    routeLink.hidden = false;
                    routeLink.setAttribute('href', routeUrl(coords));
                };

                const map = new window.ymaps.Map(canvas.id, {
                    center: currentCoords() ?? defaultCenter,
                    zoom: currentCoords() ? 15 : 11,
                    controls: ['zoomControl', 'geolocationControl'],
                }, {
                    suppressMapOpenBlock: true,
                });
                const searchControl = new window.ymaps.control.SearchControl({
                    options: {
                        noPlacemark: true,
                        position: {
                            top: 12,
                            left: 12,
                        },
                    },
                });
                map.controls.add(searchControl);

                let placemark = null;

                const removePlacemark = () => {
                    if (!placemark) {
                        return;
                    }

                    map.geoObjects.remove(placemark);
                    placemark = null;
                };

                const syncAddressFromMap = async (coords) => {
                    if (!(addressInput instanceof HTMLInputElement)) {
                        return;
                    }

                    try {
                        const result = await window.ymaps.geocode(coords);
                        const firstGeoObject = result.geoObjects.get(0);
                        if (!firstGeoObject) {
                            return;
                        }

                        const addressLine = typeof firstGeoObject.getAddressLine === 'function'
                            ? firstGeoObject.getAddressLine()
                            : firstGeoObject.properties.get('text') || firstGeoObject.properties.get('name') || '';

                        if (addressLine) {
                            addressInput.value = addressLine;
                        }
                    } catch (_) {
                        // Geocoder javobi bo'lmasa ham koordinata saqlanishi kerak.
                    }
                };

                const applyCoords = async (coords, options = {}) => {
                    if (!coords) {
                        latInput.value = '';
                        lngInput.value = '';
                        removePlacemark();
                        updateRouteLink(null);
                        setStatus('Lokatsiya hali tanlanmagan.');
                        return;
                    }

                    const normalized = normalizeCoords(coords);
                    latInput.value = normalized[0].toFixed(6);
                    lngInput.value = normalized[1].toFixed(6);
                    updateRouteLink(normalized);
                    setStatus('Lokatsiya tanlandi. Saqlashni unutmang.');

                    if (!placemark) {
                        placemark = new window.ymaps.Placemark(normalized, {
                            hintContent: 'Ustaxona lokatsiyasi',
                        }, {
                            draggable: true,
                        });
                        placemark.events.add('dragend', () => {
                            const draggedCoords = placemark.geometry.getCoordinates();
                            void applyCoords(draggedCoords, { recenter: false, syncAddress: true });
                        });
                        map.geoObjects.add(placemark);
                    } else {
                        placemark.geometry.setCoordinates(normalized);
                    }

                    if (options.recenter !== false) {
                        map.setCenter(normalized, Math.max(map.getZoom(), 15), { duration: 200 });
                    }

                    if (options.syncAddress !== false) {
                        if (typeof options.address === 'string' && options.address.trim() !== '' && addressInput instanceof HTMLInputElement) {
                            addressInput.value = options.address.trim();
                        } else {
                            await syncAddressFromMap(normalized);
                        }
                    }
                };

                map.events.add('click', (event) => {
                    void applyCoords(event.get('coords'), { syncAddress: true });
                });

                searchControl.events.add('resultselect', (event) => {
                    searchControl.getResult(event.get('index')).then((result) => {
                        const geometry = result && result.geometry ? result.geometry : null;
                        const coords = geometry && typeof geometry.getCoordinates === 'function'
                            ? geometry.getCoordinates()
                            : null;

                        if (!coords) {
                            return;
                        }

                        const address = typeof result.getAddressLine === 'function'
                            ? result.getAddressLine()
                            : result.properties.get('text') || result.properties.get('name') || '';

                        void applyCoords(coords, { syncAddress: true, address });
                    });
                });

                if (clearButton) {
                    clearButton.addEventListener('click', () => {
                        void applyCoords(null);
                    });
                }

                const initialCoords = currentCoords();
                if (initialCoords) {
                    void applyCoords(initialCoords, { recenter: false, syncAddress: false });
                } else {
                    updateRouteLink(null);
                    setStatus('Lokatsiya hali tanlanmagan.');
                }
            });
        });
    })();
</script>
</body>
</html>
