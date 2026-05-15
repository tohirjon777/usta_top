@extends('layouts.ustatop-public', ['pageClass' => 'customer-privacy-policy-page'])

@section('content')
    <section class="hero">
        <div class="hero-card">
            <div class="eyebrow">Privacy Policy</div>
            <h1>AutoMaster Privacy Policy</h1>
            <p>
                Maxfiylik siyosati uch tilda berilgan: O‘zbek, English va Русский.
                This page explains how AutoMaster collects, uses, stores and protects user data.
            </p>
            <div class="hero-actions">
                <a class="button" href="#uz">O‘zbek</a>
                <a class="button-secondary" href="#en">English</a>
                <a class="button-secondary" href="#ru">Русский</a>
            </div>
        </div>
        <aside class="hero-card hero-side">
            <h2>Quick info</h2>
            <div class="feature-list">
                <div class="feature"><strong>App:</strong> AutoMaster</div>
                <div class="feature"><strong>Last updated:</strong> May 13, 2026</div>
                <div class="feature"><strong>Account deletion:</strong> <a href="/account/delete">/account/delete</a></div>
            </div>
        </aside>
    </section>

    <section id="uz" class="card">
        <div class="section-title" style="margin-top:0;">
            <div>
                <h2>O‘zbek: AutoMaster maxfiylik siyosati</h2>
                <p>Oxirgi yangilanish: 2026-yil 13-may</p>
            </div>
        </div>

        <h2>1. Biz yig‘adigan ma’lumotlar</h2>
        <div class="feature-list">
            <div class="feature">Akkaunt ma’lumotlari: ism, familiya, telefon raqami, SMS tasdiqlash holati, login sessiyasi va profil rasmi.</div>
            <div class="feature">Zakaz ma’lumotlari: ustaxona, xizmat turi, avtomobil turi, sana/vaqt, narx, status, chat xabarlari, sharh va reyting.</div>
            <div class="feature">Joylashuv ma’lumotlari: yaqin ustaxonalarni ko‘rsatish, masofani hisoblash va navigatsiyani ochish uchun, faqat foydalanuvchi ruxsat bergandan keyin.</div>
            <div class="feature">To‘lov va cashback ma’lumotlari: karta brendi, maskalangan karta raqami, oxirgi 4 raqam, amal qilish muddati, cashback balansi va tarixi.</div>
            <div class="feature">Bildirishnoma va qurilma ma’lumotlari: Firebase push tokeni, platforma, bildirishnoma ruxsati va zakazga bog‘langan payload ma’lumotlari.</div>
            <div class="feature">Texnik ma’lumotlar: server loglari, so‘rov vaqti, endpoint, javob statusi, IP manzil va xatolik diagnostikasi.</div>
        </div>

        <h2>2. Ma’lumotlardan foydalanish</h2>
        <div class="feature-list">
            <div class="feature">Foydalanuvchini ro‘yxatdan o‘tkazish, login qilish va SMS orqali telefon raqamini tasdiqlash.</div>
            <div class="feature">Ustaxonalar, xizmatlar, narxlar va bo‘sh vaqtlarni ko‘rsatish.</div>
            <div class="feature">Zakaz yaratish, qabul qilish, bekor qilish, qayta rejalashtirish va statusni yangilash.</div>
            <div class="feature">Yaqin ustaxonalarni topish, masofani hisoblash va navigatsiya ilovalarini ochish.</div>
            <div class="feature">Cashbackni hisoblash, saqlash va keyingi zakazlarda ishlatish.</div>
            <div class="feature">Push bildirishnomalar yuborish, xavfsizlik va tizim barqarorligini yaxshilash.</div>
        </div>

        <h2>3. Ma’lumotlarni ulashish</h2>
        <p>Biz foydalanuvchi ma’lumotlarini sotmaymiz. Ma’lumotlar faqat xizmatni ko‘rsatish uchun zarur holatlarda ulashiladi.</p>
        <div class="feature-list">
            <div class="feature">Tanlangan ustaxona yoki usta zakazni bajarish uchun kerakli ma’lumotlarni ko‘rishi mumkin.</div>
            <div class="feature">Admin va owner panel foydalanuvchilari ustaxona va zakazlarni boshqarish uchun kerakli ma’lumotlarni ko‘rishi mumkin.</div>
            <div class="feature">SMS provayder, Firebase, Yandex Maps, Telegram Bot API, hosting/VPS provayderi va kelajakdagi to‘lov provayderiga minimal zarur ma’lumotlar uzatilishi mumkin.</div>
            <div class="feature">Qonuniy talab, sud qarori yoki majburiy so‘rov bo‘lsa vakolatli davlat organlariga ma’lumot berilishi mumkin.</div>
        </div>

        <h2>4. Saqlash, xavfsizlik va huquqlar</h2>
        <div class="feature-list">
            <div class="feature">Akkaunt ma’lumotlari akkaunt faol bo‘lgan davrda saqlanadi. Zakaz, to‘lov holati va cashback tarixi xizmat tarixi, hisob-kitob va qonuniy talablar uchun saqlanishi mumkin.</div>
            <div class="feature">Parollar hash ko‘rinishida saqlanadi, access token orqali himoyalangan API endpointlardan foydalaniladi, karta raqami maskalanadi va CVV saqlanmaydi.</div>
            <div class="feature">Foydalanuvchi profilini yangilashi, bildirishnomalarni o‘chirishi, joylashuv ruxsatini bekor qilishi va akkauntini o‘chirishi mumkin.</div>
            <div class="feature">Akkauntni o‘chirish uchun ilova ichida <strong>Kabinet</strong> bo‘limidagi <strong>Akkauntni o‘chirish</strong> tugmasidan yoki web orqali <a href="/account/delete">/account/delete</a> sahifasidan foydalaning.</div>
        </div>

        <h2>5. Bolalar maxfiyligi, o‘zgarishlar va aloqa</h2>
        <p>
            AutoMaster avtomobil servis xizmatlari uchun mo‘ljallangan va voyaga yetmagan bolalar tomonidan mustaqil foydalanish uchun mo‘ljallanmagan.
            Siyosat vaqti-vaqti bilan yangilanishi mumkin. Maxfiylik yoki akkauntni o‘chirish bo‘yicha savollar uchun ilova, Play Market sahifasi yoki web-sayt orqali AutoMaster operatoriga murojaat qiling.
        </p>
    </section>

    <section id="en" class="card">
        <div class="section-title" style="margin-top:0;">
            <div>
                <h2>English: AutoMaster Privacy Policy</h2>
                <p>Last updated: May 13, 2026</p>
            </div>
        </div>

        <h2>1. Information we collect</h2>
        <div class="feature-list">
            <div class="feature">Account information: full name, phone number, SMS verification status, login session and profile photo.</div>
            <div class="feature">Order information: selected workshop, service type, vehicle type, date/time, price, status, chat messages, review and rating.</div>
            <div class="feature">Location information: used to show nearby workshops, calculate distance and open navigation, only after the user grants permission.</div>
            <div class="feature">Payment and cashback information: card brand, masked card number, last 4 digits, expiry date, cashback balance and cashback history.</div>
            <div class="feature">Notification and device information: Firebase push token, platform, notification permission status and order-related notification payloads.</div>
            <div class="feature">Technical information: server logs, request time, endpoint, response status, IP address and error diagnostics.</div>
        </div>

        <h2>2. How we use information</h2>
        <div class="feature-list">
            <div class="feature">To register users, sign users in and verify phone numbers by SMS.</div>
            <div class="feature">To show workshops, services, prices and available booking times.</div>
            <div class="feature">To create, accept, cancel, reschedule and update orders.</div>
            <div class="feature">To find nearby workshops, calculate distance and open navigation apps.</div>
            <div class="feature">To calculate, store and apply cashback to future orders.</div>
            <div class="feature">To send push notifications and improve safety, stability and service quality.</div>
        </div>

        <h2>3. Sharing information</h2>
        <p>We do not sell user data. Information is shared only when necessary to provide the service.</p>
        <div class="feature-list">
            <div class="feature">The selected workshop or master may see the information needed to complete the order.</div>
            <div class="feature">Admin and owner panel users may see information needed to manage workshops and orders.</div>
            <div class="feature">Minimum required data may be shared with SMS providers, Firebase, Yandex Maps, Telegram Bot API, hosting/VPS providers and future payment providers.</div>
            <div class="feature">Information may be disclosed to authorized authorities when required by law, court order or a valid legal request.</div>
        </div>

        <h2>4. Storage, security and user rights</h2>
        <div class="feature-list">
            <div class="feature">Account data is stored while the account is active. Order, payment status and cashback history may be retained for service history, accounting and legal requirements.</div>
            <div class="feature">Passwords are stored as hashes, protected API endpoints use access tokens, card numbers are masked and CVV is not stored.</div>
            <div class="feature">Users can update their profile, disable notifications, revoke location permission and delete their account.</div>
            <div class="feature">To delete an account, use the <strong>Delete account</strong> button in the app’s <strong>Profile</strong> section or the web page <a href="/account/delete">/account/delete</a>.</div>
        </div>

        <h2>5. Children, updates and contact</h2>
        <p>
            AutoMaster is intended for automotive service use and is not intended for independent use by children.
            This policy may be updated from time to time. For privacy or account deletion questions, contact the AutoMaster operator through the app, Play Market page or website.
        </p>
    </section>

    <section id="ru" class="card">
        <div class="section-title" style="margin-top:0;">
            <div>
                <h2>Русский: Политика конфиденциальности AutoMaster</h2>
                <p>Последнее обновление: 13 мая 2026 года</p>
            </div>
        </div>

        <h2>1. Какие данные мы собираем</h2>
        <div class="feature-list">
            <div class="feature">Данные аккаунта: имя и фамилия, номер телефона, статус SMS-подтверждения, сессия входа и фотография профиля.</div>
            <div class="feature">Данные заказа: выбранная мастерская, тип услуги, тип автомобиля, дата/время, цена, статус, сообщения чата, отзыв и рейтинг.</div>
            <div class="feature">Данные местоположения: используются для показа ближайших мастерских, расчета расстояния и открытия навигации только после разрешения пользователя.</div>
            <div class="feature">Данные оплаты и cashback: бренд карты, маскированный номер карты, последние 4 цифры, срок действия, баланс и история cashback.</div>
            <div class="feature">Данные уведомлений и устройства: Firebase push token, платформа, статус разрешения уведомлений и payload уведомлений, связанных с заказом.</div>
            <div class="feature">Технические данные: серверные логи, время запроса, endpoint, статус ответа, IP-адрес и диагностика ошибок.</div>
        </div>

        <h2>2. Как мы используем данные</h2>
        <div class="feature-list">
            <div class="feature">Для регистрации пользователей, входа в аккаунт и подтверждения номера телефона через SMS.</div>
            <div class="feature">Для отображения мастерских, услуг, цен и доступного времени записи.</div>
            <div class="feature">Для создания, принятия, отмены, переноса и обновления заказов.</div>
            <div class="feature">Для поиска ближайших мастерских, расчета расстояния и открытия навигационных приложений.</div>
            <div class="feature">Для начисления, хранения и использования cashback в следующих заказах.</div>
            <div class="feature">Для отправки push-уведомлений и улучшения безопасности, стабильности и качества сервиса.</div>
        </div>

        <h2>3. Передача данных</h2>
        <p>Мы не продаем данные пользователей. Данные передаются только тогда, когда это необходимо для предоставления сервиса.</p>
        <div class="feature-list">
            <div class="feature">Выбранная мастерская или мастер может видеть данные, необходимые для выполнения заказа.</div>
            <div class="feature">Пользователи admin и owner панелей могут видеть данные, необходимые для управления мастерскими и заказами.</div>
            <div class="feature">Минимально необходимые данные могут передаваться SMS-провайдеру, Firebase, Yandex Maps, Telegram Bot API, hosting/VPS провайдеру и будущему платежному провайдеру.</div>
            <div class="feature">Данные могут быть раскрыты уполномоченным органам при законном требовании, решении суда или обязательном запросе.</div>
        </div>

        <h2>4. Хранение, безопасность и права пользователя</h2>
        <div class="feature-list">
            <div class="feature">Данные аккаунта хранятся, пока аккаунт активен. История заказов, статус оплаты и история cashback могут храниться для истории сервиса, учета и законных требований.</div>
            <div class="feature">Пароли хранятся в виде hash, защищенные API endpoint используют access token, номер карты маскируется, CVV не хранится.</div>
            <div class="feature">Пользователь может обновить профиль, отключить уведомления, отозвать разрешение на местоположение и удалить аккаунт.</div>
            <div class="feature">Чтобы удалить аккаунт, используйте кнопку <strong>Удалить аккаунт</strong> в разделе <strong>Профиль</strong> приложения или web-страницу <a href="/account/delete">/account/delete</a>.</div>
        </div>

        <h2>5. Дети, изменения и контакты</h2>
        <p>
            AutoMaster предназначен для автомобильных сервисных услуг и не предназначен для самостоятельного использования детьми.
            Эта политика может периодически обновляться. По вопросам конфиденциальности или удаления аккаунта свяжитесь с оператором AutoMaster через приложение, страницу Play Market или web-сайт.
        </p>
    </section>
@endsection
