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

## Login ma'lumotlari (seed)

- Telefon: `+998901234567`
- Parol: `123456`

## Endpointlar

- `GET /health`
- `POST /auth/login`
- `GET /auth/me` (Bearer token kerak)
- `GET /workshops` (Bearer token kerak)
- `GET /workshops/:id` (Bearer token kerak)
- `GET /bookings` (Bearer token kerak)
- `POST /bookings` (Bearer token kerak)
- `PATCH /bookings/:id/cancel` (Bearer token kerak)

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
