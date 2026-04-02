(function () {
    const dataNode = document.getElementById('customer-workshop-data');
    if (!dataNode) {
        return;
    }

    const payload = JSON.parse(dataNode.textContent || '{}');
    const workshop = payload.workshop || {};
    const savedVehicles = Array.isArray(payload.savedVehicles) ? payload.savedVehicles : [];
    const hasCustomer = !!payload.currentCustomer;
    const defaultCenter = [41.3111, 69.2797];

    function formatUzs(value) {
        const amount = Number(value || 0);
        return `${amount.toLocaleString('ru-RU')} so'm`;
    }

    function initMap() {
        const mapNode = document.getElementById('detailMap');
        if (!mapNode) {
            return;
        }

        if (!window.ymaps) {
            mapNode.innerHTML = '<div class="map-fallback">Yandex Maps yuklanmadi. API key yoki script holatini tekshiring.</div>';
            return;
        }

        window.ymaps.ready(() => {
            const map = new window.ymaps.Map('detailMap', {
                center: defaultCenter,
                zoom: 11,
                controls: [],
            }, {
                suppressMapOpenBlock: true,
            });

            if (workshop.latitude != null && workshop.longitude != null) {
                const marker = new window.ymaps.Placemark(
                    [workshop.latitude, workshop.longitude],
                    {
                        hintContent: workshop.name,
                    },
                    {
                        iconLayout: 'default#image',
                        iconImageHref: markerDataUrl(),
                        iconImageSize: [58, 72],
                        iconImageOffset: [-29, -72],
                        hideIconOnBalloonOpen: false,
                    }
                );
                map.geoObjects.add(marker);
                map.setCenter([workshop.latitude, workshop.longitude], 14, { duration: 250 });
            } else {
                map.setCenter(defaultCenter, 11, { duration: 250 });
            }
        });
    }

    function markerDataUrl() {
        const svg = `
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="80" viewBox="0 0 64 80" fill="none">
                <path d="M32 78C32 78 56 52.5 56 31C56 16.6406 45.3594 6 32 6C18.6406 6 8 16.6406 8 31C8 52.5 32 78 32 78Z" fill="#0f766e" stroke="#ffffff" stroke-width="3"/>
                <rect x="20" y="24" width="24" height="18" rx="4" fill="white" opacity="0.98"/>
                <path d="M16 42L22 36.5H42L48 42V48C48 49.6569 46.6569 51 45 51H19C17.3431 51 16 49.6569 16 48V42Z" fill="white" opacity="0.98"/>
                <circle cx="24" cy="48" r="4" fill="#0f766e"/>
                <circle cx="40" cy="48" r="4" fill="#0f766e"/>
            </svg>
        `;

        return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
    }

    function initBookingForm() {
        if (!hasCustomer) {
            return;
        }

        const serviceField = document.getElementById('bookingService');
        const dateField = document.getElementById('bookingDate');
        const timeField = document.getElementById('bookingTime');
        const typeField = document.getElementById('vehicleTypeId');
        const brandField = document.getElementById('vehicleBrand');
        const modelField = document.getElementById('vehicleModelName');
        const savedVehicleField = document.getElementById('savedVehicleSelect');
        const paymentMethodField = document.getElementById('paymentMethod');
        const availabilityHint = document.getElementById('bookingAvailabilityHint');
        const savedCardsHint = document.getElementById('savedCardsHint');
        const quoteBase = document.getElementById('quoteBase');
        const quotePrice = document.getElementById('quotePrice');
        const quotePrepayment = document.getElementById('quotePrepayment');
        const quoteRemaining = document.getElementById('quoteRemaining');
        const quoteDuration = document.getElementById('quoteDuration');

        if (!serviceField || !dateField || !timeField || !typeField || !brandField || !modelField) {
            return;
        }

        async function fetchJson(url) {
            const response = await fetch(url, { headers: { Accept: 'application/json' } });
            if (!response.ok) {
                const payload = await response.json().catch(() => ({}));
                throw new Error(payload.error || 'So‘rovda xatolik yuz berdi');
            }

            return response.json();
        }

        async function populateNearestAvailability() {
            const serviceId = serviceField.value;
            if (!serviceId) {
                timeField.innerHTML = '<option value="">Avval xizmatni tanlang</option>';
                availabilityHint.textContent = 'Avval xizmatni tanlang.';
                return;
            }

            try {
                const url = `/workshops/${encodeURIComponent(workshop.id)}/availability/calendar?serviceId=${encodeURIComponent(serviceId)}&from=${encodeURIComponent(new Date().toISOString().slice(0, 10))}&days=14`;
                const response = await fetchJson(url);
                const data = response.data || {};
                if (data.nearestAvailableDate) {
                    dateField.value = data.nearestAvailableDate;
                    await populateSlots();
                    if (data.nearestAvailableTime) {
                        timeField.value = data.nearestAvailableTime;
                    }
                    availabilityHint.textContent = `Eng yaqin bo‘sh vaqt: ${data.nearestAvailableDate} ${data.nearestAvailableTime || ''}`.trim();
                } else {
                    timeField.innerHTML = '<option value="">Bo‘sh vaqt topilmadi</option>';
                    availabilityHint.textContent = 'Hozircha bo‘sh vaqt topilmadi.';
                }
            } catch (error) {
                availabilityHint.textContent = error.message;
            }
        }

        async function populateSlots() {
            const serviceId = serviceField.value;
            const date = dateField.value;
            if (!serviceId || !date) {
                timeField.innerHTML = '<option value="">Avval xizmat va sanani tanlang</option>';
                return;
            }

            try {
                const url = `/workshops/${encodeURIComponent(workshop.id)}/availability?serviceId=${encodeURIComponent(serviceId)}&date=${encodeURIComponent(date)}`;
                const response = await fetchJson(url);
                const data = response.data || {};
                const allSlots = Array.isArray(data.allSlots) ? data.allSlots : [];

                if (!allSlots.length) {
                    timeField.innerHTML = '<option value="">Bo‘sh vaqt topilmadi</option>';
                    availabilityHint.textContent = data.isClosedDay
                        ? 'Tanlangan sana dam olish kuni.'
                        : 'Tanlangan sana uchun bo‘sh vaqt topilmadi.';
                    return;
                }

                const options = ['<option value="">Vaqtni tanlang</option>'];
                allSlots.forEach((slot) => {
                    const state = slot.isAvailable ? '' : 'disabled';
                    const suffix = slot.isPast ? ' (o‘tib ketgan)' : (slot.reason === 'booked' ? ' (band)' : '');
                    options.push(`<option value="${slot.time}" ${state}>${slot.time}${suffix}</option>`);
                });
                timeField.innerHTML = options.join('');

                const firstAvailable = allSlots.find((slot) => slot.isAvailable);
                if (firstAvailable) {
                    timeField.value = firstAvailable.time;
                    availabilityHint.textContent = `Bo‘sh slotlar yuklandi. Birinchi bo‘sh vaqt: ${firstAvailable.time}`;
                } else {
                    availabilityHint.textContent = 'Faqat band yoki o‘tgan slotlar mavjud.';
                }
            } catch (error) {
                timeField.innerHTML = '<option value="">Slotlar yuklanmadi</option>';
                availabilityHint.textContent = error.message;
            }
        }

        async function refreshQuote() {
            const serviceId = serviceField.value;
            if (!serviceId) {
                quoteBase.textContent = '—';
                quotePrice.textContent = '—';
                quotePrepayment.textContent = '—';
                quoteRemaining.textContent = '—';
                quoteDuration.textContent = '—';
                return;
            }

            try {
                const params = new URLSearchParams({
                    serviceId,
                    vehicleBrand: brandField.value.trim(),
                    vehicleModelName: modelField.value.trim(),
                    vehicleTypeId: typeField.value,
                });
                const response = await fetchJson(`/workshops/${encodeURIComponent(workshop.id)}/price-quote?${params.toString()}`);
                const data = response.data || {};
                quoteBase.textContent = formatUzs(data.basePrice);
                quotePrice.textContent = formatUzs(data.price);
                quotePrepayment.textContent = `${formatUzs(data.prepaymentAmount)}${data.prepaymentPercent ? ` (${data.prepaymentPercent}%)` : ''}`;
                quoteRemaining.textContent = formatUzs(data.remainingAmount);
                quoteDuration.textContent = `${data.serviceDurationMinutes || 30} daqiqa`;
            } catch (error) {
                quoteBase.textContent = '—';
                quotePrice.textContent = '—';
                quotePrepayment.textContent = '—';
                quoteRemaining.textContent = '—';
                quoteDuration.textContent = '—';
            }
        }

        if (savedVehicleField) {
            savedVehicleField.addEventListener('change', () => {
                if (!savedVehicleField.value) {
                    return;
                }

                try {
                    const vehicle = JSON.parse(savedVehicleField.value);
                    brandField.value = vehicle.brand || '';
                    modelField.value = vehicle.model || '';
                    if (vehicle.vehicleTypeId) {
                        typeField.value = vehicle.vehicleTypeId;
                    }
                    refreshQuote();
                } catch (error) {
                    console.warn('Saved vehicle parse xatosi', error);
                }
            });
        }

        if (paymentMethodField && savedCardsHint) {
            const toggleCardsHint = () => {
                savedCardsHint.style.display = paymentMethodField.value === 'test_card' ? 'block' : 'none';
            };
            paymentMethodField.addEventListener('change', toggleCardsHint);
            toggleCardsHint();
        }

        serviceField.addEventListener('change', async () => {
            await populateNearestAvailability();
            await refreshQuote();
        });
        dateField.addEventListener('change', populateSlots);
        typeField.addEventListener('change', refreshQuote);
        brandField.addEventListener('input', refreshQuote);
        modelField.addEventListener('input', refreshQuote);

        if (serviceField.value) {
            populateNearestAvailability();
            refreshQuote();
        }
    }

    initMap();
    initBookingForm();
})();
