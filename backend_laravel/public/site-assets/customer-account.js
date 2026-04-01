(function () {
    const dataNode = document.getElementById('customer-account-data');
    if (!dataNode) {
        return;
    }

    function fetchJson(url) {
        return fetch(url, { headers: { Accept: 'application/json' } })
            .then(async (response) => {
                if (!response.ok) {
                    const payload = await response.json().catch(() => ({}));
                    throw new Error(payload.error || 'So‘rovda xatolik yuz berdi');
                }

                return response.json();
            });
    }

    document.querySelectorAll('.js-reschedule-form').forEach((form) => {
        const dateField = form.querySelector('input[name="bookingDate"]');
        const timeField = document.getElementById(form.dataset.timeTarget || '');
        const hintField = document.getElementById(form.dataset.hintTarget || '');
        const workshopId = form.dataset.workshopId || '';
        const serviceId = form.dataset.serviceId || '';

        if (!dateField || !timeField || !workshopId || !serviceId) {
            return;
        }

        const loadSlots = async () => {
            if (!dateField.value) {
                timeField.innerHTML = '<option value="">Avval sanani tanlang</option>';
                return;
            }

            try {
                const url = `/workshops/${encodeURIComponent(workshopId)}/availability?serviceId=${encodeURIComponent(serviceId)}&date=${encodeURIComponent(dateField.value)}`;
                const response = await fetchJson(url);
                const data = response.data || {};
                const allSlots = Array.isArray(data.allSlots) ? data.allSlots : [];

                if (!allSlots.length) {
                    timeField.innerHTML = '<option value="">Bo‘sh vaqt topilmadi</option>';
                    if (hintField) {
                        hintField.textContent = data.isClosedDay
                            ? 'Tanlangan sana dam olish kuni.'
                            : 'Tanlangan sana uchun bo‘sh slot topilmadi.';
                    }
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
                }
                if (hintField) {
                    hintField.textContent = firstAvailable
                        ? `Bo‘sh vaqtlar yuklandi. Birinchi bo‘sh slot: ${firstAvailable.time}`
                        : 'Faqat band yoki o‘tgan slotlar mavjud.';
                }
            } catch (error) {
                timeField.innerHTML = '<option value="">Slotlar yuklanmadi</option>';
                if (hintField) {
                    hintField.textContent = error.message;
                }
            }
        };

        dateField.addEventListener('change', loadSlots);
    });
})();
