@extends('layouts.ustatop-public', ['pageClass' => 'customer-auth-page'])

@section('content')
    <section class="auth-shell">
        <div class="auth-card auth-card-hero">
            <div class="eyebrow">Customer web kirish</div>
            <h1>Mijoz kabinetiga kiring yoki yangi akkaunt oching.</h1>
            <p>
                Sayt orqali ham ustaxona topish, bron qilish, vaqtni ko‘chirish, sharh qoldirish va xabar almashish mumkin.
            </p>
            <div class="feature-list">
                <div class="feature"><strong>Bron:</strong> bo‘sh vaqtlarni ko‘rib, to‘g‘ridan-to‘g‘ri buyurtma qiling.</div>
                <div class="feature"><strong>Kabinet:</strong> bronlar, kartalar va profilingiz bir joyda saqlanadi.</div>
                <div class="feature"><strong>Sharh va xabar:</strong> bajarilgan xizmatdan keyin fikr qoldiring va ustaxona bilan yozishing.</div>
            </div>
        </div>

        <div class="auth-stack">
            <article class="auth-card">
                <div class="section-title auth-title">
                    <div>
                        <h2>Kirish</h2>
                        <p>Mavjud akkauntingiz bilan tizimga kiring.</p>
                    </div>
                </div>
                <form method="post" action="/customer/login" class="form-grid">
                    @csrf
                    <label class="field">
                        <span>Telefon</span>
                        <input type="text" name="phone" placeholder="+99890 123 45 67" value="{{ old('phone') }}" required>
                    </label>
                    <label class="field">
                        <span>Parol</span>
                        <input type="password" name="password" placeholder="Parolingiz" required>
                    </label>
                    <button class="button button-block" type="submit">Kabinetga kirish</button>
                </form>
            </article>

            <article class="auth-card">
                <div class="section-title auth-title">
                    <div>
                        <h2>Ro‘yxatdan o‘tish</h2>
                        <p>
                            @if($pendingRegistration)
                                Endi telefoningizga yuborilgan SMS kodni kiriting.
                            @else
                                Yangi mijoz akkauntini xavfsiz tarzda SMS tasdiqlash bilan yarating.
                            @endif
                        </p>
                    </div>
                </div>
                <form method="post" action="/customer/register" class="form-grid">
                    @csrf
                    @if($pendingRegistration)
                        <div class="feature">
                            <strong>Telefon:</strong> {{ $pendingRegistration['phone'] }}
                        </div>
                        <div class="feature">
                            <strong>Ism:</strong> {{ $pendingRegistration['fullName'] }}
                        </div>
                        @if(session('registerDebugCode'))
                            <div class="feature">
                                <strong>Test kodi:</strong> {{ session('registerDebugCode') }}
                            </div>
                        @endif
                        <label class="field">
                            <span>SMS kodi</span>
                            <input type="text" name="code" placeholder="123456" inputmode="numeric" autocomplete="one-time-code" required>
                        </label>
                        <button class="button button-block" type="submit">SMS kodni tasdiqlash</button>
                    @else
                        <label class="field">
                            <span>To‘liq ism</span>
                            <input type="text" name="fullName" placeholder="Toxirjon Aliyev" value="{{ old('fullName') }}" required>
                        </label>
                        <label class="field">
                            <span>Telefon</span>
                            <input type="text" name="phone" placeholder="+99890 123 45 67" value="{{ old('phone') }}" required>
                        </label>
                        <label class="field">
                            <span>Parol</span>
                            <input type="password" name="password" placeholder="Kamida 6 belgi" required>
                        </label>
                        <button class="button button-block" type="submit">SMS kod yuborish</button>
                    @endif
                </form>
            </article>
        </div>
    </section>
@endsection
