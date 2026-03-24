import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';

import '../booking_cancellation.dart';
import '../models.dart';
import '../owner_auth.dart';
import '../store.dart';
import '../telegram_bot.dart';
import '../user_notifications.dart';
import '../vehicle_types.dart';
import '../workshop_notifications.dart';

class OwnerController {
  OwnerController(
    this._store, {
    required this.ownerAuthService,
    required this.bookingsFilePath,
    required this.workshopsFilePath,
    required this.reviewsFilePath,
    required this.telegramSyncStateFilePath,
    required this.telegramBotService,
    required this.notificationsService,
    required this.userNotificationsService,
  });

  final InMemoryStore _store;
  final OwnerAuthService ownerAuthService;
  final String bookingsFilePath;
  final String workshopsFilePath;
  final String reviewsFilePath;
  final String telegramSyncStateFilePath;
  final TelegramBotService telegramBotService;
  final WorkshopNotificationsService notificationsService;
  final UserNotificationsService userNotificationsService;
  static final Random _telegramCodeRandom = Random.secure();
  bool _isTelegramSyncRunning = false;

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

  Future<Response> generateTelegramLinkCode(Request request) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? workshop = _ownerWorkshopFromRequest(request);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    final WorkshopModel updated = workshop.copyWith(
      telegramLinkCode: _newTelegramLinkCode(),
    );
    _store.updateWorkshop(workshopId: workshop.id, workshop: updated);
    await _store.saveWorkshops(workshopsFilePath);

