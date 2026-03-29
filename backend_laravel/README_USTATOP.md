# Usta Top Laravel Backend

Bu loyiha uchun asosiy backend endi shu papka ichidagi Laravel servisidir.
Asosiy JSON ma'lumotlari ham endi shu papkada: `backend_laravel/data`.

Asosiy imkoniyatlar:
- JSON fayllar bilan ishlaydigan repository qatlam
- API: `/health`, `/auth`, `/workshops`, `/bookings`
- Booking availability, price quote, review, booking message endpointlari
- Admin panel: `/admin/login`, `/admin/workshops`, `/admin/bookings`, `/admin/analytics`
- Owner panel: `/owner/login`, `/owner/bookings`
- Telegram: owner link code, admin test xabari, yangi zakaz/status xabarlari
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

Telegram bot:
1. `backend_laravel/.env.local` ichiga `TELEGRAM_BOT_TOKEN=...` yozing
2. `../backend_service.sh restart`
3. Owner panelda `Bog‘lash kodini yaratish`
4. Botga `/start UT-xxxxxx`
5. Owner panelda `Tekshirish`

Shundan keyin yangi zakaz va status o‘zgarishlari shu Telegram chatga yuboriladi.

Eslatma:
- `../backend/` papkasi legacy arxiv sifatida qoldirilgan
- root-level `../backend_service.sh` va `../run_dev.sh` faqat Laravel backendni ishga tushiradi
