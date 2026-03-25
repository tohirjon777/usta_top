import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../admin_auth.dart';
import '../models.dart';
import '../store.dart';
import '../workshop_notifications.dart';

class AdminController {
  const AdminController(
    this._store, {
    required this.adminAuthService,
    required this.locationsFilePath,
    required this.workshopsFilePath,
    required this.notificationsService,
  });

  static const double _defaultLatitude = 41.3111;
  static const double _defaultLongitude = 69.2797;

  final InMemoryStore _store;
  final AdminAuthService adminAuthService;
  final String locationsFilePath;
  final String workshopsFilePath;
  final WorkshopNotificationsService notificationsService;

  Response entry(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    if (adminAuthService.isAuthenticated(request)) {
      return Response.seeOther(_adminPageUri(lang: lang));
    }
    return Response.seeOther(_loginPageUri(lang: lang));
  }

  Response loginPage(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String? error = request.url.queryParameters['error'];
    final String next = _sanitizeNext(
      request.url.queryParameters['next'],
      lang: lang,
    );
    if (adminAuthService.isAuthenticated(request)) {
      return Response.seeOther(Uri.parse(next));
    }

    final Uri langUzUri = _loginPageUri(lang: 'uz', next: next);
    final Uri langRuUri = _loginPageUri(lang: 'ru', next: next);
    final Uri langEnUri = _loginPageUri(lang: 'en', next: next);

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'adminLoginTitle'))}</title>
  <style>
    :root {
      color-scheme: light only;
      --bg: #f5efe5;
      --card: rgba(255, 251, 245, 0.94);
      --line: rgba(88, 67, 40, 0.14);
      --text: #221b16;
      --muted: #6b6259;
      --accent: #bf5b21;
      --accent-strong: #8f3811;
      --shadow: 0 18px 60px rgba(56, 34, 12, 0.1);
      --radius: 28px;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 20px;
      font-family: "Avenir Next", "Trebuchet MS", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(255, 205, 154, 0.9) 0, transparent 28%),
        radial-gradient(circle at 85% 10%, rgba(87, 145, 201, 0.18) 0, transparent 26%),
        linear-gradient(180deg, #fcfaf7 0%, var(--bg) 100%);
      color: var(--text);
    }

    .shell {
      width: min(100%, 980px);
      display: grid;
      gap: 18px;
    }

    .topbar, .card {
      background: var(--card);
      border: 1px solid var(--line);
      box-shadow: var(--shadow);
      border-radius: var(--radius);
    }

    .topbar {
      padding: 16px 18px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 14px;
      flex-wrap: wrap;
    }

    .brand-mark {
      width: 46px;
      height: 46px;
      border-radius: 16px;
      display: grid;
      place-items: center;
      background: linear-gradient(135deg, rgba(191, 91, 33, 0.95) 0%, rgba(143, 56, 17, 0.95) 100%);
      color: white;
      font-weight: 800;
      letter-spacing: 0.08em;
    }

    .brand-copy {
      display: grid;
      gap: 4px;
    }

    .eyebrow {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--accent-strong);
      font-weight: 700;
    }

    .brand-title, h1, h2, p { margin: 0; }
    .brand-title {
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: 24px;
      letter-spacing: -0.02em;
    }

    .lang-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .pill-link, .submit-btn {
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      border-radius: 999px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      cursor: pointer;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }

    .pill-link.active, .submit-btn {
      border-color: transparent;
      color: white;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
    }

    .card {
      overflow: hidden;
      display: grid;
      grid-template-columns: minmax(0, 1.15fr) minmax(320px, 0.85fr);
    }

    .hero, .form-wrap {
      padding: 28px;
      display: grid;
      gap: 16px;
    }

    .hero {
      background:
        radial-gradient(circle at top right, rgba(255, 216, 176, 0.85) 0, transparent 30%),
        linear-gradient(135deg, rgba(255, 250, 243, 0.96) 0%, rgba(247, 238, 229, 0.92) 100%);
    }

    .hero h1 {
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: clamp(34px, 5vw, 52px);
      line-height: 0.98;
      letter-spacing: -0.04em;
    }

    .hero p, .helper, .form-wrap p {
      color: var(--muted);
      line-height: 1.65;
    }

    .tips {
      display: grid;
      gap: 10px;
      padding: 0;
      margin: 0;
      list-style: none;
    }

    .tips li {
      padding: 12px 14px;
      border-radius: 18px;
      background: rgba(255, 249, 240, 0.9);
      border: 1px solid rgba(191, 91, 33, 0.1);
    }

    .form-wrap {
      background: rgba(255, 255, 255, 0.86);
    }

    .field {
      display: grid;
      gap: 8px;
    }

    .field label {
      font-size: 13px;
      font-weight: 700;
    }

    .field input {
      width: 100%;
      min-height: 52px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 15px;
      font-size: 15px;
      background: rgba(255, 255, 255, 0.92);
    }

    .field input:focus {
      outline: none;
      border-color: rgba(191, 91, 33, 0.5);
      box-shadow: 0 0 0 4px rgba(191, 91, 33, 0.12);
      background: white;
    }

    .alert {
      padding: 14px 16px;
      border-radius: 18px;
      background: #fff0ef;
      color: #c54b49;
      border: 1px solid rgba(197, 75, 73, 0.18);
      font-size: 14px;
      line-height: 1.5;
    }

    .helper {
      padding: 14px;
      border-radius: 18px;
      background: rgba(36, 49, 63, 0.04);
      border: 1px dashed rgba(36, 49, 63, 0.14);
      font-size: 14px;
    }

    @media (max-width: 860px) {
      .card {
        grid-template-columns: 1fr;
      }
      .hero, .form-wrap {
        padding: 20px;
      }
    }
  </style>
</head>
<body>
  <div class="shell">
    <div class="topbar">
      <div class="brand">
        <div class="brand-mark">UT</div>
        <div class="brand-copy">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'brandEyebrow'))}</div>
          <div class="brand-title">${_escapeHtml(_text(lang, 'brandTitle'))}</div>
        </div>
      </div>
      <div class="lang-row">
        <span class="eyebrow">${_escapeHtml(_text(lang, 'language'))}</span>
        <a class="pill-link${lang == 'uz' ? ' active' : ''}" href="${_escapeHtml(langUzUri.toString())}">UZ</a>
        <a class="pill-link${lang == 'ru' ? ' active' : ''}" href="${_escapeHtml(langRuUri.toString())}">RU</a>
        <a class="pill-link${lang == 'en' ? ' active' : ''}" href="${_escapeHtml(langEnUri.toString())}">EN</a>
      </div>
    </div>

    <section class="card">
      <div class="hero">
        <div class="eyebrow">${_escapeHtml(_text(lang, 'adminLoginEyebrow'))}</div>
        <h1>${_escapeHtml(_text(lang, 'adminLoginHeading'))}</h1>
        <p>${_escapeHtml(_text(lang, 'adminLoginDescription'))}</p>
        <ul class="tips">
          <li><strong>${_escapeHtml(_text(lang, 'adminLoginTip1Title'))}</strong><br>${_escapeHtml(_text(lang, 'adminLoginTip1Body'))}</li>
          <li><strong>${_escapeHtml(_text(lang, 'adminLoginTip2Title'))}</strong><br>${_escapeHtml(_text(lang, 'adminLoginTip2Body'))}</li>
          <li><strong>${_escapeHtml(_text(lang, 'adminLoginTip3Title'))}</strong><br>${_escapeHtml(_text(lang, 'adminLoginTip3Body'))}</li>
        </ul>
      </div>

      <div class="form-wrap">
        <div class="eyebrow">${_escapeHtml(_text(lang, 'adminLoginFormEyebrow'))}</div>
        <h2>${_escapeHtml(_text(lang, 'adminLoginTitle'))}</h2>
        <p>${_escapeHtml(_text(lang, 'adminLoginFormSubtitle'))}</p>
        ${error != null && error.isNotEmpty ? '<div class="alert">${_escapeHtml(error)}</div>' : ''}
        <form method="post" action="/admin/login">
          <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
          <input type="hidden" name="next" value="${_escapeHtml(next)}">
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'adminUsername'))}</label>
            <input type="text" name="username" autocomplete="username" placeholder="${_escapeHtml(adminAuthService.username)}">
          </div>
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'adminPassword'))}</label>
            <input type="password" name="password" autocomplete="current-password" placeholder="${_escapeHtml(_text(lang, 'adminPasswordPlaceholder'))}">
          </div>
          <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'adminLoginButton'))}</button>
        </form>
        <div class="helper">${_escapeHtml(_text(lang, 'adminLoginHelper'))}</div>
      </div>
    </section>
  </div>
