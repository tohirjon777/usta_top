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
