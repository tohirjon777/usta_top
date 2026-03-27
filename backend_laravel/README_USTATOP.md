# Usta Top Laravel Backend

Bu papka Dart backendni Laravel'ga ko'chirish uchun qo'shilgan.

Hozircha tayyorlangan qismlar:
- JSON fayllar bilan ishlaydigan repository qatlam
- Core API route'lar: /health, /auth, /workshops, /bookings
- Minimal admin web panel: /admin/login, /admin/workshops, /admin/bookings
- Minimal owner web panel: /owner/login, /owner/bookings
- launchd service helper: ../backend_laravel_service.sh

Ishga tushirish:
1. PHP va Composer o'rnatilgan bo'lsin.
2. backend_laravel ichida `.env` yarating: `cp .env.example .env`
3. `composer install`
4. `php artisan key:generate`
5. `php artisan serve --host=127.0.0.1 --port=8080`

Auto service:
- `./backend_laravel_service.sh install`
- `./backend_laravel_service.sh status`
