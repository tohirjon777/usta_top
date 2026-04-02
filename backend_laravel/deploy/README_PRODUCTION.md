# Usta Top Production Deploy

Bu loyiha uchun tunnel yoki lokal Mac emas, alohida Linux server eng to'g'ri yechim.

Nega:
- public URL o'zgarmaydi
- telefon internet orqali doim ulanadi
- Mac yoqilib turishi shart emas
- workshop rasmlari, bookinglar va database bir joyda saqlanadi

Tavsiya etilgan arxitektura:
- 1 ta Ubuntu VPS
- Nginx
- PHP 8.3 FPM
- Composer
- PostgreSQL 16+
- systemd orqali Telegram poller
- bitta persistent disk yoki serverning o'z local diskida ma'lumotlar

Muhim:
- lokalda backend SQLite bilan ishlaydi
- production uchun PostgreSQL tavsiya qilinadi
- repository storage qatlami `USTATOP_STORAGE_DRIVER=database` bilan PostgreSQL/MySQL ustida ishlay oladi
- boshlang'ich seed/import manbasi sifatida JSON fayllar ishlatiladi
- shu sabab eng barqaror variant: bitta server
- multi-instance autoscaling hozircha tavsiya qilinmaydi

## Tavsiya etilgan kataloglar

- Kod: `/var/www/ustatop/backend_laravel`
- Data: `/var/lib/ustatop/data`
- PostgreSQL DB: `ustatop`
- Workshop rasmlar: `/var/lib/ustatop/workshop-images`
- Auth session storage: `/var/lib/ustatop/storage/auth_sessions.json`
- Telegram sync state: `/var/lib/ustatop/storage/telegram_sync_state.json`

## Serverga o'rnatiladigan paketlar

Ubuntu 24.04 misol:

```bash
sudo apt update
sudo apt install -y nginx git unzip curl postgresql postgresql-contrib php8.3 php8.3-fpm php8.3-cli php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-bcmath php8.3-intl php8.3-pgsql composer
```

## Deploy bosqichlari

```bash
sudo mkdir -p /var/www/ustatop /var/lib/ustatop/data /var/lib/ustatop/storage /var/lib/ustatop/workshop-images
sudo chown -R $USER:www-data /var/www/ustatop /var/lib/ustatop
cd /var/www/ustatop
git clone <REPO_URL> .
cd backend_laravel
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
```

So'ng `.env` ichida:
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://api.sizning-domain.uz`
- `DB_CONNECTION=pgsql`
- `DB_HOST=127.0.0.1`
- `DB_PORT=5432`
- `DB_DATABASE=ustatop`
- `DB_USERNAME=ustatop`
- `DB_PASSWORD=...`
- `USTATOP_STORAGE_DRIVER=database`
- `USTATOP_STORAGE_DB_CONNECTION=pgsql`
- `USTATOP_STORAGE_DB_TABLE=ustatop_json_documents`
- `USTATOP_DATA_DIR=/var/lib/ustatop/data`
- `USTATOP_USERS_FILE=/var/lib/ustatop/data/users.json`
- `USTATOP_WORKSHOPS_FILE=/var/lib/ustatop/data/workshops.json`
- `USTATOP_BOOKINGS_FILE=/var/lib/ustatop/data/bookings.json`
- `USTATOP_REVIEWS_FILE=/var/lib/ustatop/data/reviews.json`
- `USTATOP_BOOKING_MESSAGES_FILE=/var/lib/ustatop/data/booking_messages.json`
- `USTATOP_WORKSHOP_LOCATIONS_FILE=/var/lib/ustatop/data/workshop_locations.json`
- `USTATOP_AUTH_SESSIONS_FILE=/var/lib/ustatop/storage/auth_sessions.json`
- `USTATOP_SMS_VERIFICATIONS_FILE=/var/lib/ustatop/storage/sms_verifications.json`
- `USTATOP_TELEGRAM_SYNC_STATE_FILE=/var/lib/ustatop/storage/telegram_sync_state.json`
- `USTATOP_WORKSHOP_IMAGES_DIR=/var/lib/ustatop/workshop-images`
- `ADMIN_USERNAME=admin`
- `ADMIN_PASSWORD=admin123`
- `TELEGRAM_BOT_TOKEN=...`
- `SMS_DRIVER=devsms`
- `SMS_BEARER_TOKEN=...`

Keyin:

```bash
sudo -u postgres psql <<'SQL'
CREATE DATABASE ustatop;
CREATE USER ustatop WITH PASSWORD 'change-me';
GRANT ALL PRIVILEGES ON DATABASE ustatop TO ustatop;
SQL

php artisan ustatop:bootstrap-storage
php artisan ustatop:doctor
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Forge deploy

Forge uchun tayyor fayllar:
- `deploy/forge/deploy.sh`
- `deploy/forge/daemon-telegram-poll.txt`
- `deploy/forge/FORGE_SETUP.md`

Forge site deploy script ichiga `deploy/forge/deploy.sh` ichidagi buyruqlarni qo'ying.
Forge daemon command sifatida esa `deploy/forge/daemon-telegram-poll.txt` dagi buyruqni ishlating.

## Nginx

Tayyor config:
- `deploy/nginx/ustatop.conf`

Serverga joylash:

```bash
sudo cp deploy/nginx/ustatop.conf /etc/nginx/sites-available/ustatop
sudo ln -s /etc/nginx/sites-available/ustatop /etc/nginx/sites-enabled/ustatop
sudo nginx -t
sudo systemctl reload nginx
```

## Telegram poller

Tayyor service:
- `deploy/systemd/ustatop-telegram-poll.service`

Serverga joylash:

```bash
sudo cp deploy/systemd/ustatop-telegram-poll.service /etc/systemd/system/ustatop-telegram-poll.service
sudo systemctl daemon-reload
sudo systemctl enable --now ustatop-telegram-poll.service
sudo systemctl status ustatop-telegram-poll.service
```

## Fayl huquqlari

```bash
sudo chown -R www-data:www-data /var/lib/ustatop
sudo chown -R www-data:www-data /var/www/ustatop/backend_laravel/storage /var/www/ustatop/backend_laravel/bootstrap/cache
sudo chmod -R ug+rw /var/www/ustatop/backend_laravel/storage /var/www/ustatop/backend_laravel/bootstrap/cache
```

## SSL

Domain tayyor bo'lsa:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.sizning-domain.uz
```

## Telefon app uchun

Shundan keyin appga bitta doimiy URL berasiz:

```text
https://api.sizning-domain.uz
```

Tunnel kerak bo'lmaydi.

## Backup

- SQLite local backup commandlari production PostgreSQL uchun ishlatilmaydi
- PostgreSQL uchun `pg_dump` va `pg_restore` ishlating

Misol:

```bash
pg_dump -Fc -h 127.0.0.1 -U ustatop ustatop > /var/backups/ustatop-$(date +%Y%m%d-%H%M%S).dump
pg_restore -d ustatop /var/backups/ustatop-YYYYMMDD-HHMMSS.dump
```

## Doctor

Deploydan keyin yoki muammo qidirayotganda:

```bash
php artisan ustatop:doctor
php artisan ustatop:doctor --json
```