    return Response.seeOther(
      _ownerBookingsUri(
        lang: lang,
        status: returnStatus,
        message: _text(
          lang,
          'telegramCodeCreated',
          <String, Object>{'code': updated.telegramLinkCode},
        ),
      ),
    );
  }

  Future<Response> checkTelegramLink(Request request) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? workshop = _ownerWorkshopFromRequest(request);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    if (!telegramBotService.isConfigured) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: _text(lang, 'telegramBotNotConfigured'),
        ),
      );
    }

    try {
      await syncTelegramUpdates();
      final WorkshopModel? refreshedWorkshop = _store.workshopById(workshop.id);
      if (refreshedWorkshop == null) {
        return Response.seeOther(
          _ownerBookingsUri(
            lang: lang,
            status: returnStatus,
            error: _text(lang, 'garageNotFound'),
          ),
        );
      }

      final bool isConnected =
          refreshedWorkshop.telegramChatId.trim().isNotEmpty &&
              refreshedWorkshop.telegramLinkCode.trim().isEmpty;
      if (isConnected) {
        final bool linkedNow = workshop.telegramChatId.trim() !=
                refreshedWorkshop.telegramChatId.trim() ||
            workshop.telegramChatLabel.trim() !=
                refreshedWorkshop.telegramChatLabel.trim() ||
            workshop.telegramLinkCode.trim().isNotEmpty;
        return Response.seeOther(
          _ownerBookingsUri(
            lang: lang,
            status: returnStatus,
            message: _text(
              lang,
              linkedNow ? 'telegramLinkedNow' : 'telegramAlreadyConnected',
              <String, Object>{
                'chat': _telegramConnectedChatLabel(refreshedWorkshop),
              },
            ),
          ),
        );
      }

      if (refreshedWorkshop.telegramLinkCode.trim().isEmpty) {
        return Response.seeOther(
          _ownerBookingsUri(
            lang: lang,
            status: returnStatus,
            error: _text(lang, 'telegramCodeMissing'),
          ),
        );
      }

      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(
            lang,
            'telegramStillWaiting',
            <String, Object>{'code': refreshedWorkshop.telegramLinkCode},
          ),
        ),
      );
    } on TelegramBotException catch (error) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: error.message,
        ),
      );
    } on Exception catch (error) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: error.toString(),
        ),
      );
    }
  }

  Future<Response> disconnectTelegram(Request request) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? workshop = _ownerWorkshopFromRequest(request);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    final WorkshopModel updated = workshop.copyWith(
      telegramChatId: '',
      telegramChatLabel: '',
      telegramLinkCode: '',
    );
    _store.updateWorkshop(workshopId: workshop.id, workshop: updated);
    await _store.saveWorkshops(workshopsFilePath);

    return Response.seeOther(
      _ownerBookingsUri(
        lang: lang,
        status: returnStatus,
        message: _text(lang, 'telegramDisconnected'),
      ),
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
    final String telegramCard = _telegramCardHtml(
      workshop: workshop,
      lang: lang,
      status: status,
    );
    final String servicePricingCard = _servicePricingCardHtml(
      workshop: workshop,
      lang: lang,
      status: status,
    );

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
      <span>${_escapeHtml(_text(lang, 'vehicleLabel'))}</span>
      <strong>${_escapeHtml(_vehicleSummary(item, lang))}</strong>
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
      <span>${_escapeHtml(_text(lang, 'basePriceLabel'))}</span>
      <strong>${_escapeHtml(item.basePrice.toString())}k</strong>
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
	      ${_statusActionsHtml(item, lang, status)}
	    </div>
	  </div>
	  ${item.status == BookingStatus.cancelled ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'cancelledByLabel'))}: <strong>${_escapeHtml(bookingCancellationActorLabel(item.cancelledByRole, lang))}</strong> · ${_escapeHtml(_text(lang, 'cancelReasonLabel'))}: <strong>${_escapeHtml(_cancellationReasonLabel(item, lang))}</strong></div>' : ''}
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

    .summary-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.55fr) minmax(320px, 0.95fr);
      gap: 18px;
      align-items: start;
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

    .pill-link, .ghost-btn, .status-btn, .danger-btn, .cancel-select {
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
    .cancel-form {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      align-items: center;
    }
    .cancel-select {
      min-width: 210px;
      padding-right: 38px;
      color: var(--ink);
      appearance: none;
    }
    .cancel-meta {
      margin-top: 12px;
      padding-top: 12px;
      border-top: 1px dashed var(--line);
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }

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

    .telegram-card {
      padding: 24px;
      display: grid;
      gap: 16px;
    }

    .telegram-card p {
      color: var(--muted);
      line-height: 1.65;
    }

    .service-pricing-card {
      padding: 24px;
      display: grid;
      gap: 16px;
    }

    .service-pricing-card p {
      color: var(--muted);
      line-height: 1.65;
    }

    .service-pricing-note {
      padding: 14px 16px;
      border-radius: 18px;
      background: rgba(36, 49, 63, 0.04);
      border: 1px dashed rgba(36, 49, 63, 0.14);
      color: var(--muted);
      line-height: 1.65;
    }

    .service-pricing-list {
      display: grid;
      gap: 12px;
    }

    .service-pricing-row {
      margin: 0;
      padding: 16px;
      border-radius: 20px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
    }

    .service-pricing-copy {
      display: grid;
      gap: 6px;
    }

    .service-pricing-meta {
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }

    .service-pricing-actions {
      display: flex;
      gap: 12px;
      align-items: end;
      flex-wrap: wrap;
    }

    .service-pricing-field {
      display: grid;
      gap: 6px;
      min-width: 170px;
    }

    .service-pricing-field span {
      color: var(--muted);
      font-size: 13px;
      font-weight: 700;
    }

    .service-pricing-field input {
      min-height: 48px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 14px;
      font-size: 15px;
      background: rgba(255, 255, 255, 0.92);
    }

    .telegram-status {
      padding: 14px 16px;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: grid;
      gap: 6px;
    }

    .telegram-status.ok {
      background: var(--mint-soft);
      border-color: rgba(31, 138, 99, 0.15);
      color: var(--mint);
    }

    .telegram-status.pending {
      background: #fff7df;
      border-color: rgba(155, 107, 0, 0.15);
      color: var(--yellow);
    }

    .telegram-code {
      display: inline-flex;
      width: fit-content;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      border-radius: 999px;
      font-weight: 800;
      letter-spacing: 0.08em;
      background: rgba(36, 49, 63, 0.92);
      color: white;
    }

    .telegram-steps {
      margin: 0;
      padding-left: 18px;
      color: var(--muted);
      line-height: 1.7;
      display: grid;
      gap: 6px;
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

    .chat-preview {
      padding: 14px;
      border-radius: 18px;
      border: 1px solid rgba(88, 67, 40, 0.1);
      background: rgba(255, 247, 238, 0.92);
      display: grid;
      gap: 6px;
    }

    .chat-preview span {
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .booking-footer {
      justify-content: space-between;
    }

    .chat-btn {
      position: relative;
    }

    .chat-badge {
      min-width: 22px;
      height: 22px;
      padding: 0 7px;
      border-radius: 999px;
      background: var(--accent-strong);
      color: white;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 800;
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
      .summary-grid { grid-template-columns: 1fr; }
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

    <section class="summary-grid">
      <div class="hero-card">
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
      </div>

      $telegramCard
    </section>

    ${_flashHtml(message: message, error: error)}

    $servicePricingCard

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

  Future<Response> updateServicePrice(Request request, String serviceId) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final WorkshopModel? workshop = _ownerWorkshopFromRequest(request);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    final ServiceModel? currentService = workshop.getServiceById(serviceId);
    if (currentService == null) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: _text(lang, 'ownerServiceNotFound'),
        ),
      );
    }

    try {
      final int nextPrice = _parseIntField(
        form['price'],
        fieldLabel: _text(
          lang,
          'servicePriceFieldLabel',
          <String, Object>{'service': currentService.name},
        ),
        lang: lang,
        min: 0,
      );

      final List<ServiceModel> updatedServices = workshop.services
          .map((ServiceModel item) => item.id == currentService.id
              ? item.copyWith(price: nextPrice)
              : item)
          .toList(growable: false);
      final WorkshopModel updated =
          workshop.copyWith(services: updatedServices);
      _store.updateWorkshop(workshopId: workshop.id, workshop: updated);
      await _store.saveWorkshops(workshopsFilePath);

      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(
            lang,
            'servicePriceUpdated',
            <String, Object>{
              'service': currentService.name,
              'price': '${nextPrice}k',
            },
          ),
        ),
      );
    } on FormatException catch (error) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: error.message,
        ),
      );
    }
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
    final String cancellationReasonId =
        normalizeBookingCancellationReasonId(form['cancellationReason'] ?? '');

    try {
      final BookingModel updated = nextStatus == BookingStatus.cancelled
          ? _store.cancelWorkshopBooking(
              workshopId: workshopId,
              bookingId: bookingId,
              reasonId: cancellationReasonId,
              actorRole: 'owner_panel',
            )
          : _store.updateWorkshopBookingStatus(
              workshopId: workshopId,
              bookingId: bookingId,
              status: nextStatus,
            );
      await _store.saveBookings(bookingsFilePath);
      await _notifyWorkshopAboutStatusChange(updated);
      await _notifyUserAboutStatusChange(
        updated,
        actor: 'Ustaxona egasi',
      );
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

  Future<void> _notifyWorkshopAboutStatusChange(BookingModel booking) async {
    final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
    if (workshop == null) {
      return;
    }

    try {
      await notificationsService.sendBookingStatusNotification(
        workshop: workshop,
        booking: booking,
        actor: 'Ustaxona egasi',
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram owner status xabari yuborilmadi: $error');
    }
  }

  Future<void> _notifyUserAboutStatusChange(
    BookingModel booking, {
    required String actor,
  }) async {
    final UserModel? user = _store.userById(booking.userId);
    if (user == null) {
      return;
    }

    try {
      await userNotificationsService.sendBookingStatusNotification(
        user: user,
        booking: booking,
        actor: actor,
      );
    } on Exception catch (error) {
      stderr.writeln('Push owner status xabari yuborilmadi: $error');
    }
  }

  WorkshopModel? _ownerWorkshopFromRequest(Request request) {
    final String workshopId =
        ownerAuthService.workshopIdFromRequest(request) ?? '';
    if (workshopId.isEmpty) {
      return null;
    }
    return _store.workshopById(workshopId);
  }

  String _servicePricingCardHtml({
    required WorkshopModel workshop,
    required String lang,
    required String status,
  }) {
    final String hiddenFields = '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
''';

    final String serviceList = workshop.services.isEmpty
        ? '<section class="empty-card"><p>${_escapeHtml(_text(lang, 'servicePricingEmpty'))}</p></section>'
        : workshop.services.map((ServiceModel service) {
            final String durationText = _text(
              lang,
              'serviceDurationMinutes',
              <String, Object>{'minutes': service.durationMinutes},
            );
            final String currentPriceText = _text(
              lang,
              'serviceCurrentPriceLabel',
              <String, Object>{'price': '${service.price}k'},
            );
            return '''
<form class="service-pricing-row" method="post" action="/owner/services/${Uri.encodeComponent(service.id)}/price?lang=${Uri.encodeQueryComponent(lang)}">
  $hiddenFields
  <div class="service-pricing-copy">
    <strong>${_escapeHtml(service.name)}</strong>
    <div class="service-pricing-meta">${_escapeHtml(durationText)} • ${_escapeHtml(currentPriceText)}</div>
  </div>
  <div class="service-pricing-actions">
    <label class="service-pricing-field">
      <span>${_escapeHtml(_text(lang, 'serviceNewPriceLabel'))}</span>
      <input type="number" name="price" min="0" step="1" value="${_escapeHtml(service.price.toString())}" placeholder="${_escapeHtml(_text(lang, 'servicePricePlaceholder'))}">
    </label>
    <button class="status-btn" type="submit">${_escapeHtml(_text(lang, 'servicePriceSave'))}</button>
  </div>
</form>
''';
          }).join();

    return '''
<section class="card service-pricing-card">
  <div>
    <div class="eyebrow">${_escapeHtml(_text(lang, 'servicePricingEyebrow'))}</div>
    <h2>${_escapeHtml(_text(lang, 'servicePricingTitle'))}</h2>
    <p>${_escapeHtml(_text(lang, 'servicePricingDescription'))}</p>
  </div>

  <div class="service-pricing-note">${_escapeHtml(_text(lang, 'servicePricingHint'))}</div>

  <div class="service-pricing-list">
    $serviceList
  </div>
</section>
''';
  }

  String _telegramCardHtml({
    required WorkshopModel workshop,
    required String lang,
    required String status,
  }) {
    final bool botConfigured = telegramBotService.isConfigured;
    final bool connected = workshop.telegramChatId.trim().isNotEmpty;
    final bool hasPendingCode = workshop.telegramLinkCode.trim().isNotEmpty;
    final String chatLabel = _telegramConnectedChatLabel(workshop);
    final String statusClass = connected ? 'ok' : 'pending';
    final String statusTitle = connected
        ? _text(lang, 'telegramConnected')
        : botConfigured
            ? _text(lang, 'telegramPending')
            : _text(lang, 'telegramBotNotConfiguredShort');
    final String statusBody = connected
        ? _text(
            lang,
            'telegramConnectedBody',
            <String, Object>{'chat': chatLabel},
          )
        : botConfigured
            ? _text(lang, 'telegramPendingBody')
            : _text(lang, 'telegramBotNotConfiguredBody');
    final String hiddenFields = '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
''';
    final String pendingCodeHtml = hasPendingCode
        ? '''
<div class="telegram-code">${_escapeHtml(workshop.telegramLinkCode)}</div>
<ol class="telegram-steps">
  <li>${_escapeHtml(_text(lang, 'telegramStepOpenBot'))}</li>
  <li>${_escapeHtml(_text(lang, 'telegramStepSendCode', <String, Object>{
                'code': workshop.telegramLinkCode
              }))}</li>
  <li>${_escapeHtml(_text(lang, 'telegramStepCheck'))}</li>
</ol>
'''
        : '<p>${_escapeHtml(_text(lang, botConfigured ? 'telegramCodeMissingBody' : 'telegramBotNotConfiguredBody'))}</p>';
    final String disconnectButton = connected
        ? '''
<form class="inline-form" method="post" action="/owner/telegram/disconnect?lang=${Uri.encodeQueryComponent(lang)}">
  $hiddenFields
  <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'telegramDisconnect'))}</button>
</form>
'''
        : '';
    final String checkButton = hasPendingCode
        ? '''
<form class="inline-form" method="post" action="/owner/telegram/check?lang=${Uri.encodeQueryComponent(lang)}">
  $hiddenFields
  <button class="ghost-btn" type="submit">${_escapeHtml(_text(lang, 'telegramCheck'))}</button>
</form>
'''
        : '';
    final String generateLabel = hasPendingCode
        ? _text(lang, 'telegramRegenerateCode')
        : _text(lang, 'telegramGenerateCode');

    return '''
<section class="card telegram-card">
  <div>
    <div class="eyebrow">${_escapeHtml(_text(lang, 'telegramEyebrow'))}</div>
    <h2>${_escapeHtml(_text(lang, 'telegramTitle'))}</h2>
    <p>${_escapeHtml(_text(lang, 'telegramDescription'))}</p>
  </div>

  <div class="telegram-status $statusClass">
    <strong>${_escapeHtml(statusTitle)}</strong>
    <span>${_escapeHtml(statusBody)}</span>
  </div>

  $pendingCodeHtml

  <div class="quick-links">
    <form class="inline-form" method="post" action="/owner/telegram/generate?lang=${Uri.encodeQueryComponent(lang)}">
      $hiddenFields
      <button class="status-btn" type="submit">${_escapeHtml(generateLabel)}</button>
    </form>
    $checkButton
    $disconnectButton
  </div>
</section>
''';
  }

  String _telegramConnectedChatLabel(WorkshopModel workshop) {
    if (workshop.telegramChatLabel.trim().isNotEmpty) {
      return workshop.telegramChatLabel.trim();
    }
    if (workshop.telegramChatId.trim().isNotEmpty) {
      return workshop.telegramChatId.trim();
    }
    return workshop.name;
  }

  String _vehicleSummary(BookingModel booking, String lang) {
    final String vehicleType =
        vehicleTypePricingById(booking.vehicleTypeId).label(lang);
    final String vehicleModel = booking.vehicleModel.trim();
    if (vehicleModel.isEmpty) {
      return vehicleType;
    }
    return '$vehicleModel • $vehicleType';
  }

  String _newTelegramLinkCode() {
    final Set<String> existingCodes = _store
        .workshops()
        .map((WorkshopModel item) => item.telegramLinkCode.trim().toUpperCase())
        .where((String item) => item.isNotEmpty)
        .toSet();

    for (int attempt = 0; attempt < 60; attempt++) {
      final String code = 'UT-${100000 + _telegramCodeRandom.nextInt(900000)}';
      if (!existingCodes.contains(code)) {
        return code;
      }
    }

    final int suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'UT-${suffix.toString().padLeft(6, '0')}';
  }

  Future<void> syncTelegramUpdates() async {
    if (!telegramBotService.isConfigured || _isTelegramSyncRunning) {
      return;
    }

    _isTelegramSyncRunning = true;
    try {
      final int nextUpdateId = await _loadTelegramNextUpdateId();
      final List<Map<String, dynamic>> updates =
          await telegramBotService.getUpdates(
        offset: nextUpdateId,
      );
      int nextProcessedUpdateId = nextUpdateId;
      final Map<String, String> workshopIdByCode = <String, String>{};
      for (final WorkshopModel workshop in _store.workshops()) {
        final String code = workshop.telegramLinkCode.trim().toUpperCase();
        if (code.isNotEmpty) {
          workshopIdByCode[code] = workshop.id;
        }
      }
      final List<WorkshopModel> newlyLinked = <WorkshopModel>[];
      bool workshopsChanged = false;
      bool bookingsChanged = false;
      bool reviewsChanged = false;

      for (final Map<String, dynamic> update in updates) {
        final int updateId = _toInt(update['update_id']);
        if (updateId >= nextProcessedUpdateId) {
          nextProcessedUpdateId = updateId + 1;
        }

        final _TelegramIncomingMessage? message =
            _telegramIncomingMessageFromUpdate(update);
        if (message != null) {
          for (final String candidate in _extractTelegramCodes(message.text)) {
            final String? workshopId = workshopIdByCode.remove(candidate);
            if (workshopId == null) {
              continue;
            }

            final WorkshopModel? current = _store.workshopById(workshopId);
            if (current == null) {
              continue;
            }

            final WorkshopModel updated = current.copyWith(
              telegramChatId: message.chatId,
              telegramChatLabel: message.chatLabel,
              telegramLinkCode: '',
            );
            _store.updateWorkshop(workshopId: current.id, workshop: updated);
            workshopsChanged = true;
            newlyLinked.add(updated);
            break;
          }

          final bool handledReviewReply =
              await _handleTelegramReviewReply(message);
          if (handledReviewReply) {
            reviewsChanged = true;
          }
        }

        final _TelegramCallbackAction? callbackAction =
            _telegramCallbackActionFromUpdate(update);
        if (callbackAction == null) {
          continue;
        }

        final bool changed =
            await _handleTelegramCallbackAction(callbackAction);
        if (changed) {
          bookingsChanged = true;
        }
      }

      if (workshopsChanged) {
        await _store.saveWorkshops(workshopsFilePath);
      }
      if (bookingsChanged) {
        await _store.saveBookings(bookingsFilePath);
      }
      if (reviewsChanged) {
        await _store.saveReviews(reviewsFilePath);
      }
      if (nextProcessedUpdateId != nextUpdateId) {
        await _saveTelegramNextUpdateId(nextProcessedUpdateId);
      }

      for (final WorkshopModel workshop in newlyLinked) {
        try {
          await notificationsService.sendTestNotification(workshop: workshop);
        } on Exception catch (error) {
          stderr.writeln('Telegram ulanish test xabari yuborilmadi: $error');
        }
      }
    } finally {
      _isTelegramSyncRunning = false;
    }
  }

  Future<int> _loadTelegramNextUpdateId() async {
    final File file = File(telegramSyncStateFilePath);
    if (!await file.exists()) {
      return 0;
    }

    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return 0;
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return 0;
    }
    return _toInt(decoded['nextUpdateId']);
  }

  Future<void> _saveTelegramNextUpdateId(int nextUpdateId) async {
    final File file = File(telegramSyncStateFilePath);
    await file.parent.create(recursive: true);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      '${encoder.convert(<String, Object>{'nextUpdateId': nextUpdateId})}\n',
    );
  }

  _TelegramIncomingMessage? _telegramIncomingMessageFromUpdate(
    Map<String, dynamic> update,
  ) {
    for (final String key in <String>['message', 'edited_message']) {
      final dynamic rawMessage = update[key];
      if (rawMessage is! Map<String, dynamic>) {
        continue;
      }

      final String text = (rawMessage['text'] ?? '').toString().trim();
      final dynamic rawChat = rawMessage['chat'];
      if (text.isEmpty || rawChat is! Map<String, dynamic>) {
        continue;
      }

      final String chatId = '${rawChat['id'] ?? ''}'.trim();
      if (chatId.isEmpty) {
        continue;
      }

      return _TelegramIncomingMessage(
        chatId: chatId,
        chatLabel: _telegramChatLabelFromChat(rawChat),
        text: text,
        replyToText:
            (rawMessage['reply_to_message'] as Map<String, dynamic>?)?['text']
                    ?.toString() ??
                '',
      );
    }
    return null;
  }

  Iterable<String> _extractTelegramCodes(String rawText) sync* {
    final String normalized = rawText.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }

    final RegExp codePattern = RegExp(r'UT-\d{6}');
    for (final RegExpMatch match in codePattern.allMatches(normalized)) {
      final String? code = match.group(0);
      if (code != null && code.isNotEmpty) {
        yield code;
      }
    }
  }

  String _telegramChatLabelFromChat(Map<String, dynamic> chat) {
    final String username = (chat['username'] ?? '').toString().trim();
    if (username.isNotEmpty) {
      return '@$username';
    }

    final String title = (chat['title'] ?? '').toString().trim();
    if (title.isNotEmpty) {
      return title;
    }

    final String firstName = (chat['first_name'] ?? '').toString().trim();
    final String lastName = (chat['last_name'] ?? '').toString().trim();
    final String fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return '${chat['id'] ?? ''}'.trim();
  }

  Future<bool> _handleTelegramCallbackAction(
    _TelegramCallbackAction action,
  ) async {
    final _TelegramBookingCallback? parsed =
        _parseTelegramBookingCallback(action.data);
    if (parsed == null) {
      await _safeAnswerTelegramCallback(
        action.callbackQueryId,
        'Bu tugma endi faol emas',
      );
      return false;
    }

    final WorkshopModel? workshop = parsed.workshopId.isEmpty
        ? _telegramWorkshopByChatId(action.chatId)
        : _store.workshopById(parsed.workshopId);
    if (workshop == null) {
      await _safeAnswerTelegramCallback(
        action.callbackQueryId,
        'Workshop topilmadi',
      );
      return false;
    }

    if (workshop.telegramChatId.trim() != action.chatId.trim()) {
      await _safeAnswerTelegramCallback(
        action.callbackQueryId,
        'Bu tugma boshqa chat uchun ulangan',
      );
      return false;
    }

    final BookingModel? booking = _workshopBookingById(
      workshopId: workshop.id,
      bookingId: parsed.bookingId,
    );
    if (booking == null) {
      await _safeClearTelegramButtons(action);
      await _safeAnswerTelegramCallback(
        action.callbackQueryId,
        'Zakaz topilmadi',
      );
      return false;
    }

    switch (booking.status) {
      case BookingStatus.completed:
        await _safeClearTelegramButtons(action);
        await _safeAnswerTelegramCallback(
          action.callbackQueryId,
          'Zakaz allaqachon bajarilgan',
        );
        return false;
      case BookingStatus.cancelled:
        await _safeClearTelegramButtons(action);
        await _safeAnswerTelegramCallback(
          action.callbackQueryId,
          'Bu zakaz allaqachon bekor qilingan',
        );
        return false;
      case BookingStatus.upcoming:
        try {
          final BookingModel updated = parsed.kind == 'cancel'
              ? _store.cancelWorkshopBooking(
                  workshopId: workshop.id,
                  bookingId: booking.id,
                  reasonId: parsed.reasonId,
                  actorRole: 'owner_telegram',
                )
              : _store.updateWorkshopBookingStatus(
                  workshopId: workshop.id,
                  bookingId: booking.id,
                  status: BookingStatus.completed,
                );
          await _safeClearTelegramButtons(action);
          await _safeAnswerTelegramCallback(
            action.callbackQueryId,
            parsed.kind == 'cancel'
                ? 'Zakaz bekor qilindi'
                : 'Zakaz bajarildi deb belgilandi',
          );
          try {
            await notificationsService.sendBookingStatusNotification(
              workshop: workshop,
              booking: updated,
              actor: 'Telegram tugmasi',
            );
          } on Exception catch (error) {
            stderr
                .writeln('Telegram callback status xabari yuborilmadi: $error');
          }
          await _notifyUserAboutStatusChange(
            updated,
            actor: 'Telegram bot',
          );
          return true;
        } on StateError catch (error) {
          await _safeAnswerTelegramCallback(
            action.callbackQueryId,
            error.message,
          );
          return false;
        }
    }
  }

  _TelegramCallbackAction? _telegramCallbackActionFromUpdate(
    Map<String, dynamic> update,
  ) {
    final dynamic rawCallback = update['callback_query'];
    if (rawCallback is! Map<String, dynamic>) {
      return null;
    }

    final String callbackQueryId = (rawCallback['id'] ?? '').toString().trim();
    final String data = (rawCallback['data'] ?? '').toString().trim();
    final dynamic rawMessage = rawCallback['message'];
    if (callbackQueryId.isEmpty ||
        data.isEmpty ||
        rawMessage is! Map<String, dynamic>) {
      return null;
    }

    final dynamic rawChat = rawMessage['chat'];
    if (rawChat is! Map<String, dynamic>) {
      return null;
    }

    final String chatId = '${rawChat['id'] ?? ''}'.trim();
    final int messageId = _toInt(rawMessage['message_id']);
    if (chatId.isEmpty || messageId <= 0) {
      return null;
    }

    return _TelegramCallbackAction(
      callbackQueryId: callbackQueryId,
      chatId: chatId,
      messageId: messageId,
      data: data,
    );
  }

  _TelegramBookingCallback? _parseTelegramBookingCallback(String raw) {
    final List<String> parts = raw.trim().split(':');
    if (parts.length == 2 && parts.first == 'd') {
      final String bookingId = parts[1].trim();
      if (bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'done',
        workshopId: '',
        bookingId: bookingId,
      );
    }

    if (parts.length == 3 && parts.first == 'c') {
      final String reasonId =
          _telegramCancellationReasonFromShortCode(parts[1]);
      final String bookingId = parts[2].trim();
      if (reasonId.isEmpty || bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'cancel',
        workshopId: '',
        bookingId: bookingId,
        reasonId: reasonId,
      );
    }

    if (parts.length == 3 && parts.first == 'done') {
      final String workshopId = parts[1].trim();
      final String bookingId = parts[2].trim();
      if (workshopId.isEmpty || bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'done',
        workshopId: workshopId,
        bookingId: bookingId,
      );
    }

    if (parts.length == 4 && parts.first == 'cancel') {
      final String reasonId = normalizeBookingCancellationReasonId(parts[1]);
      final String workshopId = parts[2].trim();
      final String bookingId = parts[3].trim();
      if (reasonId.isEmpty || workshopId.isEmpty || bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'cancel',
        workshopId: workshopId,
        bookingId: bookingId,
        reasonId: reasonId,
      );
    }

    return null;
  }

  String _telegramCancellationReasonFromShortCode(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'wb':
        return 'workshop_busy';
      case 'mu':
        return 'master_unavailable';
      case 'wc':
        return 'workshop_closed';
      case 'mp':
        return 'missing_parts';
      case 'cr':
        return 'customer_request';
    }
    return '';
  }

  BookingModel? _workshopBookingById({
    required String workshopId,
    required String bookingId,
  }) {
    for (final BookingModel item in _store.bookings(workshopId: workshopId)) {
      if (item.id == bookingId) {
        return item;
      }
    }
    return null;
  }

  WorkshopModel? _telegramWorkshopByChatId(String chatId) {
    final String normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) {
      return null;
    }

    for (final WorkshopModel workshop in _store.workshops()) {
      if (workshop.telegramChatId.trim() == normalizedChatId) {
        return workshop;
      }
    }
    return null;
  }

  Future<void> _safeAnswerTelegramCallback(
    String callbackQueryId,
    String text,
  ) async {
    try {
      await telegramBotService.answerCallbackQuery(
        callbackQueryId: callbackQueryId,
        text: text,
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram callback javobi yuborilmadi: $error');
    }
  }

  Future<void> _safeClearTelegramButtons(
    _TelegramCallbackAction action,
  ) async {
    try {
      await telegramBotService.editMessageReplyMarkup(
        chatId: action.chatId,
        messageId: action.messageId,
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram callback tugmasi tozalanmadi: $error');
    }
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  Future<bool> _handleTelegramReviewReply(
    _TelegramIncomingMessage message,
  ) async {
    final String reviewId = _reviewIdFromText(message.replyToText);
    if (reviewId.isEmpty) {
      return false;
    }

    final WorkshopModel? workshop = _telegramWorkshopByChatId(message.chatId);
    if (workshop == null) {
      return false;
    }

    final WorkshopReviewModel? review = _store.reviewById(reviewId);
    if (review == null || review.workshopId != workshop.id) {
      return false;
    }

    try {
      final WorkshopReviewModel updated = _store.replyToWorkshopReview(
        workshopId: workshop.id,
        reviewId: review.id,
        reply: message.text,
        source: 'owner_telegram',
      );
      await _notifyUserAboutReviewReply(
        workshop: workshop,
        review: updated,
      );
      return true;
    } on StateError {
      return false;
    }
  }

  Future<void> _notifyUserAboutReviewReply({
    required WorkshopModel workshop,
    required WorkshopReviewModel review,
  }) async {
    final UserModel? user = _store.userById(review.userId);
    if (user == null) {
      return;
    }

    try {
      await userNotificationsService.sendWorkshopReviewReplyNotification(
        user: user,
        workshop: workshop,
        review: review,
      );
    } on Exception {
      // Push sozlanmagan bo'lsa Telegram javob oqimini to'xtatmaymiz.
    }
  }

  String _reviewIdFromText(String raw) {
    final RegExpMatch? match =
        RegExp(r'Sharh ID:\s*(rv-[A-Za-z0-9\-]+)', caseSensitive: false)
            .firstMatch(raw);
    if (match == null) {
      return '';
    }
    return (match.group(1) ?? '').trim();
  }

  String _statusActionsHtml(
    BookingModel booking,
    String lang,
    String status,
  ) {
    if (booking.status != BookingStatus.upcoming) {
      return '<span class="muted">${_escapeHtml(_text(lang, 'noFurtherActions'))}</span>';
    }

    final String completeForm = _statusActionForm(
      booking,
      BookingStatus.completed,
      lang,
      status,
    );
    final String cancelForm = _cancelActionForm(
      booking: booking,
      lang: lang,
      status: status,
    );
    return '$completeForm$cancelForm';
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

  String _cancelActionForm({
    required BookingModel booking,
    required String lang,
    required String status,
  }) {
    final DateTime now = DateTime.now();
    final bool canCancel = booking.dateTime.isAfter(
      now.add(workshopCancellationLeadTime),
    );
    if (!canCancel) {
      return '<span class="muted">${_escapeHtml(_text(lang, 'cancelGuardHint', <String, Object>{
            'minutes': workshopCancellationLeadTime.inMinutes
          }))}</span>';
    }

    final String options = bookingCancellationReasons
        .where(
            (BookingCancellationReason item) => item.id != 'customer_request')
        .map(
          (BookingCancellationReason item) =>
              '<option value="${_escapeHtml(item.id)}">${_escapeHtml(item.label(lang))}</option>',
        )
        .join();
    return '''
<form class="inline-form cancel-form" method="post" action="/owner/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
  <input type="hidden" name="bookingStatus" value="cancelled">
  <select class="cancel-select" name="cancellationReason" aria-label="${_escapeHtml(_text(lang, 'cancelReasonLabel'))}">
    $options
  </select>
  <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'cancelButton'))}</button>
</form>
''';
  }

  String _cancellationReasonLabel(BookingModel booking, String lang) {
    final String reasonId = booking.cancelReasonId.trim();
    if (reasonId.isEmpty) {
      return _text(lang, 'unknownReason');
    }
    return bookingCancellationReasonById(reasonId).label(lang);
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

  int _parseIntField(
    String? raw, {
    required String fieldLabel,
    required String lang,
    required int min,
  }) {
    final String normalized = (raw ?? '').trim();
    if (normalized.isEmpty) {
      throw FormatException(
        _text(lang, 'requiredField', <String, Object>{'field': fieldLabel}),
      );
    }

    final int? value = int.tryParse(normalized);
    if (value == null) {
      throw FormatException(
        _text(lang, 'invalidNumber', <String, Object>{'field': fieldLabel}),
      );
    }
    if (value < min) {
      throw FormatException(
        _text(
          lang,
          'numberMin',
          <String, Object>{'field': fieldLabel, 'min': min},
        ),
      );
    }
    return value;
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
      'vehicleLabel': 'Mashina',
      'masterLabel': 'Mas’ul usta',
      'appointmentLabel': 'Bron vaqti',
      'priceLabel': 'Narx',
      'basePriceLabel': 'Bazaviy narx',
      'createdLabel': 'Tushgan vaqt',
      'callCustomer': 'Mijozga qo‘ng‘iroq',
      'chatButton': 'Chat',
      'chatPreviewLabel': 'Oxirgi xabar',
      'servicePricingEyebrow': 'Narx boshqaruvi',
      'servicePricingTitle': 'Xizmat narxlarini o‘zingiz belgilang',
      'servicePricingDescription':
          'Quyida faqat shu ustaxonaga tegishli xizmatlar narxini yangilaysiz.',
      'servicePricingHint':
          'Saqlangan narx appdagi keyingi yangilanishda ko‘rinadi va keyingi zakazlar shu bazaviy narx bilan hisoblanadi.',
      'servicePricingEmpty': 'Bu ustaxonaga hali xizmatlar qo‘shilmagan.',
      'serviceDurationMinutes': '{minutes} daqiqa',
      'serviceCurrentPriceLabel': 'Joriy narx: {price}',
      'serviceNewPriceLabel': 'Yangi narx',
      'servicePricePlaceholder': 'Masalan: 150',
      'servicePriceSave': 'Narxni saqlash',
      'servicePriceUpdated': '{service} narxi {price} ga yangilandi',
      'servicePriceFieldLabel': '{service} narxi',
      'ownerServiceNotFound': 'Xizmat topilmadi',
      'requiredField': '{field} majburiy',
      'invalidNumber': '{field} noto‘g‘ri',
      'numberMin': '{field} kamida {min} bo‘lishi kerak',
      'statusUpdated': '{id} statusi {status} ga o‘zgardi',
      'cancelButton': 'Bekor qilish',
      'cancelReasonLabel': 'Bekor qilish sababi',
      'cancelledByLabel': 'Bekor qildi',
      'cancelGuardHint':
          'Bekor qilish faqat bron vaqtigacha kamida {minutes} daqiqa qolganda mumkin.',
      'noFurtherActions': 'Bu zakaz uchun qo‘shimcha amal yo‘q.',
      'unknownReason': 'Ko‘rsatilmagan',
      'logout': 'Chiqish',
      'garageNotFound': 'Workshop topilmadi',
      'telegramEyebrow': 'Telegram Bot',
      'telegramTitle': 'Zakazlarni Telegramga ulang',
      'telegramDescription':
          'Har bir workshop profili o‘z Telegram chatiga faqat o‘z zakazlarini oladi.',
      'telegramConnected': 'Telegram ulangan',
      'telegramPending': 'Telegram hali ulanmagan',
      'telegramConnectedBody': 'Zakaz xabarlari {chat} chatiga yuborilmoqda.',
      'telegramPendingBody':
          'Botga link kod yuborib, keyin shu yerda tekshirishni bosing.',
      'telegramBotNotConfiguredShort': 'Telegram bot o‘chiq',
      'telegramBotNotConfiguredBody':
          'Backendda TELEGRAM_BOT_TOKEN yoqilmagani uchun bot ulanishi hozir ishlamaydi.',
      'telegramStepOpenBot': 'Telegram botni oching.',
      'telegramStepSendCode': 'Botga quyidagi xabarni yuboring: /start {code}',
      'telegramStepCheck': 'Keyin bu sahifada “Tekshirish” tugmasini bosing.',
      'telegramGenerateCode': 'Bog‘lash kodini yaratish',
      'telegramRegenerateCode': 'Yangi kod yaratish',
      'telegramCheck': 'Tekshirish',
      'telegramDisconnect': 'Telegramni uzish',
      'telegramCodeCreated':
          'Bog‘lash kodi yaratildi: {code}. Uni botga yuboring.',
      'telegramLinkedNow':
          'Telegram ulandi. Endi zakazlar {chat} chatiga boradi.',
      'telegramAlreadyConnected': 'Telegram allaqachon ulangan: {chat}.',
      'telegramStillWaiting': 'Botda hali {code} kodi bilan xabar topilmadi.',
      'telegramCodeMissing': 'Avval Telegram bog‘lash kodini yarating.',
      'telegramCodeMissingBody':
          'Pastdagi tugma orqali yangi bog‘lash kodini yarating.',
      'telegramDisconnected': 'Telegram ulanishi uzildi.',
      'telegramBotNotConfigured':
          'Telegram bot token sozlanmagan. Backendni token bilan qayta yoqing.',
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
      'vehicleLabel': 'Машина',
      'masterLabel': 'Ответственный мастер',
      'appointmentLabel': 'Время записи',
      'priceLabel': 'Цена',
      'basePriceLabel': 'Базовая цена',
      'createdLabel': 'Время поступления',
      'callCustomer': 'Позвонить клиенту',
      'chatButton': 'Чат',
      'chatPreviewLabel': 'Последнее сообщение',
      'servicePricingEyebrow': 'Управление ценами',
      'servicePricingTitle': 'Устанавливайте цены на услуги сами',
      'servicePricingDescription':
          'Ниже вы обновляете цены только для услуг своего автосервиса.',
      'servicePricingHint':
          'Сохраненная цена появится в приложении после следующего обновления, а новые заказы будут считаться по этой базовой цене.',
      'servicePricingEmpty': 'Для этого workshop пока не добавлены услуги.',
      'serviceDurationMinutes': '{minutes} мин',
      'serviceCurrentPriceLabel': 'Текущая цена: {price}',
      'serviceNewPriceLabel': 'Новая цена',
      'servicePricePlaceholder': 'Например: 150',
      'servicePriceSave': 'Сохранить цену',
      'servicePriceUpdated': 'Цена услуги {service} обновлена до {price}',
      'servicePriceFieldLabel': 'Цена для {service}',
      'ownerServiceNotFound': 'Услуга не найдена',
      'requiredField': 'Поле {field} обязательно',
      'invalidNumber': 'Поле {field} заполнено неверно',
      'numberMin': 'Поле {field} должно быть не меньше {min}',
      'statusUpdated': 'Статус {id} изменен на {status}',
      'cancelButton': 'Отменить заказ',
      'cancelReasonLabel': 'Причина отмены',
      'cancelledByLabel': 'Кто отменил',
      'cancelGuardHint':
          'Отмена доступна только если до записи осталось не меньше {minutes} минут.',
      'noFurtherActions': 'Для этого заказа больше нет доступных действий.',
      'unknownReason': 'Не указано',
      'logout': 'Выйти',
      'garageNotFound': 'Workshop не найден',
      'telegramEyebrow': 'Telegram Bot',
      'telegramTitle': 'Подключите заказы к Telegram',
      'telegramDescription':
          'Каждый профиль workshop получает в свой Telegram только свои заказы.',
      'telegramConnected': 'Telegram подключен',
      'telegramPending': 'Telegram еще не подключен',
      'telegramConnectedBody':
          'Уведомления о заказах отправляются в чат {chat}.',
      'telegramPendingBody':
          'Отправьте код привязки боту, затем нажмите проверку на этой странице.',
      'telegramBotNotConfiguredShort': 'Telegram bot выключен',
      'telegramBotNotConfiguredBody':
          'Пока не задан TELEGRAM_BOT_TOKEN, подключение бота на backend не работает.',
      'telegramStepOpenBot': 'Откройте Telegram-бота.',
      'telegramStepSendCode':
          'Отправьте боту следующее сообщение: /start {code}',
      'telegramStepCheck': 'Потом нажмите кнопку «Проверить» на этой странице.',
      'telegramGenerateCode': 'Создать код привязки',
      'telegramRegenerateCode': 'Создать новый код',
      'telegramCheck': 'Проверить',
      'telegramDisconnect': 'Отключить Telegram',
      'telegramCodeCreated': 'Код привязки создан: {code}. Отправьте его боту.',
      'telegramLinkedNow':
          'Telegram подключен. Теперь заказы будут приходить в чат {chat}.',
      'telegramAlreadyConnected': 'Telegram уже подключен: {chat}.',
      'telegramStillWaiting': 'Бот пока не получил сообщение с кодом {code}.',
      'telegramCodeMissing': 'Сначала создайте код привязки Telegram.',
      'telegramCodeMissingBody': 'Создайте новый код привязки кнопкой ниже.',
      'telegramDisconnected': 'Подключение Telegram отключено.',
      'telegramBotNotConfigured':
          'Токен Telegram-бота не настроен. Перезапустите backend с токеном.',
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
      'vehicleLabel': 'Vehicle',
      'masterLabel': 'Lead mechanic',
      'appointmentLabel': 'Appointment time',
      'priceLabel': 'Price',
      'basePriceLabel': 'Base price',
      'createdLabel': 'Received at',
      'callCustomer': 'Call customer',
      'chatButton': 'Chat',
      'chatPreviewLabel': 'Latest message',
      'servicePricingEyebrow': 'Price control',
      'servicePricingTitle': 'Set your own service prices',
      'servicePricingDescription':
          'Update prices here only for the services that belong to your workshop.',
      'servicePricingHint':
          'The saved price appears in the app on the next refresh, and new bookings will use that base price immediately.',
      'servicePricingEmpty':
          'No services have been added to this workshop yet.',
      'serviceDurationMinutes': '{minutes} min',
      'serviceCurrentPriceLabel': 'Current price: {price}',
      'serviceNewPriceLabel': 'New price',
      'servicePricePlaceholder': 'For example: 150',
      'servicePriceSave': 'Save price',
      'servicePriceUpdated': '{service} price was updated to {price}',
      'servicePriceFieldLabel': 'Price for {service}',
      'ownerServiceNotFound': 'Service not found',
      'requiredField': '{field} is required',
      'invalidNumber': '{field} must be a valid number',
      'numberMin': '{field} must be at least {min}',
      'statusUpdated': '{id} status changed to {status}',
      'cancelButton': 'Cancel order',
      'cancelReasonLabel': 'Cancellation reason',
      'cancelledByLabel': 'Cancelled by',
      'cancelGuardHint':
          'Cancellation is allowed only when at least {minutes} minutes remain before the appointment.',
      'noFurtherActions': 'No further actions are available for this order.',
      'unknownReason': 'Not specified',
      'logout': 'Log out',
      'garageNotFound': 'Workshop not found',
      'telegramEyebrow': 'Telegram Bot',
      'telegramTitle': 'Connect orders to Telegram',
      'telegramDescription':
          'Each workshop profile receives only its own orders in its own Telegram chat.',
      'telegramConnected': 'Telegram connected',
      'telegramPending': 'Telegram not connected yet',
      'telegramConnectedBody': 'Order notifications are being sent to {chat}.',
      'telegramPendingBody':
          'Send the link code to the bot, then press check on this page.',
      'telegramBotNotConfiguredShort': 'Telegram bot is off',
      'telegramBotNotConfiguredBody':
          'The bot cannot connect until TELEGRAM_BOT_TOKEN is set on the backend.',
      'telegramStepOpenBot': 'Open the Telegram bot.',
      'telegramStepSendCode': 'Send this message to the bot: /start {code}',
      'telegramStepCheck': 'Then press the "Check" button on this page.',
      'telegramGenerateCode': 'Create link code',
      'telegramRegenerateCode': 'Create new code',
      'telegramCheck': 'Check',
      'telegramDisconnect': 'Disconnect Telegram',
      'telegramCodeCreated':
          'A link code was created: {code}. Send it to the bot.',
      'telegramLinkedNow':
          'Telegram connected. Orders will now arrive in {chat}.',
      'telegramAlreadyConnected': 'Telegram is already connected: {chat}.',
      'telegramStillWaiting':
          'The bot has not received a message with code {code} yet.',
      'telegramCodeMissing': 'Create a Telegram link code first.',
      'telegramCodeMissingBody':
          'Create a new link code with the button below.',
      'telegramDisconnected': 'Telegram connection was removed.',
      'telegramBotNotConfigured':
          'Telegram bot token is not configured. Restart the backend with a token.',
    },
  };
}

class _TelegramIncomingMessage {
  const _TelegramIncomingMessage({
    required this.chatId,
    required this.chatLabel,
    required this.text,
    this.replyToText = '',
  });

  final String chatId;
  final String chatLabel;
  final String text;
  final String replyToText;
}

class _TelegramCallbackAction {
  const _TelegramCallbackAction({
    required this.callbackQueryId,
    required this.chatId,
    required this.messageId,
    required this.data,
  });

  final String callbackQueryId;
  final String chatId;
  final int messageId;
  final String data;
}

class _TelegramBookingCallback {
  const _TelegramBookingCallback({
    required this.kind,
    required this.workshopId,
    required this.bookingId,
    this.reasonId = '',
  });

  final String kind;
  final String workshopId;
  final String bookingId;
  final String reasonId;
}
