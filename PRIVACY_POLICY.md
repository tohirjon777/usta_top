# AutoMaster Maxfiylik Siyosati

Oxirgi yangilangan sana: 2026-yil 13-may

Ushbu Maxfiylik siyosati AutoMaster mobil ilovasi, backend API, mijoz veb-sayti, admin panel, owner panel va ularga bog'langan xizmatlarda foydalanuvchi ma'lumotlari qanday yig'ilishi, ishlatilishi, saqlanishi va himoya qilinishini tushuntiradi.

Ushbu siyosatda "AutoMaster", "biz" yoki "ilova" deganda AutoMaster servis ekotizimi tushuniladi. "Foydalanuvchi" deganda mijozlar, ustaxona egalari, adminlar va ilovadan foydalanadigan boshqa shaxslar tushuniladi.

## 1. Biz yig'adigan ma'lumotlar

### Akkaunt va login ma'lumotlari

Ilovada ro'yxatdan o'tish, kirish va profilni yuritish uchun quyidagi ma'lumotlar olinishi mumkin:

- ism va familiya;
- telefon raqami;
- SMS tasdiqlash kodi holati;
- parolning himoyalangan hash ko'rinishi;
- login sessiyasi va access token;
- profil rasmi, agar foydalanuvchi yuklasa.

SMS kodlar xavfsizlik uchun vaqtinchalik ishlatiladi. Backend kodning o'zini doimiy saqlash o'rniga uning hash qiymati va amal qilish muddatini saqlashi mumkin.

### Zakaz va servis ma'lumotlari

Ustaxona xizmatlarini band qilish va zakazlarni boshqarish uchun quyidagi ma'lumotlar ishlatiladi:

- tanlangan ustaxona, usta yoki servis nomi;
- xizmat turi, sana va vaqt;
- avtomobil turi, marka va model;
- zakaz narxi, oldindan to'lov foizi, to'lov holati;
- zakaz statuslari: qabul qilingan, bajarilgan, bekor qilingan yoki qayta rejalashtirilgan;
- mijoz va ustaxona o'rtasidagi chat xabarlari;
- sharh, reyting va ustaxona egasining javobi;
- bekor qilish yoki vaqtni o'zgartirish sabablari.

### Joylashuv ma'lumotlari

Ilovada xarita, yaqin ustaxonalarni ko'rsatish, masofani hisoblash va navigatsiyani ochish uchun qurilmaning joylashuv ma'lumoti ishlatilishi mumkin.

Joylashuv faqat foydalanuvchi ruxsat bergandan keyin olinadi. Ilova doimiy fon rejimida kuzatish uchun mo'ljallanmagan. Joylashuv ruxsatini telefon sozlamalaridan istalgan vaqtda o'chirish mumkin.

### To'lov kartasi va cashback ma'lumotlari

To'lov va sinov cashback funksiyalari uchun quyidagi ma'lumotlar ishlatilishi mumkin:

- karta egasi ismi;
- karta brendi;
- karta raqamining maskalangan ko'rinishi;
- kartaning oxirgi 4 raqami;
- amal qilish muddati;
- default karta belgisi;
- cashback balansi, cashback tarixi va zakazga bog'langan cashback summalari.

AutoMaster hozirgi implementatsiyada kartaning to'liq raqamini doimiy saqlamaydi: karta raqami maskalanadi va faqat kerakli qismlar saqlanadi. CVV kod ilovada saqlanmasligi kerak. Agar kelajakda real to'lov provayderi ulanadigan bo'lsa, to'lov ma'lumotlari shu provayder qoidalari bo'yicha ham qayta ishlanishi mumkin.

### Bildirishnoma va qurilma ma'lumotlari

Zakaz statuslari va muhim xabarlarni yuborish uchun quyidagi ma'lumotlar ishlatilishi mumkin:

- Firebase push tokeni;
- qurilma platformasi: Android yoki iOS;
- bildirishnoma ruxsati holati;
- xabarnoma payload ma'lumotlari, masalan zakaz ID yoki status.

Foydalanuvchi bildirishnomalarni ilova yoki telefon sozlamalari orqali o'chirishi mumkin.

### Texnik va xavfsizlik ma'lumotlari

Xizmatni barqaror ishlatish, xatolarni topish va xavfsizlikni ta'minlash uchun quyidagi texnik ma'lumotlar qayta ishlanishi mumkin:

- server loglari;
- so'rov vaqti, endpoint va javob statuslari;
- IP manzil va brauzer yoki qurilma haqidagi texnik ma'lumotlar;
- xatolik diagnostikasi.

## 2. Ma'lumotlardan foydalanish maqsadlari

Yig'ilgan ma'lumotlar quyidagi maqsadlarda ishlatiladi:

- foydalanuvchini ro'yxatdan o'tkazish va login qilish;
- SMS orqali telefon raqamini tasdiqlash;
- ustaxonalarni, xizmatlarni, narxlarni va bo'sh vaqtlarni ko'rsatish;
- zakaz yaratish, qabul qilish, bekor qilish va statusini yangilash;
- yaqin ustaxonalarni va masofani hisoblash;
- navigatsiya ilovalarini ochish;
- cashbackni hisoblash, saqlash va keyingi zakazlarda ishlatish;
- push bildirishnomalar yuborish;
- mijoz, ustaxona egasi va admin o'rtasidagi operatsion jarayonlarni yuritish;
- profil, karta va avtomobil ma'lumotlarini saqlash;
- xizmat sifati, xavfsizlik va tizim barqarorligini yaxshilash;
- qonunchilik talablariga rioya qilish.

## 3. Ma'lumotlarni kimlar ko'rishi yoki olishi mumkin

