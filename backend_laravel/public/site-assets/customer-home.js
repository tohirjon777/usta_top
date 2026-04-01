(function () {
    const dataNode = document.getElementById('customer-home-data');
    if (!dataNode) {
        return;
    }

    const payload = JSON.parse(dataNode.textContent || '{}');
    const workshopApiEndpoint = payload.apiEndpoint || '/workshops';
    const fallbackWorkshops = Array.isArray(payload.initialWorkshops) ? payload.initialWorkshops : [];

    let workshops = fallbackWorkshops;
    let selectedWorkshopId = fallbackWorkshops[0]?.id ?? null;
    let map = null;
    let markers = [];

    function routeLink(workshop) {
        if (workshop.routeUrl) {
            return workshop.routeUrl;
        }
        if (workshop.latitude == null || workshop.longitude == null) {
            return '#';
        }
        return `https://www.google.com/maps/dir/?api=1&destination=${workshop.latitude},${workshop.longitude}`;
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

        if (!filtered.some((item) => item.id === selectedWorkshopId)) {
            selectedWorkshopId = filtered[0].id;
        }

        container.innerHTML = filtered.map(cardTemplate).join('');
        container.querySelectorAll('[data-id]').forEach((card) => {
            card.addEventListener('click', () => {
                selectWorkshop(card.dataset.id, true);
            });
        });
    }

    function renderMap(filtered) {
        if (!map) {
            map = L.map('workshopMap', { scrollWheelZoom: true });
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap contributors',
            }).addTo(map);
        }

        markers.forEach((marker) => marker.remove());
        markers = [];

        const bounds = [];
        filtered.forEach((workshop) => {
            if (workshop.latitude == null || workshop.longitude == null) {
                return;
            }

            const marker = L.marker([workshop.latitude, workshop.longitude]).addTo(map);
            marker.on('click', () => selectWorkshop(workshop.id, false));
            markers.push(marker);
            bounds.push([workshop.latitude, workshop.longitude]);
        });

        if (bounds.length) {
            map.fitBounds(bounds, { padding: [28, 28] });
        } else {
            map.setView([41.3111, 69.2797], 11);
        }
    }

    function renderMapPanel(workshop) {
        const panel = document.getElementById('mapPanel');
        if (!workshop) {
            panel.className = 'map-panel map-empty';
            panel.innerHTML = 'Xaritadan marker tanlang. Shu yerda ustaxona tavsifi va marshrut tugmasi chiqadi.';
            return;
        }

        panel.className = 'map-panel';
        panel.innerHTML = `
            <div class="badge-row" style="margin-bottom:10px;">
                <span class="pill ${workshop.isOpen ? 'status-open' : 'status-closed'}">${workshop.isOpen ? 'Ochiq' : 'Yopiq'}</span>
                ${workshop.badge ? `<span class="pill">${workshop.badge}</span>` : ''}
                <span class="pill muted">⭐ ${workshop.rating}</span>
            </div>
            <h3 style="margin:0 0 8px; font-size:24px;">${workshop.name}</h3>
            <p style="margin:0 0 10px; color:var(--muted); line-height:1.6;">${workshop.fullDescription || workshop.description || ''}</p>
            <div class="meta-row" style="margin-bottom:12px;">
                <span class="pill muted">${workshop.address || 'Manzil ko‘rsatilmagan'}</span>
                <span class="pill muted">Boshlanishi: ${workshop.startingPriceLabel}</span>
            </div>
            <div class="actions-row">
                <a class="button-secondary" href="${workshop.detailUrl}">Ustaxona sahifasi</a>
                <a class="button" href="${routeLink(workshop)}" target="_blank" rel="noreferrer">Marshrut</a>
            </div>
        `;
    }

    function selectWorkshop(id, scrollIntoView) {
        selectedWorkshopId = id;
        const filtered = applyFilters();
        const workshop = filtered.find((item) => item.id === id) || workshops.find((item) => item.id === id);
        renderList(filtered);
        renderMap(filtered);
        renderMapPanel(workshop);

        if (workshop?.latitude != null && workshop?.longitude != null && map) {
            map.flyTo([workshop.latitude, workshop.longitude], Math.max(map.getZoom(), 13), { duration: 0.6 });
        }

        if (scrollIntoView) {
            document.querySelector(`[data-id="${CSS.escape(id)}"]`)?.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    function refreshUi() {
        const filtered = applyFilters();
        renderList(filtered);
        renderMap(filtered);
        renderMapPanel(filtered.find((item) => item.id === selectedWorkshopId) || filtered[0] || null);
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
                        startingPriceLabel: item.startingPrice ? `${Number(item.startingPrice).toLocaleString('ru-RU')} UZS` : 'Narx so‘rov asosida',
                        fullDescription: item.description || '',
                        imageUrl: item.imageUrl || '',
                        serviceNames: (item.services || []).slice(0, 4).map((service) => service.name || ''),
                        detailUrl: `/workshop/${encodeURIComponent(item.id)}`,
                        routeUrl: item.latitude != null && item.longitude != null
                            ? `https://www.google.com/maps/dir/?api=1&destination=${item.latitude},${item.longitude}`
                            : null,
                    }));
                }
            }
        } catch (error) {
            console.warn('Workshop API ishlamadi, fallback data ishlatilmoqda.', error);
        }

        document.getElementById('searchInput').addEventListener('input', refreshUi);
        document.getElementById('serviceFilter').addEventListener('change', refreshUi);
        document.getElementById('openOnly').addEventListener('change', refreshUi);
        refreshUi();
    }

    bootstrap();
})();

