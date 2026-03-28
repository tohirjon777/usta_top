# Usta Top Laravel Backend

Bu loyiha uchun asosiy backend endi shu papka ichidagi Laravel servisidir.
Asosiy JSON ma'lumotlari ham endi shu papkada: `backend_laravel/data`.

Asosiy imkoniyatlar:
- JSON fayllar bilan ishlaydigan repository qatlam
- API: `/health`, `/auth`, `/workshops`, `/bookings`
- Booking availability, price quote, review, booking message endpointlari
- Admin panel: `/admin/login`, `/admin/workshops`, `/admin/bookings`, `/admin/reviews`
- Owner panel: `/owner/login`, `/owner/bookings`
- Root-level service script: `../backend_service.sh`

Ishga tushirish:
1. PHP va Composer o'rnatilgan bo'lsin.
2. `cp .env.example .env`
3. `composer install`
4. `php artisan key:generate`
5. `php artisan serve --host=127.0.0.1 --port=8080`

Avtomatik service:
- `../backend_service.sh install`
- `../backend_service.sh status`
- `../backend_service.sh restart`

Dev oqimi:
- `../run_dev.sh`

Eslatma:
- `../backend/` papkasi legacy arxiv sifatida qoldirilgan
- root-level `../backend_service.sh` va `../run_dev.sh` faqat Laravel backendni ishga tushiradi
