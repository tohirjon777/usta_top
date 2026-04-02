(function () {
    function formatMoney(value) {
        const amount = Number(value || 0);
        return `${amount.toLocaleString('ru-RU')} so'm`;
    }

    function yandexRouteUrl(latitude, longitude) {
        if (latitude == null || longitude == null) {
            return '#';
        }

        return `https://yandex.com/maps/?rtext=~${latitude},${longitude}&rtt=auto`;
    }

    function garageMarkerDataUrl(options = {}) {
        const {
            isSelected = false,
        } = options;
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

    window.UstaTopCustomer = {
        formatMoney,
        yandexRouteUrl,
        garageMarkerDataUrl,
    };
})();
