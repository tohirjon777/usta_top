(function () {
    const dataNode = document.getElementById('customer-home-data');
    if (!dataNode) {
        return;
    }

    const payload = JSON.parse(dataNode.textContent || '{}');
    const workshopApiEndpoint = payload.apiEndpoint || '/workshops';
    const fallbackWorkshops = Array.isArray(payload.initialWorkshops) ? payload.initialWorkshops : [];
    const defaultCenter = [41.3111, 69.2797];

    let workshops = fallbackWorkshops;
    let selectedWorkshopId = null;
    let map = null;
    let geoObjectCollection = null;
    let mapReadyPromise = null;
    let hasFittedInitialBounds = false;

    function yandexRouteUrl(latitude, longitude) {
        if (latitude == null || longitude == null) {
            return '#';
        }

        return `https://yandex.com/maps/?rtext=~${latitude},${longitude}&rtt=auto`;
    }

    function routeLink(workshop) {
        if (workshop.routeUrl) {
            return workshop.routeUrl;
        }

        return yandexRouteUrl(workshop.latitude, workshop.longitude);
    }

    function markerDataUrl(isSelected) {
        const fill = isSelected ? '#0f766e' : '#14b8a6';
        const stroke = isSelected ? '#ffffff' : '#083344';
        const svg = `
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="80" viewBox="0 0 64 80" fill="none">
                <path d="M32 78C32 78 56 52.5 56 31C56 16.6406 45.3594 6 32 6C18.6406 6 8 16.6406 8 31C8 52.5 32 78 32 78Z" fill="${fill}" stroke="${stroke}" stroke-width="3"/>
                <rect x="20" y="24" width="24" height="18" rx="4" fill="white" opacity="0.98"/>
                <path d="M16 42L22 36.5H42L48 42V48C48 49.6569 46.6569 51 45 51H19C17.3431 51 16 49.6569 16 48V42Z" fill="white" opacity="0.98"/>
                <circle cx="24" cy="48" r="4" fill="${fill}"/>
                <circle cx="40" cy="48" r="4" fill="${fill}"/>
            </svg>
        `;

        return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
    }

    function cardTemplate(workshop) {
        const image = workshop.imageUrl
            ? `<img src="${workshop.imageUrl}" alt="${workshop.name}">`
            : `${(workshop.name || 'UT').slice(0, 2).toUpperCase()}`;
        const services = (workshop.serviceNames || []).map((item) => `<span class="pill muted">${item}</span>`).join('');

        return `
            <article class="workshop-card ${selectedWorkshopId === workshop.id ? 'is-active' : ''}" data-id="${workshop.id}">
                <div class="workshop-image">${image}</div>
                <div>
                    <div class="badge-row">
                        <span class="pill ${workshop.isOpen ? 'status-open' : 'status-closed'}">${workshop.isOpen ? 'Ochiq' : 'Yopiq'}</span>
                        ${workshop.badge ? `<span class="pill">${workshop.badge}</span>` : ''}
                        <span class="pill muted">⭐ ${workshop.rating} · ${workshop.reviewCount} sharh</span>
                        <span class="pill muted">${workshop.distanceKm} km</span>
                    </div>
                    <h3 class="workshop-title">${workshop.name}</h3>
                    <p class="workshop-copy">${workshop.description || ''}</p>
                    <div class="meta-row" style="margin-bottom:10px;">
                        <span class="pill muted">Boshlanishi: ${workshop.startingPriceLabel}</span>
                        <span class="pill muted">${workshop.address || 'Manzil ko‘rsatilmagan'}</span>
                    </div>
                    <div class="service-row" style="margin-bottom:12px;">${services}</div>
                    <div class="actions-row">
                        <a class="button-secondary" href="${workshop.detailUrl}">Batafsil</a>
                        <a class="button" href="${routeLink(workshop)}" target="_blank" rel="noreferrer">Marshrut</a>
                    </div>
                </div>
            </article>
        `;
    }

    function applyFilters() {
        const query = document.getElementById('searchInput').value.trim().toLowerCase();
        const service = document.getElementById('serviceFilter').value.trim().toLowerCase();
        const openOnly = document.getElementById('openOnly').checked;

        return workshops.filter((workshop) => {
            const haystack = [workshop.name, workshop.address, workshop.fullDescription, workshop.badge]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();
            const services = (workshop.services || []).map((item) => (item.name || '').toLowerCase());
            if (query && !haystack.includes(query)) {
                return false;
            }
            if (service && !services.includes(service)) {
                return false;
            }
            if (openOnly && !workshop.isOpen) {
                return false;
            }
            return true;
        });
    }

    function renderList(filtered) {
        const container = document.getElementById('workshopList');
        if (!filtered.length) {
            container.innerHTML = '<div class="service-card">Bu filter bo‘yicha ustaxona topilmadi.</div>';
            return;
        }

        container.innerHTML = filtered.map(cardTemplate).join('');
        container.querySelectorAll('[data-id]').forEach((card) => {
            card.addEventListener('click', () => {
                void selectWorkshop(card.dataset.id, true);
            });
        });
    }

    function renderMapPanel(workshop) {
        const panel = document.getElementById('mapPanel');
        if (!panel) {
            return;
        }

        if (!workshop) {
            panel.className = 'map-panel is-hidden';
            panel.setAttribute('aria-hidden', 'true');
            panel.innerHTML = '';
            return;
        }

        const embedUrl = `${workshop.detailUrl}${workshop.detailUrl.includes('?') ? '&' : '?'}embedded=1`;
        panel.className = 'map-panel';
        panel.setAttribute('aria-hidden', 'false');
        panel.innerHTML = `
            <div class="map-panel__bar">
                <strong>${workshop.name}</strong>
                <button type="button" class="map-panel__close" aria-label="Oynani yopish">×</button>
            </div>
            <iframe
                class="map-panel__frame"
                src="${embedUrl}"
                title="${workshop.name}"
                loading="lazy"
            ></iframe>
        `;

        panel.querySelector('.map-panel__close')?.addEventListener('click', () => {
            clearSelection();
        });
    }

    function ensureMapReady() {
        if (mapReadyPromise) {
            return mapReadyPromise;
        }

        const mapNode = document.getElementById('workshopMap');
        if (!mapNode || !window.ymaps) {
            renderMapPanel(null);
            const panel = document.getElementById('mapPanel');
            if (panel) {
                panel.className = 'map-panel map-empty';
                panel.textContent = 'Yandex Maps yuklanmadi. API key yoki script holatini tekshiring.';
            }

            return Promise.resolve(null);
        }

        mapReadyPromise = new Promise((resolve) => {
            window.ymaps.ready(() => {
                map = new window.ymaps.Map('workshopMap', {
                    center: defaultCenter,
                    zoom: 11,
                    controls: [],
                }, {
                    suppressMapOpenBlock: true,
                });
                geoObjectCollection = new window.ymaps.GeoObjectCollection();
                map.geoObjects.add(geoObjectCollection);

                resolve(map);
            });
        });

        return mapReadyPromise;
    }

    function buildPlacemark(workshop, isSelected) {
        return new window.ymaps.Placemark(
            [workshop.latitude, workshop.longitude],
            {
                hintContent: workshop.name,
            },
            {
                iconLayout: 'default#image',
                iconImageHref: markerDataUrl(isSelected),
                iconImageSize: isSelected ? [56, 70] : [46, 58],
                iconImageOffset: isSelected ? [-28, -70] : [-23, -58],
                hideIconOnBalloonOpen: false,
                cursor: 'pointer',
            }
        );
    }

    async function renderMap(filtered, options = {}) {
        const {
            preserveViewport = false,
        } = options;
        const readyMap = await ensureMapReady();
        if (!readyMap) {
            return;
        }

        if (geoObjectCollection) {
            geoObjectCollection.removeAll();
        }

        const points = [];
        filtered.forEach((workshop) => {
            if (workshop.latitude == null || workshop.longitude == null) {
                return;
            }

            const placemark = buildPlacemark(workshop, workshop.id === selectedWorkshopId);
            placemark.events.add('click', () => {
                void selectWorkshop(workshop.id, false);
            });
            geoObjectCollection.add(placemark);
            points.push([workshop.latitude, workshop.longitude]);
        });

        if (preserveViewport) {
            return;
        }

        if (points.length === 1) {
            readyMap.setCenter(points[0], 14, { duration: 250 });
            hasFittedInitialBounds = true;
            return;
        }

        const bounds = geoObjectCollection ? geoObjectCollection.getBounds() : null;
        if (points.length > 1 && bounds) {
            readyMap.setBounds(bounds, {
                checkZoomRange: true,
                zoomMargin: 28,
                duration: 250,
            });
            hasFittedInitialBounds = true;
            return;
        }

        if (!hasFittedInitialBounds) {
            readyMap.setCenter(defaultCenter, 11, { duration: 250 });
            hasFittedInitialBounds = true;
        }
    }

    async function selectWorkshop(id, scrollIntoView) {
        if (selectedWorkshopId === id) {
            clearSelection();
            return;
        }

        selectedWorkshopId = id;
        const filtered = applyFilters();
        const workshop = filtered.find((item) => item.id === id) || workshops.find((item) => item.id === id);

        renderList(filtered);
        renderMapPanel(workshop);
        await renderMap(filtered, {
            preserveViewport: !scrollIntoView,
        });

        if (scrollIntoView && workshop?.latitude != null && workshop?.longitude != null && map) {
            map.setCenter([workshop.latitude, workshop.longitude], 14, { duration: 300 });
        }

        if (scrollIntoView) {
            document.querySelector(`[data-id="${CSS.escape(id)}"]`)?.scrollIntoView({
                behavior: 'smooth',
                block: 'center',
            });
        }
    }

    function clearSelection() {
        selectedWorkshopId = null;
        const filtered = applyFilters();
        renderList(filtered);
        renderMapPanel(null);
        void renderMap(filtered, {
            preserveViewport: true,
        });
    }

    async function refreshUi(options = {}) {
        const {
            refitBounds = false,
        } = options;
        const filtered = applyFilters();
        if (selectedWorkshopId && !filtered.some((item) => item.id === selectedWorkshopId)) {
            selectedWorkshopId = null;
        }
        renderList(filtered);
        renderMapPanel(filtered.find((item) => item.id === selectedWorkshopId) || null);
        await renderMap(filtered, {
            preserveViewport: !refitBounds && hasFittedInitialBounds,
        });
    }

    async function bootstrap() {
        try {
            const response = await fetch(workshopApiEndpoint, { headers: { Accept: 'application/json' } });
            if (response.ok) {
                const apiPayload = await response.json();
                if (Array.isArray(apiPayload.data)) {
                    workshops = apiPayload.data.map((item) => ({
                        ...item,
                        rating: Number(item.rating || 0).toFixed(1),
                        reviewCount: Number(item.reviewCount || 0),
                        distanceKm: Number(item.distanceKm || 0).toFixed(1),
                        startingPriceLabel: item.startingPrice ? `${Number(item.startingPrice).toLocaleString('ru-RU')} so'm` : 'Narx so‘rov asosida',
                        fullDescription: item.description || '',
                        imageUrl: item.imageUrl || '',
                        serviceNames: (item.services || []).slice(0, 4).map((service) => service.name || ''),
                        detailUrl: `/workshop/${encodeURIComponent(item.id)}`,
                        routeUrl: yandexRouteUrl(item.latitude, item.longitude),
                    }));
                }
            }
        } catch (error) {
            console.warn('Workshop API ishlamadi, fallback data ishlatilmoqda.', error);
        }

        document.getElementById('searchInput').addEventListener('input', () => {
            void refreshUi({ refitBounds: true });
        });
        document.getElementById('serviceFilter').addEventListener('change', () => {
            void refreshUi({ refitBounds: true });
        });
        document.getElementById('openOnly').addEventListener('change', () => {
            void refreshUi({ refitBounds: true });
        });

        await refreshUi({ refitBounds: true });
    }

    void bootstrap();
})();
