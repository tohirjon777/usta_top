import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models.dart';
import '../owner_auth.dart';
import '../store.dart';

class OwnerController {
  const OwnerController(
    this._store, {
    required this.ownerAuthService,
    required this.bookingsFilePath,
  });

  final InMemoryStore _store;
  final OwnerAuthService ownerAuthService;
  final String bookingsFilePath;

  Response entry(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    if (ownerAuthService.isAuthenticated(request)) {
      return Response.seeOther(_ownerBookingsUri(lang: lang));
    }
    return Response.seeOther(_ownerLoginUri(lang: lang));
  }

  Response loginPage(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String? error = request.url.queryParameters['error'];
    final String? selectedWorkshopId = request.url.queryParameters['workshop'];
    final List<WorkshopModel> workshops = _store.workshops();

    if (ownerAuthService.isAuthenticated(request)) {
      return Response.seeOther(_ownerBookingsUri(lang: lang));
    }

    final String workshopOptions = workshops.map((WorkshopModel workshop) {
      final bool isSelected = workshop.id == selectedWorkshopId;
      return '<option value="${_escapeHtml(workshop.id)}"${isSelected ? ' selected' : ''}>${_escapeHtml(workshop.name)}</option>';
    }).join();

    final Uri langUzUri =
        _ownerLoginUri(lang: 'uz', workshopId: selectedWorkshopId);
    final Uri langRuUri =
        _ownerLoginUri(lang: 'ru', workshopId: selectedWorkshopId);
    final Uri langEnUri =
        _ownerLoginUri(lang: 'en', workshopId: selectedWorkshopId);

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'loginTitle'))}</title>
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

    .brand-copy { display: grid; gap: 4px; }
    .brand-title, h1, h2, p { margin: 0; }
    .brand-title {
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: 24px;
      letter-spacing: -0.02em;
    }

    .eyebrow {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--accent-strong);
      font-weight: 700;
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
      grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);
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

    .field input, .field select {
      width: 100%;
      min-height: 52px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 15px;
      font-size: 15px;
      background: rgba(255, 255, 255, 0.92);
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
      .card { grid-template-columns: 1fr; }
      .hero, .form-wrap { padding: 20px; }
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
        <div class="eyebrow">${_escapeHtml(_text(lang, 'heroEyebrow'))}</div>
        <h1>${_escapeHtml(_text(lang, 'heroTitle'))}</h1>
        <p>${_escapeHtml(_text(lang, 'heroDescription'))}</p>
        <ul class="tips">
          <li><strong>${_escapeHtml(_text(lang, 'tip1Title'))}</strong><br>${_escapeHtml(_text(lang, 'tip1Body'))}</li>
          <li><strong>${_escapeHtml(_text(lang, 'tip2Title'))}</strong><br>${_escapeHtml(_text(lang, 'tip2Body'))}</li>
          <li><strong>${_escapeHtml(_text(lang, 'tip3Title'))}</strong><br>${_escapeHtml(_text(lang, 'tip3Body'))}</li>
        </ul>
      </div>

      <div class="form-wrap">
        <div class="eyebrow">${_escapeHtml(_text(lang, 'loginEyebrow'))}</div>
        <h2>${_escapeHtml(_text(lang, 'loginTitle'))}</h2>
        <p>${_escapeHtml(_text(lang, 'loginSubtitle'))}</p>
        ${error != null && error.isNotEmpty ? '<div class="alert">${_escapeHtml(error)}</div>' : ''}
        <form method="post" action="/owner/login">
          <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'workshopField'))}</label>
            <select name="workshopId">
              <option value="">${_escapeHtml(_text(lang, 'workshopPlaceholder'))}</option>
              $workshopOptions
            </select>
          </div>
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'accessCodeField'))}</label>
            <input type="password" name="accessCode" autocomplete="one-time-code" placeholder="${_escapeHtml(_text(lang, 'accessCodePlaceholder'))}">
          </div>
          <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'loginButton'))}</button>
        </form>
        <div class="helper">${_escapeHtml(_text(lang, 'loginHelper'))}</div>
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
    final String workshopId = (form['workshopId'] ?? '').trim();
    final String accessCode = (form['accessCode'] ?? '').trim();

    if (workshopId.isEmpty || accessCode.isEmpty) {
      return Response.seeOther(
        _ownerLoginUri(
          lang: lang,
          workshopId: workshopId,
          error: _text(lang, 'loginMissing'),
        ),
      );
    }

    final WorkshopModel? workshop = _store.workshopByOwnerAccess(
      workshopId: workshopId,
      accessCode: accessCode,
    );
    if (workshop == null) {
      return Response.seeOther(
        _ownerLoginUri(
          lang: lang,
          workshopId: workshopId,
          error: _text(lang, 'loginInvalid'),
        ),
      );
    }

    final String token = ownerAuthService.createSession(workshop.id);
    return Response.seeOther(
      _ownerBookingsUri(lang: lang),
      headers: <String, String>{
        'set-cookie': ownerAuthService.buildSessionCookie(token),
      },
    );
  }

  Response logout(Request request) {
    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    ownerAuthService.revokeSession(ownerAuthService.readSessionToken(request));
    return Response.seeOther(
      _ownerLoginUri(lang: lang),
      headers: <String, String>{
        'set-cookie': ownerAuthService.buildClearedSessionCookie(),
      },
    );
  }

  Response bookingsPage(Request request) {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String workshopId =
        ownerAuthService.workshopIdFromRequest(request) ?? '';
    final WorkshopModel? workshop = _store.workshopById(workshopId);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    final String status =
        _normalizeStatus(request.url.queryParameters['status']);
    final List<BookingModel> bookings = _store.bookings(
      workshopId: workshop.id,
      status: status == 'all' ? null : _statusFromRaw(status),
    );
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final int upcomingCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.upcoming)
        .length;
    final int completedCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.completed)
        .length;
    final int cancelledCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.cancelled)
        .length;

    final Uri langUzUri = _ownerBookingsUri(lang: 'uz', status: status);
    final Uri langRuUri = _ownerBookingsUri(lang: 'ru', status: status);
    final Uri langEnUri = _ownerBookingsUri(lang: 'en', status: status);

    final String bookingCards = bookings.isEmpty
        ? '''
<section class="empty-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'emptyEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'emptyTitle'))}</h3>
  <p>${_escapeHtml(_text(lang, status == 'all' ? 'emptyBody' : 'emptyFilteredBody'))}</p>
</section>
'''
        : bookings.map((BookingModel item) {
            final String statusLabel = _statusLabel(item.status, lang);
            final String statusClass = switch (item.status) {
              BookingStatus.upcoming => 'status-upcoming',
              BookingStatus.completed => 'status-completed',
              BookingStatus.cancelled => 'status-cancelled',
            };
            return '''
<article class="booking-card">
  <div class="booking-head">
    <div>
      <div class="eyebrow">${_escapeHtml(_text(lang, 'orderId'))} ${_escapeHtml(item.id)}</div>
      <h3>${_escapeHtml(item.customerName.isEmpty ? _text(lang, 'unknownCustomer') : item.customerName)}</h3>
      <div class="muted">${_escapeHtml(item.customerPhone.isEmpty ? _text(lang, 'noPhone') : item.customerPhone)}</div>
    </div>
    <span class="status-pill $statusClass">${_escapeHtml(statusLabel)}</span>
  </div>

  <div class="meta-grid">
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'serviceLabel'))}</span>
      <strong>${_escapeHtml(item.serviceName)}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'masterLabel'))}</span>
      <strong>${_escapeHtml(item.masterName)}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'appointmentLabel'))}</span>
      <strong>${_escapeHtml(_formatDateTime(item.dateTime))}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'priceLabel'))}</span>
      <strong>${_escapeHtml(item.price.toString())}k</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'createdLabel'))}</span>
      <strong>${_escapeHtml(_formatDateTime(item.createdAt))}</strong>
    </div>
  </div>

  <div class="booking-footer">
    <div class="quick-links">
      ${item.customerPhone.isEmpty ? '' : '<a class="ghost-btn" href="tel:${_escapeHtml(item.customerPhone)}">${_escapeHtml(_text(lang, 'callCustomer'))}</a>'}
    </div>
    <div class="quick-links">
      ${_statusActionForm(item, BookingStatus.upcoming, lang, status)}
      ${_statusActionForm(item, BookingStatus.completed, lang, status)}
      ${_statusActionForm(item, BookingStatus.cancelled, lang, status)}
    </div>
  </div>
</article>
''';
          }).join();

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'panelTitle'))}</title>
  <style>
    :root {
      color-scheme: light only;
      --bg: #f5efe5;
      --card: rgba(255, 251, 245, 0.92);
      --line: rgba(88, 67, 40, 0.14);
      --text: #221b16;
      --muted: #6b6259;
      --accent: #bf5b21;
      --accent-strong: #8f3811;
      --shadow: 0 18px 60px rgba(56, 34, 12, 0.09);
      --mint: #1f8a63;
      --mint-soft: #e8f7f0;
      --yellow: #9b6b00;
      --yellow-soft: #fff4cf;
      --red: #c54b49;
      --red-soft: #fff0ef;
      --ink: #24313f;
      --radius: 26px;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Avenir Next", "Trebuchet MS", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(255, 205, 154, 0.9) 0, transparent 28%),
        radial-gradient(circle at 85% 10%, rgba(87, 145, 201, 0.18) 0, transparent 26%),
        linear-gradient(180deg, #fcfaf7 0%, var(--bg) 100%);
      color: var(--text);
    }

    a { color: inherit; text-decoration: none; }
    button { font: inherit; }

    .wrap {
      max-width: 1280px;
      margin: 0 auto;
      padding: 26px 18px 48px;
      display: grid;
      gap: 18px;
    }

    .card, .topbar, .hero-card, .empty-card, .booking-card {
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
      gap: 14px;
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
      display: grid;
      place-items: center;
      color: white;
      font-weight: 800;
      letter-spacing: 0.08em;
      background: linear-gradient(135deg, rgba(191, 91, 33, 0.95) 0%, rgba(143, 56, 17, 0.95) 100%);
    }

    .brand-copy { display: grid; gap: 4px; }
    .brand-title, h1, h2, h3, p { margin: 0; }
    .brand-title {
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: 24px;
      letter-spacing: -0.02em;
    }

    .eyebrow {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--accent-strong);
      font-weight: 700;
    }

    .top-actions, .stats-grid, .quick-links, .booking-footer {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .pill-link, .ghost-btn, .status-btn, .danger-btn {
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      border-radius: 999px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 700;
      color: var(--ink);
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }

    .pill-link.active, .status-btn.active {
      color: white;
      border-color: transparent;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
    }

    .danger-btn {
      color: var(--red);
      background: var(--red-soft);
      border-color: rgba(197, 75, 73, 0.2);
    }

    .inline-form { margin: 0; }

    .hero-card {
      padding: 24px;
      display: grid;
      gap: 16px;
      background:
        radial-gradient(circle at top right, rgba(255, 216, 176, 0.95) 0, transparent 30%),
        linear-gradient(135deg, rgba(255, 250, 243, 0.96) 0%, rgba(247, 238, 229, 0.92) 100%);
    }

    .hero-card p, .muted { color: var(--muted); line-height: 1.65; }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .stat-card {
      padding: 18px;
      border-radius: 22px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.66);
    }

    .stat-card strong {
      display: block;
      font-size: 28px;
      margin-top: 10px;
    }

    .flash {
      padding: 14px 16px;
      border-radius: 18px;
      font-size: 14px;
    }

    .flash.ok {
      background: var(--mint-soft);
      color: var(--mint);
      border: 1px solid rgba(31, 138, 99, 0.15);
    }

    .flash.err {
      background: var(--red-soft);
      color: var(--red);
      border: 1px solid rgba(197, 75, 73, 0.15);
    }

    .booking-list {
      display: grid;
      gap: 14px;
    }

    .booking-card {
      padding: 18px;
      display: grid;
      gap: 14px;
    }

    .booking-head {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: start;
      flex-wrap: wrap;
    }

    .meta-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
    }

    .meta-card {
      padding: 14px;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: grid;
      gap: 6px;
    }

    .meta-card span {
      color: var(--muted);
      font-size: 13px;
    }

    .booking-footer {
      justify-content: space-between;
    }

    .status-pill {
      padding: 9px 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
    }

    .status-upcoming {
      color: var(--yellow);
      background: var(--yellow-soft);
    }

    .status-completed {
      color: var(--mint);
      background: var(--mint-soft);
    }

    .status-cancelled {
      color: var(--red);
      background: var(--red-soft);
    }

    .empty-card {
      padding: 24px;
      display: grid;
      gap: 10px;
    }

    @media (max-width: 760px) {
      .wrap { padding: 18px 12px 36px; }
      .stats-grid, .meta-grid { grid-template-columns: 1fr; }
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
          <div class="brand-title">${_escapeHtml(workshop.name)}</div>
        </div>
      </div>
      <div class="top-actions">
        <a class="pill-link${status == 'all' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang).toString())}">${_escapeHtml(_text(lang, 'statusAll'))}</a>
        <a class="pill-link${status == 'upcoming' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'upcoming').toString())}">${_escapeHtml(_text(lang, 'statusUpcoming'))}</a>
        <a class="pill-link${status == 'completed' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'completed').toString())}">${_escapeHtml(_text(lang, 'statusCompleted'))}</a>
        <a class="pill-link${status == 'cancelled' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'cancelled').toString())}">${_escapeHtml(_text(lang, 'statusCancelled'))}</a>
        <a class="pill-link${lang == 'uz' ? ' active' : ''}" href="${_escapeHtml(langUzUri.toString())}">UZ</a>
        <a class="pill-link${lang == 'ru' ? ' active' : ''}" href="${_escapeHtml(langRuUri.toString())}">RU</a>
        <a class="pill-link${lang == 'en' ? ' active' : ''}" href="${_escapeHtml(langEnUri.toString())}">EN</a>
        <form class="inline-form" method="post" action="/owner/logout?lang=${_escapeHtml(lang)}">
          <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'logout'))}</button>
        </form>
      </div>
    </div>

    <section class="hero-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'panelEyebrow'))}</div>
      <h1>${_escapeHtml(_text(lang, 'panelTitle'))}</h1>
      <p>${_escapeHtml(_text(lang, 'panelDescription'))}</p>

      <div class="stats-grid">
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statusUpcoming'))}</div>
          <strong>$upcomingCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'upcomingHint'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statusCompleted'))}</div>
          <strong>$completedCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'completedHint'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statusCancelled'))}</div>
          <strong>$cancelledCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'cancelledHint'))}</div>
        </div>
      </div>
    </section>

    ${_flashHtml(message: message, error: error)}

    <section class="booking-list">
      $bookingCards
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

  Future<Response> updateStatus(Request request, String bookingId) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String workshopId =
        ownerAuthService.workshopIdFromRequest(request) ?? '';
    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final BookingStatus nextStatus = _statusFromRaw(form['bookingStatus']);

    try {
      final BookingModel updated = _store.updateWorkshopBookingStatus(
        workshopId: workshopId,
        bookingId: bookingId,
        status: nextStatus,
      );
      await _store.saveBookings(bookingsFilePath);
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(
            lang,
            'statusUpdated',
            <String, Object>{
              'id': updated.id,
              'status': _statusLabel(updated.status, lang),
            },
          ),
        ),
      );
    } on StateError catch (error) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: error.message,
        ),
      );
    }
  }

  String _statusActionForm(
    BookingModel booking,
    BookingStatus nextStatus,
    String lang,
    String status,
  ) {
    final bool isActive = booking.status == nextStatus;
    return '''
<form class="inline-form" method="post" action="/owner/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
  <input type="hidden" name="bookingStatus" value="${_escapeHtml(nextStatus.name)}">
  <button class="status-btn${isActive ? ' active' : ''}" type="submit">${_escapeHtml(_statusLabel(nextStatus, lang))}</button>
</form>
''';
  }

  Response? _requireOwner(Request request) {
    if (ownerAuthService.isAuthenticated(request)) {
      return null;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    return Response.seeOther(_ownerLoginUri(lang: lang));
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
        values[key] = list.last;
      }
    });
    return values;
  }

  Uri _ownerLoginUri({
    String? lang,
    String? workshopId,
    String? error,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    if (workshopId != null && workshopId.trim().isNotEmpty) {
      params['workshop'] = workshopId.trim();
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/owner/login', queryParameters: params);
  }

  Uri _ownerBookingsUri({
    String? lang,
    String? status,
    String? message,
    String? error,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    final String normalizedStatus = _normalizeStatus(status);
    if (normalizedStatus != 'all') {
      params['status'] = normalizedStatus;
    }
    if (message != null && message.trim().isNotEmpty) {
      params['message'] = message.trim();
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/owner/bookings', queryParameters: params);
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

  String _normalizeStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'upcoming':
        return 'upcoming';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'all';
    }
  }

  BookingStatus _statusFromRaw(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'upcoming':
      default:
        return BookingStatus.upcoming;
    }
  }

  String _statusLabel(BookingStatus status, String lang) {
    switch (status) {
      case BookingStatus.upcoming:
        return _text(lang, 'statusUpcoming');
      case BookingStatus.completed:
        return _text(lang, 'statusCompleted');
      case BookingStatus.cancelled:
        return _text(lang, 'statusCancelled');
    }
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
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

  String _escapeHtml(String value) => const HtmlEscape().convert(value);

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'uz': <String, String>{
      'brandEyebrow': 'Owner Portal',
      'brandTitle': 'Usta Top Workshop Egasi',
      'language': 'Til',
      'loginTitle': 'Workshop egasi kirishi',
      'heroEyebrow': 'Zakazlarni Ko‘rish',
      'heroTitle': 'Faqat o‘z ustaxonangiz zakazlarini kuzating',
      'heroDescription':
          'Workshop va access code orqali kirib, mijoz buyurtmalarini ko‘rishingiz va statusini yangilashingiz mumkin.',
      'tip1Title': 'Yangi zakazlar',
      'tip1Body':
          'Ilovadan tushgan yangi buyurtmalar shu yerda darhol ko‘rinadi.',
      'tip2Title': 'Mijoz bilan aloqa',
      'tip2Body': 'Telefon tugmasi orqali mijozga tezda qo‘ng‘iroq qilasiz.',
      'tip3Title': 'Status nazorati',
      'tip3Body':
          'Kutilmoqda, yakunlangan yoki bekor qilingan statuslarini shu paneldan boshqarasiz.',
      'loginEyebrow': 'Workshop Login',
      'loginSubtitle': 'Davom etish uchun workshop va access code ni tanlang.',
      'workshopField': 'Workshop',
      'workshopPlaceholder': 'Workshopni tanlang',
      'accessCodeField': 'Access code',
      'accessCodePlaceholder': 'Masalan: 0001',
      'loginButton': 'Kirish',
      'loginHelper':
          'Agar kodni bilmasangiz, admin paneldagi workshop kartasidan ko‘rishingiz mumkin.',
      'loginMissing': 'Workshop va access code ni kiriting',
      'loginInvalid': 'Workshop yoki access code noto‘g‘ri',
      'panelEyebrow': 'Workshop Inbox',
      'panelTitle': 'Workshop zakazlari',
      'panelDescription':
          'Quyidagi ro‘yxatda faqat sizning ustaxonangizga tegishli buyurtmalar ko‘rinadi.',
      'statusAll': 'Barchasi',
      'statusUpcoming': 'Kutilmoqda',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'upcomingHint': 'Tez javob berish kerak bo‘lgan yangi zakazlar.',
      'completedHint': 'Bajarib bo‘lingan zakazlar.',
      'cancelledHint': 'Bekor qilingan buyurtmalar.',
      'emptyEyebrow': 'Zakaz Yo‘q',
      'emptyTitle': 'Hozircha zakaz yo‘q',
      'emptyBody': 'Bu workshop uchun hali zakaz tushmagan.',
      'emptyFilteredBody': 'Tanlangan status bo‘yicha zakaz topilmadi.',
      'orderId': 'Zakaz ID',
      'unknownCustomer': 'Mijoz nomi yo‘q',
      'noPhone': 'Telefon yo‘q',
      'serviceLabel': 'Xizmat',
      'masterLabel': 'Mas’ul usta',
      'appointmentLabel': 'Bron vaqti',
      'priceLabel': 'Narx',
      'createdLabel': 'Tushgan vaqt',
      'callCustomer': 'Mijozga qo‘ng‘iroq',
      'statusUpdated': '{id} statusi {status} ga o‘zgardi',
      'logout': 'Chiqish',
    },
    'ru': <String, String>{
      'brandEyebrow': 'Owner Portal',
      'brandTitle': 'Владелец сервиса Usta Top',
      'language': 'Язык',
      'loginTitle': 'Вход владельца workshop',
      'heroEyebrow': 'Просмотр Заказов',
      'heroTitle': 'Следите только за заказами своего автосервиса',
      'heroDescription':
          'Выберите workshop и access code, чтобы смотреть заказы клиентов и менять их статус.',
      'tip1Title': 'Новые заказы',
      'tip1Body': 'Новые заявки из приложения появляются здесь сразу.',
      'tip2Title': 'Связь с клиентом',
      'tip2Body': 'Через кнопку телефона можно быстро позвонить клиенту.',
      'tip3Title': 'Контроль статуса',
      'tip3Body':
          'Статусы ожидания, завершения и отмены управляются прямо из панели.',
      'loginEyebrow': 'Workshop Login',
      'loginSubtitle': 'Выберите workshop и введите access code.',
      'workshopField': 'Workshop',
      'workshopPlaceholder': 'Выберите workshop',
      'accessCodeField': 'Access code',
      'accessCodePlaceholder': 'Например: 0001',
      'loginButton': 'Войти',
      'loginHelper':
          'Если вы не знаете код, его можно посмотреть в карточке workshop в админке.',
      'loginMissing': 'Выберите workshop и введите access code',
      'loginInvalid': 'Workshop или access code неверны',
      'panelEyebrow': 'Workshop Inbox',
      'panelTitle': 'Заказы workshop',
      'panelDescription':
          'В этом списке показаны только заказы, относящиеся к вашему автосервису.',
      'statusAll': 'Все',
      'statusUpcoming': 'Ожидает',
      'statusCompleted': 'Завершен',
      'statusCancelled': 'Отменен',
      'upcomingHint': 'Новые заказы, на которые нужно быстро ответить.',
      'completedHint': 'Заказы, по которым работа уже завершена.',
      'cancelledHint': 'Отмененные заявки.',
      'emptyEyebrow': 'Нет Заказов',
      'emptyTitle': 'Пока заказов нет',
      'emptyBody': 'Для этого workshop пока не поступило заказов.',
      'emptyFilteredBody': 'По выбранному статусу заказов не найдено.',
      'orderId': 'ID заказа',
      'unknownCustomer': 'Имя клиента не указано',
      'noPhone': 'Телефон не указан',
      'serviceLabel': 'Услуга',
      'masterLabel': 'Ответственный мастер',
      'appointmentLabel': 'Время записи',
      'priceLabel': 'Цена',
      'createdLabel': 'Время поступления',
      'callCustomer': 'Позвонить клиенту',
      'statusUpdated': 'Статус {id} изменен на {status}',
      'logout': 'Выйти',
    },
    'en': <String, String>{
      'brandEyebrow': 'Owner Portal',
      'brandTitle': 'Usta Top Workshop Owner',
      'language': 'Language',
      'loginTitle': 'Workshop owner sign in',
      'heroEyebrow': 'Order Visibility',
      'heroTitle': 'Watch only your workshop’s incoming orders',
      'heroDescription':
          'Choose your workshop and enter the access code to see customer orders and update their status.',
      'tip1Title': 'New orders',
      'tip1Body': 'New bookings from the app appear here right away.',
      'tip2Title': 'Customer contact',
      'tip2Body': 'Use the phone button to call the customer quickly.',
      'tip3Title': 'Status control',
      'tip3Body':
          'Manage upcoming, completed, and cancelled states from this panel.',
      'loginEyebrow': 'Workshop Login',
      'loginSubtitle': 'Choose your workshop and enter the access code.',
      'workshopField': 'Workshop',
      'workshopPlaceholder': 'Select a workshop',
      'accessCodeField': 'Access code',
      'accessCodePlaceholder': 'For example: 0001',
      'loginButton': 'Sign in',
      'loginHelper':
          'If the owner does not know the code yet, it can be seen in the admin workshop card.',
      'loginMissing': 'Choose a workshop and enter the access code',
      'loginInvalid': 'The workshop or access code is incorrect',
      'panelEyebrow': 'Workshop Inbox',
      'panelTitle': 'Workshop orders',
      'panelDescription':
          'Only orders assigned to your workshop are shown in this list.',
      'statusAll': 'All',
      'statusUpcoming': 'Upcoming',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'upcomingHint': 'Fresh orders that need attention.',
      'completedHint': 'Orders that have already been finished.',
      'cancelledHint': 'Orders that were cancelled.',
      'emptyEyebrow': 'No Orders',
      'emptyTitle': 'No orders yet',
      'emptyBody': 'No orders have arrived for this workshop yet.',
      'emptyFilteredBody': 'No orders match the selected status.',
      'orderId': 'Order ID',
      'unknownCustomer': 'Unknown customer',
      'noPhone': 'No phone number',
      'serviceLabel': 'Service',
      'masterLabel': 'Lead mechanic',
      'appointmentLabel': 'Appointment time',
      'priceLabel': 'Price',
      'createdLabel': 'Received at',
      'callCustomer': 'Call customer',
      'statusUpdated': '{id} status changed to {status}',
      'logout': 'Log out',
    },
  };
}