</body>
</html>
''';

    return Response.ok(
      html,
      headers: const <String, String>{
        'content-type': 'text/html; charset=utf-8',
      },
    );
  }

  Future<Response> login(Request request) async {
    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String next = _sanitizeNext(form['next'], lang: lang);
    final String username = (form['username'] ?? '').trim();
    final String password = (form['password'] ?? '').toString();

    if (username.isEmpty || password.isEmpty) {
      return Response.seeOther(
        _loginPageUri(
          lang: lang,
          next: next,
          error: _text(lang, 'adminLoginMissing'),
        ),
      );
    }

    if (!adminAuthService.validateCredentials(
      username: username,
      password: password,
    )) {
      return Response.seeOther(
        _loginPageUri(
          lang: lang,
          next: next,
          error: _text(lang, 'adminLoginInvalid'),
        ),
      );
    }

    final String token = adminAuthService.createSession();
    return Response.seeOther(
      Uri.parse(next),
      headers: <String, String>{
        'set-cookie': adminAuthService.buildSessionCookie(token),
      },
    );
  }

  Response logout(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    adminAuthService.revokeSession(adminAuthService.readSessionToken(request));
    return Response.seeOther(
      _loginPageUri(lang: lang),
      headers: <String, String>{
        'set-cookie': adminAuthService.buildClearedSessionCookie(),
      },
    );
  }

  Response workshopsPage(Request request) {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String query = (request.url.queryParameters['q'] ?? '').trim();
    final String status =
        _normalizeStatus(request.url.queryParameters['status']);
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];
    final Uri refreshUri = _adminPageUri(
      query: query,
      status: status,
      lang: lang,
    );
    final Uri resetUri = _adminPageUri(lang: lang);
    final Uri langUzUri = _adminPageUri(
      query: query,
      status: status,
      lang: 'uz',
    );
    final Uri langRuUri = _adminPageUri(
      query: query,
      status: status,
      lang: 'ru',
    );
    final Uri langEnUri = _adminPageUri(
      query: query,
      status: status,
      lang: 'en',
    );
    final Uri bookingsUri = _adminBookingsPageUri(lang: lang);
    final Uri reviewsUri = _adminReviewsPageUri(lang: lang);

    final List<WorkshopModel> allWorkshops = _store.workshops();
    final List<WorkshopModel> searchResults = _store.workshops(query: query);
    final List<WorkshopModel> workshops = _applyStatusFilter(
      searchResults,
      status: status,
    );

    final int openCount =
        allWorkshops.where((WorkshopModel item) => item.isOpen).length;
    final int closedCount = allWorkshops.length - openCount;
    final int serviceCount = allWorkshops.fold<int>(
      0,
      (int sum, WorkshopModel item) => sum + item.services.length,
    );
    final double ratingSum = allWorkshops.fold<double>(
      0,
      (double sum, WorkshopModel item) => sum + item.rating,
    );
    final double averageRating =
        allWorkshops.isEmpty ? 0 : ratingSum / allWorkshops.length;

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'pageTitle'))}</title>
  <link
    rel="stylesheet"
    href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
  <style>
    :root {
      color-scheme: light only;
      --bg: #f5efe5;
      --card: rgba(255, 251, 245, 0.92);
      --line: rgba(88, 67, 40, 0.14);
      --line-strong: rgba(88, 67, 40, 0.24);
      --text: #221b16;
      --muted: #6b6259;
      --accent: #bf5b21;
      --accent-strong: #8f3811;
      --accent-soft: #ffe2c7;
      --ink: #24313f;
      --mint: #1f8a63;
      --mint-soft: #e8f7f0;
      --red: #c54b49;
      --red-soft: #fff0ef;
      --shadow: 0 18px 60px rgba(56, 34, 12, 0.09);
      --radius-xl: 28px;
      --radius-lg: 22px;
      --radius-md: 18px;
    }

    * { box-sizing: border-box; }

    html { scroll-behavior: smooth; }

    body {
      margin: 0;
      min-height: 100vh;
      position: relative;
      font-family: "Avenir Next", "Trebuchet MS", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(255, 205, 154, 0.9) 0, transparent 28%),
        radial-gradient(circle at 85% 10%, rgba(87, 145, 201, 0.18) 0, transparent 26%),
        linear-gradient(180deg, #fcfaf7 0%, var(--bg) 100%);
      color: var(--text);
    }

    body::before {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      background-image:
        linear-gradient(rgba(34, 27, 22, 0.035) 1px, transparent 1px),
        linear-gradient(90deg, rgba(34, 27, 22, 0.035) 1px, transparent 1px);
      background-size: 28px 28px;
      mask-image: linear-gradient(180deg, rgba(0, 0, 0, 0.9), transparent 95%);
      opacity: 0.45;
    }

    a { color: inherit; text-decoration: none; }
    button, input, select, textarea { font: inherit; }

    .wrap {
      max-width: 1460px;
      margin: 0 auto;
      padding: 28px 18px 64px;
    }

    .topbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 18px;
      flex-wrap: wrap;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 14px;
      flex-wrap: wrap;
    }

    .brand-mark {
      width: 48px;
      height: 48px;
      border-radius: 16px;
      background: linear-gradient(135deg, rgba(191, 91, 33, 0.95) 0%, rgba(143, 56, 17, 0.95) 100%);
      display: grid;
      place-items: center;
      color: white;
      font-weight: 800;
      letter-spacing: 0.08em;
      box-shadow: 0 12px 30px rgba(143, 56, 17, 0.28);
    }

    .brand-copy { display: grid; gap: 4px; }

    .eyebrow {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--accent-strong);
      font-weight: 700;
    }

    .brand-title {
      margin: 0;
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: 24px;
      letter-spacing: -0.02em;
    }

    .top-actions, .chip-row, .preview-links, .service-toolbar, .inline-actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .pill-link, .ghost-btn, .mini-link, .danger-btn {
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.62);
      border-radius: 999px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 700;
      color: var(--ink);
      transition: transform 160ms ease, border-color 160ms ease,
          background 160ms ease, box-shadow 160ms ease;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      cursor: pointer;
    }

    .pill-link:hover, .ghost-btn:hover, .mini-link:hover, .danger-btn:hover {
      transform: translateY(-1px);
      border-color: var(--line-strong);
      box-shadow: 0 10px 22px rgba(36, 49, 63, 0.08);
    }

    .danger-btn {
      background: var(--red-soft);
      color: var(--red);
      border-color: rgba(197, 75, 73, 0.2);
    }

    .hero-card, .card {
      background: var(--card);
      backdrop-filter: blur(10px);
      border: 1px solid var(--line);
      box-shadow: var(--shadow);
    }

    .hero-card {
      border-radius: 34px;
      overflow: hidden;
      position: relative;
      padding: 28px;
      margin-bottom: 18px;
      background:
        radial-gradient(circle at top right, rgba(255, 216, 176, 0.95) 0, transparent 30%),
        linear-gradient(135deg, rgba(255, 250, 243, 0.96) 0%, rgba(247, 238, 229, 0.92) 100%);
    }

    .hero-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.55fr) minmax(280px, 0.95fr);
      gap: 22px;
      align-items: stretch;
    }

    .hero-copy h1 {
      margin: 8px 0 12px;
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: clamp(36px, 4.9vw, 60px);
      line-height: 0.98;
      letter-spacing: -0.045em;
    }

    .hero-copy p, .toolbar-title p, .sidebar p, .editor-head p, .helper-box, .result-count {
      margin: 0;
      color: var(--muted);
      line-height: 1.65;
    }

    .hero-actions {
      margin-top: 18px;
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
    }

    .hero-primary, .submit-btn, .save-btn {
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
      color: white;
      border-color: transparent;
      box-shadow: 0 14px 30px rgba(143, 56, 17, 0.22);
    }

    .hero-side {
      background: rgba(255, 255, 255, 0.62);
      border: 1px solid rgba(88, 67, 40, 0.12);
      border-radius: var(--radius-xl);
      padding: 20px;
      display: grid;
      gap: 14px;
    }

    .hero-side h2, .toolbar-title h2, .sidebar h3, .workshop-head h2, .editor-head h4 {
      margin: 0;
    }

    .hero-list, .tips {
      display: grid;
      gap: 10px;
      margin: 0;
      padding: 0;
      list-style: none;
    }

    .hero-list li, .tips li {
      display: grid;
      gap: 4px;
      padding: 12px 14px;
      border-radius: 18px;
      background: rgba(255, 249, 240, 0.9);
      border: 1px solid rgba(191, 91, 33, 0.1);
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
      margin-bottom: 18px;
    }

    .stat-card {
      border-radius: 24px;
      padding: 18px;
      position: relative;
      overflow: hidden;
    }

    .stat-card::after {
      content: "";
      position: absolute;
      inset: auto -28px -28px auto;
      width: 120px;
      height: 120px;
      border-radius: 50%;
      background: rgba(191, 91, 33, 0.08);
    }

    .stat-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.13em;
      color: var(--muted);
      font-weight: 700;
      position: relative;
      z-index: 1;
    }

    .stat-value {
      margin-top: 10px;
      font-size: clamp(28px, 3vw, 36px);
      line-height: 1;
      font-weight: 800;
      letter-spacing: -0.05em;
      position: relative;
      z-index: 1;
    }

    .stat-sub {
      margin-top: 8px;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.45;
      position: relative;
      z-index: 1;
    }

    .flash {
      margin: 0 0 18px;
      padding: 16px 18px;
      border-radius: 20px;
      font-size: 15px;
      line-height: 1.45;
      border: 1px solid transparent;
    }

    .flash.ok {
      background: var(--mint-soft);
      color: var(--mint);
      border-color: rgba(31, 138, 99, 0.16);
    }

    .flash.err {
      background: var(--red-soft);
      color: var(--red);
      border-color: rgba(197, 75, 73, 0.16);
    }

    .layout {
      display: grid;
      grid-template-columns: minmax(0, 1.55fr) minmax(300px, 0.8fr);
      gap: 18px;
      align-items: start;
    }

    .main-column, .sidebar, .workshop-list {
      display: grid;
      gap: 16px;
    }

    .card {
      border-radius: var(--radius-xl);
      padding: 20px;
    }

    .toolbar-card, .sidebar-panel, .editor-panel, .preview-panel {
      display: grid;
      gap: 16px;
    }

    .toolbar-row, .results-row, .editor-footer, .workshop-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      flex-wrap: wrap;
    }

    .filter-form, .editor-form {
      display: grid;
      gap: 14px;
    }

    .inline-form {
      margin: 0;
    }

    .filter-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.6fr) minmax(180px, 0.7fr) auto;
      gap: 12px;
      align-items: end;
    }

    .field-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
    }

    .field-grid.three {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .field-grid.four {
      grid-template-columns: repeat(4, minmax(0, 1fr));
    }

    .field {
      display: grid;
      gap: 8px;
    }

    .field label {
      font-size: 13px;
      font-weight: 700;
      color: var(--ink);
    }

    .field input,
    .field select,
    .field textarea {
      width: 100%;
      min-height: 52px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 15px;
      font-size: 15px;
      background: rgba(255, 255, 255, 0.82);
      color: var(--text);
    }

    .field textarea {
      resize: vertical;
      min-height: 108px;
    }

    .field input:focus,
    .field select:focus,
    .field textarea:focus {
      outline: none;
      border-color: rgba(191, 91, 33, 0.5);
      box-shadow: 0 0 0 4px rgba(191, 91, 33, 0.12);
      background: white;
    }

    .checkbox-row {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      font-size: 14px;
      font-weight: 700;
      color: var(--ink);
    }

    .checkbox-row input {
      width: 18px;
      height: 18px;
      min-height: 18px;
      accent-color: var(--accent);
    }

    .checkbox-pills {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .checkbox-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 12px;
      border-radius: 999px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.82);
      color: var(--ink);
      font-size: 13px;
      font-weight: 700;
    }

    .checkbox-pill input {
      width: 16px;
      height: 16px;
      min-height: 16px;
      accent-color: var(--accent);
    }

    .chip {
      padding: 9px 12px;
      border-radius: 999px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.68);
      font-size: 13px;
      font-weight: 700;
      color: var(--ink);
    }

    .sidebar-panel {
      position: sticky;
      top: 18px;
    }

    .storage-block {
      padding: 16px;
      border-radius: 18px;
      background: linear-gradient(180deg, rgba(36, 49, 63, 0.05), rgba(36, 49, 63, 0.02));
      border: 1px solid rgba(36, 49, 63, 0.08);
      display: grid;
      gap: 10px;
    }

    .path-view {
      margin: 0;
      padding: 14px;
      border-radius: 16px;
      background: #201b19;
      color: #f8efe3;
      font-family: "SFMono-Regular", Menlo, monospace;
      font-size: 13px;
      line-height: 1.5;
      overflow-x: auto;
    }

    .workshop-card {
      display: grid;
      gap: 18px;
    }

    .head-tags, .service-row {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      align-items: center;
    }

    .tag, .status-pill, .service-pill {
      display: inline-flex;
      align-items: center;
      border-radius: 999px;
      padding: 9px 12px;
      font-size: 13px;
      font-weight: 700;
      line-height: 1;
    }

    .tag {
      background: var(--accent-soft);
      color: var(--accent-strong);
    }

    .status-pill {
      border: 1px solid transparent;
    }

    .status-open {
      background: var(--mint-soft);
      color: var(--mint);
      border-color: rgba(31, 138, 99, 0.16);
    }

    .status-closed {
      background: var(--red-soft);
      color: var(--red);
      border-color: rgba(197, 75, 73, 0.16);
    }

    .service-pill {
      background: rgba(36, 49, 63, 0.06);
      color: var(--ink);
      border: 1px solid rgba(36, 49, 63, 0.08);
    }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 12px;
    }

    .info-item {
      padding: 14px;
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.7);
      border: 1px solid rgba(36, 49, 63, 0.08);
      display: grid;
      gap: 7px;
    }

    .info-item span {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--muted);
      font-weight: 700;
    }

    .info-item strong {
      font-size: 18px;
      line-height: 1.2;
    }

    .editor-layout {
      display: grid;
      grid-template-columns: minmax(280px, 0.88fr) minmax(0, 1.12fr);
      gap: 16px;
      align-items: start;
    }

    .preview-panel {
      border-radius: var(--radius-lg);
      background:
        linear-gradient(180deg, rgba(255, 248, 240, 0.92), rgba(248, 239, 231, 0.82));
      border: 1px solid rgba(36, 49, 63, 0.08);
      padding: 16px;
    }

    .preview-map {
      position: relative;
      min-height: 220px;
      overflow: hidden;
      border-radius: 22px;
      border: 1px solid rgba(36, 49, 63, 0.09);
      background:
        radial-gradient(circle at 20% 20%, rgba(255, 211, 168, 0.9) 0, transparent 28%),
        radial-gradient(circle at 78% 26%, rgba(110, 171, 231, 0.36) 0, transparent 32%),
        linear-gradient(135deg, #fef8f1 0%, #efe2d0 100%);
      --pin-x: 50%;
      --pin-y: 50%;
    }

    .preview-map::before {
      content: "";
      position: absolute;
      inset: 0;
      background-image:
        linear-gradient(rgba(36, 49, 63, 0.08) 1px, transparent 1px),
        linear-gradient(90deg, rgba(36, 49, 63, 0.08) 1px, transparent 1px);
      background-size: 38px 38px;
      opacity: 0.7;
    }

    .preview-map::after {
      content: "";
      position: absolute;
      inset: 16px;
      border-radius: 18px;
      border: 1px solid rgba(255, 255, 255, 0.8);
      pointer-events: none;
    }

    .preview-map.is-invalid {
      filter: grayscale(0.22);
      opacity: 0.78;
    }

    .preview-hud {
      position: absolute;
      top: 14px;
      left: 14px;
      z-index: 2;
      padding: 8px 11px;
      border-radius: 999px;
      background: rgba(34, 27, 22, 0.72);
      color: white;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    .map-pin {
      position: absolute;
      left: var(--pin-x);
      top: var(--pin-y);
      width: 22px;
      height: 22px;
      transform: translate(-50%, -50%);
      z-index: 3;
    }

    .map-pin::before,
    .map-pin::after {
      content: "";
      position: absolute;
      inset: 0;
      border-radius: 999px;
    }

    .map-pin::before {
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
      box-shadow: 0 0 0 8px rgba(191, 91, 33, 0.16),
          0 8px 18px rgba(143, 56, 17, 0.26);
    }

    .map-pin::after {
      inset: -20px;
      border: 2px solid rgba(191, 91, 33, 0.24);
      animation: pulse 2.2s ease-out infinite;
    }

    .coord-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
    }

    .coord-card {
      border-radius: 18px;
      padding: 14px;
      background: rgba(255, 255, 255, 0.82);
      border: 1px solid rgba(36, 49, 63, 0.08);
      display: grid;
      gap: 6px;
    }

    .coord-card span {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--muted);
      font-weight: 700;
    }

    .coord-card strong {
      font-size: 18px;
      font-family: "SFMono-Regular", Menlo, monospace;
    }

    .editor-panel {
      border-radius: var(--radius-lg);
      background: rgba(255, 255, 255, 0.72);
      border: 1px solid rgba(36, 49, 63, 0.08);
      padding: 16px;
    }

    .helper-box {
      border-radius: 18px;
      padding: 14px;
      background: rgba(36, 49, 63, 0.04);
      border: 1px dashed rgba(36, 49, 63, 0.14);
      font-size: 14px;
    }

    .service-list {
      display: grid;
      gap: 10px;
    }

    .service-row-editor {
      padding: 12px;
      border-radius: 18px;
      border: 1px solid rgba(36, 49, 63, 0.08);
      background: rgba(255, 255, 255, 0.78);
      display: grid;
      gap: 10px;
    }

    .service-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.4fr) repeat(2, minmax(0, 0.8fr));
      gap: 10px;
    }

    .muted {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.5;
    }

    .empty-state {
      display: grid;
      gap: 12px;
      text-align: center;
      justify-items: center;
      padding: 44px 20px;
    }

    .empty-state h3 {
      margin: 0;
      font-size: 24px;
    }

    .map-modal {
      position: fixed;
      inset: 0;
      z-index: 999;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 20px;
      background: rgba(20, 18, 17, 0.58);
      backdrop-filter: blur(6px);
    }

    .map-modal.open {
      display: flex;
    }

    .map-dialog {
      width: min(1100px, 100%);
      background: rgba(255, 251, 245, 0.98);
      border-radius: 28px;
      border: 1px solid rgba(88, 67, 40, 0.12);
      box-shadow: 0 24px 80px rgba(20, 18, 17, 0.22);
      padding: 18px;
      display: grid;
      gap: 14px;
    }

    .map-toolbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }

    .map-meta {
      color: var(--muted);
      font-size: 14px;
      line-height: 1.5;
    }

    #pickerMap {
      width: 100%;
      height: min(68vh, 560px);
      border-radius: 20px;
      overflow: hidden;
      border: 1px solid rgba(36, 49, 63, 0.1);
    }

    .map-coords {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .map-coords .chip {
      font-family: "SFMono-Regular", Menlo, monospace;
    }

    .mini-link { min-height: 44px; }

    @keyframes pulse {
      0% { transform: scale(0.58); opacity: 0.9; }
      100% { transform: scale(1.2); opacity: 0; }
    }

    @media (max-width: 1200px) {
      .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .layout { grid-template-columns: 1fr; }
      .sidebar-panel { position: static; }
    }

    @media (max-width: 980px) {
      .hero-grid, .editor-layout, .filter-grid { grid-template-columns: 1fr; }
      .info-grid, .field-grid.three, .field-grid.four { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }

    @media (max-width: 720px) {
      .wrap { padding: 18px 12px 40px; }
      .hero-card, .card { border-radius: 24px; padding: 16px; }
      .stats-grid, .info-grid, .coord-grid, .field-grid, .service-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="topbar">
      <div class="brand">
        <div class="brand-mark">UT</div>
        <div class="brand-copy">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'brandEyebrow'))}</div>
          <h1 class="brand-title">${_escapeHtml(_text(lang, 'brandTitle'))}</h1>
        </div>
      </div>
      <div class="top-actions">
        <a class="pill-link hero-primary" href="${_escapeHtml(refreshUri.toString())}">${_escapeHtml(_text(lang, 'workshopsTab'))}</a>
        <a class="pill-link" href="${_escapeHtml(bookingsUri.toString())}">${_escapeHtml(_text(lang, 'bookingsTab'))}</a>
        <a class="pill-link" href="${_escapeHtml(reviewsUri.toString())}">${_escapeHtml(_text(lang, 'reviewsTab'))}</a>
        <span class="chip">${_escapeHtml(_text(lang, 'language'))}</span>
        <a class="pill-link${lang == 'uz' ? ' hero-primary' : ''}" href="${_escapeHtml(langUzUri.toString())}">UZ</a>
        <a class="pill-link${lang == 'ru' ? ' hero-primary' : ''}" href="${_escapeHtml(langRuUri.toString())}">RU</a>
        <a class="pill-link${lang == 'en' ? ' hero-primary' : ''}" href="${_escapeHtml(langEnUri.toString())}">EN</a>
        <a class="pill-link" href="${_escapeHtml(refreshUri.toString())}">${_escapeHtml(_text(lang, 'refreshPanel'))}</a>
        <a class="pill-link" href="/health" target="_blank" rel="noreferrer">${_escapeHtml(_text(lang, 'healthEndpoint'))}</a>
        <form class="inline-form" method="post" action="/admin/logout?lang=${_escapeHtml(lang)}">
          <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'logout'))}</button>
        </form>
      </div>
    </div>

    <section class="hero-card">
      <div class="hero-grid">
        <div class="hero-copy">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'heroEyebrow'))}</div>
          <h1>${_escapeHtml(_text(lang, 'heroTitle'))}</h1>
          <p>${_escapeHtml(_text(lang, 'heroDescription'))}</p>
          <div class="hero-actions">
            <a class="pill-link hero-primary" href="#create-workshop">${_escapeHtml(_text(lang, 'heroPrimaryAction'))}</a>
            <a class="pill-link" href="#workshop-list">${_escapeHtml(_text(lang, 'heroSecondaryAction'))}</a>
          </div>
        </div>
        <div class="hero-side">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'workflowEyebrow'))}</div>
          <h2>${_escapeHtml(_text(lang, 'workflowTitle'))}</h2>
          <ul class="hero-list">
            <li>
              <strong>${_escapeHtml(_text(lang, 'workflowStep1Title'))}</strong>
              <span>${_escapeHtml(_text(lang, 'workflowStep1Body'))}</span>
            </li>
            <li>
              <strong>${_escapeHtml(_text(lang, 'workflowStep2Title'))}</strong>
              <span>${_escapeHtml(_text(lang, 'workflowStep2Body'))}</span>
            </li>
            <li>
              <strong>${_escapeHtml(_text(lang, 'workflowStep3Title'))}</strong>
              <span>${_escapeHtml(_text(lang, 'workflowStep3Body'))}</span>
            </li>
          </ul>
        </div>
      </div>
    </section>

    <section class="stats-grid">
      <div class="card stat-card">
        <div class="stat-label">${_escapeHtml(_text(lang, 'statWorkshopsLabel'))}</div>
        <div class="stat-value">${allWorkshops.length}</div>
        <div class="stat-sub">${_escapeHtml(_text(lang, 'statWorkshopsSub'))}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">${_escapeHtml(_text(lang, 'statStatusLabel'))}</div>
        <div class="stat-value">$openCount / $closedCount</div>
        <div class="stat-sub">${_escapeHtml(_text(lang, 'statStatusSub'))}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">${_escapeHtml(_text(lang, 'statRatingLabel'))}</div>
        <div class="stat-value">${averageRating.toStringAsFixed(1)}</div>
        <div class="stat-sub">${_escapeHtml(_text(lang, 'statRatingSub'))}</div>
      </div>
      <div class="card stat-card">
        <div class="stat-label">${_escapeHtml(_text(lang, 'statServicesLabel'))}</div>
        <div class="stat-value">$serviceCount</div>
        <div class="stat-sub">${_escapeHtml(_text(lang, 'statServicesSub'))}</div>
      </div>
    </section>

    ${_flashHtml(message: message, error: error)}

    <div class="layout">
      <main class="main-column">
        <section class="card toolbar-card" id="create-workshop">
          <div class="toolbar-row">
            <div class="toolbar-title">
              <div class="eyebrow">${_escapeHtml(_text(lang, 'createEyebrow'))}</div>
              <h2>${_escapeHtml(_text(lang, 'createTitle'))}</h2>
              <p>${_escapeHtml(_text(lang, 'createSubtitle'))}</p>
            </div>
            <div class="chip-row">
              <span class="chip">${_escapeHtml(_text(lang, 'searchResultsChip', <String, Object>{
          'count': searchResults.length
        }))}</span>
              <span class="chip">${_escapeHtml(_text(lang, 'visibleChip', <String, Object>{
          'count': workshops.length
        }))}</span>
            </div>
          </div>
          ${_createWorkshopPanelHtml(lang)}
        </section>

        <section class="card toolbar-card" id="workshop-list">
          <div class="toolbar-row">
            <div class="toolbar-title">
              <div class="eyebrow">${_escapeHtml(_text(lang, 'manageEyebrow'))}</div>
              <h2>${_escapeHtml(_text(lang, 'manageTitle'))}</h2>
              <p>${_escapeHtml(_text(lang, 'manageSubtitle'))}</p>
            </div>
            <div class="chip-row">
              <span class="chip">${_escapeHtml(_text(lang, 'statusChip', <String, Object>{
          'status': _statusLabel(status, lang)
        }))}</span>
            </div>
          </div>

          <form class="filter-form" method="get" action="/admin/workshops">
            <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
            <div class="filter-grid">
              <div class="field">
                <label for="search">${_escapeHtml(_text(lang, 'searchLabel'))}</label>
                <input
                  id="search"
                  type="search"
                  name="q"
                  value="${_escapeHtml(query)}"
                  placeholder="${_escapeHtml(_text(lang, 'searchPlaceholder'))}">
              </div>
              <div class="field">
                <label for="status">${_escapeHtml(_text(lang, 'statusFilterLabel'))}</label>
                <select id="status" name="status">
                  <option value="all"${_selectedAttr(status == 'all')}>${_escapeHtml(_text(lang, 'statusAll'))}</option>
                  <option value="open"${_selectedAttr(status == 'open')}>${_escapeHtml(_text(lang, 'statusOpenOnly'))}</option>
                  <option value="closed"${_selectedAttr(status == 'closed')}>${_escapeHtml(_text(lang, 'statusClosedOnly'))}</option>
                </select>
              </div>
              <div class="inline-actions">
                <a class="ghost-btn" href="${_escapeHtml(resetUri.toString())}">${_escapeHtml(_text(lang, 'resetFilters'))}</a>
                <button class="pill-link hero-primary" type="submit">${_escapeHtml(_text(lang, 'applyFilter'))}</button>
              </div>
            </div>
          </form>

          <div class="results-row">
            <div class="result-count">
              ${_escapeHtml(_resultsSummary(
      lang: lang,
      totalCount: allWorkshops.length,
      searchCount: searchResults.length,
      visibleCount: workshops.length,
      query: query,
      status: status,
    ))}
            </div>
          </div>
        </section>

        <div class="workshop-list">
          ${workshops.isEmpty ? _emptyStateHtml(lang: lang, query: query, status: status) : workshops.map(
              (WorkshopModel item) => _workshopCardHtml(
                lang,
                item,
                returnQuery: query,
                returnStatus: status,
              ),
            ).join('\n')}
        </div>
      </main>

      <aside class="sidebar">
        <section class="card sidebar-panel">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'sidebarEyebrow'))}</div>
          <h3>${_escapeHtml(_text(lang, 'sidebarTitle'))}</h3>
          <p>${_escapeHtml(_text(lang, 'sidebarSubtitle'))}</p>
          <ul class="tips">
            <li>${_escapeHtml(_text(lang, 'sidebarTip1'))}</li>
            <li>${_escapeHtml(_text(lang, 'sidebarTip2'))}</li>
            <li>${_escapeHtml(_text(lang, 'sidebarTip3'))}</li>
          </ul>
          <div class="storage-block">
            <div class="eyebrow">${_escapeHtml(_text(lang, 'workshopsFileLabel'))}</div>
            <pre class="path-view">${_escapeHtml(workshopsFilePath)}</pre>
          </div>
          <div class="storage-block">
            <div class="eyebrow">${_escapeHtml(_text(lang, 'locationFileLabel'))}</div>
            <pre class="path-view">${_escapeHtml(locationsFilePath)}</pre>
          </div>
        </section>
      </aside>
    </div>
  </div>

  <div class="map-modal" id="mapModal">
    <div class="map-dialog">
      <div class="map-toolbar">
        <div>
          <div class="eyebrow">${_escapeHtml(_text(lang, 'mapPickerEyebrow'))}</div>
          <div class="map-meta">${_escapeHtml(_text(lang, 'mapPickerMeta'))}</div>
        </div>
        <div class="inline-actions">
          <button class="ghost-btn" type="button" id="mapCloseButton">${_escapeHtml(_text(lang, 'close'))}</button>
        </div>
      </div>
      <div class="map-coords">
        <span class="chip" id="mapLatChip">lat: --</span>
        <span class="chip" id="mapLngChip">lng: --</span>
      </div>
      <div id="pickerMap"></div>
    </div>
  </div>

  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script>
    (function () {
      var labels = ${jsonEncode(_jsLabels(lang))};
      var DEFAULT_LAT = ${_defaultLatitude.toStringAsFixed(6)};
      var DEFAULT_LNG = ${_defaultLongitude.toStringAsFixed(6)};
      var modal = document.getElementById('mapModal');
      var mapCloseButton = document.getElementById('mapCloseButton');
      var latChip = document.getElementById('mapLatChip');
      var lngChip = document.getElementById('mapLngChip');
      var mapInstance = null;
      var mapMarker = null;
      var activeRoot = null;

      function normalizeNumber(value) {
        return String(value || '').trim().replace(',', '.');
      }

      function isValidCoordinate(lat, lng) {
        return Number.isFinite(lat) &&
          Number.isFinite(lng) &&
          lat >= -90 && lat <= 90 &&
          lng >= -180 && lng <= 180;
      }

      function updateChips(lat, lng) {
        latChip.textContent = 'lat: ' + (Number.isFinite(lat) ? lat.toFixed(6) : '--');
        lngChip.textContent = 'lng: ' + (Number.isFinite(lng) ? lng.toFixed(6) : '--');
      }

      function updatePreview(root) {
        var latInput = root.querySelector('[data-lat-input]');
        var lngInput = root.querySelector('[data-lng-input]');
        var latPreview = root.querySelector('[data-preview-lat]');
        var lngPreview = root.querySelector('[data-preview-lng]');
        var previewMap = root.querySelector('[data-map-preview]');
        var yandexLink = root.querySelector('[data-map-link="yandex"]');
        var googleLink = root.querySelector('[data-map-link="google"]');
        var osmLink = root.querySelector('[data-map-link="osm"]');
        var copyButton = root.querySelector('[data-copy-btn]');
        var latRaw = normalizeNumber(latInput.value);
        var lngRaw = normalizeNumber(lngInput.value);
        var lat = Number(latRaw);
        var lng = Number(lngRaw);
        var valid = isValidCoordinate(lat, lng);

        latPreview.textContent = latRaw || '--';
        lngPreview.textContent = lngRaw || '--';
        previewMap.classList.toggle('is-invalid', !valid);
        copyButton.disabled = !valid;

        if (!valid) {
          return;
        }

        var x = ((lng + 180) / 360) * 100;
        var y = ((90 - lat) / 180) * 100;
        previewMap.style.setProperty('--pin-x', x.toFixed(2) + '%');
        previewMap.style.setProperty('--pin-y', y.toFixed(2) + '%');

        var latText = lat.toFixed(6);
        var lngText = lng.toFixed(6);
        yandexLink.href = 'https://yandex.com/maps/?pt=' + lngText + ',' + latText + '&z=15&l=map';
        googleLink.href = 'https://www.google.com/maps?q=' + latText + ',' + lngText;
        osmLink.href = 'https://www.openstreetmap.org/?mlat=' + latText + '&mlon=' + lngText + '#map=15/' + latText + '/' + lngText;
      }

      function createEmptyService() {
        return {
          id: '',
          name: '',
          price: '',
          durationMinutes: ''
        };
      }

      function syncServices(root, services) {
        var hiddenInput = root.querySelector('[data-services-json]');
        hiddenInput.value = JSON.stringify(
          services.map(function (item) {
            return {
              id: String(item.id || '').trim(),
              name: String(item.name || '').trim(),
              price: String(item.price || '').trim(),
              durationMinutes: String(item.durationMinutes || '').trim()
            };
          })
        );
      }

      function renderServices(root, services) {
        var container = root.querySelector('[data-services-container]');
        container.innerHTML = '';

        services.forEach(function (service, index) {
          var row = document.createElement('div');
          row.className = 'service-row-editor';
          row.innerHTML =
            '<div class="service-toolbar">' +
              '<strong>' + labels.serviceItem + ' #' + (index + 1) + '</strong>' +
              '<button class="danger-btn" type="button" data-remove-service>' + labels.remove + '</button>' +
            '</div>' +
            '<div class="service-grid">' +
              '<div class="field">' +
                '<label>' + labels.name + '</label>' +
                '<input type="text" data-service-name value="' + escapeHtml(service.name || '') + '" placeholder="' + labels.serviceNamePlaceholder + '">' +
              '</div>' +
              '<div class="field">' +
                '<label>' + labels.price + '</label>' +
                '<input type="number" min="0" data-service-price value="' + escapeHtml(service.price || '') + '" placeholder="' + labels.pricePlaceholder + '">' +
              '</div>' +
              '<div class="field">' +
                '<label>' + labels.duration + '</label>' +
                '<input type="number" min="1" data-service-duration value="' + escapeHtml(service.durationMinutes || '') + '" placeholder="' + labels.durationPlaceholder + '">' +
              '</div>' +
            '</div>' +
            '<input type="hidden" data-service-id value="' + escapeHtml(service.id || '') + '">' +
            '<div class="muted">' + labels.serviceNote + '</div>';

          container.appendChild(row);

          row.querySelector('[data-remove-service]').addEventListener('click', function () {
            services.splice(index, 1);
            if (!services.length) {
              services.push(createEmptyService());
            }
            renderServices(root, services);
            syncServices(root, services);
          });

          row.querySelector('[data-service-name]').addEventListener('input', function (event) {
            services[index].name = event.target.value;
            syncServices(root, services);
          });
          row.querySelector('[data-service-price]').addEventListener('input', function (event) {
            services[index].price = event.target.value;
            syncServices(root, services);
          });
          row.querySelector('[data-service-duration]').addEventListener('input', function (event) {
            services[index].durationMinutes = event.target.value;
            syncServices(root, services);
          });
        });
      }

      function parseServices(root) {
        var hiddenInput = root.querySelector('[data-services-json]');
        try {
          var parsed = JSON.parse(hiddenInput.value || '[]');
          if (!Array.isArray(parsed)) {
            return [createEmptyService()];
          }
          if (!parsed.length) {
            return [createEmptyService()];
          }
          return parsed.map(function (item) {
            return {
              id: item && item.id ? String(item.id) : '',
              name: item && item.name ? String(item.name) : '',
              price: item && item.price != null ? String(item.price) : '',
              durationMinutes: item && item.durationMinutes != null
                ? String(item.durationMinutes)
                : ''
            };
          });
        } catch (_) {
          return [createEmptyService()];
        }
      }

      function escapeHtml(value) {
        return String(value)
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&#39;');
      }

      function ensureMap() {
        if (mapInstance || !window.L) {
          return;
        }
        mapInstance = L.map('pickerMap');
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; OpenStreetMap contributors'
        }).addTo(mapInstance);

        mapInstance.on('click', function (event) {
          if (!activeRoot) {
            return;
          }
          var lat = event.latlng.lat;
          var lng = event.latlng.lng;
          updateChips(lat, lng);
          activeRoot.querySelector('[data-lat-input]').value = lat.toFixed(6);
          activeRoot.querySelector('[data-lng-input]').value = lng.toFixed(6);
          activeRoot.querySelector('[data-lat-input]').dispatchEvent(new Event('input', { bubbles: true }));
          activeRoot.querySelector('[data-lng-input]').dispatchEvent(new Event('input', { bubbles: true }));
          if (!mapMarker) {
            mapMarker = L.marker([lat, lng]).addTo(mapInstance);
          } else {
            mapMarker.setLatLng([lat, lng]);
          }
        });
      }

      function openMapPicker(root) {
        ensureMap();
        if (!mapInstance) {
          return;
        }
        activeRoot = root;

        var latInput = root.querySelector('[data-lat-input]');
        var lngInput = root.querySelector('[data-lng-input]');
        var lat = Number(normalizeNumber(latInput.value));
        var lng = Number(normalizeNumber(lngInput.value));
        if (!isValidCoordinate(lat, lng)) {
          lat = DEFAULT_LAT;
          lng = DEFAULT_LNG;
        }

        modal.classList.add('open');
        updateChips(lat, lng);
        setTimeout(function () {
          mapInstance.invalidateSize();
          mapInstance.setView([lat, lng], 13);
          if (!mapMarker) {
            mapMarker = L.marker([lat, lng]).addTo(mapInstance);
          } else {
            mapMarker.setLatLng([lat, lng]);
          }
        }, 20);
      }

      function closeMapPicker() {
        modal.classList.remove('open');
      }

      function initRoot(root) {
        var services = parseServices(root);
        syncServices(root, services);
        renderServices(root, services);
        updatePreview(root);

        root.querySelector('[data-add-service]').addEventListener('click', function () {
          services.push(createEmptyService());
          renderServices(root, services);
          syncServices(root, services);
        });

        root.querySelector('[data-lat-input]').addEventListener('input', function () {
          updatePreview(root);
        });
        root.querySelector('[data-lng-input]').addEventListener('input', function () {
          updatePreview(root);
        });

        root.querySelector('[data-copy-btn]').addEventListener('click', function () {
          var lat = normalizeNumber(root.querySelector('[data-lat-input]').value);
          var lng = normalizeNumber(root.querySelector('[data-lng-input]').value);
          if (!lat || !lng || !navigator.clipboard) {
            return;
          }
          var button = this;
          navigator.clipboard.writeText(lat + ', ' + lng).then(function () {
            var previous = button.textContent;
            button.textContent = labels.copied;
            setTimeout(function () {
              button.textContent = previous;
            }, 1200);
          });
        });

        root.querySelector('[data-open-map-picker]').addEventListener('click', function () {
          openMapPicker(root);
        });

        root.querySelector('[data-editor-form]').addEventListener('submit', function () {
          syncServices(root, services);
        });
      }

      document.querySelectorAll('[data-editor-root]').forEach(initRoot);

      mapCloseButton.addEventListener('click', closeMapPicker);
      modal.addEventListener('click', function (event) {
        if (event.target === modal) {
          closeMapPicker();
        }
      });
    })();
  </script>
</body>
</html>
''';

    return Response.ok(
      html,
      headers: const <String, String>{
        'content-type': 'text/html; charset=utf-8',
      },
    );
  }

  Future<Response> createWorkshop(Request request) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);

    try {
      final WorkshopModel workshop = _parseWorkshopForm(
        form,
        lang: lang,
        workshopId: _store.newWorkshopId(),
        currentWorkshop: null,
      );
      _store.createWorkshop(workshop: workshop);
      await _persistWorkshopFiles();
      return _redirectWithMessage(
        _text(lang, 'createSuccess'),
        query: '',
        status: 'all',
        lang: lang,
      );
    } on StateError catch (error) {
      return _redirectWithError(
        error.message,
        query: '',
        status: 'all',
        lang: lang,
      );
    } on FormatException catch (error) {
      return _redirectWithError(
        error.message,
        query: '',
        status: 'all',
        lang: lang,
      );
    }
  }

  Future<Response> updateWorkshop(Request request, String id) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String query = (form['returnQ'] ?? '').trim();
    final String status = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? currentWorkshop = _store.workshopById(id);

    try {
      final WorkshopModel workshop = _parseWorkshopForm(
        form,
        lang: lang,
        workshopId: id,
        currentWorkshop: currentWorkshop,
      );
      final WorkshopModel? updated = _store.updateWorkshop(
        workshopId: id,
        workshop: workshop,
      );
      if (updated == null) {
        return _redirectWithError(
          _text(lang, 'garageNotFound'),
          query: query,
          status: status,
          lang: lang,
        );
      }

      await _persistWorkshopFiles();
      return _redirectWithMessage(
        _text(lang, 'updateSuccess', <String, Object>{'name': updated.name}),
        query: query,
        status: status,
        lang: lang,
      );
    } on StateError catch (error) {
      return _redirectWithError(
        error.message,
        query: query,
        status: status,
        lang: lang,
      );
    } on FormatException catch (error) {
      return _redirectWithError(
        error.message,
        query: query,
        status: status,
        lang: lang,
      );
    }
  }

  Future<Response> deleteWorkshop(Request request, String id) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String query = (form['returnQ'] ?? '').trim();
    final String status = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? current = _store.workshopById(id);

    if (!_store.deleteWorkshop(id)) {
      return _redirectWithError(
        _text(lang, 'garageNotFound'),
        query: query,
        status: status,
        lang: lang,
      );
    }

    await _persistWorkshopFiles();
    return _redirectWithMessage(
      current == null
          ? _text(lang, 'deleteSuccess')
          : _text(lang, 'deleteSuccessNamed', <String, Object>{
              'name': current.name,
            }),
      query: query,
      status: status,
      lang: lang,
    );
  }

  Future<Response> updateWorkshopLocation(Request request, String id) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String query = (form['returnQ'] ?? '').trim();
    final String status = _normalizeStatus(form['returnStatus']);

    try {
      final double latitude = _parseDoubleField(
        form['latitude'],
        fieldLabel: _text(lang, 'fieldLatitude'),
        lang: lang,
        min: -90,
        max: 90,
      );
      final double longitude = _parseDoubleField(
        form['longitude'],
        fieldLabel: _text(lang, 'fieldLongitude'),
        lang: lang,
        min: -180,
        max: 180,
      );
      final bool updated = _store.updateWorkshopLocation(
        workshopId: id,
        latitude: latitude,
        longitude: longitude,
      );
      if (!updated) {
        return _redirectWithError(
          _text(lang, 'garageNotFound'),
          query: query,
          status: status,
          lang: lang,
        );
      }

      await _persistWorkshopFiles();
      return _redirectWithMessage(
        _text(lang, 'locationUpdated'),
        query: query,
        status: status,
        lang: lang,
      );
    } on FormatException catch (error) {
      return _redirectWithError(
        error.message,
        query: query,
        status: status,
        lang: lang,
      );
    }
  }

  Future<Response> sendTelegramTest(Request request, String id) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String query = (form['returnQ'] ?? '').trim();
    final String status = _normalizeStatus(form['returnStatus']);

    final WorkshopModel? workshop = _store.workshopById(id);
    if (workshop == null) {
      return _redirectWithError(
        _text(lang, 'garageNotFound'),
        query: query,
        status: status,
        lang: lang,
      );
    }

    try {
      await notificationsService.sendTestNotification(workshop: workshop);
      return _redirectWithMessage(
        _text(
          lang,
          'telegramTestSent',
          <String, Object>{'name': workshop.name},
        ),
        query: query,
        status: status,
        lang: lang,
      );
    } on Exception catch (error) {
      return _redirectWithError(
        error.toString(),
        query: query,
        status: status,
        lang: lang,
      );
    }
  }

  Future<void> _persistWorkshopFiles() async {
    await _store.saveWorkshops(workshopsFilePath);
    await _store.saveWorkshopLocations(locationsFilePath);
  }

  Future<Map<String, String>> _readForm(Request request) async {
    final String body = await request.readAsString();
    if (body.trim().isEmpty) {
      return <String, String>{};
    }

    final Uri uri = Uri(query: body);
    final Map<String, String> values = <String, String>{};
    uri.queryParametersAll.forEach((String key, List<String> list) {
      if (list.isNotEmpty) {
        values[key] = list.length == 1 ? list.last : list.join(',');
      }
    });
    return values;
  }

  WorkshopModel _parseWorkshopForm(
    Map<String, String> form, {
    required String lang,
    required String workshopId,
    required WorkshopModel? currentWorkshop,
  }) {
    final String name =
        _requiredText(form['name'], _text(lang, 'fieldWorkshopName'), lang);
    final String master =
        _requiredText(form['master'], _text(lang, 'fieldMaster'), lang);
    final String address =
        _requiredText(form['address'], _text(lang, 'fieldAddress'), lang);
    final String description = _requiredText(
      form['description'],
      _text(lang, 'fieldDescription'),
      lang,
    );
    final String badge =
        _requiredText(form['badge'], _text(lang, 'fieldBadge'), lang);
    final String ownerAccessCode = _optionalText(
      form['ownerAccessCode'],
      fallback: WorkshopModel.defaultOwnerAccessCode(workshopId),
    );
    final String telegramChatId = _optionalText(
      form['telegramChatId'],
      fallback: currentWorkshop?.telegramChatId ?? '',
    );
    final bool telegramChatChanged = currentWorkshop != null &&
        telegramChatId != currentWorkshop.telegramChatId;
    final String telegramChatLabel = telegramChatChanged
        ? ''
        : currentWorkshop?.telegramChatLabel ?? '';
    final String telegramLinkCode = telegramChatChanged
        ? ''
        : currentWorkshop?.telegramLinkCode ?? '';
    final double rating = _parseDoubleField(
      form['rating'],
      fieldLabel: _text(lang, 'fieldRating'),
      lang: lang,
      min: 0,
      max: 5,
    );
    final int reviewCount = _parseIntField(
      form['reviewCount'],
      fieldLabel: _text(lang, 'fieldReviewCount'),
      lang: lang,
      min: 0,
    );
    final double distanceKm = _parseDoubleField(
      form['distanceKm'],
      fieldLabel: _text(lang, 'fieldDistance'),
      lang: lang,
      min: 0,
      max: 1000,
    );
    final double latitude = _parseDoubleField(
      form['latitude'],
      fieldLabel: _text(lang, 'fieldLatitude'),
      lang: lang,
      min: -90,
      max: 90,
    );
    final double longitude = _parseDoubleField(
      form['longitude'],
      fieldLabel: _text(lang, 'fieldLongitude'),
      lang: lang,
      min: -180,
      max: 180,
    );
    final bool isOpen = (form['isOpen'] ?? '').toLowerCase() == 'on' ||
        (form['isOpen'] ?? '').toLowerCase() == 'true';
    final WorkshopScheduleModel schedule = _parseWorkshopSchedule(
      form,
      lang: lang,
      fallback: currentWorkshop?.schedule ?? WorkshopScheduleModel.standard(),
    );
    final List<ServiceModel> services = _parseServicesJson(
      form['servicesJson'] ?? '[]',
      lang: lang,
    );
    if (services.isEmpty) {
      throw FormatException(_text(lang, 'minimumOneService'));
    }

    return WorkshopModel(
      id: workshopId,
      name: name,
      master: master,
      rating: rating,
      reviewCount: reviewCount,
      address: address,
      description: description,
      distanceKm: distanceKm,
      latitude: latitude,
      longitude: longitude,
      isOpen: isOpen,
      badge: badge,
      ownerAccessCode: ownerAccessCode,
      telegramChatId: telegramChatId,
      telegramChatLabel: telegramChatLabel,
      telegramLinkCode: telegramLinkCode,
      schedule: schedule,
      services: services,
    );
  }

  WorkshopScheduleModel _parseWorkshopSchedule(
    Map<String, String> form, {
    required String lang,
    required WorkshopScheduleModel fallback,
  }) {
    final String openingTime = _parseTimeField(
      form['openingTime'],
      fieldLabel: _text(lang, 'fieldOpeningTime'),
      lang: lang,
      fallback: fallback.openingTime,
    );
    final String closingTime = _parseTimeField(
      form['closingTime'],
      fieldLabel: _text(lang, 'fieldClosingTime'),
      lang: lang,
      fallback: fallback.closingTime,
    );
    final String breakStartTime = _parseOptionalTimeField(
      form['breakStartTime'],
      fieldLabel: _text(lang, 'fieldBreakStart'),
      lang: lang,
    );
    final String breakEndTime = _parseOptionalTimeField(
      form['breakEndTime'],
      fieldLabel: _text(lang, 'fieldBreakEnd'),
      lang: lang,
    );
    final List<int> closedWeekdays = _parseClosedWeekdays(
      form['closedWeekdays'],
      fallback: fallback.closedWeekdays,
    );

    final int openingMinutes = _minutesFromTime(openingTime);
    final int closingMinutes = _minutesFromTime(closingTime);
    if (closingMinutes <= openingMinutes) {
      throw FormatException(_text(lang, 'scheduleTimeRangeError'));
    }

    if (breakStartTime.isEmpty != breakEndTime.isEmpty) {
      throw FormatException(_text(lang, 'scheduleBreakPairError'));
    }

    if (breakStartTime.isNotEmpty && breakEndTime.isNotEmpty) {
      final int breakStartMinutes = _minutesFromTime(breakStartTime);
      final int breakEndMinutes = _minutesFromTime(breakEndTime);
      final bool breakOutsideRange =
          breakStartMinutes < openingMinutes ||
              breakEndMinutes > closingMinutes ||
              breakEndMinutes <= breakStartMinutes;
      if (breakOutsideRange) {
        throw FormatException(_text(lang, 'scheduleBreakRangeError'));
      }
    }

    return WorkshopScheduleModel(
      openingTime: openingTime,
      closingTime: closingTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      closedWeekdays: List<int>.unmodifiable(closedWeekdays),
    );
  }

  List<ServiceModel> _parseServicesJson(
    String raw, {
    required String lang,
  }) {
    if (raw.trim().isEmpty) {
      return <ServiceModel>[];
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException(_text(lang, 'invalidServicesFormat'));
    }

    final List<ServiceModel> services = <ServiceModel>[];
    for (final dynamic item in decoded) {
      if (item is! Map) {
        continue;
      }

      final String name = (item['name'] ?? '').toString().trim();
      final String priceRaw = (item['price'] ?? '').toString().trim();
      final String durationRaw =
          (item['durationMinutes'] ?? '').toString().trim();

      if (name.isEmpty && priceRaw.isEmpty && durationRaw.isEmpty) {
        continue;
      }
      if (name.isEmpty) {
        throw FormatException(
          _text(
            lang,
            'requiredField',
            <String, Object>{'field': _text(lang, 'fieldServiceName')},
          ),
        );
      }

      services.add(
        ServiceModel(
          id: (item['id'] ?? '').toString().trim().isEmpty
              ? _store.newServiceId()
              : (item['id'] ?? '').toString().trim(),
          name: name,
          price: _parseIntField(
            priceRaw,
            fieldLabel: _text(lang, 'fieldServicePrice'),
            lang: lang,
            min: 0,
          ),
          durationMinutes: _parseIntField(
            durationRaw,
            fieldLabel: _text(lang, 'fieldServiceDuration'),
            lang: lang,
            min: 1,
          ),
        ),
      );
    }
    return services;
  }

  String _requiredText(
    String? raw,
    String fieldLabel,
    String lang,
  ) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      throw FormatException(
        _text(
          lang,
          'requiredField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    return value;
  }

  String _optionalText(
    String? raw, {
    required String fallback,
  }) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  String _parseTimeField(
    String? raw, {
    required String fieldLabel,
    required String lang,
    required String fallback,
  }) {
    final String value = (raw ?? '').trim();
    final String normalized = value.isEmpty ? fallback : value;
    if (!_isTimeValue(normalized)) {
      throw FormatException(
        _text(
          lang,
          'invalidTimeField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    return normalized;
  }

  String _parseOptionalTimeField(
    String? raw, {
    required String fieldLabel,
    required String lang,
  }) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    if (!_isTimeValue(value)) {
      throw FormatException(
        _text(
          lang,
          'invalidTimeField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    return value;
  }

  bool _isTimeValue(String value) {
    return RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(value.trim());
  }

  int _minutesFromTime(String value) {
    final List<String> parts = value.split(':');
    final int hours = int.tryParse(parts.first) ?? 0;
    final int minutes = int.tryParse(parts.last) ?? 0;
    return (hours * 60) + minutes;
  }

  List<int> _parseClosedWeekdays(
    String? raw, {
    required List<int> fallback,
  }) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return List<int>.from(fallback);
    }

    final List<int> result = <int>[];
    for (final String part in value.split(',')) {
      final int? weekday = int.tryParse(part.trim());
      if (weekday == null || weekday < 1 || weekday > 7 || result.contains(weekday)) {
        continue;
      }
      result.add(weekday);
    }
    result.sort();
    return result;
  }

  int _parseIntField(
    String? raw, {
    required String fieldLabel,
    required String lang,
    required int min,
  }) {
    final String value = (raw ?? '').trim();
    final int? parsed = int.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        _text(
          lang,
          'invalidField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    if (parsed < min) {
      throw FormatException(
        _text(
          lang,
          'outOfRangeField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    return parsed;
  }

  double _parseDoubleField(
    String? raw, {
    required String fieldLabel,
    required String lang,
    required double min,
    required double max,
  }) {
    final String value = (raw ?? '').trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        _text(
          lang,
          'invalidField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    if (parsed < min || parsed > max) {
      throw FormatException(
        _text(
          lang,
          'outOfRangeField',
          <String, Object>{'field': fieldLabel},
        ),
      );
    }
    return parsed;
  }

  Response _redirectWithMessage(
    String message, {
    required String query,
    required String status,
    required String lang,
  }) {
    return Response.seeOther(
      _adminPageUri(
        message: message,
        query: query,
        status: status,
        lang: lang,
      ),
    );
  }

  Response _redirectWithError(
    String message, {
    required String query,
    required String status,
    required String lang,
  }) {
    return Response.seeOther(
      _adminPageUri(
        error: message,
        query: query,
        status: status,
        lang: lang,
      ),
    );
  }

  Response? _requireAdmin(Request request) {
    if (adminAuthService.isAuthenticated(request)) {
      return null;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    return Response.seeOther(
      _loginPageUri(
        lang: lang,
        next: _requestPathWithQuery(request, lang: lang),
      ),
    );
  }

  Uri _loginPageUri({
    String? lang,
    String? next,
    String? error,
  }) {
    final String normalizedLang = _normalizeLang(lang);
    final String fallbackNext = _adminPageUri(lang: normalizedLang).toString();
    final String sanitizedNext = _sanitizeNext(next, lang: normalizedLang);
    final Map<String, String> params = <String, String>{
      'lang': normalizedLang,
    };
    if (sanitizedNext != fallbackNext) {
      params['next'] = sanitizedNext;
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/admin/login', queryParameters: params);
  }

  String _sanitizeNext(String? raw, {String? lang}) {
    final String normalizedLang = _normalizeLang(lang);
    final String fallback = _adminPageUri(lang: normalizedLang).toString();
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return fallback;
    }

    final Uri? parsed = Uri.tryParse(value);
    if (parsed == null || parsed.hasScheme || parsed.hasAuthority) {
      return fallback;
    }

    final String path =
        parsed.path.startsWith('/') ? parsed.path : '/${parsed.path}';
    final bool isAdminPath = path == '/admin' || path.startsWith('/admin/');
    if (!isAdminPath || path == '/admin/login' || path == '/admin/logout') {
      return fallback;
    }

    final Map<String, String> params = <String, String>{
      ...parsed.queryParameters,
    };
    if (!params.containsKey('lang')) {
      params['lang'] = normalizedLang;
    }

    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
      fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
    ).toString();
  }

  String _requestPathWithQuery(Request request, {required String lang}) {
    final String path = request.url.path.startsWith('/')
        ? request.url.path
        : '/${request.url.path}';
    final Map<String, String> params = <String, String>{
      ...request.url.queryParameters,
    };
    if ((path == '/admin' || path.startsWith('/admin/')) &&
        !params.containsKey('lang')) {
      params['lang'] = _normalizeLang(lang);
    }
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  Uri _adminPageUri({
    String? message,
    String? error,
    String? query,
    String? status,
    String? lang,
  }) {
    final Map<String, String> params = <String, String>{};
    if (message != null && message.isNotEmpty) {
      params['message'] = message;
    }
    if (error != null && error.isNotEmpty) {
      params['error'] = error;
    }

    final String normalizedQuery = (query ?? '').trim();
    if (normalizedQuery.isNotEmpty) {
      params['q'] = normalizedQuery;
    }

    final String normalizedStatus = _normalizeStatus(status);
    if (normalizedStatus != 'all') {
      params['status'] = normalizedStatus;
    }

    final String normalizedLang = _normalizeLang(lang);
    if (normalizedLang.isNotEmpty) {
      params['lang'] = normalizedLang;
    }

    return Uri(
      path: '/admin/workshops',
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Uri _adminBookingsPageUri({
    String? lang,
    String? workshopId,
    String? status,
    String? query,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };

    final String normalizedWorkshopId = (workshopId ?? '').trim();
    if (normalizedWorkshopId.isNotEmpty) {
      params['workshop'] = normalizedWorkshopId;
    }

    final String normalizedStatus = (status ?? '').trim().toLowerCase();
    if (normalizedStatus == 'upcoming' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'cancelled') {
      params['status'] = normalizedStatus;
    }

    final String normalizedQuery = (query ?? '').trim();
    if (normalizedQuery.isNotEmpty) {
      params['q'] = normalizedQuery;
    }

    return Uri(
      path: '/admin/bookings',
      queryParameters: params,
    );
  }

  Uri _adminReviewsPageUri({
    String? lang,
  }) {
    return Uri(
      path: '/admin/reviews',
      queryParameters: <String, String>{
        'lang': _normalizeLang(lang),
      },
    );
  }

  Uri _ownerLoginUri({
    String? lang,
    String? workshopId,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };

    final String normalizedWorkshopId = (workshopId ?? '').trim();
    if (normalizedWorkshopId.isNotEmpty) {
      params['workshop'] = normalizedWorkshopId;
    }

    return Uri(
      path: '/owner/login',
      queryParameters: params,
    );
  }

  String _telegramBotStatusLabel(String lang) {
    if (notificationsService.isConfigured) {
      return _text(lang, 'telegramBotEnabled');
    }
    return _text(lang, 'telegramBotDisabled');
  }

  List<WorkshopModel> _applyStatusFilter(
    List<WorkshopModel> workshops, {
    required String status,
  }) {
    if (status == 'open') {
      return workshops
          .where((WorkshopModel item) => item.isOpen)
          .toList(growable: false);
    }
    if (status == 'closed') {
      return workshops
          .where((WorkshopModel item) => !item.isOpen)
          .toList(growable: false);
    }
    return workshops;
  }

  String _normalizeStatus(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'open':
        return 'open';
      case 'closed':
        return 'closed';
      default:
        return 'all';
    }
  }

  String _statusLabel(String status, String lang) {
    switch (status) {
      case 'open':
        return _text(lang, 'statusOpenOnly');
      case 'closed':
        return _text(lang, 'statusClosedOnly');
      default:
        return _text(lang, 'statusAll');
    }
  }

  String _selectedAttr(bool selected) => selected ? ' selected' : '';

  String _resultsSummary({
    required String lang,
    required int totalCount,
    required int searchCount,
    required int visibleCount,
    required String query,
    required String status,
  }) {
    if (query.isEmpty && status == 'all') {
      return _text(
        lang,
        'resultsAll',
        <String, Object>{'count': totalCount},
      );
    }
    if (query.isNotEmpty && status == 'all') {
      return _text(
        lang,
        'resultsSearch',
        <String, Object>{
          'query': query,
          'searchCount': searchCount,
          'visibleCount': visibleCount,
        },
      );
    }
    if (query.isEmpty) {
      return _text(
        lang,
        'resultsStatus',
        <String, Object>{
          'status': _statusLabel(status, lang),
          'count': visibleCount,
        },
      );
    }
    return _text(
      lang,
      'resultsSearchStatus',
      <String, Object>{
        'query': query,
        'status': _statusLabel(status, lang).toLowerCase(),
        'count': visibleCount,
      },
    );
  }

  String _flashHtml({
    required String? message,
    required String? error,
  }) {
    if (message != null && message.isNotEmpty) {
      return '<div class="flash ok">${_escapeHtml(message)}</div>';
    }

    if (error != null && error.isNotEmpty) {
      return '<div class="flash err">${_escapeHtml(error)}</div>';
    }

    return '';
  }

  String _emptyStateHtml({
    required String lang,
    required String query,
    required String status,
  }) {
    final String text = query.isEmpty && status == 'all'
        ? _text(lang, 'emptyNoData')
        : _text(lang, 'emptyFiltered');
    return '''
<section class="card empty-state">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'emptyEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'emptyTitle'))}</h3>
  <p>${_escapeHtml(text)}</p>
  <a class="mini-link" href="${_escapeHtml(_adminPageUri(lang: lang).toString())}">${_escapeHtml(_text(lang, 'clearFilters'))}</a>
</section>
''';
  }

  String _createWorkshopPanelHtml(String lang) {
    return _editorCardHtml(
      lang: lang,
      title: _text(lang, 'createCardTitle'),
      subtitle: _text(lang, 'createCardSubtitle'),
      action: '/admin/workshops?lang=${Uri.encodeQueryComponent(lang)}',
      submitLabel: _text(lang, 'createSubmit'),
      buttonLabel: _text(lang, 'mapSelectButton'),
      latText: _defaultLatitude.toStringAsFixed(6),
      lngText: _defaultLongitude.toStringAsFixed(6),
      name: '',
      master: '',
      address: '',
      description: '',
      badge: '',
      ownerAccessCode: '',
      telegramChatId: '',
      telegramBotStatus: _telegramBotStatusLabel(lang),
      rating: '4.8',
      reviewCount: '0',
      distanceKm: '1.0',
      isOpen: true,
      openingTime: '09:00',
      closingTime: '19:00',
      breakStartTime: '13:00',
      breakEndTime: '14:00',
      closedWeekdays: const <int>[7],
      servicesJson: '[]',
      extraActionsHtml: '',
      hiddenContextHtml:
          '<input type="hidden" name="returnQ" value=""><input type="hidden" name="returnStatus" value="all"><input type="hidden" name="lang" value="${_escapeHtml(lang)}">',
    );
  }

  String _workshopCardHtml(
    String lang,
    WorkshopModel workshop, {
    required String returnQuery,
    required String returnStatus,
  }) {
    final String statusClass =
        workshop.isOpen ? 'status-open' : 'status-closed';
    final String statusLabel = workshop.isOpen
        ? _text(lang, 'statusOpenNow')
        : _text(lang, 'statusClosedNow');
    final String servicesSummary = workshop.services
        .map(
          (ServiceModel item) =>
              '<span class="service-pill">${_escapeHtml(item.name)}</span>',
        )
        .join('');
    final String hiddenContextHtml = '''
<input type="hidden" name="returnQ" value="${_escapeHtml(returnQuery)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(returnStatus)}">
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
''';
    final Uri ordersUri = _adminBookingsPageUri(
      lang: lang,
      workshopId: workshop.id,
      status: 'upcoming',
    );
    final Uri ownerPortalUri = _ownerLoginUri(
      lang: lang,
      workshopId: workshop.id,
    );
    final String telegramChatValue = workshop.telegramChatId.trim().isEmpty
        ? _text(lang, 'telegramNotLinked')
        : workshop.telegramChatId;
    final String workingHoursValue = _scheduleSummary(workshop.schedule);
    final String breakValue = _breakSummary(workshop.schedule, lang);
    final String closedDaysValue = _daysOffSummary(workshop.schedule, lang);

    return '''
<section class="card workshop-card">
  <div class="workshop-head">
    <div>
      <div class="eyebrow">${_escapeHtml(_text(lang, 'garageId'))} ${_escapeHtml(workshop.id)}</div>
      <h2>${_escapeHtml(workshop.name)}</h2>
      <div class="muted">${_escapeHtml(workshop.address)}</div>
    </div>
    <div class="head-tags">
      <span class="tag">${_escapeHtml(workshop.badge)}</span>
      <span class="status-pill $statusClass">$statusLabel</span>
    </div>
  </div>

  <div class="info-grid">
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoMaster'))}</span>
      <strong>${_escapeHtml(workshop.master)}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoRating'))}</span>
      <strong>${workshop.rating.toStringAsFixed(1)} / 5.0</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoReviews'))}</span>
      <strong>${workshop.reviewCount}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoDistance'))}</span>
      <strong>${workshop.distanceKm.toStringAsFixed(1)} km</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'fieldOwnerAccessCode'))}</span>
      <strong>${_escapeHtml(workshop.ownerAccessCode)}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'fieldTelegramChatId'))}</span>
      <strong>${_escapeHtml(telegramChatValue)}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoWorkingHours'))}</span>
      <strong>${_escapeHtml(workingHoursValue)}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoBreakTime'))}</span>
      <strong>${_escapeHtml(breakValue)}</strong>
    </div>
    <div class="info-item">
      <span>${_escapeHtml(_text(lang, 'infoDaysOff'))}</span>
      <strong>${_escapeHtml(closedDaysValue)}</strong>
    </div>
  </div>

  <div class="service-row">$servicesSummary</div>

  ${_editorCardHtml(
      lang: lang,
      title: _text(lang, 'editCardTitle'),
      subtitle: _text(lang, 'editCardSubtitle'),
      action:
          '/admin/workshops/${Uri.encodeComponent(workshop.id)}/update?lang=${Uri.encodeQueryComponent(lang)}',
      submitLabel: _text(lang, 'saveChanges'),
      buttonLabel: _text(lang, 'mapSelectButton'),
      latText: workshop.latitude.toStringAsFixed(6),
      lngText: workshop.longitude.toStringAsFixed(6),
      name: workshop.name,
      master: workshop.master,
      address: workshop.address,
      description: workshop.description,
      badge: workshop.badge,
      ownerAccessCode: workshop.ownerAccessCode,
      telegramChatId: workshop.telegramChatId,
      telegramBotStatus: _telegramBotStatusLabel(lang),
      rating: workshop.rating.toStringAsFixed(1),
      reviewCount: '${workshop.reviewCount}',
      distanceKm: workshop.distanceKm.toStringAsFixed(1),
      isOpen: workshop.isOpen,
      openingTime: workshop.schedule.openingTime,
      closingTime: workshop.schedule.closingTime,
      breakStartTime: workshop.schedule.breakStartTime,
      breakEndTime: workshop.schedule.breakEndTime,
      closedWeekdays: workshop.schedule.closedWeekdays,
      servicesJson: _escapeHtml(jsonEncode(
        workshop.services
            .map((ServiceModel item) => item.toJson())
            .toList(growable: false),
      )),
      extraActionsHtml: '''
<a class="ghost-btn" href="${_escapeHtml(ownerPortalUri.toString())}" target="_blank" rel="noreferrer">${_escapeHtml(_text(lang, 'fieldOwnerPortal'))}</a>
<a class="ghost-btn" href="${_escapeHtml(ordersUri.toString())}">${_escapeHtml(_text(lang, 'ordersButton'))}</a>
<form method="post" action="/admin/workshops/${Uri.encodeComponent(workshop.id)}/telegram/test?lang=${Uri.encodeQueryComponent(lang)}">
  $hiddenContextHtml
  <button class="ghost-btn" type="submit">${_escapeHtml(_text(lang, 'telegramTestButton'))}</button>
</form>
<form method="post" action="/admin/workshops/${Uri.encodeComponent(workshop.id)}/delete?lang=${Uri.encodeQueryComponent(lang)}" onsubmit="return confirm('${_escapeHtml(_text(lang, 'deleteConfirm'))}')">
  $hiddenContextHtml
  <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'deleteButton'))}</button>
</form>
''',
      hiddenContextHtml: hiddenContextHtml,
    )}
</section>
''';
  }

  String _scheduleSummary(WorkshopScheduleModel schedule) {
    return '${schedule.openingTime} - ${schedule.closingTime}';
  }

  String _breakSummary(WorkshopScheduleModel schedule, String lang) {
    if (!schedule.hasBreak) {
      return _text(lang, 'noBreakLabel');
    }
    return '${schedule.breakStartTime} - ${schedule.breakEndTime}';
  }

  String _daysOffSummary(WorkshopScheduleModel schedule, String lang) {
    if (schedule.closedWeekdays.isEmpty) {
      return _text(lang, 'noClosedWeekdaysLabel');
    }
    return schedule.closedWeekdays
        .map((int item) => _weekdayShortLabel(lang, item))
        .join(', ');
  }

  String _weekdayCheckboxesHtml(String lang, List<int> selectedDays) {
    return List<String>.generate(7, (int index) {
      final int weekday = index + 1;
      final bool isSelected = selectedDays.contains(weekday);
      return '''
<label class="checkbox-pill">
  <input type="checkbox" name="closedWeekdays" value="$weekday"${isSelected ? ' checked' : ''}>
  ${_escapeHtml(_weekdayShortLabel(lang, weekday))}
</label>
''';
    }).join();
  }

  String _weekdayShortLabel(String lang, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return _text(lang, 'weekdayShortMon');
      case DateTime.tuesday:
        return _text(lang, 'weekdayShortTue');
      case DateTime.wednesday:
        return _text(lang, 'weekdayShortWed');
      case DateTime.thursday:
        return _text(lang, 'weekdayShortThu');
      case DateTime.friday:
        return _text(lang, 'weekdayShortFri');
      case DateTime.saturday:
        return _text(lang, 'weekdayShortSat');
      case DateTime.sunday:
      default:
        return _text(lang, 'weekdayShortSun');
    }
  }

  String _editorCardHtml({
    required String lang,
    required String title,
    required String subtitle,
    required String action,
    required String submitLabel,
    required String buttonLabel,
    required String latText,
    required String lngText,
    required String name,
    required String master,
    required String address,
    required String description,
    required String badge,
    required String ownerAccessCode,
    required String telegramChatId,
    required String telegramBotStatus,
    required String rating,
    required String reviewCount,
    required String distanceKm,
    required bool isOpen,
    required String openingTime,
    required String closingTime,
    required String breakStartTime,
    required String breakEndTime,
    required List<int> closedWeekdays,
    required String servicesJson,
    required String extraActionsHtml,
    required String hiddenContextHtml,
  }) {
    final String yandexUrl =
        'https://yandex.com/maps/?pt=$lngText,$latText&z=15&l=map';
    final String googleUrl = 'https://www.google.com/maps?q=$latText,$lngText';
    final String osmUrl =
        'https://www.openstreetmap.org/?mlat=$latText&mlon=$lngText#map=15/$latText/$lngText';

    return '''
<div class="editor-layout" data-editor-root>
  <div class="preview-panel">
    <div class="eyebrow">${_escapeHtml(_text(lang, 'previewEyebrow'))}</div>
    <div class="preview-map" data-map-preview>
      <div class="preview-hud">${_escapeHtml(_text(lang, 'approximatePin'))}</div>
      <div class="map-pin"></div>
    </div>
    <div class="coord-grid">
      <div class="coord-card">
        <span>${_escapeHtml(_text(lang, 'fieldLatitude'))}</span>
        <strong data-preview-lat>${_escapeHtml(latText)}</strong>
      </div>
      <div class="coord-card">
        <span>${_escapeHtml(_text(lang, 'fieldLongitude'))}</span>
        <strong data-preview-lng>${_escapeHtml(lngText)}</strong>
      </div>
    </div>
    <div class="preview-links">
      <a class="ghost-btn" data-map-link="yandex" href="${_escapeHtml(yandexUrl)}" target="_blank" rel="noreferrer">${_escapeHtml(_text(lang, 'yandex'))}</a>
      <a class="ghost-btn" data-map-link="google" href="${_escapeHtml(googleUrl)}" target="_blank" rel="noreferrer">${_escapeHtml(_text(lang, 'google'))}</a>
      <a class="ghost-btn" data-map-link="osm" href="${_escapeHtml(osmUrl)}" target="_blank" rel="noreferrer">${_escapeHtml(_text(lang, 'openStreetMap'))}</a>
      <button class="ghost-btn" type="button" data-copy-btn>${_escapeHtml(_text(lang, 'copy'))}</button>
    </div>
  </div>

  <div class="editor-panel">
    <div class="editor-head">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'editorEyebrow'))}</div>
      <h4>${_escapeHtml(title)}</h4>
      <p>${_escapeHtml(subtitle)}</p>
    </div>
    <form class="editor-form" data-editor-form method="post" action="${_escapeHtml(action)}">
      $hiddenContextHtml
      <div class="field-grid">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldWorkshopName'))}</label>
          <input type="text" name="name" value="${_escapeHtml(name)}" placeholder="${_escapeHtml(_text(lang, 'placeholderWorkshopName'))}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldMaster'))}</label>
          <input type="text" name="master" value="${_escapeHtml(master)}" placeholder="${_escapeHtml(_text(lang, 'placeholderMaster'))}">
        </div>
      </div>

      <div class="field-grid">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldBadge'))}</label>
          <input type="text" name="badge" value="${_escapeHtml(badge)}" placeholder="${_escapeHtml(_text(lang, 'placeholderBadge'))}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldAddress'))}</label>
          <input type="text" name="address" value="${_escapeHtml(address)}" placeholder="${_escapeHtml(_text(lang, 'placeholderAddress'))}">
        </div>
      </div>

      <div class="field-grid">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldOwnerAccessCode'))}</label>
          <input type="text" name="ownerAccessCode" value="${_escapeHtml(ownerAccessCode)}" placeholder="${_escapeHtml(_text(lang, 'placeholderOwnerAccessCode'))}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldOwnerPortal'))}</label>
          <input type="text" value="/owner/login" readonly>
        </div>
      </div>

      <div class="field-grid">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldTelegramChatId'))}</label>
          <input type="text" name="telegramChatId" value="${_escapeHtml(telegramChatId)}" placeholder="${_escapeHtml(_text(lang, 'placeholderTelegramChatId'))}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldTelegramBotStatus'))}</label>
          <input type="text" value="${_escapeHtml(telegramBotStatus)}" readonly>
        </div>
      </div>

      <div class="field">
        <label>${_escapeHtml(_text(lang, 'fieldDescription'))}</label>
        <textarea name="description" placeholder="${_escapeHtml(_text(lang, 'placeholderDescription'))}">${_escapeHtml(description)}</textarea>
      </div>

      <div class="field-grid three">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldRating'))}</label>
          <input type="number" step="0.1" min="0" max="5" name="rating" value="${_escapeHtml(rating)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldReviewCount'))}</label>
          <input type="number" min="0" name="reviewCount" value="${_escapeHtml(reviewCount)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldDistanceKm'))}</label>
          <input type="number" step="0.1" min="0" name="distanceKm" value="${_escapeHtml(distanceKm)}">
        </div>
      </div>

      <div class="field-grid">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldLatitude'))}</label>
          <input data-lat-input type="text" name="latitude" value="${_escapeHtml(latText)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldLongitude'))}</label>
          <input data-lng-input type="text" name="longitude" value="${_escapeHtml(lngText)}">
        </div>
      </div>

      <div class="inline-actions">
        <button class="ghost-btn" type="button" data-open-map-picker>$buttonLabel</button>
        <label class="checkbox-row">
          <input type="checkbox" name="isOpen"${isOpen ? ' checked' : ''}>
          ${_escapeHtml(_text(lang, 'openCheckbox'))}
        </label>
      </div>

      <div class="helper-box">
        ${_escapeHtml(_text(lang, 'helperSchedule'))}
      </div>

      <div class="field-grid four">
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldOpeningTime'))}</label>
          <input type="time" name="openingTime" value="${_escapeHtml(openingTime)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldClosingTime'))}</label>
          <input type="time" name="closingTime" value="${_escapeHtml(closingTime)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldBreakStart'))}</label>
          <input type="time" name="breakStartTime" value="${_escapeHtml(breakStartTime)}">
        </div>
        <div class="field">
          <label>${_escapeHtml(_text(lang, 'fieldBreakEnd'))}</label>
          <input type="time" name="breakEndTime" value="${_escapeHtml(breakEndTime)}">
        </div>
      </div>

      <div class="field">
        <label>${_escapeHtml(_text(lang, 'fieldClosedWeekdays'))}</label>
        <div class="checkbox-pills">
          ${_weekdayCheckboxesHtml(lang, closedWeekdays)}
        </div>
      </div>

      <div class="helper-box">
        ${_escapeHtml(_text(lang, 'helperServices'))}
      </div>

      <div class="service-toolbar">
        <strong>${_escapeHtml(_text(lang, 'servicesTitle'))}</strong>
        <button class="ghost-btn" type="button" data-add-service>${_escapeHtml(_text(lang, 'addService'))}</button>
      </div>
      <input type="hidden" data-services-json name="servicesJson" value="$servicesJson">
      <div class="service-list" data-services-container></div>

      <div class="editor-footer">
        <div class="muted">${_escapeHtml(_text(lang, 'saveHint'))}</div>
        <div class="inline-actions">
          $extraActionsHtml
          <button class="pill-link hero-primary" type="submit">$submitLabel</button>
        </div>
      </div>
    </form>
  </div>
</div>
''';
  }

  String _normalizeLang(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'en':
        return 'en';
      case 'ru':
        return 'ru';
      default:
        return 'uz';
    }
  }

  String _text(
    String lang,
    String key, [
    Map<String, Object>? values,
  ]) {
    String result = _strings[lang]?[key] ?? _strings['uz']![key] ?? key;
    if (values != null) {
      for (final MapEntry<String, Object> entry in values.entries) {
        result = result.replaceAll('{${entry.key}}', '${entry.value}');
      }
    }
    return result;
  }

  Map<String, String> _jsLabels(String lang) {
    return <String, String>{
      'serviceItem': _text(lang, 'serviceItem'),
      'remove': _text(lang, 'remove'),
      'name': _text(lang, 'jsName'),
      'price': _text(lang, 'jsPrice'),
      'duration': _text(lang, 'jsDuration'),
      'serviceNamePlaceholder': _text(lang, 'serviceNamePlaceholder'),
      'pricePlaceholder': _text(lang, 'servicePricePlaceholder'),
      'durationPlaceholder': _text(lang, 'serviceDurationPlaceholder'),
      'serviceNote': _text(lang, 'serviceNote'),
      'copied': _text(lang, 'copied'),
    };
  }

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'uz': <String, String>{
      'pageTitle': 'Usta Top Avtoservis Admini',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Usta Top Avtoservis Admini',
      'language': 'Til',
      'workshopsTab': 'Avtoservislar',
      'bookingsTab': 'Zakazlar',
      'reviewsTab': 'Sharhlar',
      'ordersButton': 'Zakazlarni ko‘rish',
      'logout': 'Chiqish',
      'adminLoginTitle': 'Admin kirish',
      'adminLoginEyebrow': 'Himoyalangan Kirish',
      'adminLoginHeading': 'Avtoservis admin paneliga xavfsiz kirish',
      'adminLoginDescription':
          'Workshop kartalari, xarita nuqtalari va xizmat menyusini boshqarish uchun admin hisob bilan tizimga kiring.',
      'adminLoginTip1Title': 'Workshop kartalari',
      'adminLoginTip1Body':
          'Avtoservis nuqtalarini yaratish, tahrirlash va o‘chirish shu yerda boshqariladi.',
      'adminLoginTip2Title': 'Koordinata nazorati',
      'adminLoginTip2Body':
          'Xaritadan taxminiy lokatsiya tanlab, uni ilovadagi servis kartalari uchun saqlaysiz.',
      'adminLoginTip3Title': 'Til va sessiya',
      'adminLoginTip3Body':
          'Panel UZ, RU va EN tillarida ishlaydi, kirish esa admin sessiyasi bilan himoyalanadi.',
      'adminLoginFormEyebrow': 'Admin sessiyasi',
      'adminLoginFormSubtitle':
          'Davom etish uchun admin login va parolini kiriting.',
      'adminUsername': 'Admin login',
      'adminPassword': 'Admin parol',
      'adminPasswordPlaceholder': 'Parolingizni kiriting',
      'adminLoginButton': 'Kirish',
      'adminLoginHelper':
          'Admin ma’lumotlarini `ADMIN_USERNAME` va `ADMIN_PASSWORD` orqali o‘zgartirishingiz mumkin.',
      'adminLoginMissing': 'Admin login va parolni kiriting',
      'adminLoginInvalid': 'Admin login yoki parol noto‘g‘ri',
      'refreshPanel': 'Panelni yangilash',
      'healthEndpoint': 'Health endpoint',
      'heroEyebrow': 'Avtoservis Boshqaruvi',
      'heroTitle':
          'Avtoservis nuqtalari, xizmat turlari va xarita koordinatalarini bir joydan boshqaring.',
      'heroDescription':
          'Bu panel orqali yangi avtoservis qo‘shish, mavjud servis nuqtasini tahrirlash, xizmat turlarini boshqarish va xaritadan taxminiy joylashuv tanlash mumkin.',
      'heroPrimaryAction': 'Yangi avtoservis qo‘shish',
      'heroSecondaryAction': 'Mavjud avtoservislar',
      'workflowEyebrow': 'Ish Jarayoni',
      'workflowTitle': 'Qabul ustasi uchun tez tartib',
      'workflowStep1Title': '1. Avtoservis kartasini oching yoki yarating',
      'workflowStep1Body':
          'Yangi servis nuqtasi qo‘shing yoki mavjud avtoservis kartasini tahrirga oching.',
      'workflowStep2Title': '2. Xizmat turlari va joylashuvni belgilang',
      'workflowStep2Body':
          'Diagnostika, ta’mir va servis ishlarini kiriting, so‘ng xaritadan nuqta tanlang.',
      'workflowStep3Title': '3. Ma’lumotni saqlang',
      'workflowStep3Body':
          'Saqlangan ma’lumotlar darhol ilovadagi avtoservis kartalarida ishlatiladi.',
      'statWorkshopsLabel': 'Avtoservislar',
      'statWorkshopsSub': 'Paneldagi jami servis nuqtalari soni.',
      'statStatusLabel': 'Qabul Holati',
      'statStatusSub': 'Ochiq va yopiq avtoservislar nisbati.',
      'statRatingLabel': 'O‘rtacha Reyting',
      'statRatingSub': 'Mijoz baholari bo‘yicha o‘rtacha ko‘rsatkich.',
      'statServicesLabel': 'Xizmat Turlari',
      'statServicesSub': 'Barcha avtoservislar bo‘yicha jami ish turlari soni.',
      'createEyebrow': 'Yangi Nuqta',
      'createTitle': 'Yangi avtoservis qo‘shish',
      'createSubtitle':
          'Servis nuqtasi ma’lumotlarini, xizmat menyusini va koordinatasini kiriting.',
      'searchResultsChip': 'Qidiruv natijasi: {count}',
      'visibleChip': 'Ko‘rsatilmoqda: {count}',
      'manageEyebrow': 'Servis Kartalari',
      'manageTitle': 'Avtoservis kartalari',
      'manageSubtitle':
          'Qidiruv, filtr va CRUD orqali servis nuqtalarini boshqaring.',
      'statusChip': 'Holat: {status}',
      'searchLabel': 'Avtoservis, manzil yoki xizmat bo‘yicha qidiruv',
      'searchPlaceholder': 'Masalan: Chilonzor, motor diagnostika, Aziz Usta',
      'statusFilterLabel': 'Qabul holati filtri',
      'statusAll': 'Barchasi',
      'statusOpenOnly': 'Faqat ochiq',
      'statusClosedOnly': 'Faqat yopiq',
      'resetFilters': 'Filtrlarni tozalash',
      'applyFilter': 'Filtrni qo‘llash',
      'sidebarEyebrow': 'Eslatmalar',
      'sidebarTitle': 'Saqlash va ish usuli',
      'sidebarSubtitle':
          'Avtoservis ma’lumotlari JSON faylga, xarita koordinatalari esa alohida faylga yoziladi.',
      'sidebarTip1':
          'Xaritadagi nuqta bosilganda latitude va longitude formaga darhol tushadi.',
      'sidebarTip2':
          'Xizmat turlari blokida diagnostika, moy almashtirish va boshqa ishlarni boshqaring.',
      'sidebarTip3':
          'O‘chirish tugmasi servis nuqtasini ro‘yxat va fayldan olib tashlaydi.',
      'workshopsFileLabel': 'Avtoservis fayli',
      'locationFileLabel': 'Koordinata fayli',
      'mapPickerEyebrow': 'Xaritadan Tanlash',
      'mapPickerMeta':
          'Nuqtani xaritada bosing. Tanlangan koordinata formadagi latitude va longitude maydonlariga yoziladi.',
      'close': 'Yopish',
      'serviceItem': 'Xizmat turi',
      'remove': 'Olib tashlash',
      'jsName': 'Nomi',
      'jsPrice': 'Narxi',
      'jsDuration': 'Davomiyligi',
      'serviceNamePlaceholder': 'Masalan: Kompyuter diagnostika',
      'servicePricePlaceholder': '120',
      'serviceDurationPlaceholder': '35',
      'serviceNote':
          'Kartadagi boshlang‘ich narx va xizmat yorliqlari shu ro‘yxatdan shakllanadi.',
      'copied': 'Nusxalandi',
      'createSuccess': 'Yangi avtoservis qo‘shildi',
      'garageNotFound': 'Avtoservis topilmadi',
      'updateSuccess': '{name} yangilandi',
      'deleteSuccess': 'Avtoservis o‘chirildi',
      'deleteSuccessNamed': '{name} o‘chirildi',
      'locationUpdated': 'Koordinata yangilandi',
      'fieldWorkshopName': 'Avtoservis nomi',
      'fieldMaster': 'Mas’ul usta',
      'fieldAddress': 'Manzil',
      'fieldDescription': 'Tavsif',
      'fieldBadge': 'Afzallik yorlig‘i',
      'fieldOwnerAccessCode': 'Usta kirish kodi',
      'fieldOwnerPortal': 'Usta kabineti',
      'fieldTelegramChatId': 'Telegram chat ID',
      'fieldTelegramBotStatus': 'Telegram bot holati',
      'fieldRating': 'Reyting',
      'fieldReviewCount': 'Sharhlar soni',
      'fieldDistance': 'Masofa',
      'fieldDistanceKm': 'Masofa (km)',
      'fieldLatitude': 'Latitude',
      'fieldLongitude': 'Longitude',
      'fieldOpeningTime': 'Ish boshlanishi',
      'fieldClosingTime': 'Ish tugashi',
      'fieldBreakStart': 'Tanaffus boshlanishi',
      'fieldBreakEnd': 'Tanaffus tugashi',
      'fieldClosedWeekdays': 'Dam olish kunlari',
      'fieldServiceName': 'Xizmat turi nomi',
      'fieldServicePrice': 'Xizmat narxi',
      'fieldServiceDuration': 'Xizmat davomiyligi',
      'minimumOneService': 'Kamida bitta xizmat turi kiriting',
      'invalidServicesFormat': 'Xizmat turlari formati noto‘g‘ri',
      'requiredField': '{field} majburiy',
      'invalidField': '{field} noto‘g‘ri kiritildi',
      'outOfRangeField': '{field} ruxsat etilgan oraliqda emas',
      'resultsAll': 'Hozir barcha {count} ta avtoservis ko‘rsatilmoqda.',
      'resultsSearch':
          '“{query}” qidiruvi bo‘yicha {searchCount} ta natijadan {visibleCount} tasi ko‘rsatilmoqda.',
      'resultsStatus':
          '{status} filtri bo‘yicha {count} ta avtoservis ko‘rsatilmoqda.',
      'resultsSearchStatus':
          '“{query}” qidiruvi va {status} filtri bo‘yicha {count} ta avtoservis topildi.',
      'emptyEyebrow': 'Natija Yo‘q',
      'emptyTitle': 'Mos avtoservis topilmadi',
      'emptyNoData': 'Hozircha birorta avtoservis qo‘shilmagan.',
      'emptyFiltered':
          'Tanlangan filtr yoki qidiruv bo‘yicha mos servis nuqtasi topilmadi.',
      'clearFilters': 'Filtrlarni tozalash',
      'createCardTitle': 'Yangi avtoservis',
      'createCardSubtitle':
          'Yangi servis nuqtasini to‘liq maydonlari bilan yarating.',
      'createSubmit': 'Avtoservis yaratish',
      'mapSelectButton': 'Xaritadan tanlash',
      'garageId': 'Servis ID',
      'statusOpenNow': 'Hozir ochiq',
      'statusClosedNow': 'Hozir yopiq',
      'infoMaster': 'Mas’ul usta',
      'infoRating': 'Reyting',
      'infoReviews': 'Sharhlar',
      'infoDistance': 'Masofa',
      'infoWorkingHours': 'Ish vaqti',
      'infoBreakTime': 'Tanaffus',
      'infoDaysOff': 'Dam olish kunlari',
      'editCardTitle': 'Avtoservis tahriri',
      'editCardSubtitle':
          'Servis nuqtasi ma’lumotlari, xizmatlari va koordinatasini yangilang.',
      'deleteConfirm': 'Avtoservis kartasi o‘chirilsinmi?',
      'deleteButton': 'O‘chirish',
      'previewEyebrow': 'Oldindan Ko‘rish',
      'approximatePin': 'Taxminiy nuqta',
      'yandex': 'Yandex',
      'google': 'Google',
      'openStreetMap': 'OpenStreetMap',
      'copy': 'Nusxalash',
      'editorEyebrow': 'Tahrirlash',
      'placeholderWorkshopName': 'Masalan: Turbo Usta Servis',
      'placeholderMaster': 'Masalan: Aziz Usta',
      'placeholderBadge': 'Masalan: Tez qabul',
      'placeholderOwnerAccessCode': 'Bo‘sh qoldiring yoki masalan: 0001',
      'placeholderTelegramChatId': 'Masalan: 123456789 yoki -100...',
      'placeholderAddress': 'Masalan: Chilonzor, Toshkent',
      'placeholderDescription': 'Avtoservis haqida qisqa tavsif kiriting',
      'telegramBotEnabled': 'Ulangan',
      'telegramBotDisabled': 'Token kiritilmagan',
      'telegramNotLinked': 'Kiritilmagan',
      'telegramTestButton': 'Telegram test',
      'telegramTestSent': '{name} uchun test xabar yuborildi',
      'openCheckbox': 'Avtoservis hozir ochiq',
      'helperSchedule':
          'Ish boshlanishi, tugashi, tanaffus va dam olish kunlarini shu yerda belgilang. Keyingi bosqichda bo‘sh slotlar aynan shu jadvalga tayanadi.',
      'helperServices':
          'Xizmat turlarini shu yerda boshqaring. Ilovadagi boshlang‘ich narx va xizmat yorliqlari shu ro‘yxatdan olinadi.',
      'noBreakLabel': 'Tanaffus yo‘q',
      'noClosedWeekdaysLabel': 'Har kuni ochiq',
      'invalidTimeField': '{field} vaqti noto‘g‘ri',
      'scheduleTimeRangeError':
          'Ish tugash vaqti ish boshlanish vaqtidan keyin bo‘lishi kerak.',
      'scheduleBreakPairError':
          'Tanaffus uchun boshlanish va tugash vaqtini birga kiriting yoki ikkalasini ham bo‘sh qoldiring.',
      'scheduleBreakRangeError':
          'Tanaffus oralig‘i ish vaqti ichida va to‘g‘ri tartibda bo‘lishi kerak.',
      'weekdayShortMon': 'Du',
      'weekdayShortTue': 'Se',
      'weekdayShortWed': 'Cho',
      'weekdayShortThu': 'Pa',
      'weekdayShortFri': 'Ju',
      'weekdayShortSat': 'Sha',
      'weekdayShortSun': 'Yak',
      'servicesTitle': 'Xizmat turlari',
      'addService': 'Xizmat turi qo‘shish',
      'saveHint':
          'Saqlash tugmasi avtoservis ma’lumotlari va koordinatasini faylga yozadi.',
      'saveChanges': 'Saqlash',
    },
    'ru': <String, String>{
      'pageTitle': 'Админ автосервиса Usta Top',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Админ автосервиса Usta Top',
      'language': 'Язык',
      'workshopsTab': 'Автосервисы',
      'bookingsTab': 'Заказы',
      'reviewsTab': 'Отзывы',
      'ordersButton': 'Открыть заказы',
      'logout': 'Выйти',
      'adminLoginTitle': 'Вход администратора',
      'adminLoginEyebrow': 'Защищенный Вход',
      'adminLoginHeading': 'Безопасный вход в админ-панель автосервиса',
      'adminLoginDescription':
          'Войдите под учетной записью администратора, чтобы управлять карточками автосервисов, точками на карте и списком работ.',
      'adminLoginTip1Title': 'Карточки сервисов',
      'adminLoginTip1Body':
          'Здесь создаются, редактируются и удаляются точки автосервиса.',
      'adminLoginTip2Title': 'Контроль координат',
      'adminLoginTip2Body':
          'Вы выбираете примерную геолокацию на карте и сохраняете ее для карточек сервиса в приложении.',
      'adminLoginTip3Title': 'Язык и сессия',
      'adminLoginTip3Body':
          'Панель работает на UZ, RU и EN, а вход защищен сессией администратора.',
      'adminLoginFormEyebrow': 'Сессия администратора',
      'adminLoginFormSubtitle':
          'Введите логин и пароль администратора, чтобы продолжить.',
      'adminUsername': 'Логин администратора',
      'adminPassword': 'Пароль администратора',
      'adminPasswordPlaceholder': 'Введите пароль',
      'adminLoginButton': 'Войти',
      'adminLoginHelper':
          'Данные администратора можно изменить через `ADMIN_USERNAME` и `ADMIN_PASSWORD`.',
      'adminLoginMissing': 'Введите логин и пароль администратора',
      'adminLoginInvalid': 'Неверный логин или пароль администратора',
      'refreshPanel': 'Обновить панель',
      'healthEndpoint': 'Health endpoint',
      'heroEyebrow': 'Управление Автосервисом',
      'heroTitle':
          'Управляйте точками автосервиса, перечнем работ и координатами на карте из одного места.',
      'heroDescription':
          'Через эту панель можно добавлять новый автосервис, редактировать существующую точку, менять список работ и выбирать примерную геолокацию на карте.',
      'heroPrimaryAction': 'Добавить автосервис',
      'heroSecondaryAction': 'Текущие автосервисы',
      'workflowEyebrow': 'Сценарий Работы',
      'workflowTitle': 'Быстрый порядок для приемщика',
      'workflowStep1Title': '1. Откройте или создайте карточку сервиса',
      'workflowStep1Body':
          'Добавьте новую точку автосервиса или откройте существующую карточку на редактирование.',
      'workflowStep2Title': '2. Укажите работы и местоположение',
      'workflowStep2Body':
          'Заполните диагностику, ремонт и сервисные работы, затем выберите точку на карте.',
      'workflowStep3Title': '3. Сохраните данные',
      'workflowStep3Body':
          'Сохраненные данные сразу используются в карточках автосервисов в приложении.',
      'statWorkshopsLabel': 'Автосервисы',
      'statWorkshopsSub': 'Общее число точек автосервиса в панели.',
      'statStatusLabel': 'Статус Приема',
      'statStatusSub': 'Соотношение открытых и закрытых автосервисов.',
      'statRatingLabel': 'Средний Рейтинг',
      'statRatingSub': 'Средний показатель по оценкам клиентов.',
      'statServicesLabel': 'Виды Работ',
      'statServicesSub': 'Общее количество услуг по всем автосервисам.',
      'createEyebrow': 'Новая Точка',
      'createTitle': 'Добавить автосервис',
      'createSubtitle':
          'Введите данные точки сервиса, меню услуг и координаты.',
      'searchResultsChip': 'Найдено: {count}',
      'visibleChip': 'Показано: {count}',
      'manageEyebrow': 'Карточки Сервисов',
      'manageTitle': 'Карточки автосервисов',
      'manageSubtitle':
          'Управляйте сервисными точками через поиск, фильтр и CRUD.',
      'statusChip': 'Статус: {status}',
      'searchLabel': 'Поиск по автосервису, адресу или услуге',
      'searchPlaceholder':
          'Например: Чиланзар, диагностика двигателя, Азиз Уста',
      'statusFilterLabel': 'Фильтр статуса приема',
      'statusAll': 'Все',
      'statusOpenOnly': 'Только открытые',
      'statusClosedOnly': 'Только закрытые',
      'resetFilters': 'Сбросить фильтры',
      'applyFilter': 'Применить фильтр',
      'sidebarEyebrow': 'Заметки',
      'sidebarTitle': 'Хранение и порядок работы',
      'sidebarSubtitle':
          'Данные автосервисов пишутся в JSON, а координаты карты хранятся отдельно.',
      'sidebarTip1':
          'После клика по карте latitude и longitude сразу попадут в форму.',
      'sidebarTip2':
          'В блоке работ можно управлять диагностикой, заменой масла и другими услугами.',
      'sidebarTip3':
          'Кнопка удаления убирает сервисную точку из списка и из файла.',
      'workshopsFileLabel': 'Файл автосервисов',
      'locationFileLabel': 'Файл координат',
      'mapPickerEyebrow': 'Выбор На Карте',
      'mapPickerMeta':
          'Нажмите точку на карте. Выбранные latitude и longitude будут записаны в форму.',
      'close': 'Закрыть',
      'serviceItem': 'Работа',
      'remove': 'Удалить',
      'jsName': 'Название',
      'jsPrice': 'Цена',
      'jsDuration': 'Длительность',
      'serviceNamePlaceholder': 'Например: Компьютерная диагностика',
      'servicePricePlaceholder': '120',
      'serviceDurationPlaceholder': '35',
      'serviceNote':
          'Стартовая цена и ярлыки услуг в карточке формируются из этого списка.',
      'copied': 'Скопировано',
      'createSuccess': 'Новый автосервис добавлен',
      'garageNotFound': 'Автосервис не найден',
      'updateSuccess': '{name} обновлен',
      'deleteSuccess': 'Автосервис удален',
      'deleteSuccessNamed': '{name} удален',
      'locationUpdated': 'Координаты обновлены',
      'fieldWorkshopName': 'Название автосервиса',
      'fieldMaster': 'Ответственный мастер',
      'fieldAddress': 'Адрес',
      'fieldDescription': 'Описание',
      'fieldBadge': 'Ярлык преимущества',
      'fieldOwnerAccessCode': 'Код доступа владельца',
      'fieldOwnerPortal': 'Кабинет владельца',
      'fieldTelegramChatId': 'Telegram chat ID',
      'fieldTelegramBotStatus': 'Статус Telegram бота',
      'fieldRating': 'Рейтинг',
      'fieldReviewCount': 'Количество отзывов',
      'fieldDistance': 'Расстояние',
      'fieldDistanceKm': 'Расстояние (км)',
      'fieldLatitude': 'Latitude',
      'fieldLongitude': 'Longitude',
      'fieldOpeningTime': 'Начало работы',
      'fieldClosingTime': 'Конец работы',
      'fieldBreakStart': 'Начало перерыва',
      'fieldBreakEnd': 'Конец перерыва',
      'fieldClosedWeekdays': 'Выходные дни',
      'fieldServiceName': 'Название работы',
      'fieldServicePrice': 'Цена работы',
      'fieldServiceDuration': 'Длительность работы',
      'minimumOneService': 'Добавьте хотя бы один вид работ',
      'invalidServicesFormat': 'Неверный формат списка работ',
      'requiredField': 'Поле «{field}» обязательно',
      'invalidField': 'Поле «{field}» заполнено неверно',
      'outOfRangeField': 'Поле «{field}» вне допустимого диапазона',
      'resultsAll': 'Сейчас показаны все {count} автосервисов.',
      'resultsSearch':
          'По запросу «{query}» показано {visibleCount} из {searchCount} результатов.',
      'resultsStatus': 'По фильтру «{status}» показано {count} автосервисов.',
      'resultsSearchStatus':
          'По запросу «{query}» и фильтру «{status}» найдено {count} автосервисов.',
      'emptyEyebrow': 'Нет Результатов',
      'emptyTitle': 'Подходящий автосервис не найден',
      'emptyNoData': 'Пока не добавлено ни одной точки автосервиса.',
      'emptyFiltered':
          'По выбранному фильтру или поисковому запросу подходящая точка не найдена.',
      'clearFilters': 'Очистить фильтры',
      'createCardTitle': 'Новый автосервис',
      'createCardSubtitle': 'Создайте новую сервисную точку со всеми полями.',
      'createSubmit': 'Создать автосервис',
      'mapSelectButton': 'Выбрать на карте',
      'garageId': 'ID сервиса',
      'statusOpenNow': 'Сейчас открыт',
      'statusClosedNow': 'Сейчас закрыт',
      'infoMaster': 'Мастер',
      'infoRating': 'Рейтинг',
      'infoReviews': 'Отзывы',
      'infoDistance': 'Расстояние',
      'infoWorkingHours': 'Часы работы',
      'infoBreakTime': 'Перерыв',
      'infoDaysOff': 'Выходные',
      'editCardTitle': 'Редактирование автосервиса',
      'editCardSubtitle': 'Обновите данные точки, список работ и координаты.',
      'deleteConfirm': 'Удалить карточку автосервиса?',
      'deleteButton': 'Удалить',
      'previewEyebrow': 'Предпросмотр',
      'approximatePin': 'Примерная точка',
      'yandex': 'Yandex',
      'google': 'Google',
      'openStreetMap': 'OpenStreetMap',
      'copy': 'Копировать',
      'editorEyebrow': 'Редактор',
      'placeholderWorkshopName': 'Например: Turbo Usta Service',
      'placeholderMaster': 'Например: Азиз Уста',
      'placeholderBadge': 'Например: Быстрый прием',
      'placeholderOwnerAccessCode': 'Оставьте пустым или, например: 0001',
      'placeholderTelegramChatId': 'Например: 123456789 или -100...',
      'placeholderAddress': 'Например: Чиланзар, Ташкент',
      'placeholderDescription': 'Коротко опишите автосервис',
      'telegramBotEnabled': 'Подключен',
      'telegramBotDisabled': 'Токен не задан',
      'telegramNotLinked': 'Не указан',
      'telegramTestButton': 'Тест Telegram',
      'telegramTestSent': 'Тестовое сообщение отправлено для {name}',
      'openCheckbox': 'Автосервис сейчас открыт',
      'helperSchedule':
          'Укажите рабочие часы, перерыв и выходные дни. На следующем этапе свободные слоты будут строиться по этому графику.',
      'helperServices':
          'Управляйте видами работ здесь. Стартовая цена и ярлыки услуг в приложении формируются из этого списка.',
      'noBreakLabel': 'Без перерыва',
      'noClosedWeekdaysLabel': 'Открыт каждый день',
      'invalidTimeField': 'Время в поле {field} указано неверно',
      'scheduleTimeRangeError':
          'Время окончания работы должно быть позже времени начала.',
      'scheduleBreakPairError':
          'Для перерыва нужно указать и начало, и конец, либо оставить оба поля пустыми.',
      'scheduleBreakRangeError':
          'Перерыв должен находиться внутри рабочего времени и быть задан в правильном порядке.',
      'weekdayShortMon': 'Пн',
      'weekdayShortTue': 'Вт',
      'weekdayShortWed': 'Ср',
      'weekdayShortThu': 'Чт',
      'weekdayShortFri': 'Пт',
      'weekdayShortSat': 'Сб',
      'weekdayShortSun': 'Вс',
      'servicesTitle': 'Виды работ',
      'addService': 'Добавить работу',
      'saveHint':
          'Кнопка сохранения записывает данные автосервиса и координаты в файл.',
      'saveChanges': 'Сохранить',
    },
    'en': <String, String>{
      'pageTitle': 'Usta Top Auto Service Admin',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Usta Top Auto Service Admin',
      'language': 'Language',
      'workshopsTab': 'Workshops',
      'bookingsTab': 'Orders',
      'reviewsTab': 'Reviews',
      'ordersButton': 'Open orders',
      'logout': 'Log out',
      'adminLoginTitle': 'Admin sign in',
      'adminLoginEyebrow': 'Protected Access',
      'adminLoginHeading': 'Secure access to the auto service admin panel',
      'adminLoginDescription':
          'Sign in with the admin account to manage garage cards, map points, and the job menu.',
      'adminLoginTip1Title': 'Garage cards',
      'adminLoginTip1Body':
          'Create, edit, and remove auto service points from one place.',
      'adminLoginTip2Title': 'Coordinate control',
      'adminLoginTip2Body':
          'Pick an approximate location on the map and save it for the mobile app garage cards.',
      'adminLoginTip3Title': 'Language and session',
      'adminLoginTip3Body':
          'The panel works in UZ, RU, and EN, and access is protected with an admin session.',
      'adminLoginFormEyebrow': 'Admin session',
      'adminLoginFormSubtitle':
          'Enter the admin username and password to continue.',
      'adminUsername': 'Admin username',
      'adminPassword': 'Admin password',
      'adminPasswordPlaceholder': 'Enter your password',
      'adminLoginButton': 'Sign in',
      'adminLoginHelper':
          'You can override the default admin credentials with `ADMIN_USERNAME` and `ADMIN_PASSWORD`.',
      'adminLoginMissing': 'Enter the admin username and password',
      'adminLoginInvalid': 'The admin username or password is incorrect',
      'refreshPanel': 'Refresh panel',
      'healthEndpoint': 'Health endpoint',
      'heroEyebrow': 'Garage Operations',
      'heroTitle':
          'Manage garage locations, job menus, and map coordinates from one place.',
      'heroDescription':
          'Use this panel to add a new auto service point, edit an existing garage card, manage repair jobs, and pick an approximate map location.',
      'heroPrimaryAction': 'Add auto service',
      'heroSecondaryAction': 'Current service points',
      'workflowEyebrow': 'Workflow',
      'workflowTitle': 'Quick flow for the service desk',
      'workflowStep1Title': '1. Open or create a garage card',
      'workflowStep1Body':
          'Add a new service point or open an existing garage card for editing.',
      'workflowStep2Title': '2. Set jobs and location',
      'workflowStep2Body':
          'Enter diagnostics, repair, and maintenance jobs, then choose the point on the map.',
      'workflowStep3Title': '3. Save the data',
      'workflowStep3Body':
          'Saved data is immediately used in the mobile app garage cards.',
      'statWorkshopsLabel': 'Auto Services',
      'statWorkshopsSub': 'Total number of service points in the panel.',
      'statStatusLabel': 'Reception Status',
      'statStatusSub': 'Ratio of open versus closed garages.',
      'statRatingLabel': 'Average Rating',
      'statRatingSub': 'Average score based on customer reviews.',
      'statServicesLabel': 'Job Types',
      'statServicesSub': 'Total number of listed jobs across all garages.',
      'createEyebrow': 'New Point',
      'createTitle': 'Add auto service',
      'createSubtitle':
          'Fill in the service point profile, job menu, and map coordinates.',
      'searchResultsChip': 'Search results: {count}',
      'visibleChip': 'Visible: {count}',
      'manageEyebrow': 'Service Cards',
      'manageTitle': 'Garage cards',
      'manageSubtitle':
          'Manage service points with search, filters, and CRUD actions.',
      'statusChip': 'Status: {status}',
      'searchLabel': 'Search by garage, address, or job',
      'searchPlaceholder':
          'For example: Chilanzar, engine diagnostics, Aziz Usta',
      'statusFilterLabel': 'Reception status filter',
      'statusAll': 'All',
      'statusOpenOnly': 'Open only',
      'statusClosedOnly': 'Closed only',
      'resetFilters': 'Clear filters',
      'applyFilter': 'Apply filter',
      'sidebarEyebrow': 'Notes',
      'sidebarTitle': 'Storage and workflow',
      'sidebarSubtitle':
          'Garage data is stored in a JSON file, while map coordinates are saved separately.',
      'sidebarTip1':
          'Clicking a point on the map immediately fills latitude and longitude into the form.',
      'sidebarTip2':
          'Use the jobs block to manage diagnostics, oil changes, and other workshop work.',
      'sidebarTip3':
          'The delete button removes the service point from both the list and the file.',
      'workshopsFileLabel': 'Garage data file',
      'locationFileLabel': 'Coordinate file',
      'mapPickerEyebrow': 'Map Picker',
      'mapPickerMeta':
          'Click a point on the map. The selected latitude and longitude will be written into the form.',
      'close': 'Close',
      'serviceItem': 'Job',
      'remove': 'Remove',
      'jsName': 'Name',
      'jsPrice': 'Price',
      'jsDuration': 'Duration',
      'serviceNamePlaceholder': 'For example: Computer diagnostics',
      'servicePricePlaceholder': '120',
      'serviceDurationPlaceholder': '35',
      'serviceNote':
          'Starting price and service labels on the card are generated from this list.',
      'copied': 'Copied',
      'createSuccess': 'New auto service added',
      'garageNotFound': 'Auto service not found',
      'updateSuccess': '{name} updated',
      'deleteSuccess': 'Auto service deleted',
      'deleteSuccessNamed': '{name} deleted',
      'locationUpdated': 'Coordinates updated',
      'fieldWorkshopName': 'Garage name',
      'fieldMaster': 'Lead mechanic',
      'fieldAddress': 'Address',
      'fieldDescription': 'Description',
      'fieldBadge': 'Highlight tag',
      'fieldOwnerAccessCode': 'Owner access code',
      'fieldOwnerPortal': 'Owner portal',
      'fieldTelegramChatId': 'Telegram chat ID',
      'fieldTelegramBotStatus': 'Telegram bot status',
      'fieldRating': 'Rating',
      'fieldReviewCount': 'Review count',
      'fieldDistance': 'Distance',
      'fieldDistanceKm': 'Distance (km)',
      'fieldLatitude': 'Latitude',
      'fieldLongitude': 'Longitude',
      'fieldOpeningTime': 'Opening time',
      'fieldClosingTime': 'Closing time',
      'fieldBreakStart': 'Break starts',
      'fieldBreakEnd': 'Break ends',
      'fieldClosedWeekdays': 'Days off',
      'fieldServiceName': 'Job name',
      'fieldServicePrice': 'Job price',
      'fieldServiceDuration': 'Job duration',
      'minimumOneService': 'Add at least one job type',
      'invalidServicesFormat': 'Invalid job list format',
      'requiredField': '{field} is required',
      'invalidField': '{field} is invalid',
      'outOfRangeField': '{field} is out of range',
      'resultsAll': 'All {count} auto services are currently visible.',
      'resultsSearch':
          '{visibleCount} of {searchCount} results are shown for “{query}”.',
      'resultsStatus':
          '{count} auto services are shown for the “{status}” filter.',
      'resultsSearchStatus':
          '{count} auto services were found for “{query}” with the “{status}” filter.',
      'emptyEyebrow': 'No Results',
      'emptyTitle': 'No matching garage found',
      'emptyNoData': 'No auto service points have been added yet.',
      'emptyFiltered':
          'No matching service point was found for the selected filter or search.',
      'clearFilters': 'Clear filters',
      'createCardTitle': 'New auto service',
      'createCardSubtitle':
          'Create a new service point with the full set of fields.',
      'createSubmit': 'Create auto service',
      'mapSelectButton': 'Pick from map',
      'garageId': 'Service ID',
      'statusOpenNow': 'Open now',
      'statusClosedNow': 'Closed now',
      'infoMaster': 'Lead mechanic',
      'infoRating': 'Rating',
      'infoReviews': 'Reviews',
      'infoDistance': 'Distance',
      'infoWorkingHours': 'Working hours',
      'infoBreakTime': 'Break',
      'infoDaysOff': 'Days off',
      'editCardTitle': 'Edit garage card',
      'editCardSubtitle':
          'Update the service point details, job list, and map coordinates.',
      'deleteConfirm': 'Delete this garage card?',
      'deleteButton': 'Delete',
      'previewEyebrow': 'Live Preview',
      'approximatePin': 'Approximate pin',
      'yandex': 'Yandex',
      'google': 'Google',
      'openStreetMap': 'OpenStreetMap',
      'copy': 'Copy',
      'editorEyebrow': 'Editor',
      'placeholderWorkshopName': 'For example: Turbo Usta Service',
      'placeholderMaster': 'For example: Aziz Usta',
      'placeholderBadge': 'For example: Fast intake',
      'placeholderOwnerAccessCode': 'Leave blank or use 0001',
      'placeholderTelegramChatId': 'For example: 123456789 or -100...',
      'placeholderAddress': 'For example: Chilanzar, Tashkent',
      'placeholderDescription': 'Enter a short description of the garage',
      'telegramBotEnabled': 'Connected',
      'telegramBotDisabled': 'Token not configured',
      'telegramNotLinked': 'Not linked',
      'telegramTestButton': 'Telegram test',
      'telegramTestSent': 'Test message sent for {name}',
      'openCheckbox': 'Garage is currently open',
      'helperSchedule':
          'Set working hours, break time, and days off here. The next step will use this schedule to build available slots.',
      'helperServices':
          'Manage the job list here. The app uses this list to build the starting price and service labels.',
      'noBreakLabel': 'No break',
      'noClosedWeekdaysLabel': 'Open every day',
      'invalidTimeField': '{field} has an invalid time',
      'scheduleTimeRangeError':
          'Closing time must be later than opening time.',
      'scheduleBreakPairError':
          'Enter both break start and break end, or leave both empty.',
      'scheduleBreakRangeError':
          'The break must stay inside the working hours and follow the correct order.',
      'weekdayShortMon': 'Mon',
      'weekdayShortTue': 'Tue',
      'weekdayShortWed': 'Wed',
      'weekdayShortThu': 'Thu',
      'weekdayShortFri': 'Fri',
      'weekdayShortSat': 'Sat',
      'weekdayShortSun': 'Sun',
      'servicesTitle': 'Job types',
      'addService': 'Add job type',
      'saveHint':
          'The save button writes both garage details and coordinates to file.',
      'saveChanges': 'Save',
    },
  };

  String _escapeHtml(String value) => const HtmlEscape().convert(value);
}
