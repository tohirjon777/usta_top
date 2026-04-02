# Forge Setup

Bu fayl Forge ichida aynan nimalarni kiritishni tez va aniq ko'rsatadi.

## 1. Forge server

- Provider: `Hetzner`
- Server type: `App Server`
- OS: `Ubuntu 24.04`
- PHP: `8.3`
- Database: `PostgreSQL`

Tavsiya:
- `2 vCPU`
- `4 GB RAM`
- `40 GB SSD`

## 2. Forge site

Site yaratishda:
- Domain: `api.sizning-domain.uz`
- Branch: `main`
- Web Directory: `/backend_laravel/public`

Muhim:
- repo root `usta_top`
- Laravel app esa `backend_laravel`

Shuning uchun web directory albatta `/backend_laravel/public` bo'lishi kerak.

## 3. PostgreSQL tayyorlash

Forge serverga SSH bilan kirib:

```bash
sudo -u postgres psql -f /home/forge/api.sizning-domain.uz/backend_laravel/deploy/forge/postgres-init.sql
```

Yoki qo'lda:

```bash
sudo -u postgres psql
CREATE DATABASE ustatop;
CREATE USER ustatop WITH PASSWORD 'CHANGE_ME';
GRANT ALL PRIVILEGES ON DATABASE ustatop TO ustatop;
\q
```

## 4. Forge Environment

Forge Site > Environment ga quyidagini qo'ying.
Tayyor nusxa:
- `deploy/forge/forge-production.env.example`
- generator script:
  - `deploy/forge/generate_env.sh`

Masalan lokal kompyuteringizda tayyor env chiqarish:

```bash
cd backend_laravel/deploy/forge
./generate_env.sh \
  --domain api.sizning-domain.uz \
  --db-password 'CHANGE_ME' \
  --telegram-token 'YOUR_TELEGRAM_BOT_TOKEN' \
  --sms-token 'YOUR_DEVSMS_TOKEN'
```

Bu sizga Forge > Environment ga qo'yadigan final `.env` matnini chiqaradi.

Minimal kerakli qiymatlar:

```env
APP_NAME="Usta Top"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.sizning-domain.uz

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=ustatop
DB_USERNAME=ustatop
DB_PASSWORD=CHANGE_ME
DB_SSLMODE=prefer

USTATOP_STORAGE_DRIVER=database
USTATOP_STORAGE_DB_CONNECTION=pgsql
USTATOP_STORAGE_DB_TABLE=ustatop_json_documents

ADMIN_USERNAME=admin
ADMIN_PASSWORD=CHANGE_ME
TELEGRAM_BOT_TOKEN=

SMS_DRIVER=devsms
SMS_BASE_URL=https://devsms.uz/api
SMS_BEARER_TOKEN=
SMS_SERVICE_NAME="Usta Top"
```

## 5. Deploy script

Forge Site > Deployments > Deploy Script ichiga:

```bash
#!/bin/bash

set -euo pipefail

cd "$FORGE_SITE_PATH/backend_laravel"

$FORGE_PHP artisan down || true

composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

$FORGE_PHP artisan migrate --force
$FORGE_PHP artisan ustatop:bootstrap-storage
$FORGE_PHP artisan ustatop:doctor

$FORGE_PHP artisan optimize:clear
$FORGE_PHP artisan config:cache
$FORGE_PHP artisan route:cache
$FORGE_PHP artisan view:cache

$FORGE_PHP artisan up || true
```

Tayyor fayl:
- `deploy/forge/deploy.sh`

## 5.1 Serverdagi birinchi papkalar

Deploydan oldin Forge serverda bir marta ishga tushiring:

```bash
cd /home/forge/api.sizning-domain.uz/backend_laravel/deploy/forge
bash first_boot.sh
```

Tayyor fayl:
- `deploy/forge/first_boot.sh`

## 6. Daemon

Forge Site > Daemons > Create Daemon:

- Command:

```bash
cd /home/forge/REPLACE_WITH_FORGE_SITE_DIRECTORY/backend_laravel && php artisan ustatop:telegram-poll
```

- Processes: `1`
- Directory: `/home/forge/REPLACE_WITH_FORGE_SITE_DIRECTORY/backend_laravel`

Misol:
- site directory `api.sizning-domain.uz` bo'lsa:

```bash
cd /home/forge/api.sizning-domain.uz/backend_laravel && php artisan ustatop:telegram-poll
```

Tayyor fayl:
- `deploy/forge/daemon-telegram-poll.txt`

## 7. Birinchi deploydan keyin tekshiruv

Tekshirish:

```bash
curl -fsS https://api.sizning-domain.uz/health
```

Kutiladigan natija:

```json
{"ok":true}
```

## 8. Qo'lda smoke test

Tekshiring:
- `/health`
- `/`
- `/customer/login`
- `/workshops`
- `php artisan ustatop:doctor`

## 9. Eslatma

- lokalda backup/restore hali SQLite commandlari bilan ishlaydi
- production PostgreSQL uchun backup:

```bash
pg_dump -Fc -h 127.0.0.1 -U ustatop ustatop > /var/backups/ustatop-$(date +%Y%m%d-%H%M%S).dump
```

- restore:

```bash
pg_restore -d ustatop /var/backups/ustatop-YYYYMMDD-HHMMSS.dump
```
