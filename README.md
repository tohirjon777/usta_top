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
TELEGRAM_BOT_TOKEN=... ./run_dev.sh
```

Bu script backendni ko'taradi, health'ni kutadi, keyin appni backend bilan
`flutter run` orqali ishga tushiradi. Admin panel `http://127.0.0.1:8080/admin/login`
va owner panel `http://127.0.0.1:8080/owner/login` da ochiladi.

Telegram bot yoqilgan bo'lsa, owner panel ichidan `Bog'lash kodini yaratish`
orqali ustaxona profilini o'z Telegram chatiga ulash mumkin.

Backendni terminalsiz avtomatik ishlatish uchun:

```bash
./backend_service.sh install
./backend_service.sh status
./backend_service.sh logs
```

Bu service macOS `launchd` orqali ishlaydi va login qilganingizda o'zi
ko'tariladi. Backend kodi `~/Library/Application Support/UstaTopBackend/runtime`
ga sync qilinadi, shuning uchun backend kodini o'zgartirgandan keyin:

```bash
./backend_service.sh restart
```

`run_dev.sh` esa endi 8080 da backend allaqachon ishlayotgan bo'lsa, o'shani
qayta ishlatadi.

## Push Notification

Background push notification ishlashi uchun quyidagi Firebase fayllar kerak:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- backend uchun service account JSON (`backend/secrets/firebase-service-account.json` yoki `FIREBASE_SERVICE_ACCOUNT_FILE`)

Eng qulay yo'l:

1. `google-services.json` ni `android/app/` ichiga qo'ying
2. `GoogleService-Info.plist` ni `ios/Runner/` ichiga qo'ying
3. service account JSON ni `backend/secrets/firebase-service-account.json` nomi bilan joylang
4. backend service'ni qayta ishga tushiring:

```bash
./backend_service.sh restart
```

Backendni push bilan qayta ishga tushirish:

```bash
FIREBASE_SERVICE_ACCOUNT_FILE=/abs/path/firebase-service-account.json ./backend_service.sh restart
```

Yoki backendni oddiy local rejimda:

```bash
cd backend
FIREBASE_SERVICE_ACCOUNT_FILE=/abs/path/firebase-service-account.json dart run bin/server.dart
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