Biz foydalanuvchi ma'lumotlarini sotmaymiz. Ma'lumotlar faqat xizmatni ko'rsatish uchun zarur holatlarda ulashilishi mumkin:

- tanlangan ustaxona yoki usta: zakazni bajarish uchun kerakli mijoz, xizmat, avtomobil va zakaz ma'lumotlari;
- admin va owner panel foydalanuvchilari: ustaxona va zakazlarni boshqarish uchun kerakli ma'lumotlar;
- SMS provayder: SMS kod yuborish uchun telefon raqami va OTP xabari;
- Firebase yoki boshqa push xizmati: bildirishnoma tokenlari va xabar payloadi;
- Yandex Maps va navigatsiya xizmatlari: xarita va marshrut funksiyalari uchun kerakli joylashuv yoki koordinata ma'lumotlari;
- Telegram: ustaxona Telegram chatiga ulangan bo'lsa, yangi zakaz va status xabarlari yuborilishi mumkin;
- hosting, VPS va texnik xizmat ko'rsatuvchilar: backend va ma'lumotlar bazasini ishlatish uchun;
- vakolatli davlat organlari: qonuniy talab, sud qarori yoki majburiy so'rov bo'lsa.

## 4. Uchinchi tomon xizmatlari

Ilova va backend quyidagi turdagi uchinchi tomon xizmatlaridan foydalanishi mumkin:

- SMS yuborish xizmati;
- Firebase Cloud Messaging;
- Yandex Maps;
- Telegram Bot API;
- server hosting yoki VPS provayderi;
- kelajakda ulanadigan to'lov provayderi.

Uchinchi tomon xizmatlari o'z maxfiylik siyosati va texnik qoidalariga ega bo'lishi mumkin. Ular bilan ulashiladigan ma'lumotlar faqat kerakli minimal hajmda berilishi kerak.

## 5. Ma'lumotlarni saqlash

Ma'lumotlar AutoMaster backend serverida va unga bog'langan ma'lumotlar bazasida saqlanishi mumkin. Saqlash muddati ma'lumot turiga bog'liq:

- akkaunt ma'lumotlari akkaunt faol bo'lgan davrda saqlanadi;
- zakazlar, to'lov holati va cashback tarixi xizmat tarixi, hisob-kitob va qonuniy talablar uchun saqlanishi mumkin;
- SMS tasdiqlash yozuvlari qisqa muddatga saqlanadi va kod tasdiqlanganda yoki muddati tugaganda o'chiriladi;
- push tokenlar foydalanuvchi bildirishnomani o'chirganda, logout qilganda yoki token eskirganda o'chirilishi mumkin;
- texnik loglar xavfsizlik va diagnostika uchun zarur muddatgacha saqlanishi mumkin.

## 6. Xavfsizlik

Biz foydalanuvchi ma'lumotlarini himoya qilish uchun oqilona texnik va tashkiliy choralarni qo'llaymiz:

- parollar hash ko'rinishida saqlanadi;
- SMS kodlar cheklangan muddat va urinishlar bilan ishlaydi;
- access token orqali himoyalangan API endpointlardan foydalaniladi;
- karta raqami maskalanadi;
- server va admin/owner kirishlari cheklangan bo'lishi kerak;
- zaxira nusxalar va server sozlamalari ehtiyotkorlik bilan yuritilishi kerak.

Shunga qaramay, internet orqali ma'lumot uzatish yoki serverda saqlash 100 foiz xavfsiz deb kafolatlanmaydi. Shubhali holat sezilsa, foydalanuvchi darhol operatorga murojaat qilishi kerak.

## 7. Foydalanuvchi huquqlari

Foydalanuvchi quyidagi huquqlarga ega:

- o'z profil ma'lumotlarini ko'rish va yangilash;
- telefon raqami, ism va avatarni o'zgartirish;
- saqlangan kartani o'chirish yoki yangilash;
- bildirishnomalarni o'chirish;
- joylashuv ruxsatini telefon sozlamalaridan bekor qilish;
- o'z ma'lumotlari bo'yicha tushuntirish so'rash;
- akkauntni yoki shaxsiy ma'lumotlarni o'chirishni so'rash, agar qonuniy yoki xizmat majburiyatlari bunga to'sqinlik qilmasa.

Ma'lumotlarni o'chirish so'rovi bajarilganda ayrim zakaz, hisob-kitob, xavfsizlik yoki qonuniy yozuvlar belgilangan muddatgacha saqlanishi mumkin.

## 8. Bolalar maxfiyligi

AutoMaster avtomobil servis xizmatlari uchun mo'ljallangan. Ilova voyaga yetmagan bolalar tomonidan mustaqil foydalanish uchun mo'ljallanmagan. Agar voyaga yetmagan shaxsning ma'lumoti ruxsatsiz kiritilgani aniqlansa, operatorga murojaat qilish kerak.

## 9. Siyosatga o'zgartirish kiritish

Ushbu Maxfiylik siyosati vaqti-vaqti bilan yangilanishi mumkin. Muhim o'zgarishlar bo'lsa, ilova, veb-sayt yoki boshqa aloqa kanali orqali xabar berilishi mumkin. Yangilangan siyosat e'lon qilingan kundan boshlab amal qiladi.

## 10. Aloqa

Maxfiylik, shaxsga doir ma'lumotlar yoki akkauntni o'chirish bo'yicha savollar uchun AutoMaster operatoriga murojaat qiling:

- Ilova nomi: AutoMaster

Ushbu aloqa ma'lumotlari Play Market, App Store, veb-sayt yoki ilova ichidagi qo'llab-quvvatlash bo'limidagi ma'lumotlar bilan bir xil bo'lishi kerak.