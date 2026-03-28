# Usta Top

Flutter frontend va Laravel backend bilan avto-servis ilovasi.

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

## Backend

Backend alohida papkada:

```bash
cd backend_laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan serve --host=127.0.0.1 --port=8080
```

Laravel backend endi o'z ma'lumotlarini `backend_laravel/data` ichidan oladi.
Eski `backend/` papkasi legacy arxiv sifatida qoldirilgan, lekin app va service
oqimi unga suyanmaydi.

Batafsil Laravel backend izohi:

- [`backend_laravel/README_USTATOP.md`](backend_laravel/README_USTATOP.md)

## API Kalitlar (To'lovsiz)

Hozirgi loyihada to'lov servisi yo'q. Qaysi integratsiyaga qaysi API key kerakligi bo'yicha tayyor checklist:

- [`docs/api_keys_checklist.md`](docs/api_keys_checklist.md)
