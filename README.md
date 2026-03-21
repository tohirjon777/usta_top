# Usta Top

Flutter frontend va alohida Dart backend bilan avto-servis ilovasi.

## Frontend

```bash
flutter pub get
flutter run
```

Backend bilan ishlatish:

```bash
flutter run --dart-define=USE_BACKEND=true
```

Kerak bo'lsa backend manzilini ham berish mumkin:

```bash
flutter run --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Ikkalasini birga bitta buyruq bilan ishga tushirish:

```bash
./run_dev.sh
```

Foydali variantlar:

```bash
./run_dev.sh -- --device-id chrome
./run_dev.sh --android-emulator -- -d emulator-5554
./run_dev.sh --api-base-url http://192.168.100.25:8080 -- -d YOUR_DEVICE_ID
```

Bu script backendni ko'taradi, health'ni kutadi, keyin appni backend bilan
`flutter run` orqali ishga tushiradi. Admin panel `http://127.0.0.1:8080/admin/login`
va owner panel `http://127.0.0.1:8080/owner/login` da ochiladi.

## Backend

Backend alohida papkada:

```bash
cd backend
dart pub get
dart run bin/server.dart
```

Batafsil API va `curl` misollari:

- [`backend/README.md`](backend/README.md)

## API Kalitlar (To'lovsiz)

Hozirgi loyihada to'lov servisi yo'q. Qaysi integratsiyaga qaysi API key kerakligi bo'yicha tayyor checklist:

- [`docs/api_keys_checklist.md`](docs/api_keys_checklist.md)
