import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../booking_analytics.dart';
import '../booking_cancellation.dart';
import '../booking_payment_methods.dart';
import '../money.dart';
import '../models.dart';
import '../owner_auth.dart';
import '../review_analytics.dart';
import '../store.dart';
import '../telegram_bot.dart';
import '../user_notifications.dart';
import '../vehicle_catalog.dart';
import '../vehicle_pricing_excel.dart';
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
    final DateTime calendarDate =
        _parseCalendarDate(request.url.queryParameters['date']);
    final List<BookingModel> workshopBookings = _store.bookings(
      workshopId: workshop.id,
    );
    final List<BookingModel> bookings = _store.bookings(
      workshopId: workshop.id,
      status: status == 'all' ? null : _statusFromRaw(status),
    );
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final int upcomingCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.upcoming)
        .length;
    final int acceptedCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.accepted)
        .length;
    final int completedCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.completed)
        .length;
    final int cancelledCount = _store
        .bookings(workshopId: workshop.id, status: BookingStatus.cancelled)
        .length;
    final List<BookingModel> analyticsBookings =
        status == 'all' ? workshopBookings : bookings;
    final BookingAnalyticsSummary bookingAnalytics =
        buildBookingAnalytics(analyticsBookings);
    final List<WorkshopReviewModel> reviews = _store
        .reviewsForWorkshop(workshopId: workshop.id)
        .toList(growable: false)
      ..sort((WorkshopReviewModel a, WorkshopReviewModel b) {
        if (a.hasOwnerReply == b.hasOwnerReply) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return a.hasOwnerReply ? 1 : -1;
      });
    final int pendingReviewCount =
        reviews.where((WorkshopReviewModel item) => !item.hasOwnerReply).length;
    final int repliedReviewCount = reviews.length - pendingReviewCount;
    final ReviewAnalyticsSummary reviewAnalytics = buildReviewAnalytics(
      reviews,
      segmentIdOf: (WorkshopReviewModel review) => review.serviceId,
      segmentLabelOf: (WorkshopReviewModel review) {
        final ServiceModel? service = workshop.getServiceById(review.serviceId);
        return service?.name ?? review.serviceName;
      },
    );

    final Uri langUzUri =
        _ownerBookingsUri(lang: 'uz', status: status, date: calendarDate);
    final Uri langRuUri =
        _ownerBookingsUri(lang: 'ru', status: status, date: calendarDate);
    final Uri langEnUri =
        _ownerBookingsUri(lang: 'en', status: status, date: calendarDate);
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
    final String vehiclePricingCard = _vehiclePricingCardHtml(
      workshop: workshop,
      lang: lang,
      status: status,
    );
    final String scheduleCard = _scheduleCardHtml(
      workshop: workshop,
      lang: lang,
      status: status,
    );
    final String reviewInboxCard = _reviewInboxCardHtml(
      workshop: workshop,
      reviews: reviews,
      analytics: reviewAnalytics,
      pendingReviewCount: pendingReviewCount,
      repliedReviewCount: repliedReviewCount,
      lang: lang,
      status: status,
    );
    final String calendarSection = _calendarSectionHtml(
      workshop: workshop,
      bookings: bookings,
      lang: lang,
      status: status,
      selectedDate: calendarDate,
    );
    final String bookingAnalyticsSection = _bookingAnalyticsSectionHtml(
      analytics: bookingAnalytics,
      lang: lang,
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
            final String statusClass = _statusClass(item.status);
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
      <strong>${_escapeHtml(formatMoneyUzs(item.price))}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'basePriceLabel'))}</span>
      <strong>${_escapeHtml(formatMoneyUzs(item.basePrice))}</strong>
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
	  ${item.status == BookingStatus.rescheduled && item.previousDateTime != null ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'rescheduledFromLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.previousDateTime!))}</strong>${item.rescheduledByRole.isNotEmpty ? ' · ${_escapeHtml(_text(lang, 'rescheduledByLabel'))}: <strong>${_escapeHtml(bookingRescheduleActorLabel(item.rescheduledByRole, lang))}</strong>' : ''}${item.rescheduledAt != null ? ' · ${_escapeHtml(_text(lang, 'rescheduledAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.rescheduledAt!))}</strong>' : ''}</div>' : ''}
	  ${item.status == BookingStatus.completed && item.completedAt != null ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'completedAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.completedAt!))}</strong></div>' : ''}
	  <div class="cancel-meta">${_escapeHtml(_text(lang, 'paymentStatusLabel'))}: <strong>${_escapeHtml(_paymentStatusLabel(item.paymentStatus, lang))}</strong>${item.prepaymentAmount > 0 ? ' · ${_escapeHtml(_text(lang, 'prepaymentLabel'))}: <strong>${_escapeHtml(formatMoneyUzs(item.prepaymentAmount))}</strong> · ${_escapeHtml(_text(lang, 'remainingPaymentLabel'))}: <strong>${_escapeHtml(formatMoneyUzs(item.remainingAmount))}</strong>' : ''}${item.paymentMethod.trim().isNotEmpty ? ' · ${_escapeHtml(_text(lang, 'paymentMethodLabel'))}: <strong>${_escapeHtml(bookingPaymentMethodLabel(item.paymentMethod, lang: lang))}</strong>' : ''}</div>
	  ${item.status == BookingStatus.cancelled ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'cancelledByLabel'))}: <strong>${_escapeHtml(bookingCancellationActorLabel(item.cancelledByRole, lang))}</strong>${item.cancelledAt != null ? ' · ${_escapeHtml(_text(lang, 'cancelledAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.cancelledAt!))}</strong>' : ''} · ${_escapeHtml(_text(lang, 'cancelReasonLabel'))}: <strong>${_escapeHtml(_cancellationReasonLabel(item, lang))}</strong></div>' : ''}
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
      grid-template-columns: repeat(4, minmax(0, 1fr));
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

    .calendar-card {
      padding: 24px;
      display: grid;
      gap: 16px;
    }

    .calendar-card p {
      color: var(--muted);
      line-height: 1.65;
    }

    .calendar-strip {
      display: grid;
      grid-template-columns: repeat(7, minmax(0, 1fr));
      gap: 10px;
    }

    .calendar-day {
      padding: 14px;
      border-radius: 20px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.7);
      display: grid;
      gap: 6px;
      min-height: 128px;
      color: inherit;
      text-decoration: none;
    }

    .calendar-day.active {
      border-color: rgba(191, 91, 33, 0.35);
      box-shadow: inset 0 0 0 1px rgba(191, 91, 33, 0.15);
      background: rgba(255, 246, 236, 0.92);
    }

    .calendar-day.closed {
      background: rgba(246, 240, 234, 0.92);
    }

    .calendar-day .mini {
      font-size: 12px;
      color: var(--muted);
      line-height: 1.5;
    }

    .calendar-tag {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border-radius: 999px;
      padding: 6px 10px;
      font-size: 12px;
      font-weight: 700;
      width: fit-content;
      background: rgba(36, 49, 63, 0.08);
      color: var(--ink);
    }

    .calendar-tag.closed {
      background: var(--yellow-soft);
      color: var(--yellow);
    }

    .calendar-tag.busy {
      background: var(--red-soft);
      color: var(--red);
    }

    .agenda-list {
      display: grid;
      gap: 10px;
    }

    .agenda-item {
      padding: 14px 16px;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: grid;
      gap: 6px;
    }

    .agenda-top {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      flex-wrap: wrap;
    }

    .agenda-meta {
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
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

    .review-card {
      padding: 24px;
      display: grid;
      gap: 16px;
    }

    .review-card p {
      color: var(--muted);
      line-height: 1.65;
    }

    .review-stat-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
    }

    .review-analytics-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.15fr) minmax(260px, 0.85fr);
      gap: 12px;
    }

    .review-analytics-card {
      padding: 16px;
      border-radius: 20px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: grid;
      gap: 12px;
    }

    .review-analytics-row {
      display: grid;
      grid-template-columns: 84px minmax(0, 1fr) 34px;
      gap: 10px;
      align-items: center;
    }

    .review-analytics-bar {
      height: 10px;
      border-radius: 999px;
      background: rgba(36, 49, 63, 0.08);
      overflow: hidden;
    }

    .review-analytics-fill {
      height: 100%;
      border-radius: inherit;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
    }

    .review-analytics-list {
      display: grid;
      gap: 10px;
    }

    .review-analytics-item {
      padding: 12px 14px;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.7);
      display: grid;
      gap: 6px;
    }

    .review-analytics-meta {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      color: var(--muted);
      font-size: 13px;
    }

    .review-list {
      display: grid;
      gap: 12px;
    }

    .review-item {
      padding: 16px;
      border-radius: 20px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      display: grid;
      gap: 12px;
    }

    .review-item.pending-review {
      border-color: rgba(191, 91, 33, 0.18);
      background: rgba(255, 248, 241, 0.92);
    }

    .review-head {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: start;
      flex-wrap: wrap;
    }

    .review-copy {
      display: grid;
      gap: 6px;
    }

    .review-title-row {
      display: flex;
      gap: 8px;
      align-items: center;
      flex-wrap: wrap;
    }

    .review-badge {
      padding: 7px 10px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 800;
      letter-spacing: 0.04em;
    }

    .review-badge.pending {
      color: var(--yellow);
      background: var(--yellow-soft);
    }

    .review-badge.answered {
      color: var(--mint);
      background: var(--mint-soft);
    }

    .review-meta {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }

    .review-stars {
      letter-spacing: 0.08em;
      color: var(--accent-strong);
      font-weight: 800;
    }

    .review-comment {
      line-height: 1.7;
      color: var(--ink);
      white-space: pre-wrap;
    }

    .review-reply-box {
      padding: 14px;
      border-radius: 18px;
      border: 1px solid rgba(31, 138, 99, 0.14);
      background: rgba(232, 247, 240, 0.9);
      display: grid;
      gap: 8px;
    }

    .review-reply-box strong {
      color: var(--mint);
    }

    .review-reply-meta {
      color: var(--muted);
      font-size: 13px;
    }

    .review-reply-form {
      display: grid;
      gap: 10px;
      margin: 0;
    }

    .review-reply-form textarea {
      width: 100%;
      min-height: 108px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 14px;
      font: inherit;
      resize: vertical;
      background: rgba(255, 255, 255, 0.94);
    }

    .service-pricing-note {
      padding: 14px 16px;
      border-radius: 18px;
      background: rgba(36, 49, 63, 0.04);
      border: 1px dashed rgba(36, 49, 63, 0.14);
      color: var(--muted);
      line-height: 1.65;
    }

    .service-toolbar {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: center;
      flex-wrap: wrap;
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

    .schedule-summary-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
    }

    .schedule-form {
      display: grid;
      gap: 14px;
      margin: 0;
    }

    .schedule-fields {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 12px;
    }

    .schedule-days {
      display: grid;
      gap: 8px;
      color: var(--muted);
      font-size: 13px;
      font-weight: 700;
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
      background: rgba(255, 255, 255, 0.78);
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

    .status-accepted {
      color: var(--mint);
      background: var(--mint-soft);
    }

    .status-rescheduled {
      color: var(--accent-strong);
      background: rgba(255, 230, 214, 0.95);
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
      .stats-grid, .meta-grid, .review-stat-grid, .review-analytics-grid,
      .schedule-summary-grid, .schedule-fields, .calendar-strip {
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
          <div class="brand-title">${_escapeHtml(workshop.name)}</div>
        </div>
      </div>
      <div class="top-actions">
        <a class="pill-link${status == 'all' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, date: calendarDate).toString())}">${_escapeHtml(_text(lang, 'statusAll'))}</a>
        <a class="pill-link${status == 'upcoming' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'upcoming', date: calendarDate).toString())}">${_escapeHtml(_text(lang, 'statusUpcoming'))}</a>
        <a class="pill-link${status == 'accepted' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'accepted', date: calendarDate).toString())}">${_escapeHtml(_text(lang, 'statusAccepted'))}</a>
        <a class="pill-link${status == 'completed' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'completed', date: calendarDate).toString())}">${_escapeHtml(_text(lang, 'statusCompleted'))}</a>
        <a class="pill-link${status == 'cancelled' ? ' active' : ''}" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: 'cancelled', date: calendarDate).toString())}">${_escapeHtml(_text(lang, 'statusCancelled'))}</a>
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
            <div class="eyebrow">${_escapeHtml(_text(lang, 'statusAccepted'))}</div>
            <strong>$acceptedCount</strong>
            <div class="muted">${_escapeHtml(_text(lang, 'acceptedHint'))}</div>
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

    $calendarSection
    $bookingAnalyticsSection
    $servicePricingCard
    $vehiclePricingCard
    $scheduleCard
    $reviewInboxCard

    <section class="booking-list">
      $bookingCards
    </section>
  </div>
  <script>
    (function () {
      function bindPricingUploadRoot(root) {
        var fileInput = root.querySelector('[data-pricing-file]');
        var base64Input = root.querySelector('[data-pricing-base64]');
        var nameInput = root.querySelector('[data-pricing-name]');
        var label = root.querySelector('[data-pricing-file-name]');
        if (!fileInput || !base64Input || !nameInput || !label || !window.FileReader) {
          return;
        }

        fileInput.addEventListener('change', function () {
          var file = fileInput.files && fileInput.files[0];
          if (!file) {
            base64Input.value = '';
            nameInput.value = '';
            label.textContent = '${_escapeHtml(_text(lang, 'pricingWorkbookWaiting'))}';
            return;
          }

          var reader = new FileReader();
          reader.onload = function (event) {
            var result = String(event.target && event.target.result || '');
            var commaIndex = result.indexOf(',');
            base64Input.value = commaIndex >= 0 ? result.slice(commaIndex + 1) : result;
            nameInput.value = file.name || '';
            label.textContent = file.name || '${_escapeHtml(_text(lang, 'pricingWorkbookWaiting'))}';
          };
          reader.onerror = function () {
            base64Input.value = '';
            nameInput.value = '';
            label.textContent = '${_escapeHtml(_text(lang, 'pricingWorkbookInvalid'))}';
          };
          reader.readAsDataURL(file);
        });
      }

      document.querySelectorAll('[data-pricing-upload-root]').forEach(bindPricingUploadRoot);
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
      final int nextPrice = _parsePriceField(
        form['price'],
        fieldLabel: _text(
          lang,
          'servicePriceFieldLabel',
          <String, Object>{'service': currentService.name},
        ),
        lang: lang,
        min: 0,
      );
      final int nextDurationMinutes = _parseIntField(
        form['durationMinutes'],
        fieldLabel: _text(
          lang,
          'serviceDurationFieldLabel',
          <String, Object>{'service': currentService.name},
        ),
        lang: lang,
        min: 1,
      );
      final int nextPrepaymentPercent = _parseIntField(
        form['prepaymentPercent'],
        fieldLabel: _text(
          lang,
          'servicePrepaymentFieldLabel',
          <String, Object>{'service': currentService.name},
        ),
        lang: lang,
        min: 0,
      ).clamp(0, 100);

      final List<ServiceModel> updatedServices = workshop.services
          .map((ServiceModel item) => item.id == currentService.id
              ? item.copyWith(
                  price: nextPrice,
                  durationMinutes: nextDurationMinutes,
                  prepaymentPercent: nextPrepaymentPercent,
                )
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
            'serviceSettingsUpdated',
            <String, Object>{
              'service': currentService.name,
              'price': formatMoneyUzs(nextPrice),
              'duration': '$nextDurationMinutes',
              'prepayment': '$nextPrepaymentPercent',
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

  Response downloadVehiclePricingTemplate(Request request) {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final WorkshopModel? workshop = _ownerWorkshopFromRequest(request);
    if (workshop == null) {
      return Response.seeOther(_ownerLoginUri(lang: lang));
    }

    final List<int> bytes = buildWorkshopVehiclePricingWorkbook(workshop);
    return Response.ok(
      bytes,
      headers: <String, String>{
        'content-type':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'content-disposition':
            'attachment; filename="${_pricingTemplateFilename(workshop)}"',
      },
    );
  }

  Future<Response> importVehiclePricing(Request request) async {
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

    try {
      final List<VehiclePriceRuleModel> rules =
          parseWorkshopVehiclePricingWorkbook(
        bytes: Uint8List.fromList(
          _decodePricingWorkbookBase64(form, lang: lang),
        ),
        workshop: workshop,
      );
      _store.updateWorkshop(
        workshopId: workshop.id,
        workshop: workshop.copyWith(
          vehiclePricingRules: rules,
        ),
      );
      await _store.saveWorkshops(workshopsFilePath);
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(
            lang,
            'pricingImportSuccess',
            <String, Object>{'count': rules.length},
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
    } on UnsupportedError catch (error) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: error.message,
        ),
      );
    }
  }

  Future<Response> updateSchedule(Request request) async {
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

    try {
      final WorkshopScheduleModel schedule = _parseWorkshopSchedule(
        form,
        lang: lang,
        fallback: workshop.schedule,
      );
      final WorkshopModel updated = workshop.copyWith(schedule: schedule);
      _store.updateWorkshop(workshopId: workshop.id, workshop: updated);
      await _store.saveWorkshops(workshopsFilePath);

      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(lang, 'scheduleSaved'),
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

  Future<Response> replyReview(Request request, String reviewId) async {
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

    try {
      final WorkshopReviewModel updated = _store.replyToWorkshopReview(
        workshopId: workshop.id,
        reviewId: reviewId,
        reply: form['reply'] ?? '',
        source: 'owner_panel',
      );
      await _store.saveReviews(reviewsFilePath);
      await _notifyUserAboutReviewReply(
        workshop: workshop,
        review: updated,
      );
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          message: _text(
            lang,
            'reviewReplySaved',
            <String, Object>{'service': updated.serviceName},
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
    final DateTime? scheduledAt = nextStatus == BookingStatus.rescheduled
        ? _parseDateTimeLocalField(form['scheduledAt'])
        : null;

    try {
      final BookingModel updated = nextStatus == BookingStatus.cancelled
          ? _store.cancelWorkshopBooking(
              workshopId: workshopId,
              bookingId: bookingId,
              reasonId: cancellationReasonId,
              actorRole: 'owner_panel',
            )
          : nextStatus == BookingStatus.rescheduled
              ? _store.rescheduleWorkshopBooking(
                  workshopId: workshopId,
                  bookingId: bookingId,
                  dateTime: scheduledAt ??
                      (throw StateError(_text(lang, 'rescheduleDateRequired'))),
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
              <String, Object>{'price': formatMoneyUzs(service.price)},
            );
            final String currentPrepaymentText = _text(
              lang,
              'serviceCurrentPrepaymentLabel',
              <String, Object>{'percent': service.prepaymentPercent},
            );
            return '''
<form class="service-pricing-row" method="post" action="/owner/services/${Uri.encodeComponent(service.id)}/price?lang=${Uri.encodeQueryComponent(lang)}">
  $hiddenFields
  <div class="service-pricing-copy">
    <strong>${_escapeHtml(service.name)}</strong>
    <div class="service-pricing-meta">${_escapeHtml(durationText)} • ${_escapeHtml(currentPriceText)} • ${_escapeHtml(currentPrepaymentText)}</div>
  </div>
  <div class="service-pricing-actions">
    <label class="service-pricing-field">
      <span>${_escapeHtml(_text(lang, 'serviceNewPriceLabel'))}</span>
      <input type="number" name="price" min="0" step="1000" value="${_escapeHtml(moneyInputValue(service.price))}" placeholder="${_escapeHtml(_text(lang, 'servicePricePlaceholder'))}">
    </label>
    <label class="service-pricing-field">
      <span>${_escapeHtml(_text(lang, 'serviceNewDurationLabel'))}</span>
      <input type="number" name="durationMinutes" min="1" step="1" value="${_escapeHtml(service.durationMinutes.toString())}" placeholder="${_escapeHtml(_text(lang, 'serviceDurationPlaceholder'))}">
    </label>
    <label class="service-pricing-field">
      <span>${_escapeHtml(_text(lang, 'serviceNewPrepaymentLabel'))}</span>
      <input type="number" name="prepaymentPercent" min="0" max="100" step="1" value="${_escapeHtml(service.prepaymentPercent.toString())}" placeholder="${_escapeHtml(_text(lang, 'servicePrepaymentPlaceholder'))}">
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

  String _vehiclePricingCardHtml({
    required WorkshopModel workshop,
    required String lang,
    required String status,
  }) {
    final String hiddenFields = '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
''';
    final Uri templateUri = Uri(
      path: '/owner/vehicle-pricing/template.xlsx',
      queryParameters: <String, String>{'lang': lang},
    );
    final String configuredCount = '${workshop.vehiclePricingRules.length}';
    final String templateRows =
        '${workshop.services.length * sortedVehicleCatalogEntries().length}';

    return '''
<section class="card service-pricing-card" data-pricing-upload-root>
  <div class="service-toolbar">
    <div>
      <div class="eyebrow">${_escapeHtml(_text(lang, 'pricingMatrixTitle'))}</div>
      <h2>${_escapeHtml(_text(lang, 'pricingMatrixTitle'))}</h2>
      <p>${_escapeHtml(_text(lang, 'pricingMatrixDescription'))}</p>
    </div>
    <a class="ghost-btn" href="${_escapeHtml(templateUri.toString())}">${_escapeHtml(_text(lang, 'pricingTemplateDownload'))}</a>
  </div>

  <div class="schedule-summary-grid">
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'pricingConfiguredCount'))}</div>
      <strong>$configuredCount</strong>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'pricingTemplateRows'))}</div>
      <strong>$templateRows</strong>
    </div>
  </div>

  <form class="schedule-form" method="post" action="/owner/vehicle-pricing/import?lang=${Uri.encodeQueryComponent(lang)}">
    $hiddenFields
    <input type="hidden" name="pricingWorkbookBase64" data-pricing-base64>
    <input type="hidden" name="pricingWorkbookName" data-pricing-name>
    <div class="field">
      <label>${_escapeHtml(_text(lang, 'pricingWorkbookField'))}</label>
      <input type="file" accept=".xlsx" data-pricing-file>
    </div>
    <div class="muted" data-pricing-file-name>${_escapeHtml(_text(lang, 'pricingWorkbookWaiting'))}</div>
    <div class="service-pricing-actions">
      <button class="status-btn" type="submit">${_escapeHtml(_text(lang, 'pricingTemplateUpload'))}</button>
    </div>
  </form>

  <div class="service-pricing-note">${_escapeHtml(_text(lang, 'pricingMatrixHint'))}</div>
</section>
''';
  }

  String _scheduleCardHtml({
    required WorkshopModel workshop,
    required String lang,
    required String status,
  }) {
    final String hiddenFields = '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
''';

    return '''
<section class="card service-pricing-card">
  <div>
    <div class="eyebrow">${_escapeHtml(_text(lang, 'scheduleEyebrow'))}</div>
    <h2>${_escapeHtml(_text(lang, 'scheduleTitle'))}</h2>
    <p>${_escapeHtml(_text(lang, 'scheduleDescription'))}</p>
  </div>

  <div class="schedule-summary-grid">
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'infoWorkingHours'))}</div>
      <strong>${_escapeHtml(_scheduleSummary(workshop.schedule))}</strong>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'infoBreakTime'))}</div>
      <strong>${_escapeHtml(_breakSummary(workshop.schedule, lang))}</strong>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'infoDaysOff'))}</div>
      <strong>${_escapeHtml(_daysOffSummary(workshop.schedule, lang))}</strong>
    </div>
  </div>

  <div class="service-pricing-note">${_escapeHtml(_text(lang, 'scheduleHint'))}</div>

  <form class="schedule-form" method="post" action="/owner/schedule?lang=${Uri.encodeQueryComponent(lang)}">
    $hiddenFields
    <div class="schedule-fields">
      <label class="service-pricing-field">
        <span>${_escapeHtml(_text(lang, 'fieldOpeningTime'))}</span>
        <input type="time" name="openingTime" value="${_escapeHtml(workshop.schedule.openingTime)}">
      </label>
      <label class="service-pricing-field">
        <span>${_escapeHtml(_text(lang, 'fieldClosingTime'))}</span>
        <input type="time" name="closingTime" value="${_escapeHtml(workshop.schedule.closingTime)}">
      </label>
      <label class="service-pricing-field">
        <span>${_escapeHtml(_text(lang, 'fieldBreakStart'))}</span>
        <input type="time" name="breakStartTime" value="${_escapeHtml(workshop.schedule.breakStartTime)}">
      </label>
      <label class="service-pricing-field">
        <span>${_escapeHtml(_text(lang, 'fieldBreakEnd'))}</span>
        <input type="time" name="breakEndTime" value="${_escapeHtml(workshop.schedule.breakEndTime)}">
      </label>
    </div>

    <div class="schedule-days">
      <span>${_escapeHtml(_text(lang, 'fieldClosedWeekdays'))}</span>
      <div class="checkbox-pills">
        ${_weekdayCheckboxesHtml(lang, workshop.schedule.closedWeekdays)}
      </div>
    </div>

    <div class="quick-links">
      <button class="status-btn" type="submit">${_escapeHtml(_text(lang, 'scheduleSave'))}</button>
    </div>
  </form>
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

  String _pricingTemplateFilename(WorkshopModel workshop) {
    final String slug = workshop.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final String safeSlug = slug.isEmpty ? workshop.id : slug;
    return 'usta_top_vehicle_pricing_$safeSlug.xlsx';
  }

  List<int> _decodePricingWorkbookBase64(
    Map<String, String> form, {
    required String lang,
  }) {
    final String encoded = (form['pricingWorkbookBase64'] ?? '').trim();
    if (encoded.isEmpty) {
      throw FormatException(_text(lang, 'pricingWorkbookRequired'));
    }

    try {
      return base64Decode(encoded);
    } on FormatException {
      throw FormatException(_text(lang, 'pricingWorkbookInvalid'));
    }
  }

  String _weekdayCheckboxesHtml(String lang, List<int> selectedDays) {
    return List<String>.generate(7, (int index) {
      final int weekday = index + 1;
      final bool selected = selectedDays.contains(weekday);
      return '''
<label class="checkbox-pill">
  <input type="checkbox" name="closedWeekdays" value="$weekday"${selected ? ' checked' : ''}>
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

  String _calendarSectionHtml({
    required WorkshopModel workshop,
    required List<BookingModel> bookings,
    required String lang,
    required String status,
    required DateTime selectedDate,
  }) {
    final DateTime startDate = _normalizeDate(DateTime.now());
    final List<String> dayCards = <String>[];
    for (int offset = 0; offset < 14; offset++) {
      final DateTime date = startDate.add(Duration(days: offset));
      final List<BookingModel> dayBookings = bookings
          .where((BookingModel item) {
        return _sameDate(item.dateTime.toLocal(), date);
      }).toList(growable: false)
        ..sort(
          (BookingModel a, BookingModel b) => a.dateTime.compareTo(b.dateTime),
        );
      final bool isClosedDay =
          workshop.schedule.closedWeekdays.contains(date.weekday);
      final String tagClass = isClosedDay
          ? 'closed'
          : dayBookings.isEmpty
              ? ''
              : 'busy';
      final String tagLabel = isClosedDay
          ? _text(lang, 'calendarClosedLabel')
          : dayBookings.isEmpty
              ? _text(lang, 'calendarOpenLabel')
              : _text(
                  lang,
                  'calendarBookingsCount',
                  <String, Object>{'count': dayBookings.length},
                );
      final String detail = dayBookings.isEmpty
          ? _text(lang, 'calendarNoAppointments')
          : _text(
              lang,
              'calendarFirstAppointment',
              <String, Object>{
                'time': _formatClock(dayBookings.first.dateTime)
              },
            );
      final Uri dayUri = _ownerBookingsUri(
        lang: lang,
        status: status,
        date: date,
      );
      dayCards.add('''
<a class="calendar-day${_sameDate(date, selectedDate) ? ' active' : ''}${isClosedDay ? ' closed' : ''}" href="${_escapeHtml(dayUri.toString())}">
  <div class="eyebrow">${_escapeHtml(_weekdayShortLabel(lang, date.weekday))}</div>
  <strong>${_escapeHtml(_formatShortDate(date))}</strong>
  <span class="calendar-tag $tagClass">${_escapeHtml(tagLabel)}</span>
  <div class="mini">${_escapeHtml(detail)}</div>
</a>
''');
    }

    final List<BookingModel> selectedDayBookings = bookings.where(
      (BookingModel item) {
        return _sameDate(item.dateTime.toLocal(), selectedDate);
      },
    ).toList(growable: false)
      ..sort(
        (BookingModel a, BookingModel b) => a.dateTime.compareTo(b.dateTime),
      );
    final String agendaHtml = selectedDayBookings.isEmpty
        ? '''
<section class="empty-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarSelectedEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'calendarEmptyTitle'))}</h3>
  <p>${_escapeHtml(_text(lang, 'calendarEmptyBody'))}</p>
</section>
'''
        : selectedDayBookings.map((BookingModel item) {
            return '''
<article class="agenda-item">
  <div class="agenda-top">
    <strong>${_escapeHtml(_formatClock(item.dateTime))} • ${_escapeHtml(item.customerName.isEmpty ? _text(lang, 'unknownCustomer') : item.customerName)}</strong>
    <span class="status-pill ${_statusClass(item.status)}">${_escapeHtml(_statusLabel(item.status, lang))}</span>
  </div>
  <div class="agenda-meta">
    ${_escapeHtml(item.serviceName)} • ${_escapeHtml(_vehicleSummary(item, lang))}<br>
    ${_escapeHtml(_text(lang, 'priceLabel'))}: ${_escapeHtml(formatMoneyUzs(item.price))}
  </div>
</article>
''';
          }).join();

    return '''
<section class="card calendar-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarEyebrow'))}</div>
  <h2>${_escapeHtml(_text(lang, 'calendarTitle'))}</h2>
  <p>${_escapeHtml(_text(lang, 'calendarDescription'))}</p>
  <div class="calendar-strip">${dayCards.join()}</div>
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarSelectedEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'calendarSelectedTitle', <String, Object>{
          'date': _formatShortDate(selectedDate)
        }))}</h3>
  <div class="agenda-list">$agendaHtml</div>
