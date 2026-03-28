# Usta Top Backend

Diqqat: bu papkadagi Dart backend endi legacy arxiv hisoblanadi.
Loyiha uchun faol backend Laravel variantidir:

- [backend_laravel](/Users/tokhiriy/Downloads/mobile_apps/usta_top/backend_laravel)
- [backend_laravel/README_USTATOP.md](/Users/tokhiriy/Downloads/mobile_apps/usta_top/backend_laravel/README_USTATOP.md)

Kundalik ishga tushirish uchun faqat shularni ishlating:

```bash
cd /Users/tokhiriy/Downloads/mobile_apps/usta_top
./backend_service.sh install
./run_dev.sh
```

Quyidagi qolgan matnlar eski Dart backend uchun tarixiy ma'lumot sifatida qoldirilgan.

## Ishga tushirish

```bash
cd backend
dart pub get
dart run bin/server.dart
```

Server default holatda `http://0.0.0.0:8080` da ishga tushadi.

`HOST` va `PORT` o'zgaruvchilari bilan manzilni almashtirish mumkin:

```bash
HOST=127.0.0.1 PORT=9090 dart run bin/server.dart
```

Ustaxona lokatsiyalarini alohida faylga saqlash uchun:

```bash
WORKSHOP_LOCATIONS_FILE=data/workshop_locations.json dart run bin/server.dart
```

Zakazlarni alohida faylga saqlash uchun:

```bash
BOOKINGS_FILE=data/bookings.json dart run bin/server.dart
```

Auth sessiyalarni alohida faylga saqlash uchun:

```bash
AUTH_SESSIONS_FILE=data/auth_sessions.json dart run bin/server.dart
```

Ustaxona kartalarini alohida fayldan yuklash uchun:

```bash
WORKSHOPS_FILE=data/workshops.json dart run bin/server.dart
```

Telegram bot bildirishnomalarini yoqish uchun:

```bash
TELEGRAM_BOT_TOKEN=... dart run bin/server.dart
```

Firebase push notificationni yoqish uchun:

```bash
FIREBASE_SERVICE_ACCOUNT_FILE=secrets/firebase-service-account.json dart run bin/server.dart
```

Yoki service account JSON faylini `backend/secrets/firebase-service-account.json`
nomi bilan joylang. Shunda `backend_service.sh` va `run_service.sh` uni avtomatik
ushlab oladi.

macOS'da terminalsiz avtomatik ishlatish uchun:

```bash
cd ..
./backend_service.sh install
./backend_service.sh status
./backend_service.sh logs
```

Bu service backendning runtime copy'sini
`~/Library/Application Support/UstaTopBackend/runtime` ichida ishlatadi.
Backend kodini yangilaganingizdan keyin `./backend_service.sh restart` qiling.
User login sessiyalari restartdan keyin ham saqlanadi va
`runtime/data/auth_sessions.json` fayliga yoziladi.
Push notification uchun service account JSON absolute path bilan env’da
ko‘rsatilsa, service restartdan keyin ham ishlaydi.

## Login ma'lumotlari (seed)

- Telefon: `+998901234567`
- Parol: `123456`

## Admin sahifa

Brauzerda quyidagi sahifani ochib ustaxona lokatsiyasini taxminiy koordinata bilan kiriting:

```text
http://127.0.0.1:8080/admin/workshops
```

Zakazlar paneli:

```text
http://127.0.0.1:8080/admin/bookings
```

Ustaxona kartasida `Telegram chat ID` maydoni bor. Shu yerga ustaxona egasi
bot bilan yozishgan chat ID ni kiritsangiz, yangi zakaz va status
o'zgarishlarida Telegram xabari yuboriladi.

`Telegram test` tugmasi orqali shu ustaxona uchun test xabar yuborib ko'rish
mumkin.

Admin login default holatda:

- Username: `admin`
- Password: `admin123`

Ularni `ADMIN_USERNAME` va `ADMIN_PASSWORD` bilan almashtirish mumkin.

## Ustaxona egasi kabineti

Ustaxona egasi brauzer orqali quyidagi sahifadan kiradi:

```text
http://127.0.0.1:8080/owner/login
```

Default seed ustaxonalar uchun owner access kodlari:

- `w-1` -> `5252`
- `w-2` -> `0002`
- `w-3` -> `0003`

Admin paneldagi ustaxona kartasida `Usta kirish kodi` maydoni bor. Shu kodni
o'zgartirib saqlasangiz, owner portal ham shu yangi kod bilan ishlaydi.

