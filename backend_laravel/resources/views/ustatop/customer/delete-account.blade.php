@extends('layouts.ustatop-public', ['pageClass' => 'customer-delete-account-page'])

@section('content')
    <section class="hero">
        <div class="hero-card">
            <div class="eyebrow">Account deletion</div>
            <h1>AutoMaster akkauntini o‘chirish</h1>
            <p>
                Bu sahifa Google Play Console uchun AutoMaster foydalanuvchilariga akkaunt va shaxsiy
                ma’lumotlarni o‘chirish yo‘lini ko‘rsatadi. Accountni ilova ichidan ham, ushbu web sahifadan
                ham o‘chirish mumkin.
            </p>
            <div class="hero-actions">
                @if($currentCustomer)
                    <a class="button" href="#delete-form">Web orqali o‘chirish</a>
                    <a class="button-secondary" href="/customer/account">Kabinetga qaytish</a>
                @else
                    <a class="button" href="/customer/login">Kirish va o‘chirish</a>
                    <a class="button-secondary" href="/">Bosh sahifa</a>
                @endif
            </div>
        </div>
        <aside class="hero-card hero-side">
            <h2>Ilova ichidan o‘chirish</h2>
            <div class="feature-list">
                <div class="feature"><strong>1.</strong> AutoMaster ilovasini oching va akkauntingizga kiring.</div>
                <div class="feature"><strong>2.</strong> Pastki menyudan <strong>Kabinet</strong> bo‘limiga o‘ting.</div>
                <div class="feature"><strong>3.</strong> Sahifa pastidagi <strong>Akkauntni o‘chirish</strong> tugmasini bosing va tasdiqlang.</div>
            </div>
        </aside>
    </section>

    <section class="grid-2">
        <article class="card">
            <div class="section-title" style="margin-top:0;">
                <div>
                    <h2>Nimalar o‘chiriladi?</h2>
                    <p>Account o‘chirilganda shaxsiy profil ma’lumotlari olib tashlanadi.</p>
                </div>
            </div>
            <div class="feature-list">
                <div class="feature">Profil: ism, telefon, avatar va login sessiyalari.</div>
                <div class="feature">Saqlangan kartalar, push tokenlar va cashback balansi.</div>
                <div class="feature">Eski zakazlar servis hisobi uchun qolishi mumkin, lekin mijoz ismi/telefoni anonimlashtiriladi.</div>
                <div class="feature">Mijoz yozgan chat xabarlari va sharhlar shaxsiy ma’lumotsiz holatga keltiriladi.</div>
            </div>
        </article>

        <article id="delete-form" class="card">
            @if($currentCustomer)
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Web orqali o‘chirish</h2>
                        <p>{{ $currentCustomer['fullName'] ?? 'Mijoz' }} akkaunti uchun tasdiqlash.</p>
                    </div>
                </div>
                <form method="post" action="/customer/account/delete" class="form-grid">
                    @csrf
                    <label class="checkbox-pill" style="justify-content:flex-start; padding:14px 16px;">
                        <input type="checkbox" name="confirm_delete" value="1" style="width:auto;" required>
                        Akkauntim va shaxsiy ma’lumotlarim o‘chirilishini tushundim.
                    </label>
                    <button class="button-danger" type="submit">Akkauntni butunlay o‘chirish</button>
                </form>
            @else
                <div class="section-title" style="margin-top:0;">
                    <div>
                        <h2>Web orqali o‘chirish</h2>
                        <p>Accountni o‘chirish uchun avval telefon raqam va parol bilan tizimga kiring.</p>
                    </div>
                </div>
                <div class="feature-list">
                    <div class="feature">Kirishdan keyin shu sahifaga qaytasiz va accountni o‘chirish tugmasi chiqadi.</div>
                    <div class="feature">Parol esdan chiqqan bo‘lsa, login sahifasidagi parolni tiklash oqimidan foydalaning.</div>
                </div>
                <div class="hero-actions">
                    <a class="button" href="/customer/login">Kirish / Ro‘yxatdan o‘tish</a>
                </div>
            @endif
        </article>
    </section>
@endsection
