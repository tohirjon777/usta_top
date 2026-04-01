# Usta Top Laravel Backend

Bu loyiha uchun asosiy backend endi shu papka ichidagi Laravel servisidir.
Asosiy saqlash qatlam:
- lokal SQLite baza: `backend_laravel/storage/app/ustatop/ustatop.sqlite`
- `backend_laravel/data` esa boshlang'ich import/seed JSON manbasi

Asosiy imkoniyatlar:
- SQLite bazada saqlanadigan repository qatlam
- API: `/health`, `/auth`, `/workshops`, `/bookings`
- Booking availability, price quote, review, booking message endpointlari
- Public customer website: `/`, `/customer/login`, `/customer/account`, `/workshop/{id}`
- Telegram: owner link code, admin test xabari, yangi zakaz/status xabarlari
- Root-level service script: `../backend_service.sh`

Ishga tushirish:
1. PHP va Composer o'rnatilgan bo'lsin.
2. `cp .env.example .env`
3. `composer install`
4. `php artisan key:generate`
5. `php artisan ustatop:bootstrap-storage`
6. `php artisan migrate`
7. `php artisan serve --host=127.0.0.1 --port=8080`

Avtomatik service:
- `../backend_service.sh install`
- `../backend_service.sh status`
- `../backend_service.sh restart`
- `../backend_service.sh backup`
- `../backend_service.sh backups`
- `../backend_service.sh restore <backup_path>`

Dev oqimi:
- `../run_dev.sh`

Telegram bot:
1. `backend_laravel/secrets/local.env` ichiga `TELEGRAM_BOT_TOKEN=...` yozing
2. `../backend_service.sh restart`
3. Runtime workshop ma'lumotida Telegram chat bog'langan bo'lsa, yangi zakaz va status o‘zgarishlari shu chatga yuboriladi.

SMS OTP:
1. `backend_laravel/secrets/local.env` ichiga quyidagini yozing:
   - `SMS_DRIVER=devsms`
   - `SMS_BEARER_TOKEN=...`
   - `SMS_SERVICE_NAME="Usta Top"`
2. `../backend_service.sh restart`
3. Register va parol tiklash oqimi SMS kod bilan ishlaydi.

Eslatma:
- root-level `../backend_service.sh` va `../run_dev.sh` faqat Laravel backendni ishga tushiradi
- keyingi yozuvlar va yangilanishlar SQLite bazaga saqlanadi; JSON fayllar endi seed manbasi sifatida ishlatiladi

Backup va restore:
- artisan backup: `php artisan ustatop:backup-storage`
- artisan restore: `php artisan ustatop:restore-storage /to/backup.sqlite --force`
- service backup folder: `~/Library/Application Support/UstaTopBackend/backups`

Production uchun:
- tunnel yoki lokal Mac o'rniga alohida VPS tavsiya qilinadi
- tayyor production yo'riqnoma: `deploy/README_PRODUCTION.md`
- nginx config: `deploy/nginx/ustatop.conf`
- Telegram poller service: `deploy/systemd/ustatop-telegram-poll.service`
