# Usta Top Backend

Ushbu servis Flutter ilova uchun oddiy REST API backend hisoblanadi.

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

Workshop lokatsiyalarini alohida faylga saqlash uchun:

```bash
WORKSHOP_LOCATIONS_FILE=data/workshop_locations.json dart run bin/server.dart
```

Zakazlarni alohida faylga saqlash uchun:

```bash
BOOKINGS_FILE=data/bookings.json dart run bin/server.dart
```

Workshop kartalarini alohida fayldan yuklash uchun:

```bash
WORKSHOPS_FILE=data/workshops.json dart run bin/server.dart
```

## Login ma'lumotlari (seed)

- Telefon: `+998901234567`
- Parol: `123456`

## Admin sahifa

Brauzerda quyidagi sahifani ochib workshop lokatsiyasini taxminiy koordinata bilan kiriting:

```text
http://127.0.0.1:8080/admin/workshops
```

Zakazlar paneli:

```text
http://127.0.0.1:8080/admin/bookings
```

Admin login default holatda:

- Username: `admin`
- Password: `admin123`

Ularni `ADMIN_USERNAME` va `ADMIN_PASSWORD` bilan almashtirish mumkin.

## Ustaxona egasi kabineti

Ustaxona egasi brauzer orqali quyidagi sahifadan kiradi:

```text
http://127.0.0.1:8080/owner/login
```

Default seed workshoplar uchun owner access kodlari:

- `w-1` -> `0001`
- `w-2` -> `0002`
- `w-3` -> `0003`

Admin paneldagi workshop kartasida `Usta kirish kodi` maydoni bor. Shu kodni
o'zgartirib saqlasangiz, owner portal ham shu yangi kod bilan ishlaydi.

Yangi workshop yaratishda bu maydonni bo'sh qoldirsangiz, backend workshop ID
oxirgi 4 raqami asosida kod yaratadi.

Owner kabinetda:

- faqat o'sha workshopga tegishli zakazlar ko'rinadi
- mijoz ismi va telefoni chiqadi
- zakaz statusini `upcoming`, `completed`, `cancelled` ga almashtirish mumkin

Bu sahifa `latitude` va `longitude` qiymatlarini yangilaydi va ularni
`data/workshop_locations.json` fayliga saqlab qo'yadi. Backend qayta ishga
tushganda ham shu qiymatlar qayta yuklanadi.

Zakazlar `data/bookings.json` fayliga yoziladi. `admin/bookings` sahifasida
mijoz, telefon, servis, vaqt va status ko'rinadi. Workshop kartasidan shu
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
- `POST /admin/workshops/:id/location`
- `GET /owner`
- `GET /owner/login`
- `POST /owner/login`
- `POST /owner/logout`
- `GET /owner/bookings`
- `POST /owner/bookings/:id/status`
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/forgot-password`
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
