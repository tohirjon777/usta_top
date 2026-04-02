<!doctype html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Usta Top' }}</title>
    <meta name="description" content="Usta Top orqali yaqin ustaxonalarni toping, xaritada ko‘ring va xizmatlarni solishtiring.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('site-assets/customer.css') }}">
    @if(!empty($yandexMapsApiKey))
        <script src="https://api-maps.yandex.ru/2.1/?apikey={{ urlencode($yandexMapsApiKey) }}&lang=ru_RU" type="text/javascript"></script>
    @endif
    @yield('head')
</head>
<body class="{{ $pageClass ?? '' }}">
    <div class="shell">
        <header class="topbar">
            <div class="topbar-inner">
                <a class="brand" href="/">
                    <span class="brand-mark">UT</span>
                    <span>Usta Top</span>
                </a>
                <nav class="nav-links">
                    <a href="/#discover">Ustaxonalar</a>
                    <a href="/#map">Xarita</a>
                    @if(!empty($currentCustomer))
                        <a href="/customer/account">Kabinet</a>
                        <form action="/customer/logout" method="post" class="inline-form">
                            @csrf
                            <button class="nav-button" type="submit">Chiqish</button>
                        </form>
                    @else
                        <a href="/customer/login">Kirish</a>
                    @endif
                </nav>
            </div>
        </header>

        @if(session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif
        @if(session('error'))
            <div class="alert alert-error">{{ session('error') }}</div>
        @endif

        @yield('content')
    </div>

    @yield('scripts')
</body>
</html>
