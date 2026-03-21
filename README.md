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