Yangi ustaxona yaratishda bu maydonni bo'sh qoldirsangiz, backend ustaxona ID
oxirgi 4 raqami asosida kod yaratadi.

Owner kabinetda:

- faqat o'sha ustaxonaga tegishli zakazlar ko'rinadi
- mijoz ismi va telefoni chiqadi
- zakaz statusini `upcoming`, `completed`, `cancelled` ga almashtirish mumkin
- Telegram bot uchun bog'lash kodini yaratish mumkin
- bog'lash muvaffaqiyatli bo'lsa, keyingi zakazlar shu ustaxonaning o'z Telegram chatiga keladi

## Telegram bot sozlamasi

1. Backendni `TELEGRAM_BOT_TOKEN` bilan ishga tushiring
2. Owner portalga kiring: `http://127.0.0.1:8080/owner/login`
3. Ustaxona profilingizga kiring va `Bog'lash kodini yaratish` tugmasini bosing
4. Telegram botga owner portal ko'rsatgan kodni yuboring, masalan:

```bash
/start UT-123456
```

5. Owner portalda `Tekshirish` tugmasini bosing
6. Ulanish muvaffaqiyatli bo'lsa, test xabar keladi va keyingi yangi zakazlar shu chatga yuboriladi

Manual usul ham bor:

1. Botni Telegram'da oching va kamida bir marta `/start` yuboring
2. `chat_id` ni olish uchun:

```bash
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates"
```

3. Chiqqan `chat.id` ni admin paneldagi kerakli ustaxonaga yozing
4. `Telegram test` tugmasini bosib tekshiring

Bot token kodga tikilmagan, faqat environment variable orqali ishlatiladi.

Bu sahifa `latitude` va `longitude` qiymatlarini yangilaydi va ularni
`data/workshop_locations.json` fayliga saqlab qo'yadi. Backend qayta ishga
tushganda ham shu qiymatlar qayta yuklanadi.

Zakazlar `data/bookings.json` fayliga yoziladi. `admin/bookings` sahifasida
mijoz, telefon, servis, vaqt va status ko'rinadi. Ustaxona kartasidan shu
servisning filtrlangan zakazlar inboxiga o'tish ham mumkin.

## Endpointlar

- `GET /health`
- `GET /admin`
- `GET /admin/login`
- `GET /admin/workshops`
- `GET /admin/bookings`
- `POST /admin/login`
- `POST /admin/logout`
- `POST /admin/bookings/:id/status`
- `POST /admin/workshops`
- `POST /admin/workshops/:id/update`
- `POST /admin/workshops/:id/delete`
- `POST /admin/workshops/:id/telegram/test`
- `POST /admin/workshops/:id/location`
- `GET /owner`
- `GET /owner/login`
- `POST /owner/login`
- `POST /owner/logout`
- `GET /owner/bookings`
- `POST /owner/telegram/generate`
- `POST /owner/telegram/check`
- `POST /owner/telegram/disconnect`
- `POST /owner/bookings/:id/status`
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/forgot-password`
- `POST /auth/push-token` (Bearer token kerak)
- `POST /auth/push-token/remove` (Bearer token kerak)
- `GET /auth/me` (Bearer token kerak)
- `PATCH /auth/me` (Bearer token kerak)
- `PATCH /auth/me/password` (Bearer token kerak)
- `GET /workshops` (Bearer token kerak)
- `GET /workshops/:id` (Bearer token kerak)
- `GET /bookings` (Bearer token kerak)
- `POST /bookings` (Bearer token kerak)
- `PATCH /bookings/:id/cancel` (Bearer token kerak)

## Arxitektura (Controller Skeleton)

Backend kodi controller/middleware ko'rinishida ajratilgan:

- `lib/src/controllers/auth_controller.dart`
- `lib/src/controllers/workshop_controller.dart`
- `lib/src/controllers/booking_controller.dart`
- `lib/src/controllers/health_controller.dart`
- `lib/src/auth_middleware.dart`
- `lib/src/http_helpers.dart`

`router.dart` faqat route ulash bilan shug'ullanadi.

## Tezkor sinov (curl)

```bash
# 1) Login
curl -X POST http://127.0.0.1:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+998901234567","password":"123456"}'
```

Login javobidan `token` ni olib:

```bash
# 2) Servislar ro'yxati
curl http://127.0.0.1:8080/workshops \
  -H "Authorization: Bearer <TOKEN>"
```

```bash
# 3) Buyurtma yaratish
curl -X POST http://127.0.0.1:8080/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "workshopId": "w-1",
    "serviceId": "srv-1",
    "dateTime": "2026-03-20T11:00:00.000Z"
  }'
```
