<!doctype html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }}</title>
    <style>
        :root {
            color-scheme: light only;
            --bg: #ffffff;
            --line: rgba(16,24,40,.08);
            --text: #171717;
            --muted: #667085;
            --accent: #0f766e;
            --accent-2: #14b8a6;
            --shadow: 0 14px 36px rgba(17,24,39,.08);
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font-family: "Manrope", ui-sans-serif, system-ui, sans-serif;
        }
        a { color: inherit; text-decoration: none; }
        img { max-width: 100%; display: block; }
        .embed-shell {
            min-height: 100vh;
            padding: 14px;
            display: grid;
            gap: 14px;
            background:
                radial-gradient(circle at top left, rgba(20,184,166,.10), transparent 24%),
                #fff;
        }
        .cover {
            min-height: 180px;
            border-radius: 24px;
            overflow: hidden;
            display: grid;
            place-items: center;
            background: linear-gradient(135deg, #d9f2ee, #fde7d7);
            color: var(--accent);
            font-size: 42px;
            font-weight: 800;
            box-shadow: var(--shadow);
        }
        .cover img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .badge-row, .actions-row, .meta-row {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 11px;
            border-radius: 999px;
            background: rgba(15,118,110,.08);
            color: var(--accent);
            font-weight: 700;
            font-size: 13px;
        }
        .pill.muted {
            background: rgba(17,24,39,.06);
            color: var(--muted);
        }
        .status-open {
            color: #027a48;
            background: rgba(18,183,106,.12);
        }
        .status-closed {
            color: #b42318;
            background: rgba(180,35,24,.12);
        }
        .body-card {
            padding: 18px;
            border-radius: 24px;
            border: 1px solid var(--line);
            background: rgba(255,255,255,.92);
            box-shadow: var(--shadow);
        }
        h1 {
            margin: 0 0 10px;
            font-size: 28px;
            line-height: 1.1;
        }
        p {
            margin: 0;
            color: var(--muted);
            line-height: 1.65;
        }
        .actions-row {
            margin-top: 14px;
        }
        .button, .button-secondary {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 11px 16px;
            border-radius: 999px;
            border: 1px solid var(--line);
            font-weight: 700;
        }
        .button {
            color: #fff;
            background: linear-gradient(135deg, var(--accent), var(--accent-2));
        }
        .button-secondary {
            background: rgba(255,255,255,.88);
        }
    </style>
</head>
<body>
    <div class="embed-shell">
        <div class="cover">
            @if($workshop['imageUrl'])
                <img src="{{ $workshop['imageUrl'] }}" alt="{{ $workshop['name'] }}">
            @else
                {{ strtoupper(mb_substr($workshop['name'], 0, 2)) }}
            @endif
        </div>

        <div class="body-card">
            <div class="badge-row" style="margin-bottom:12px;">
                <span class="pill {{ $workshop['isOpen'] ? 'status-open' : 'status-closed' }}">
                    {{ $workshop['isOpen'] ? 'Hozir ochiq' : 'Hozir yopiq' }}
                </span>
                @if($workshop['badge'])
                    <span class="pill">{{ $workshop['badge'] }}</span>
                @endif
                <span class="pill muted">⭐ {{ $workshop['rating'] }} · {{ $workshop['reviewCount'] }} sharh</span>
            </div>

            <h1>{{ $workshop['name'] }}</h1>
            <p>{{ $workshop['description'] ?: 'Ushbu ustaxona uchun tavsif tez orada yangilanadi.' }}</p>

            <div class="meta-row" style="margin-top:14px;">
                <span class="pill muted">{{ $workshop['distanceKm'] }} km</span>
                <span class="pill muted">Boshlanishi: {{ $workshop['startingPriceLabel'] }}</span>
                <span class="pill muted">{{ $workshop['address'] ?: 'Manzil ko‘rsatilmagan' }}</span>
            </div>

            <div class="actions-row">
                <a class="button-secondary" href="{{ $workshop['detailUrl'] }}" target="_top">To‘liq sahifa</a>
                @if($workshop['routeUrl'])
                    <a class="button" href="{{ $workshop['routeUrl'] }}" target="_blank" rel="noreferrer">Marshrut</a>
                @endif
            </div>
        </div>
    </div>
</body>
</html>
