# API Keys Checklist (To'lovsiz)

Quyidagi ro'yxat hozirgi `Usta Top` loyihasi uchun.

## Hozir majburiy bo'lganlar

1. `API_BASE_URL` (backend manzili)
2. Test foydalanuvchi login ma'lumotlari (`phone`, `password`)

## Hozir majburiy EMAS (xarita, push va SMS qo'shilganda kerak bo'ladi)

1. Xarita kalitlari
2. Push notification kalitlari
3. SMS OTP kalitlari

## 1) Xarita uchun (Google Maps varianti)

Kerak bo'ladigan kalitlar:

1. Google Cloud API Key (`GOOGLE_MAPS_API_KEY`)

Google Cloud'da yoqilishi kerak bo'lgan API'lar:

1. `Maps SDK for Android`
2. `Maps SDK for iOS`
3. `Places API` (faqat qidiruv/autocomplete kerak bo'lsa)
4. `Geocoding API` (faqat manzil <-> koordinata kerak bo'lsa)

Qayerga qo'yiladi:

1. Android:
   Fayl: `android/app/src/main/AndroidManifest.xml`
   Qo'shiladigan joy (`<application>` ichiga):

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY" />
   ```

2. iOS:
   Odatda `google_maps_flutter` ishlatilganda `AppDelegate.swift` ichida `GMSServices.provideAPIKey(...)` beriladi.
   Fayl: `ios/Runner/AppDelegate.swift`

Tavsiya:

1. Android uchun API key'ni package name + SHA-1 bilan cheklang
2. iOS uchun bundle identifier bilan cheklang

## 2) Push notification uchun (Firebase Cloud Messaging)

Kerak bo'ladiganlar:

1. Firebase project
2. Android uchun `google-services.json`
3. iOS uchun `GoogleService-Info.plist`

Qayerga qo'yiladi:

1. Android:
   `android/app/google-services.json`
2. iOS:
   `ios/Runner/GoogleService-Info.plist`

Qo'shimcha:

1. Backendda FCM server tomoni auth (service account) bo'ladi
2. Flutter app ichiga secret server kalit kiritilmaydi

## 3) SMS OTP uchun (ixtiyoriy)

Misol providerlar:

1. Eskiz
2. Twilio

Kerak bo'ladigan kalitlar:

1. `SMS_API_KEY`
2. `SMS_API_SECRET`

Muhim:

1. Bu kalitlar faqat backend `.env` da turadi
2. Flutter app ichiga secret kalit yozilmaydi

## Xavfsizlik qoidasi

1. `secret` kalitlar faqat backendda saqlanadi
2. Flutter tarafga faqat public ma'lumot yoki token beriladi
3. Git'ga `.env` va maxfiy fayllarni commit qilmang

## Ushbu loyiha holati (2026-03-21)

1. To'lov integratsiyasi yo'q
2. Xarita ekrani `flutter_map` + OpenStreetMap (keysiz) bilan ulangan
3. Joriy joylashuv (`geolocator`) qo'shilgan, API key emas permission kerak
4. Servis carddan `Yandex Maps`ga o'tish qo'shilgan (API key kerak emas)
5. Push notification paketi hali ulanmagan
6. SMS OTP hali ulanmagan
