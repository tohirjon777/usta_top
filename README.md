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

Fizik Android telefon uchun eng qulay yo'l:

```bash
./run_phone.sh
```

Bu script backendni tekshiradi va odatda lokal IP orqali ulaydi, shuning
uchun USB uzilgandan keyin ham telefon backend bilan ishlayveradi. Faqat debug
uchun xohlasangiz `adb reverse`ni majburlash mumkin. Device ID aniq berish ham
mumkin:

```bash
./run_phone.sh --device-id R9JN50PWH2J
./run_phone.sh --wifi --device-id R9JN50PWH2J
./run_phone.sh --adb-reverse --device-id R9JN50PWH2J
```

Bu script backendni ko'taradi, health'ni kutadi, keyin appni backend bilan
`flutter run` orqali ishga tushiradi. Customer website `http://127.0.0.1:8080/`
da ochiladi.

Backend service hozir lokal tarmoqdan ham ochiladi. Shu sabab bir tarmoqdagi
telefon brauzerida yoki ilovada quyidagi manzil ishlaydi:

```text
http://<sizning-mac-ip>:8080
```

Telefon internetda, Mac esa boshqa Wi‑Fi tarmoqda bo'lsa, public tunnel yoqing:

```bash
./backend_tunnel.sh start
./backend_tunnel.sh url
./backend_tunnel.sh status
```

Shunda `https://...trycloudflare.com` ko'rinishidagi public URL chiqadi. Uni
telefon ilovasidagi `Server sozlamalari`ga kiritsangiz, bir xil Wi‑Fi shart
bo'lmaydi.

Yoki public URL bilan APK'ni bir yo'la tayyorlang:

```bash
./build_public_phone_apk.sh
```

Bu `backend_tunnel.sh` orqali public URL olib, APK'ni shu manzil bilan
`~/Downloads/UstaTop-public-debug.apk` qilib yig'adi.

Telefonni USBsiz ishlatish uchun tayyor APK ham yig'ish mumkin:

```bash
./build_phone_apk.sh
```

Bu script joriy lokal IP bilan APK yig'adi va uni `~/Downloads/UstaTop-phone-debug.apk`
 sifatida tayyorlaydi.

Telegram bot yoqilgan bo'lsa, ustaxona Telegram sozlamalari runtime ma'lumotda
saqlanadi va yangi zakaz/status xabarlari yuboriladi.
Tokenlar Laravel backend uchun
[secrets/local.env](/Users/tokhiriy/Downloads/mobile_apps/usta_top/backend_laravel/secrets/local.env)
ichiga yoziladi.

Backendni terminalsiz avtomatik ishlatish uchun:

```bash
./backend_service.sh install
./backend_service.sh status
./backend_service.sh logs
./backend_service.sh backup
./backend_service.sh backups
./backend_service.sh restore <backup_path>
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

Laravel backend endi lokal `SQLite` bazada ishlaydi:
- DB fayl: `backend_laravel/storage/app/ustatop/ustatop.sqlite`
- mavjud `backend_laravel/data` JSON fayllari bir martalik seed/import manbasi sifatida ishlatiladi

App, service va dev oqimi to'liq Laravel backendga ulangan va keyingi yozuvlar
shu SQLite bazaga saqlanadi.

Mac service ishlayotgan bo'lsa backup fayllar shu yerga tushadi:
- `~/Library/Application Support/UstaTopBackend/backups`

Batafsil Laravel backend izohi:

- [`backend_laravel/README_USTATOP.md`](backend_laravel/README_USTATOP.md)

## API Kalitlar (To'lovsiz)

Hozirgi loyihada to'lov servisi yo'q. Qaysi integratsiyaga qaysi API key kerakligi bo'yicha tayyor checklist:

- [`docs/api_keys_checklist.md`](docs/api_keys_checklist.md)