</section>
''';
  }

  DateTime _parseCalendarDate(String? raw) {
    final DateTime? parsed = DateTime.tryParse((raw ?? '').trim());
    return _normalizeDate(parsed ?? DateTime.now());
  }

  DateTime _normalizeDate(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    final DateTime left = _normalizeDate(a);
    final DateTime right = _normalizeDate(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _formatShortDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$day ${months[local.month - 1]}';
  }

  String _formatClock(DateTime value) {
    final DateTime local = value.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _reviewInboxCardHtml({
    required WorkshopModel workshop,
    required List<WorkshopReviewModel> reviews,
    required ReviewAnalyticsSummary analytics,
    required int pendingReviewCount,
    required int repliedReviewCount,
    required String lang,
    required String status,
  }) {
    final String hiddenFields = '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
<input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
''';

    final String reviewItems = reviews.isEmpty
        ? '<section class="empty-card"><p>${_escapeHtml(_text(lang, 'reviewEmptyBody'))}</p></section>'
        : reviews.map((WorkshopReviewModel review) {
            final bool hasReply = review.hasOwnerReply;
            final String customerLabel = review.customerName.trim().isEmpty
                ? _text(lang, 'unknownCustomer')
                : review.customerName;
            final String phoneLabel = review.customerPhone.trim().isEmpty
                ? _text(lang, 'noPhone')
                : review.customerPhone;
            final String sourceLabel = hasReply
                ? _reviewReplySourceLabel(review.ownerReplySource, lang)
                : '';
            final String replyMeta = review.ownerReplyAt == null
                ? sourceLabel
                : '$sourceLabel • ${_formatDateTime(review.ownerReplyAt!)}';
            final String replyBox = hasReply
                ? '''
<div class="review-reply-box">
  <strong>${_escapeHtml(_text(lang, 'reviewReplyLabel'))}</strong>
  <div class="review-comment">${_escapeHtml(review.ownerReply)}</div>
  <div class="review-reply-meta">${_escapeHtml(replyMeta)}</div>
</div>
'''
                : '';
            return '''
<article class="review-item${hasReply ? '' : ' pending-review'}">
  <div class="review-head">
    <div class="review-copy">
      <div class="review-title-row">
        <strong>${_escapeHtml(review.serviceName)}</strong>
        <span class="review-badge ${hasReply ? 'answered' : 'pending'}">${_escapeHtml(_reviewReplyBadgeLabel(hasReply, lang))}</span>
      </div>
      <div class="review-meta">
        <span>${_escapeHtml(customerLabel)}</span>
        <span>${_escapeHtml(phoneLabel)}</span>
        <span>${_escapeHtml(_formatDateTime(review.createdAt))}</span>
      </div>
    </div>
    <div class="review-stars">${_escapeHtml(_reviewStars(review.rating))} ${_escapeHtml(review.rating.toString())}/5</div>
  </div>
  <div class="review-comment">${_escapeHtml(review.comment)}</div>
  $replyBox
  <form class="review-reply-form" method="post" action="/owner/reviews/${Uri.encodeComponent(review.id)}/reply?lang=${Uri.encodeQueryComponent(lang)}">
    $hiddenFields
    <textarea name="reply" placeholder="${_escapeHtml(_text(lang, 'reviewReplyPlaceholder'))}">${_escapeHtml(review.ownerReply)}</textarea>
    <div class="quick-links">
      <button class="status-btn" type="submit">${_escapeHtml(_text(lang, hasReply ? 'reviewReplyUpdate' : 'reviewReplySave'))}</button>
    </div>
  </form>
</article>
''';
          }).join();

    return '''
<section class="card review-card">
  <div>
    <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewInboxEyebrow'))}</div>
    <h2>${_escapeHtml(_text(lang, 'reviewInboxTitle'))}</h2>
    <p>${_escapeHtml(_text(lang, 'reviewInboxDescription'))}</p>
  </div>

  <div class="review-stat-grid">
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewPendingTitle'))}</div>
      <strong>$pendingReviewCount</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'reviewPendingHint'))}</div>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewAnsweredTitle'))}</div>
      <strong>$repliedReviewCount</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'reviewAnsweredHint'))}</div>
    </div>
  </div>

  ${_reviewAnalyticsSectionHtml(
      analytics: analytics,
      lang: lang,
    )}

  <div class="review-list">
    $reviewItems
  </div>
</section>
''';
  }

  String _bookingAnalyticsSectionHtml({
    required BookingAnalyticsSummary analytics,
    required String lang,
  }) {
    final String topServices = analytics.topServices.isEmpty
        ? '<div class="muted">${_escapeHtml(_text(lang, 'analyticsNoData'))}</div>'
        : analytics.topServices.map((BookingAnalyticsSegment item) {
            return '''
<div class="meta-card">
  <strong>${_escapeHtml(item.label)}</strong>
  <div class="muted">${_escapeHtml(_text(lang, 'analyticsBookingsCount', <String, Object>{
                  'count': item.bookingCount
                }))}</div>
  <div class="muted">${_escapeHtml(formatMoneyUzs(item.revenue))}</div>
</div>
''';
          }).join();
    final String topVehicles = analytics.topVehicles.isEmpty
        ? '<div class="muted">${_escapeHtml(_text(lang, 'analyticsNoData'))}</div>'
        : analytics.topVehicles.map((BookingAnalyticsSegment item) {
            return '''
<div class="meta-card">
  <strong>${_escapeHtml(item.label)}</strong>
  <div class="muted">${_escapeHtml(_text(lang, 'analyticsBookingsCount', <String, Object>{
                  'count': item.bookingCount
                }))}</div>
  <div class="muted">${_escapeHtml(formatMoneyUzs(item.revenue))}</div>
</div>
''';
          }).join();

    return '''
<section class="card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsEyebrow'))}</div>
  <h2>${_escapeHtml(_text(lang, 'analyticsTitle'))}</h2>
  <p>${_escapeHtml(_text(lang, 'analyticsDescription'))}</p>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsCompletedRevenue'))}</div>
      <strong>${_escapeHtml(formatMoneyUzs(analytics.completedRevenue))}</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'completedHint'))}</div>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsPrepaymentCollected'))}</div>
      <strong>${_escapeHtml(formatMoneyUzs(analytics.prepaymentCollected))}</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'paymentStatusPaid'))}</div>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsScheduledToday'))}</div>
      <strong>${analytics.scheduledTodayCount}</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'statusUpcoming'))}</div>
    </div>
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsCreatedToday'))}</div>
      <strong>${analytics.createdTodayCount}</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'panelTitle'))}</div>
    </div>
  </div>
  <div class="meta-grid">
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'analyticsTopServices'))}</span>
      $topServices
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'analyticsTopVehicles'))}</span>
      $topVehicles
    </div>
  </div>
</section>
''';
  }

  String _reviewAnalyticsSectionHtml({
    required ReviewAnalyticsSummary analytics,
    required String lang,
  }) {
    final String ratingRows =
        analytics.starBuckets.map((ReviewStarBucket bucket) {
      final double widthPercent = bucket.share <= 0 ? 0 : bucket.share * 100;
      return '''
<div class="review-analytics-row">
  <span>${_escapeHtml(_text(lang, 'reviewAnalyticsStars', <String, Object>{
            'stars': bucket.stars
          }))}</span>
  <div class="review-analytics-bar"><div class="review-analytics-fill" style="width: ${widthPercent.toStringAsFixed(1)}%;"></div></div>
  <strong>${bucket.count}</strong>
</div>
''';
    }).join();

    final String topSegments = analytics.topSegments.isEmpty
        ? '<div class="muted">${_escapeHtml(_text(lang, 'reviewAnalyticsEmpty'))}</div>'
        : analytics.topSegments.map((ReviewSegmentSummary segment) {
            return '''
<div class="review-analytics-item">
  <strong>${_escapeHtml(segment.label)}</strong>
  <div class="review-analytics-meta">
    <span>${_escapeHtml(_text(lang, 'reviewAnalyticsCount', <String, Object>{
                  'count': segment.reviewCount
                }))}</span>
    <span>${segment.averageRating.toStringAsFixed(1)} / 5</span>
  </div>
</div>
''';
          }).join();

    return '''
<div class="review-analytics-grid">
  <div class="review-analytics-card">
    <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewAnalyticsEyebrow'))}</div>
    <strong>${analytics.totalReviews == 0 ? '0.0' : analytics.averageRating.toStringAsFixed(1)} / 5</strong>
    <div class="muted">${_escapeHtml(_text(lang, 'reviewAnalyticsSummary', <String, Object>{
          'count': analytics.totalReviews
        }))}</div>
    $ratingRows
  </div>
  <div class="review-analytics-card">
    <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewAnalyticsTopTitle'))}</div>
    <div class="review-analytics-list">
      $topSegments
    </div>
  </div>
</div>
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
      case BookingStatus.accepted:
      case BookingStatus.rescheduled:
      case BookingStatus.upcoming:
        if (parsed.kind == 'restore') {
          await _safeRefreshTelegramBookingMessage(
            action,
            workshop: workshop,
            booking: booking,
          );
          await _safeAnswerTelegramCallback(
            action.callbackQueryId,
            'Asosiy tugmalar qaytarildi',
          );
          return false;
        }
        if (parsed.kind == 'reschedule') {
          try {
            final List<DateTime> suggestions =
                _store.suggestedWorkshopRescheduleSlots(
              workshopId: workshop.id,
              serviceId: booking.serviceId,
              fromDateTime: booking.dateTime,
              excludeBookingId: booking.id,
            );
            if (suggestions.isEmpty) {
              await _safeAnswerTelegramCallback(
                action.callbackQueryId,
                'Yaqin bo‘sh vaqt topilmadi',
              );
              return false;
            }
            await telegramBotService.editMessageText(
              chatId: action.chatId,
              messageId: action.messageId,
              text: notificationsService.bookingRescheduleSelectionText(
                workshop: workshop,
                booking: booking,
                suggestions: suggestions,
              ),
              replyMarkup: notificationsService.bookingRescheduleOptionsMarkup(
                workshop: workshop,
                booking: booking,
                suggestions: suggestions,
              ),
            );
            await _safeAnswerTelegramCallback(
              action.callbackQueryId,
              'Yangi vaqtni tanlang',
            );
          } on StateError catch (error) {
            await _safeAnswerTelegramCallback(
              action.callbackQueryId,
              error.message,
            );
          } on Exception catch (error) {
            stderr.writeln(
                'Telegram reschedule variantlari yangilanmadi: $error');
            await _safeAnswerTelegramCallback(
              action.callbackQueryId,
              'Variantlarni ochib bo‘lmadi',
            );
          }
          return false;
        }
        if (parsed.kind == 'accept' &&
            booking.status == BookingStatus.accepted) {
          await _safeAnswerTelegramCallback(
            action.callbackQueryId,
            'Zakaz allaqachon qabul qilingan',
          );
          return false;
        }
        try {
          final BookingModel updated = parsed.kind == 'cancel'
              ? _store.cancelWorkshopBooking(
                  workshopId: workshop.id,
                  bookingId: booking.id,
                  reasonId: parsed.reasonId,
                  actorRole: 'owner_telegram',
                )
              : parsed.kind == 'pick_reschedule'
                  ? _store.rescheduleWorkshopBooking(
                      workshopId: workshop.id,
                      bookingId: booking.id,
                      dateTime: parsed.scheduledAt ??
                          (throw StateError('Yangi vaqt topilmadi')),
                      actorRole: 'owner_telegram',
                    )
                  : parsed.kind == 'accept'
                      ? _store.updateWorkshopBookingStatus(
                          workshopId: workshop.id,
                          bookingId: booking.id,
                          status: BookingStatus.accepted,
                        )
                      : _store.updateWorkshopBookingStatus(
                          workshopId: workshop.id,
                          bookingId: booking.id,
                          status: BookingStatus.completed,
                        );
          await _safeRefreshTelegramBookingMessage(
            action,
            workshop: workshop,
            booking: updated,
          );
          await _safeAnswerTelegramCallback(
            action.callbackQueryId,
            parsed.kind == 'cancel'
                ? 'Zakaz bekor qilindi'
                : parsed.kind == 'pick_reschedule'
                    ? 'Zakaz yangi vaqtga ko‘chirildi'
                    : parsed.kind == 'accept'
                        ? 'Zakaz qabul qilindi'
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
    if (parts.length == 2 && parts.first == 'a') {
      final String bookingId = parts[1].trim();
      if (bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'accept',
        workshopId: '',
        bookingId: bookingId,
      );
    }

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

    if (parts.length == 2 && parts.first == 'r') {
      final String bookingId = parts[1].trim();
      if (bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'reschedule',
        workshopId: '',
        bookingId: bookingId,
      );
    }

    if (parts.length == 2 && parts.first == 'b') {
      final String bookingId = parts[1].trim();
      if (bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'restore',
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

    if (parts.length == 3 && parts.first == 's') {
      final DateTime? scheduledAt = _parseTelegramSlotCode(parts[1]);
      final String bookingId = parts[2].trim();
      if (scheduledAt == null || bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'pick_reschedule',
        workshopId: '',
        bookingId: bookingId,
        scheduledAt: scheduledAt,
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

    if (parts.length == 3 && parts.first == 'accept') {
      final String workshopId = parts[1].trim();
      final String bookingId = parts[2].trim();
      if (workshopId.isEmpty || bookingId.isEmpty) {
        return null;
      }

      return _TelegramBookingCallback(
        kind: 'accept',
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

  DateTime? _parseTelegramSlotCode(String raw) {
    final String value = raw.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return null;
    }
    final int year = int.parse(value.substring(0, 4));
    final int month = int.parse(value.substring(4, 6));
    final int day = int.parse(value.substring(6, 8));
    final int hour = int.parse(value.substring(8, 10));
    final int minute = int.parse(value.substring(10, 12));
    return DateTime(year, month, day, hour, minute).toUtc();
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

  Future<void> _safeRefreshTelegramBookingMessage(
    _TelegramCallbackAction action, {
    required WorkshopModel workshop,
    required BookingModel booking,
  }) async {
    try {
      await telegramBotService.editMessageText(
        chatId: action.chatId,
        messageId: action.messageId,
        text: notificationsService.newBookingText(
          workshop: workshop,
          booking: booking,
          includeStatus: true,
        ),
        replyMarkup: notificationsService.bookingActionMarkup(
          workshop: workshop,
          booking: booking,
        ),
      );
      if (booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.cancelled) {
        await telegramBotService.editMessageReplyMarkup(
          chatId: action.chatId,
          messageId: action.messageId,
        );
      }
    } on Exception catch (error) {
      stderr.writeln('Telegram zakaz xabari yangilanmadi: $error');
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
    if (booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled) {
      return '<span class="muted">${_escapeHtml(_text(lang, 'noFurtherActions'))}</span>';
    }

    final String acceptForm = booking.status == BookingStatus.upcoming ||
            booking.status == BookingStatus.rescheduled
        ? _statusActionForm(
            booking,
            BookingStatus.accepted,
            lang,
            status,
          )
        : '';
    final String completeForm = _statusActionForm(
      booking,
      BookingStatus.completed,
      lang,
      status,
    );
    final String rescheduleForm = _rescheduleActionForm(
      booking: booking,
      lang: lang,
      status: status,
    );
    final String cancelForm = _cancelActionForm(
      booking: booking,
      lang: lang,
      status: status,
    );
    return '$acceptForm$completeForm$rescheduleForm$cancelForm';
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

  String _rescheduleActionForm({
    required BookingModel booking,
    required String lang,
    required String status,
  }) {
    return '''
<form class="inline-form cancel-form" method="post" action="/owner/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
  <input type="hidden" name="bookingStatus" value="rescheduled">
  <input class="cancel-select" type="datetime-local" name="scheduledAt" value="${_escapeHtml(_formatDateTimeLocalValue(booking.dateTime))}" aria-label="${_escapeHtml(_text(lang, 'rescheduleDateLabel'))}">
  <button class="status-btn" type="submit">${_escapeHtml(_text(lang, 'rescheduleButton'))}</button>
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
        values[key] = list.length == 1 ? list.last : list.join(',');
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
    DateTime? date,
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
    if (date != null) {
      final DateTime normalizedDate = _normalizeDate(date);
      final String month = normalizedDate.month.toString().padLeft(2, '0');
      final String day = normalizedDate.day.toString().padLeft(2, '0');
      params['date'] = '${normalizedDate.year}-$month-$day';
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

  int _parsePriceField(
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

    final int? value = tryParseStoredMoneyAmount(normalized);
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
      final bool breakOutsideRange = breakStartMinutes < openingMinutes ||
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
      if (weekday == null ||
          weekday < 1 ||
          weekday > 7 ||
          result.contains(weekday)) {
        continue;
      }
      result.add(weekday);
    }
    result.sort();
    return result;
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
      case 'rescheduled':
        return 'rescheduled';
      case 'accepted':
        return 'accepted';
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
      case 'rescheduled':
        return BookingStatus.rescheduled;
      case 'accepted':
        return BookingStatus.accepted;
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
      case BookingStatus.rescheduled:
        return _text(lang, 'statusRescheduled');
      case BookingStatus.accepted:
        return _text(lang, 'statusAccepted');
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

  String _formatDateTimeLocalValue(DateTime value) {
    final DateTime local = value.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day'
        'T$hour:$minute';
  }

  DateTime? _parseDateTimeLocalField(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _statusClass(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'status-upcoming';
      case BookingStatus.accepted:
        return 'status-accepted';
      case BookingStatus.rescheduled:
        return 'status-rescheduled';
      case BookingStatus.completed:
        return 'status-completed';
      case BookingStatus.cancelled:
        return 'status-cancelled';
    }
  }

  String _paymentStatusLabel(BookingPaymentStatus status, String lang) {
    switch (status) {
      case BookingPaymentStatus.pending:
        return _text(lang, 'paymentStatusPending');
      case BookingPaymentStatus.paid:
        return _text(lang, 'paymentStatusPaid');
      case BookingPaymentStatus.refunded:
        return _text(lang, 'paymentStatusRefunded');
      case BookingPaymentStatus.notRequired:
        return _text(lang, 'paymentStatusNotRequired');
    }
  }

  String _reviewStars(int rating) {
    final int normalized = rating.clamp(1, 5);
    return List<String>.filled(normalized, '★').join();
  }

  String _reviewReplyBadgeLabel(bool hasReply, String lang) {
    return _text(lang, hasReply ? 'reviewAnsweredBadge' : 'reviewPendingBadge');
  }

  String _reviewReplySourceLabel(String source, String lang) {
    switch (source.trim()) {
      case 'owner_telegram':
        return _text(lang, 'reviewReplySourceTelegram');
      case 'owner_panel':
      default:
        return _text(lang, 'reviewReplySourcePanel');
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

  String _escapeHtml(String value) => const HtmlEscape().convert(value);

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'uz': <String, String>{
      'brandEyebrow': 'Owner Portal',
      'brandTitle': 'Usta Top Ustaxona Egasi',
      'language': 'Til',
      'loginTitle': 'Ustaxona egasi kirishi',
      'heroEyebrow': 'Zakazlarni Ko‘rish',
      'heroTitle': 'Faqat o‘z ustaxonangiz zakazlarini kuzating',
      'heroDescription':
          'Ustaxona va access code orqali kirib, mijoz buyurtmalarini ko‘rishingiz va statusini yangilashingiz mumkin.',
      'tip1Title': 'Yangi zakazlar',
      'tip1Body':
          'Ilovadan tushgan yangi buyurtmalar shu yerda darhol ko‘rinadi.',
      'tip2Title': 'Mijoz bilan aloqa',
      'tip2Body': 'Telefon tugmasi orqali mijozga tezda qo‘ng‘iroq qilasiz.',
      'tip3Title': 'Status nazorati',
      'tip3Body':
          'Kutilmoqda, yakunlangan yoki bekor qilingan statuslarini shu paneldan boshqarasiz.',
      'loginEyebrow': 'Ustaxona Kirishi',
      'loginSubtitle': 'Davom etish uchun ustaxona va access code ni tanlang.',
      'workshopField': 'Ustaxona',
      'workshopPlaceholder': 'Ustaxonani tanlang',
      'accessCodeField': 'Access code',
      'accessCodePlaceholder': 'Masalan: 0001',
      'loginButton': 'Kirish',
      'loginHelper':
          'Agar kodni bilmasangiz, admin paneldagi ustaxona kartasidan ko‘rishingiz mumkin.',
      'loginMissing': 'Ustaxona va access code ni kiriting',
      'loginInvalid': 'Ustaxona yoki access code noto‘g‘ri',
      'panelEyebrow': 'Ustaxona Inbox',
      'panelTitle': 'Ustaxona zakazlari',
      'panelDescription':
          'Quyidagi ro‘yxatda faqat sizning ustaxonangizga tegishli buyurtmalar ko‘rinadi.',
      'statusAll': 'Barchasi',
      'statusUpcoming': 'Kutilmoqda',
      'statusRescheduled': 'Ko‘chirildi',
      'statusAccepted': 'Qabul qilindi',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'upcomingHint': 'Tez javob berish kerak bo‘lgan yangi zakazlar.',
      'acceptedHint': 'Usta qabul qilib olgan zakazlar.',
      'completedHint': 'Bajarib bo‘lingan zakazlar.',
      'cancelledHint': 'Bekor qilingan buyurtmalar.',
      'emptyEyebrow': 'Zakaz Yo‘q',
      'emptyTitle': 'Hozircha zakaz yo‘q',
      'emptyBody': 'Bu ustaxona uchun hali zakaz tushmagan.',
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
      'prepaymentLabel': 'Avans',
      'remainingPaymentLabel': 'Qolgani',
      'paymentStatusLabel': 'To‘lov holati',
      'paymentMethodLabel': 'To‘lov usuli',
      'paymentStatusPending': 'Kutilmoqda',
      'paymentStatusPaid': 'To‘langan',
      'paymentStatusRefunded': 'Qaytarilgan',
      'paymentStatusNotRequired': 'Talab qilinmaydi',
      'createdLabel': 'Tushgan vaqt',
      'callCustomer': 'Mijozga qo‘ng‘iroq',
      'chatButton': 'Chat',
      'chatPreviewLabel': 'Oxirgi xabar',
      'reviewInboxEyebrow': 'Sharhlar Inbox',
      'reviewInboxTitle': 'Mijoz sharhlariga javob bering',
      'reviewInboxDescription':
          'Javobsiz sharhlar tepada turadi. Shu paneldan yozilgan javob ilovada ham darhol ko‘rinadi.',
      'reviewPendingTitle': 'Javobsiz sharhlar',
      'reviewPendingHint': 'Tez javob berish kerak bo‘lgan fikrlar.',
      'reviewAnsweredTitle': 'Javob berilgan',
      'reviewAnsweredHint': 'Usta tomonidan javob yozilgan sharhlar.',
      'reviewEmptyBody': 'Bu ustaxona uchun hali sharhlar kelmagan.',
      'reviewReplyLabel': 'Usta javobi',
      'reviewReplyPlaceholder':
          'Mijozga qisqa, aniq va professional javob yozing.',
      'reviewReplySave': 'Javobni yuborish',
      'reviewReplyUpdate': 'Javobni yangilash',
      'reviewReplySaved': '{service} bo‘yicha javob saqlandi',
      'reviewPendingBadge': 'Javob kutilmoqda',
      'reviewAnsweredBadge': 'Javob berilgan',
      'reviewReplySourceTelegram': 'Telegram orqali',
      'reviewReplySourcePanel': 'Panel orqali',
      'reviewAnalyticsEyebrow': 'Reyting rasmi',
      'reviewAnalyticsSummary': '{count} ta public sharh',
      'reviewAnalyticsTopTitle': 'Eng ko‘p sharhlangan xizmatlar',
      'reviewAnalyticsEmpty':
          'Sharhlar ko‘paygach, xizmatlar kesimidagi statistika shu yerda chiqadi.',
      'reviewAnalyticsCount': '{count} ta sharh',
      'reviewAnalyticsStars': '{stars} yulduz',
      'servicePricingEyebrow': 'Narx boshqaruvi',
      'servicePricingTitle': 'Xizmat narxi va davomiyligini boshqaring',
      'servicePricingDescription':
          'Quyida faqat shu ustaxonaga tegishli xizmatlar narxi va davomiyligini yangilaysiz.',
      'servicePricingHint':
          'Saqlangan narx va davomiylik appdagi keyingi yangilanishda ko‘rinadi va keyingi zakazlar shu bazaviy qiymatlar bilan ishlaydi.',
      'servicePricingEmpty': 'Bu ustaxonaga hali xizmatlar qo‘shilmagan.',
      'serviceDurationMinutes': '{minutes} daqiqa',
      'serviceCurrentPriceLabel': 'Joriy narx: {price}',
      'serviceCurrentPrepaymentLabel': 'Avans: {percent}%',
      'serviceNewPriceLabel': 'Yangi narx',
      'serviceNewDurationLabel': 'Yangi davomiylik',
      'serviceNewPrepaymentLabel': 'Yangi avans foizi',
      'servicePricePlaceholder': 'Masalan: 150000',
      'serviceDurationPlaceholder': 'Masalan: 45',
      'servicePrepaymentPlaceholder': 'Masalan: 30',
      'servicePriceSave': 'Narxni saqlash',
      'serviceSettingsUpdated':
          '{service} uchun narx {price}, davomiylik {duration} daqiqa, avans esa {prepayment}% qilib yangilandi',
      'servicePriceFieldLabel': '{service} narxi',
      'serviceDurationFieldLabel': '{service} davomiyligi',
      'servicePrepaymentFieldLabel': '{service} uchun avans foizi',
      'ownerServiceNotFound': 'Xizmat topilmadi',
      'pricingMatrixTitle': 'Mashina bo‘yicha narxlar',
      'pricingMatrixDescription':
          'Har bir xizmat uchun mashina modeli kesimidagi narxlarni Excel orqali boshqaring.',
      'pricingMatrixHint':
          'Template-ni yuklab oling, price_uzs ustunini to‘liq UZS formatida o‘zgartiring va faylni shu joyga qayta yuklang.',
      'pricingConfiguredCount': 'Sozlangan narxlar',
      'pricingTemplateRows': 'Template satrlari',
      'pricingTemplateDownload': 'Excel template',
      'pricingTemplateUpload': 'Excel yuklash',
      'pricingWorkbookField': 'Narxlar fayli (.xlsx)',
      'pricingWorkbookWaiting': 'Hali fayl tanlanmagan',
      'pricingWorkbookRequired': 'Excel fayl tanlanmadi',
      'pricingWorkbookInvalid': 'Excel faylni o‘qib bo‘lmadi',
      'pricingImportSuccess': '{count} ta narx qoidasi yuklandi',
      'scheduleEyebrow': 'Ish jadvali',
      'scheduleTitle': 'Qabul vaqtini boshqaring',
      'scheduleDescription':
          'Ish boshlanishi, tugashi, tanaffus va dam olish kunlarini shu ustaxona uchun alohida saqlang.',
      'scheduleHint':
          'Keyingi bosqichda bo‘sh slotlar aynan shu jadval asosida hisoblanadi.',
      'scheduleSave': 'Jadvalni saqlash',
      'scheduleSaved': 'Ustaxona ish jadvali saqlandi',
      'infoWorkingHours': 'Ish vaqti',
      'infoBreakTime': 'Tanaffus',
      'infoDaysOff': 'Dam olish kunlari',
      'fieldOpeningTime': 'Ish boshlanishi',
      'fieldClosingTime': 'Ish tugashi',
      'fieldBreakStart': 'Tanaffus boshlanishi',
      'fieldBreakEnd': 'Tanaffus tugashi',
      'fieldClosedWeekdays': 'Dam olish kunlari',
      'noBreakLabel': 'Tanaffus yo‘q',
      'noClosedWeekdaysLabel': 'Har kuni ochiq',
      'invalidTimeField': '{field} vaqti noto‘g‘ri',
      'scheduleTimeRangeError':
          'Ish tugash vaqti ish boshlanish vaqtidan keyin bo‘lishi kerak.',
      'scheduleBreakPairError':
          'Tanaffus uchun boshlanish va tugash vaqtini birga kiriting yoki ikkalasini ham bo‘sh qoldiring.',
      'scheduleBreakRangeError':
          'Tanaffus oralig‘i ish vaqti ichida va to‘g‘ri tartibda bo‘lishi kerak.',
      'calendarEyebrow': 'Kalendar ko‘rinishi',
      'calendarTitle': 'Yaqin 14 kun bron holati',
      'calendarDescription':
          'Band kunlar, yopiq kunlar va shu kunning eng yaqin yozuvlari bir qarashda ko‘rinadi.',
      'calendarSelectedEyebrow': 'Tanlangan kun',
      'calendarSelectedTitle': '{date} kunining zakazlari',
      'calendarOpenLabel': 'Bo‘sh',
      'calendarClosedLabel': 'Yopiq kun',
      'calendarBookingsCount': '{count} ta bron',
      'calendarFirstAppointment': 'Birinchi bron {time}',
      'calendarNoAppointments': 'Hali bron yo‘q',
      'calendarEmptyTitle': 'Bu kunda zakaz yo‘q',
      'calendarEmptyBody':
          'Tanlangan sanada hali hech qanday yozuv yo‘q yoki shu status bo‘yicha topilmadi.',
      'analyticsEyebrow': 'Zakaz analitikasi',
      'analyticsTitle': 'Tushum va yuklama kesimi',
      'analyticsDescription':
          'Ustaxonangiz bo‘yicha tushum, avans va eng ko‘p kelayotgan xizmat yoki mashina yo‘nalishlari shu yerda ko‘rinadi.',
      'analyticsCompletedRevenue': 'Yakunlangan tushum',
      'analyticsPrepaymentCollected': 'Yig‘ilgan avans',
      'analyticsScheduledToday': 'Bugungi bronlar',
      'analyticsCreatedToday': 'Bugun tushgan',
      'analyticsTopServices': 'Top xizmatlar',
      'analyticsTopVehicles': 'Top mashinalar',
      'analyticsNoData': 'Hozircha yetarli ma’lumot yo‘q.',
      'analyticsBookingsCount': '{count} ta zakaz',
      'weekdayShortMon': 'Du',
      'weekdayShortTue': 'Se',
      'weekdayShortWed': 'Cho',
      'weekdayShortThu': 'Pa',
      'weekdayShortFri': 'Ju',
      'weekdayShortSat': 'Sha',
      'weekdayShortSun': 'Yak',
      'requiredField': '{field} majburiy',
      'invalidNumber': '{field} noto‘g‘ri',
      'numberMin': '{field} kamida {min} bo‘lishi kerak',
      'statusUpdated': '{id} statusi {status} ga o‘zgardi',
      'rescheduleButton': 'Ko‘chirish',
      'rescheduleDateLabel': 'Yangi bron vaqti',
      'rescheduleDateRequired': 'Ko‘chirish uchun yangi vaqtni tanlang',
      'rescheduledFromLabel': 'Oldingi vaqt',
      'rescheduledByLabel': 'Ko‘chirdi',
      'rescheduledAtLabel': 'Ko‘chirilgan vaqt',
      'completedAtLabel': 'Yakunlangan vaqt',
      'cancelButton': 'Bekor qilish',
      'cancelReasonLabel': 'Bekor qilish sababi',
      'cancelledByLabel': 'Bekor qildi',
      'cancelledAtLabel': 'Bekor qilingan vaqt',
      'cancelGuardHint':
          'Bekor qilish faqat bron vaqtigacha kamida {minutes} daqiqa qolganda mumkin.',
      'noFurtherActions': 'Bu zakaz uchun qo‘shimcha amal yo‘q.',
      'unknownReason': 'Ko‘rsatilmagan',
      'logout': 'Chiqish',
      'garageNotFound': 'Ustaxona topilmadi',
      'telegramEyebrow': 'Telegram Bot',
      'telegramTitle': 'Zakazlarni Telegramga ulang',
      'telegramDescription':
          'Har bir ustaxona profili o‘z Telegram chatiga faqat o‘z zakazlarini oladi.',
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
      'loginTitle': 'Вход владельца автосервиса',
      'heroEyebrow': 'Просмотр Заказов',
      'heroTitle': 'Следите только за заказами своего автосервиса',
      'heroDescription':
          'Выберите автосервис и access code, чтобы смотреть заказы клиентов и менять их статус.',
      'tip1Title': 'Новые заказы',
      'tip1Body': 'Новые заявки из приложения появляются здесь сразу.',
      'tip2Title': 'Связь с клиентом',
      'tip2Body': 'Через кнопку телефона можно быстро позвонить клиенту.',
      'tip3Title': 'Контроль статуса',
      'tip3Body':
          'Статусы ожидания, завершения и отмены управляются прямо из панели.',
      'loginEyebrow': 'Вход в автосервис',
      'loginSubtitle': 'Выберите автосервис и введите access code.',
      'workshopField': 'Автосервис',
      'workshopPlaceholder': 'Выберите автосервис',
      'accessCodeField': 'Access code',
      'accessCodePlaceholder': 'Например: 0001',
      'loginButton': 'Войти',
      'loginHelper':
          'Если вы не знаете код, его можно посмотреть в карточке автосервиса в админке.',
      'loginMissing': 'Выберите автосервис и введите access code',
      'loginInvalid': 'Автосервис или access code неверны',
      'panelEyebrow': 'Inbox автосервиса',
      'panelTitle': 'Заказы автосервиса',
      'panelDescription':
          'В этом списке показаны только заказы, относящиеся к вашему автосервису.',
      'statusAll': 'Все',
      'statusUpcoming': 'Ожидает',
      'statusRescheduled': 'Перенесен',
      'statusAccepted': 'Принят',
      'statusCompleted': 'Завершен',
      'statusCancelled': 'Отменен',
      'upcomingHint': 'Новые заказы, на которые нужно быстро ответить.',
      'acceptedHint': 'Заказы, которые мастер уже принял.',
      'completedHint': 'Заказы, по которым работа уже завершена.',
      'cancelledHint': 'Отмененные заявки.',
      'emptyEyebrow': 'Нет Заказов',
      'emptyTitle': 'Пока заказов нет',
      'emptyBody': 'Для этого автосервиса пока не поступило заказов.',
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
      'prepaymentLabel': 'Аванс',
      'remainingPaymentLabel': 'Остаток',
      'paymentStatusLabel': 'Статус оплаты',
      'paymentMethodLabel': 'Способ оплаты',
      'paymentStatusPending': 'Ожидает',
      'paymentStatusPaid': 'Оплачено',
      'paymentStatusRefunded': 'Возвращено',
      'paymentStatusNotRequired': 'Не требуется',
      'createdLabel': 'Время поступления',
      'callCustomer': 'Позвонить клиенту',
      'chatButton': 'Чат',
      'chatPreviewLabel': 'Последнее сообщение',
      'reviewInboxEyebrow': 'Inbox отзывов',
      'reviewInboxTitle': 'Отвечайте на отзывы клиентов',
      'reviewInboxDescription':
          'Отзывы без ответа показываются сверху. Ответ отсюда сразу появляется и в приложении.',
      'reviewPendingTitle': 'Без ответа',
      'reviewPendingHint':
          'Отзывы, на которые стоит ответить в первую очередь.',
      'reviewAnsweredTitle': 'С ответом',
      'reviewAnsweredHint': 'Отзывы, где мастер уже оставил ответ.',
      'reviewEmptyBody': 'Для этого автосервиса отзывов пока нет.',
      'reviewReplyLabel': 'Ответ мастера',
      'reviewReplyPlaceholder':
          'Напишите клиенту короткий, понятный и профессиональный ответ.',
      'reviewReplySave': 'Отправить ответ',
      'reviewReplyUpdate': 'Обновить ответ',
      'reviewReplySaved': 'Ответ по услуге {service} сохранен',
      'reviewPendingBadge': 'Ждёт ответа',
      'reviewAnsweredBadge': 'Ответ дан',
      'reviewReplySourceTelegram': 'Через Telegram',
      'reviewReplySourcePanel': 'Через панель',
      'reviewAnalyticsEyebrow': 'Снимок рейтинга',
      'reviewAnalyticsSummary': '{count} видимых отзывов',
      'reviewAnalyticsTopTitle': 'Самые обсуждаемые услуги',
      'reviewAnalyticsEmpty':
          'Когда отзывов станет больше, здесь появится статистика по услугам.',
      'reviewAnalyticsCount': '{count} отзывов',
      'reviewAnalyticsStars': '{stars} звезды',
      'servicePricingEyebrow': 'Управление ценами',
      'servicePricingTitle': 'Управляйте ценой и длительностью услуг',
      'servicePricingDescription':
          'Ниже вы обновляете только цену и длительность услуг своего автосервиса.',
      'servicePricingHint':
          'Сохраненные цена и длительность появятся в приложении после следующего обновления, а новые заказы будут использовать эти базовые значения.',
      'servicePricingEmpty': 'Для этого автосервиса пока не добавлены услуги.',
      'serviceDurationMinutes': '{minutes} мин',
      'serviceCurrentPriceLabel': 'Текущая цена: {price}',
      'serviceCurrentPrepaymentLabel': 'Аванс: {percent}%',
      'serviceNewPriceLabel': 'Новая цена',
      'serviceNewDurationLabel': 'Новая длительность',
      'serviceNewPrepaymentLabel': 'Новый процент аванса',
      'servicePricePlaceholder': 'Например: 150000',
      'serviceDurationPlaceholder': 'Например: 45',
      'servicePrepaymentPlaceholder': 'Например: 30',
      'servicePriceSave': 'Сохранить цену',
      'serviceSettingsUpdated':
          'Для услуги {service} цена обновлена до {price}, длительность до {duration} мин, а аванс до {prepayment}%',
      'servicePriceFieldLabel': 'Цена для {service}',
      'serviceDurationFieldLabel': 'Длительность для {service}',
      'servicePrepaymentFieldLabel': 'Аванс для {service}',
      'ownerServiceNotFound': 'Услуга не найдена',
      'pricingMatrixTitle': 'Цены по моделям авто',
      'pricingMatrixDescription':
          'Управляйте ценами по моделям для каждой услуги через Excel.',
      'pricingMatrixHint':
          'Скачайте шаблон, измените колонку price_uzs в полном формате UZS и загрузите файл обратно сюда.',
      'pricingConfiguredCount': 'Настроено цен',
      'pricingTemplateRows': 'Строк в шаблоне',
      'pricingTemplateDownload': 'Excel шаблон',
      'pricingTemplateUpload': 'Загрузить Excel',
      'pricingWorkbookField': 'Файл цен (.xlsx)',
      'pricingWorkbookWaiting': 'Файл пока не выбран',
      'pricingWorkbookRequired': 'Excel-файл не выбран',
      'pricingWorkbookInvalid': 'Не удалось прочитать Excel-файл',
      'pricingImportSuccess': 'Загружено {count} ценовых правил',
      'scheduleEyebrow': 'График работы',
      'scheduleTitle': 'Управляйте временем приема',
      'scheduleDescription':
          'Сохраняйте часы работы, перерыв и выходные отдельно для этого автосервиса.',
      'scheduleHint':
          'На следующем этапе свободные слоты будут строиться по этому графику.',
      'scheduleSave': 'Сохранить график',
      'scheduleSaved': 'График автосервиса сохранен',
      'infoWorkingHours': 'Часы работы',
      'infoBreakTime': 'Перерыв',
      'infoDaysOff': 'Выходные',
      'fieldOpeningTime': 'Начало работы',
      'fieldClosingTime': 'Конец работы',
      'fieldBreakStart': 'Начало перерыва',
      'fieldBreakEnd': 'Конец перерыва',
      'fieldClosedWeekdays': 'Выходные дни',
      'noBreakLabel': 'Без перерыва',
      'noClosedWeekdaysLabel': 'Открыт каждый день',
      'invalidTimeField': 'Время в поле {field} указано неверно',
      'scheduleTimeRangeError':
          'Время окончания работы должно быть позже времени начала.',
      'scheduleBreakPairError':
          'Для перерыва нужно указать и начало, и конец, либо оставить оба поля пустыми.',
      'scheduleBreakRangeError':
          'Перерыв должен находиться внутри рабочего времени и быть задан в правильном порядке.',
      'calendarEyebrow': 'Календарный вид',
      'calendarTitle': 'Брони на ближайшие 14 дней',
      'calendarDescription':
          'Занятые дни, выходные и ближайшие записи за день видны с одного взгляда.',
      'calendarSelectedEyebrow': 'Выбранный день',
      'calendarSelectedTitle': 'Заказы на {date}',
      'calendarOpenLabel': 'Свободно',
      'calendarClosedLabel': 'Выходной',
      'calendarBookingsCount': '{count} броней',
      'calendarFirstAppointment': 'Первая запись в {time}',
      'calendarNoAppointments': 'Записей пока нет',
      'calendarEmptyTitle': 'На этот день заказов нет',
      'calendarEmptyBody':
          'На выбранную дату еще нет записей или ничего не найдено по этому статусу.',
      'analyticsEyebrow': 'Аналитика заказов',
      'analyticsTitle': 'Срез по выручке и нагрузке',
      'analyticsDescription':
          'Здесь показаны выручка, авансы и самые частые услуги и машины именно по вашему автосервису.',
      'analyticsCompletedRevenue': 'Выручка по завершенным',
      'analyticsPrepaymentCollected': 'Собранный аванс',
      'analyticsScheduledToday': 'Брони на сегодня',
      'analyticsCreatedToday': 'Создано сегодня',
      'analyticsTopServices': 'Топ услуг',
      'analyticsTopVehicles': 'Топ машин',
      'analyticsNoData': 'Пока недостаточно данных.',
      'analyticsBookingsCount': '{count} заказов',
      'weekdayShortMon': 'Пн',
      'weekdayShortTue': 'Вт',
      'weekdayShortWed': 'Ср',
      'weekdayShortThu': 'Чт',
      'weekdayShortFri': 'Пт',
      'weekdayShortSat': 'Сб',
      'weekdayShortSun': 'Вс',
      'requiredField': 'Поле {field} обязательно',
      'invalidNumber': 'Поле {field} заполнено неверно',
      'numberMin': 'Поле {field} должно быть не меньше {min}',
      'statusUpdated': 'Статус {id} изменен на {status}',
      'rescheduleButton': 'Перенести',
      'rescheduleDateLabel': 'Новое время записи',
      'rescheduleDateRequired': 'Выберите новое время для переноса',
      'rescheduledFromLabel': 'Старое время',
      'rescheduledByLabel': 'Перенес',
      'rescheduledAtLabel': 'Перенесено в',
      'completedAtLabel': 'Завершено в',
      'cancelButton': 'Отменить заказ',
      'cancelReasonLabel': 'Причина отмены',
      'cancelledByLabel': 'Кто отменил',
      'cancelledAtLabel': 'Отменено в',
      'cancelGuardHint':
          'Отмена доступна только если до записи осталось не меньше {minutes} минут.',
      'noFurtherActions': 'Для этого заказа больше нет доступных действий.',
      'unknownReason': 'Не указано',
      'logout': 'Выйти',
      'garageNotFound': 'Автосервис не найден',
      'telegramEyebrow': 'Telegram Bot',
      'telegramTitle': 'Подключите заказы к Telegram',
      'telegramDescription':
          'Каждый профиль автосервиса получает в свой Telegram только свои заказы.',
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
      'statusRescheduled': 'Rescheduled',
      'statusAccepted': 'Accepted',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'upcomingHint': 'Fresh orders that need attention.',
      'acceptedHint': 'Orders already accepted by the workshop.',
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
      'prepaymentLabel': 'Prepayment',
      'remainingPaymentLabel': 'Remaining',
      'paymentStatusLabel': 'Payment status',
      'paymentMethodLabel': 'Payment method',
      'paymentStatusPending': 'Pending',
      'paymentStatusPaid': 'Paid',
      'paymentStatusRefunded': 'Refunded',
      'paymentStatusNotRequired': 'Not required',
      'createdLabel': 'Received at',
      'callCustomer': 'Call customer',
      'chatButton': 'Chat',
      'chatPreviewLabel': 'Latest message',
      'reviewInboxEyebrow': 'Review Inbox',
      'reviewInboxTitle': 'Reply to customer reviews',
      'reviewInboxDescription':
          'Unanswered reviews stay at the top. Replies written here appear in the app right away.',
      'reviewPendingTitle': 'Waiting for reply',
      'reviewPendingHint': 'Reviews that still need your attention.',
      'reviewAnsweredTitle': 'Answered',
      'reviewAnsweredHint': 'Reviews that already have a workshop reply.',
      'reviewEmptyBody': 'No reviews have arrived for this workshop yet.',
      'reviewReplyLabel': 'Workshop reply',
      'reviewReplyPlaceholder':
          'Write a short, clear, professional reply for the customer.',
      'reviewReplySave': 'Send reply',
      'reviewReplyUpdate': 'Update reply',
      'reviewReplySaved': 'Reply saved for {service}',
      'reviewPendingBadge': 'Awaiting reply',
      'reviewAnsweredBadge': 'Answered',
      'reviewReplySourceTelegram': 'Via Telegram',
      'reviewReplySourcePanel': 'Via panel',
      'reviewAnalyticsEyebrow': 'Rating snapshot',
      'reviewAnalyticsSummary': '{count} public reviews',
      'reviewAnalyticsTopTitle': 'Most reviewed services',
      'reviewAnalyticsEmpty':
          'Service-level stats will appear here as more reviews arrive.',
      'reviewAnalyticsCount': '{count} reviews',
      'reviewAnalyticsStars': '{stars} stars',
      'servicePricingEyebrow': 'Price control',
      'servicePricingTitle': 'Manage service price and duration',
      'servicePricingDescription':
          'Update only the price and duration of services that belong to your workshop.',
      'servicePricingHint':
          'The saved price and duration appear in the app on the next refresh, and new bookings will use those base values immediately.',
      'servicePricingEmpty':
          'No services have been added to this workshop yet.',
      'serviceDurationMinutes': '{minutes} min',
      'serviceCurrentPriceLabel': 'Current price: {price}',
      'serviceCurrentPrepaymentLabel': 'Prepayment: {percent}%',
      'serviceNewPriceLabel': 'New price',
      'serviceNewDurationLabel': 'New duration',
      'serviceNewPrepaymentLabel': 'New prepayment percent',
      'servicePricePlaceholder': 'For example: 150000',
      'serviceDurationPlaceholder': 'For example: 45',
      'servicePrepaymentPlaceholder': 'For example: 30',
      'servicePriceSave': 'Save price',
      'serviceSettingsUpdated':
          '{service} was updated to {price}, {duration} minutes, and {prepayment}% prepayment',
      'servicePriceFieldLabel': 'Price for {service}',
      'serviceDurationFieldLabel': 'Duration for {service}',
      'servicePrepaymentFieldLabel': 'Prepayment for {service}',
      'ownerServiceNotFound': 'Service not found',
      'pricingMatrixTitle': 'Vehicle pricing matrix',
      'pricingMatrixDescription':
          'Manage vehicle-specific prices for each service through Excel.',
      'pricingMatrixHint':
          'Download the template, update the price_uzs column with full UZS amounts, and upload the file back here.',
      'pricingConfiguredCount': 'Configured prices',
      'pricingTemplateRows': 'Template rows',
      'pricingTemplateDownload': 'Excel template',
      'pricingTemplateUpload': 'Upload Excel',
      'pricingWorkbookField': 'Pricing file (.xlsx)',
      'pricingWorkbookWaiting': 'No file selected yet',
      'pricingWorkbookRequired': 'No Excel file selected',
      'pricingWorkbookInvalid': 'The Excel file could not be read',
      'pricingImportSuccess': '{count} pricing rules imported',
      'scheduleEyebrow': 'Working schedule',
      'scheduleTitle': 'Manage intake hours',
      'scheduleDescription':
          'Save opening time, closing time, break, and days off separately for this workshop.',
      'scheduleHint':
          'In the next step, available slots will be generated from this schedule.',
      'scheduleSave': 'Save schedule',
      'scheduleSaved': 'Workshop schedule saved',
      'infoWorkingHours': 'Working hours',
      'infoBreakTime': 'Break',
      'infoDaysOff': 'Days off',
      'fieldOpeningTime': 'Opening time',
      'fieldClosingTime': 'Closing time',
      'fieldBreakStart': 'Break starts',
      'fieldBreakEnd': 'Break ends',
      'fieldClosedWeekdays': 'Days off',
      'noBreakLabel': 'No break',
      'noClosedWeekdaysLabel': 'Open every day',
      'invalidTimeField': '{field} has an invalid time',
      'scheduleTimeRangeError': 'Closing time must be later than opening time.',
      'scheduleBreakPairError':
          'Enter both break start and break end, or leave both empty.',
      'scheduleBreakRangeError':
          'The break must stay inside the working hours and follow the correct order.',
      'calendarEyebrow': 'Calendar view',
      'calendarTitle': 'Booking flow for the next 14 days',
      'calendarDescription':
          'Busy days, closed days, and the earliest appointment for each day are visible at a glance.',
      'calendarSelectedEyebrow': 'Selected day',
      'calendarSelectedTitle': 'Bookings for {date}',
      'calendarOpenLabel': 'Open',
      'calendarClosedLabel': 'Closed day',
      'calendarBookingsCount': '{count} bookings',
      'calendarFirstAppointment': 'First booking at {time}',
      'calendarNoAppointments': 'No bookings yet',
      'calendarEmptyTitle': 'No bookings on this day',
      'calendarEmptyBody':
          'There are no bookings for the selected date yet, or none match this status.',
      'analyticsEyebrow': 'Order analytics',
      'analyticsTitle': 'Revenue and workload snapshot',
      'analyticsDescription':
          'See revenue, prepayments, and the busiest service and vehicle segments for your workshop here.',
      'analyticsCompletedRevenue': 'Completed revenue',
      'analyticsPrepaymentCollected': 'Collected prepayments',
      'analyticsScheduledToday': 'Scheduled today',
      'analyticsCreatedToday': 'Created today',
      'analyticsTopServices': 'Top services',
      'analyticsTopVehicles': 'Top vehicles',
      'analyticsNoData': 'Not enough data yet.',
      'analyticsBookingsCount': '{count} orders',
      'weekdayShortMon': 'Mon',
      'weekdayShortTue': 'Tue',
      'weekdayShortWed': 'Wed',
      'weekdayShortThu': 'Thu',
      'weekdayShortFri': 'Fri',
      'weekdayShortSat': 'Sat',
      'weekdayShortSun': 'Sun',
      'requiredField': '{field} is required',
      'invalidNumber': '{field} must be a valid number',
      'numberMin': '{field} must be at least {min}',
      'statusUpdated': '{id} status changed to {status}',
      'rescheduleButton': 'Reschedule',
      'rescheduleDateLabel': 'New appointment time',
      'rescheduleDateRequired': 'Choose a new appointment time',
      'rescheduledFromLabel': 'Previous time',
      'rescheduledByLabel': 'Moved by',
      'rescheduledAtLabel': 'Moved at',
      'completedAtLabel': 'Completed at',
      'cancelButton': 'Cancel order',
      'cancelReasonLabel': 'Cancellation reason',
      'cancelledByLabel': 'Cancelled by',
      'cancelledAtLabel': 'Cancelled at',
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
    this.scheduledAt,
  });

  final String kind;
  final String workshopId;
  final String bookingId;
  final String reasonId;
  final DateTime? scheduledAt;
}
