<!doctype html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Usta Top Panel' }}</title>
    <style>
        :root {
            color-scheme: light only;
            --bg: #f6f4ef;
            --card: #ffffff;
            --line: #ddd;
            --line-strong: #c9c9c9;
            --text: #1c1c1c;
            --muted: #666;
            --accent: #0f766e;
            --accent-soft: #14b8a6;
            --danger: #8b1e1e;
            --warning: #9a5b00;
            --success-bg: #dcfce7;
            --error-bg: #fee2e2;
            --radius: 16px;
            --shadow: 0 16px 42px rgba(17, 24, 39, 0.06);
        }

        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: radial-gradient(circle at top left, rgba(20, 184, 166, 0.08), transparent 24%), var(--bg);
            color: var(--text);
            font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        .page {
            max-width: 1220px;
            margin: 0 auto;
            padding: 24px 20px 48px;
        }

        .nav {
            display: flex;
            gap: 12px;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .nav a,
        .nav button,
        .ghost-link,
        .pill-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 14px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.82);
            color: var(--text);
            text-decoration: none;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
        }

        .nav a.active {
            border-color: transparent;
            background: linear-gradient(135deg, var(--accent), var(--accent-soft));
            color: white;
        }

        .nav form { margin: 0; }
        .nav .spacer { flex: 1 1 auto; }
        .nav .muted { margin-left: auto; }

        .hero,
        .card,
        .metric-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
        }

        .card,
        .metric-card {
            padding: 16px;
            margin-bottom: 16px;
        }

        .hero {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            align-items: flex-start;
            flex-wrap: wrap;
            padding: 18px;
            margin-bottom: 16px;
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.95), rgba(243, 250, 249, 0.98));
        }

        .card-head,
        .chart-head,
        .summary-head {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
        }

        h1, h2, h3, p { margin: 0; }
        h1 { margin-bottom: 12px; font-size: 32px; }
        h2 { font-size: 22px; margin-bottom: 10px; }
        h3 { font-size: 17px; }

        form { display: grid; gap: 10px; }
        label { font-weight: 600; font-size: 14px; }
        textarea { min-height: 92px; resize: vertical; }
        input, select, button, textarea {
            padding: 10px 12px;
            border-radius: 10px;
            border: 1px solid #cfcfcf;
            font: inherit;
            width: 100%;
            background: white;
        }

        input:focus,
        select:focus,
        textarea:focus {
            outline: none;
            border-color: rgba(15, 118, 110, 0.5);
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.12);
        }

        button {
            cursor: pointer;
            background: linear-gradient(135deg, var(--accent), var(--accent-soft));
            color: white;
            border-color: transparent;
            font-weight: 700;
        }

        .button-secondary,
        .ghost-link {
            background: rgba(255, 255, 255, 0.85);
            color: var(--text);
            border-color: var(--line);
        }

        .danger,
        .button-danger {
            background: var(--danger);
            color: white;
            border-color: var(--danger);
        }

        .warning-btn {
            background: var(--warning);
            color: white;
            border-color: var(--warning);
        }

        .flash {
            padding: 12px 14px;
            border-radius: 12px;
            margin-bottom: 16px;
            font-weight: 600;
        }

        .flash.error { background: var(--error-bg); }
        .flash.success { background: var(--success-bg); }

        .grid-two {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }

        .filter-grid {
            display: grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 12px;
            align-items: end;
        }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 16px;
        }

        .metric-label {
            font-size: 13px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .metric-value {
            font-size: 28px;
            font-weight: 800;
            margin: 8px 0 6px;
        }

        .metric-hint, .muted, .hint {
            color: var(--muted);
            font-size: 14px;
            line-height: 1.55;
        }

        .section-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 16px;
        }

        .section-grid.single {
            grid-template-columns: 1fr;
        }

        .chart-list,
        .summary-list {
            display: grid;
            gap: 12px;
            margin-top: 14px;
        }

        .chart-row,
        .summary-row {
            display: grid;
            gap: 8px;
        }

        .bar-track {
            height: 10px;
            border-radius: 999px;
            background: #ece7dc;
            overflow: hidden;
        }

        .bar-fill {
            height: 100%;
            border-radius: 999px;
            background: linear-gradient(90deg, var(--accent), var(--accent-soft));
        }

        .summary-value {
            font-weight: 700;
        }

        .actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        .checkbox-row {
            display: flex;
            gap: 8px;
            align-items: center;
        }

        .checkbox-row input[type="checkbox"] {
            width: auto;
        }

        .image-preview {
            display: flex;
            gap: 14px;
            align-items: center;
            padding: 12px;
            border: 1px dashed #d6d0c5;
            border-radius: 14px;
            background: #fcfaf6;
            margin-bottom: 14px;
        }

        .image-preview img,
        .image-placeholder {
            width: 88px;
            height: 88px;
            border-radius: 18px;
            object-fit: cover;
            background: #ece6dc;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #8a6f3a;
            font-weight: 700;
            flex-shrink: 0;
        }

        .image-preview.empty {
            background: #faf7f1;
        }

        .login-shell {
            max-width: 520px;
            margin: 0 auto;
            padding-top: 80px;
        }

        .empty-state {
            text-align: center;
            padding: 22px;
        }

        @media (max-width: 960px) {
            .metrics-grid,
            .section-grid,
            .filter-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 720px) {
            .page { padding: 18px 14px 36px; }
            .grid-two,
            .metrics-grid,
            .section-grid,
            .filter-grid {
                grid-template-columns: 1fr;
            }
            .hero,
            .card-head,
            .chart-head,
            .summary-head {
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    <main class="page">
        @if (session('error'))
            <div class="flash error">{{ session('error') }}</div>
        @endif
        @if (session('success'))
            <div class="flash success">{{ session('success') }}</div>
        @endif

        @yield('content')
</main>
<script>
    (() => {
        const pageKey = `ustatop:panel:${window.location.pathname}${window.location.search}`;
        const scrollKey = `${pageKey}:scrollY`;
        const actionKey = `${pageKey}:action`;

        if ('scrollRestoration' in history) {
            history.scrollRestoration = 'manual';
        }

        const restorePosition = () => {
            const savedAction = sessionStorage.getItem(actionKey);
            const savedScroll = sessionStorage.getItem(scrollKey);

            if (!savedAction && !savedScroll) {
                return;
            }

            let restored = false;
            if (savedAction) {
                const matchingForm = Array.from(document.forms).find((form) => form.getAttribute('action') === savedAction);
                const target = matchingForm
                    ? (matchingForm.closest('.card, .metric-card, .hero, article') || matchingForm)
                    : null;
                if (target) {
                    target.scrollIntoView({ block: 'start' });
                    window.scrollBy(0, -16);
                    restored = true;
                }
            }

            if (!restored && savedScroll) {
                const top = Number(savedScroll);
                if (!Number.isNaN(top)) {
                    window.scrollTo({ top, left: 0, behavior: 'auto' });
                }
            }

            sessionStorage.removeItem(actionKey);
            sessionStorage.removeItem(scrollKey);
        };

        window.addEventListener('load', () => {
            window.requestAnimationFrame(() => {
                window.requestAnimationFrame(restorePosition);
            });
        });

        document.addEventListener('submit', (event) => {
            const form = event.target;
            if (!(form instanceof HTMLFormElement)) {
                return;
            }

            sessionStorage.setItem(scrollKey, String(window.scrollY));
            sessionStorage.setItem(actionKey, form.getAttribute('action') || '');
        });
    })();
</script>
</body>
</html>
