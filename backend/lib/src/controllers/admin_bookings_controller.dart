import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../admin_auth.dart';
import '../booking_analytics.dart';
import '../booking_cancellation.dart';
import '../booking_payment_methods.dart';
import '../money.dart';
import '../models.dart';
import '../store.dart';
import '../user_notifications.dart';
import '../vehicle_types.dart';
import '../workshop_notifications.dart';

class AdminBookingsController {
  const AdminBookingsController(
    this._store, {
    required this.adminAuthService,
    required this.bookingsFilePath,
    required this.notificationsService,
    required this.userNotificationsService,
  });

  final InMemoryStore _store;
  final AdminAuthService adminAuthService;
  final String bookingsFilePath;
  final WorkshopNotificationsService notificationsService;
  final UserNotificationsService userNotificationsService;

  Response bookingsPage(Request request) {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String query = (request.url.queryParameters['q'] ?? '').trim();
    final String workshopId =
        (request.url.queryParameters['workshop'] ?? '').trim();
    final String status =
        _normalizeStatus(request.url.queryParameters['status']);
    final DateTime calendarDate =
        _parseCalendarDate(request.url.queryParameters['date']);
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final List<WorkshopModel> workshops = _store.workshops();
    final List<BookingModel> allBookings = _store.bookings();
    final List<BookingModel> filtered = allBookings.where((BookingModel item) {
      if (workshopId.isNotEmpty && item.workshopId != workshopId) {
        return false;
      }
      if (!_matchesStatusFilter(item.status, status)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final String q = query.toLowerCase();
      return item.customerName.toLowerCase().contains(q) ||
          item.customerPhone.toLowerCase().contains(q) ||
          item.workshopName.toLowerCase().contains(q) ||
          item.masterName.toLowerCase().contains(q) ||
          item.serviceName.toLowerCase().contains(q) ||
          item.vehicleModel.toLowerCase().contains(q) ||
          vehicleTypePricingById(item.vehicleTypeId)
              .label(lang)
              .toLowerCase()
              .contains(q) ||
          item.id.toLowerCase().contains(q);
    }).toList(growable: false);

    final int upcomingCount =
        _store.bookings(status: BookingStatus.upcoming).length;
    final int acceptedCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.accepted)
        .length;
    final int completedCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.completed)
        .length;
    final int cancelledCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.cancelled)
        .length;
    final List<BookingModel> analyticsBookings =
        (query.isEmpty && workshopId.isEmpty && status == 'all')
            ? allBookings
            : filtered;
    final BookingAnalyticsSummary analytics =
        buildBookingAnalytics(analyticsBookings);

    final Uri workshopsUri = _adminWorkshopsUri(lang: lang);
    final Uri bookingsUri = _adminBookingsUri(
      lang: lang,
      query: query,
      workshopId: workshopId,
      status: status,
    );
    final Uri reviewsUri = _adminReviewsUri(lang: lang);
    final Uri resetUri = _adminBookingsUri(lang: lang);
    final Uri langUzUri = _adminBookingsUri(
      lang: 'uz',
      query: query,
      workshopId: workshopId,
      status: status,
      date: calendarDate,
    );
    final Uri langRuUri = _adminBookingsUri(
      lang: 'ru',
      query: query,
      workshopId: workshopId,
      status: status,
      date: calendarDate,
    );
    final Uri langEnUri = _adminBookingsUri(
      lang: 'en',
      query: query,
      workshopId: workshopId,
      status: status,
      date: calendarDate,
    );
    final WorkshopModel? calendarWorkshop =
        workshopId.isEmpty ? null : _store.workshopById(workshopId);
    final String calendarSection = _calendarSectionHtml(
      lang: lang,
      bookings: filtered,
      workshop: calendarWorkshop,
      query: query,
      workshopId: workshopId,
      status: status,
      selectedDate: calendarDate,
    );
    final String analyticsSection = _analyticsSectionHtml(
      lang: lang,
      analytics: analytics,
    );

    final String workshopOptions = workshops.map((WorkshopModel workshop) {
      final bool selected = workshop.id == workshopId;
      return '<option value="${_escapeHtml(workshop.id)}"${selected ? ' selected' : ''}>${_escapeHtml(workshop.name)}</option>';
    }).join();

    final String bookingCards = filtered.isEmpty
        ? '''
<section class="empty-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'emptyEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'emptyTitle'))}</h3>
  <p>${_escapeHtml(_text(lang, query.isEmpty && workshopId.isEmpty && status == 'all' ? 'emptyBody' : 'emptyFilteredBody'))}</p>
</section>
'''
        : filtered.map((BookingModel item) {
            final String statusLabel = _statusLabel(item.status, lang);
            final String statusClass = _statusClass(item.status);
            final String workshopInboxUri = _adminBookingsUri(
              lang: lang,
              workshopId: item.workshopId,
            ).toString();

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
      <span>${_escapeHtml(_text(lang, 'garageLabel'))}</span>
      <strong>${_escapeHtml(item.workshopName)}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'masterLabel'))}</span>
      <strong>${_escapeHtml(item.masterName)}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'serviceLabel'))}</span>
      <strong>${_escapeHtml(item.serviceName)}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'vehicleLabel'))}</span>
      <strong>${_escapeHtml(_vehicleSummary(item, lang))}</strong>
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
      <span>${_escapeHtml(_text(lang, 'appointmentLabel'))}</span>
      <strong>${_escapeHtml(_formatDateTime(item.dateTime))}</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'createdLabel'))}</span>
      <strong>${_escapeHtml(_formatDateTime(item.createdAt))}</strong>
    </div>
  </div>

  <div class="booking-footer">
	    <div class="quick-links">
	      <a class="ghost-btn" href="${_escapeHtml(workshopInboxUri)}">${_escapeHtml(_text(lang, 'ownerInboxLink'))}</a>
	      ${item.customerPhone.isEmpty ? '' : '<a class="ghost-btn" href="tel:${_escapeHtml(item.customerPhone)}">${_escapeHtml(_text(lang, 'callCustomer'))}</a>'}
	    </div>
	    <div class="quick-links">
	      ${_statusActionsHtml(item, lang, query, workshopId, status)}
	    </div>
	  </div>
	  ${item.status == BookingStatus.rescheduled && item.previousDateTime != null ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'rescheduledFromLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.previousDateTime!))}</strong>${item.rescheduledByRole.isNotEmpty ? ' · ${_escapeHtml(_text(lang, 'rescheduledByLabel'))}: <strong>${_escapeHtml(bookingRescheduleActorLabel(item.rescheduledByRole, lang))}</strong>' : ''}${item.rescheduledAt != null ? ' · ${_escapeHtml(_text(lang, 'rescheduledAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.rescheduledAt!))}</strong>' : ''}</div>' : ''}
	  ${item.status == BookingStatus.completed && item.completedAt != null ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'completedAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.completedAt!))}</strong></div>' : ''}
	  <div class="cancel-meta">${_escapeHtml(_text(lang, 'paymentStatusLabel'))}: <strong>${_escapeHtml(_paymentStatusLabel(item.paymentStatus, lang))}</strong>${item.prepaymentAmount > 0 ? ' · ${_escapeHtml(_text(lang, 'prepaymentLabel'))}: <strong>${_escapeHtml(formatMoneyUzs(item.prepaymentAmount))}</strong> · ${_escapeHtml(_text(lang, 'remainingPaymentLabel'))}: <strong>${_escapeHtml(formatMoneyUzs(item.remainingAmount))}</strong>' : ''}${item.paymentMethod.trim().isNotEmpty ? ' · ${_escapeHtml(_text(lang, 'paymentMethodLabel'))}: <strong>${_escapeHtml(bookingPaymentMethodLabel(item.paymentMethod, lang: lang))}</strong>' : ''}</div>
	  ${item.status == BookingStatus.cancelled ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'cancelledByLabel'))}: <strong>${_escapeHtml(bookingCancellationActorLabel(item.cancelledByRole, lang))}</strong>${item.cancelledAt != null ? ' · ${_escapeHtml(_text(lang, 'cancelledAtLabel'))}: <strong>${_escapeHtml(_formatDateTime(item.cancelledAt!))}</strong>' : ''} · ${_escapeHtml(_text(lang, 'cancelReasonLabel'))}: <strong>${_escapeHtml(_cancellationReasonLabel(item, lang))}</strong></div>' : ''}
	</article>
	''';
          }).join();

    final String ownerFlow = workshopId.isEmpty
        ? _text(lang, 'ownerFlowAll')
        : _text(
            lang,
            'ownerFlowSelected',
            <String, Object>{
              'link': _adminBookingsUri(
                lang: lang,
                workshopId: workshopId,
                status: 'upcoming',
              ).toString(),
            },
          );

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'pageTitle'))}</title>
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
    button, input, select { font: inherit; }

    .wrap {
      max-width: 1440px;
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

    .top-actions, .tab-row, .filters, .stats-grid, .quick-links, .booking-footer {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .pill-link, .ghost-btn, .status-btn, .danger-btn, .cancel-select {
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.7);
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

    .hero-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.4fr) minmax(320px, 0.8fr);
      gap: 16px;
    }

    .hero-card p, .muted { color: var(--muted); line-height: 1.65; }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(5, minmax(0, 1fr));
    }

    .stat-card, .filter-card, .owner-card {
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
      padding: 22px;
      display: grid;
      gap: 16px;
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

    .layout {
      display: grid;
      gap: 16px;
    }

    .filter-card {
      display: grid;
      gap: 12px;
    }

    .filter-grid {
      display: grid;
      grid-template-columns: minmax(0, 1.4fr) minmax(220px, 0.8fr) minmax(200px, 0.8fr) auto auto;
      gap: 12px;
      align-items: end;
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

    .field input, .field select {
      min-height: 52px;
      border-radius: 16px;
      border: 1px solid var(--line);
      padding: 12px 14px;
      background: rgba(255, 255, 255, 0.9);
      color: var(--text);
      width: 100%;
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

    .owner-card {
      display: grid;
      gap: 10px;
    }

    .code-box {
      padding: 14px;
      border-radius: 18px;
      background: #201b19;
      color: #f8efe3;
      font-family: "SFMono-Regular", Menlo, monospace;
      overflow-x: auto;
      font-size: 13px;
      line-height: 1.5;
      margin: 0;
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
      grid-template-columns: repeat(3, minmax(0, 1fr));
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

    @media (max-width: 1100px) {
      .hero-grid, .filter-grid, .meta-grid, .stats-grid, .calendar-strip {
        grid-template-columns: 1fr 1fr;
      }
    }

    @media (max-width: 760px) {
      .wrap { padding: 18px 12px 36px; }
      .hero-grid, .filter-grid, .meta-grid, .stats-grid, .calendar-strip {
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
          <div class="brand-title">${_escapeHtml(_text(lang, 'brandTitle'))}</div>
        </div>
      </div>
      <div class="top-actions">
        <div class="tab-row">
          <a class="pill-link" href="${_escapeHtml(workshopsUri.toString())}">${_escapeHtml(_text(lang, 'workshopsTab'))}</a>
          <a class="pill-link active" href="${_escapeHtml(bookingsUri.toString())}">${_escapeHtml(_text(lang, 'bookingsTab'))}</a>
          <a class="pill-link" href="${_escapeHtml(reviewsUri.toString())}">${_escapeHtml(_text(lang, 'reviewsTab'))}</a>
        </div>
        <a class="pill-link${lang == 'uz' ? ' active' : ''}" href="${_escapeHtml(langUzUri.toString())}">UZ</a>
        <a class="pill-link${lang == 'ru' ? ' active' : ''}" href="${_escapeHtml(langRuUri.toString())}">RU</a>
        <a class="pill-link${lang == 'en' ? ' active' : ''}" href="${_escapeHtml(langEnUri.toString())}">EN</a>
        <form class="inline-form" method="post" action="/admin/logout?lang=${_escapeHtml(lang)}">
          <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'logout'))}</button>
        </form>
      </div>
    </div>

    <section class="hero-card">
      <div class="hero-grid">
        <div>
          <div class="eyebrow">${_escapeHtml(_text(lang, 'heroEyebrow'))}</div>
          <h1>${_escapeHtml(_text(lang, 'heroTitle'))}</h1>
          <p>${_escapeHtml(_text(lang, 'heroDescription'))}</p>
        </div>
        <div class="owner-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'ownerEyebrow'))}</div>
          <h2>${_escapeHtml(_text(lang, 'ownerTitle'))}</h2>
          <p>${_escapeHtml(ownerFlow)}</p>
          <pre class="code-box">${_escapeHtml(_adminBookingsUri(lang: lang, workshopId: workshopId.isEmpty ? 'w-1' : workshopId, status: 'upcoming').toString())}</pre>
        </div>
      </div>

      <div class="stats-grid">
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statAll'))}</div>
          <strong>${allBookings.length}</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statAllSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statUpcoming'))}</div>
          <strong>$upcomingCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statUpcomingSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statAccepted'))}</div>
          <strong>$acceptedCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statAcceptedSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statCompleted'))}</div>
          <strong>$completedCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statCompletedSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statCancelled'))}</div>
          <strong>$cancelledCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statCancelledSub'))}</div>
        </div>
      </div>
    </section>

    ${_flashHtml(message: message, error: error)}
    $calendarSection
    $analyticsSection

    <section class="filter-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'filterEyebrow'))}</div>
      <form method="get" action="/admin/bookings">
        <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
        <input type="hidden" name="date" value="${_escapeHtml('${calendarDate.year.toString().padLeft(4, '0')}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}')}">
        <div class="filter-grid">
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'searchLabel'))}</label>
            <input type="text" name="q" value="${_escapeHtml(query)}" placeholder="${_escapeHtml(_text(lang, 'searchPlaceholder'))}">
          </div>
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'workshopFilter'))}</label>
            <select name="workshop">
              <option value="">${_escapeHtml(_text(lang, 'allWorkshops'))}</option>
              $workshopOptions
            </select>
          </div>
          <div class="field">
            <label>${_escapeHtml(_text(lang, 'statusFilter'))}</label>
            <select name="status">
              <option value="all"${status == 'all' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'statusAll'))}</option>
              <option value="upcoming"${status == 'upcoming' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'statusUpcoming'))}</option>
              <option value="accepted"${status == 'accepted' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'statusAccepted'))}</option>
              <option value="completed"${status == 'completed' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'statusCompleted'))}</option>
              <option value="cancelled"${status == 'cancelled' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'statusCancelled'))}</option>
            </select>
          </div>
          <button class="pill-link active" type="submit">${_escapeHtml(_text(lang, 'applyFilters'))}</button>
          <a class="pill-link" href="${_escapeHtml(resetUri.toString())}">${_escapeHtml(_text(lang, 'resetFilters'))}</a>
        </div>
      </form>
    </section>

    <section class="layout">
      <div class="booking-list">$bookingCards</div>
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
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String query = (form['returnQ'] ?? '').trim();
    final String workshopId = (form['returnWorkshop'] ?? '').trim();
    final String status = _normalizeStatus(form['returnStatus']);
    final BookingStatus nextStatus = _statusFromRaw(form['bookingStatus']);
    final String cancellationReasonId =
        normalizeBookingCancellationReasonId(form['cancellationReason'] ?? '');
    final DateTime? scheduledAt = nextStatus == BookingStatus.rescheduled
        ? _parseDateTimeLocalField(form['scheduledAt'])
        : null;

    try {
      final BookingModel updated = nextStatus == BookingStatus.cancelled
          ? _store.cancelBookingByAdmin(
              bookingId: bookingId,
              reasonId: cancellationReasonId,
            )
          : nextStatus == BookingStatus.rescheduled
              ? _store.rescheduleBookingByAdmin(
                  bookingId: bookingId,
                  dateTime: scheduledAt ??
                      (throw StateError(_text(lang, 'rescheduleDateRequired'))),
                )
              : _store.updateBookingStatus(
                  bookingId: bookingId,
                  status: nextStatus,
                );
      await _store.saveBookings(bookingsFilePath);
      await _notifyWorkshopAboutStatusChange(updated);
      await _notifyUserAboutStatusChange(updated);
      return Response.seeOther(
        _adminBookingsUri(
          lang: lang,
          query: query,
          workshopId: workshopId,
          status: status,
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
        _adminBookingsUri(
          lang: lang,
          query: query,
          workshopId: workshopId,
          status: status,
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
        actor: 'Admin',
      );
    } on Exception catch (error) {
      stderr.writeln('Telegram admin status xabari yuborilmadi: $error');
    }
  }

  Future<void> _notifyUserAboutStatusChange(BookingModel booking) async {
    final UserModel? user = _store.userById(booking.userId);
    if (user == null) {
      return;
    }

    try {
      await userNotificationsService.sendBookingStatusNotification(
        user: user,
        booking: booking,
        actor: 'Admin',
      );
    } on Exception catch (error) {
      stderr.writeln('Push admin status xabari yuborilmadi: $error');
    }
  }

  String _statusActionsHtml(
    BookingModel booking,
    String lang,
    String query,
    String workshopId,
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
            query,
            workshopId,
            status,
          )
        : '';
    final String completeForm = _statusActionForm(
      booking,
      BookingStatus.completed,
      lang,
      query,
      workshopId,
      status,
    );
    final String rescheduleForm = _rescheduleActionForm(
      booking: booking,
      lang: lang,
      query: query,
      workshopId: workshopId,
      status: status,
    );
    final String cancelForm = _cancelActionForm(
      booking: booking,
      lang: lang,
      query: query,
      workshopId: workshopId,
      status: status,
    );
    return '$acceptForm$completeForm$rescheduleForm$cancelForm';
  }

  String _statusActionForm(
    BookingModel booking,
    BookingStatus nextStatus,
    String lang,
    String query,
    String workshopId,
    String status,
  ) {
    final bool isActive = booking.status == nextStatus;
    return '''
<form class="inline-form" method="post" action="/admin/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnQ" value="${_escapeHtml(query)}">
  <input type="hidden" name="returnWorkshop" value="${_escapeHtml(workshopId)}">
  <input type="hidden" name="returnStatus" value="${_escapeHtml(status)}">
  <input type="hidden" name="bookingStatus" value="${_escapeHtml(nextStatus.name)}">
  <button class="status-btn${isActive ? ' active' : ''}" type="submit">${_escapeHtml(_statusLabel(nextStatus, lang))}</button>
</form>
''';
  }

  String _rescheduleActionForm({
    required BookingModel booking,
    required String lang,
    required String query,
    required String workshopId,
    required String status,
  }) {
    return '''
<form class="inline-form cancel-form" method="post" action="/admin/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnQ" value="${_escapeHtml(query)}">
  <input type="hidden" name="returnWorkshop" value="${_escapeHtml(workshopId)}">
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
    required String query,
    required String workshopId,
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
<form class="inline-form cancel-form" method="post" action="/admin/bookings/${Uri.encodeComponent(booking.id)}/status?lang=${Uri.encodeQueryComponent(lang)}">
  <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
  <input type="hidden" name="returnQ" value="${_escapeHtml(query)}">
  <input type="hidden" name="returnWorkshop" value="${_escapeHtml(workshopId)}">
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

  String _calendarSectionHtml({
    required String lang,
    required List<BookingModel> bookings,
    required WorkshopModel? workshop,
    required String query,
    required String workshopId,
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
        ..sort((BookingModel a, BookingModel b) =>
            a.dateTime.compareTo(b.dateTime));
      final bool isClosedDay = workshop != null &&
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
      final Uri dayUri = _adminBookingsUri(
        lang: lang,
        query: query,
        workshopId: workshopId,
        status: status,
        date: date,
      );
      dayCards.add('''
<a class="calendar-day${_sameDate(date, selectedDate) ? ' active' : ''}${isClosedDay ? ' closed' : ''}" href="${_escapeHtml(dayUri.toString())}">
  <div class="eyebrow">${_escapeHtml(_weekdayShort(date.weekday, lang))}</div>
  <strong>${_escapeHtml(_formatShortDate(date))}</strong>
  <span class="calendar-tag $tagClass">${_escapeHtml(tagLabel)}</span>
  <div class="mini">${_escapeHtml(detail)}</div>
</a>
''');
    }

    final List<BookingModel> selectedDayBookings = bookings
        .where((BookingModel item) {
      return _sameDate(item.dateTime.toLocal(), selectedDate);
    }).toList(growable: false)
      ..sort(
          (BookingModel a, BookingModel b) => a.dateTime.compareTo(b.dateTime));
    final String agendaHtml = selectedDayBookings.isEmpty
        ? '''
<section class="empty-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarSelectedEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'calendarEmptyTitle'))}</h3>
  <p>${_escapeHtml(_text(lang, 'calendarEmptyBody'))}</p>
</section>
'''
        : selectedDayBookings.map((BookingModel item) {
            final String workshopSuffix = workshopId.isEmpty
                ? ' • ${_escapeHtml(item.workshopName)}'
                : '';
            return '''
<article class="agenda-item">
  <div class="agenda-top">
    <strong>${_escapeHtml(_formatClock(item.dateTime))} • ${_escapeHtml(item.customerName.isEmpty ? _text(lang, 'unknownCustomer') : item.customerName)}</strong>
    <span class="status-pill ${_statusClass(item.status)}">${_escapeHtml(_statusLabel(item.status, lang))}</span>
  </div>
  <div class="agenda-meta">
    ${_escapeHtml(item.serviceName)} • ${_escapeHtml(_vehicleSummary(item, lang))}$workshopSuffix<br>
    ${_escapeHtml(_text(lang, 'priceLabel'))}: ${_escapeHtml(formatMoneyUzs(item.price))}
  </div>
</article>
''';
          }).join();

    return '''
<section class="calendar-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarEyebrow'))}</div>
  <h2>${_escapeHtml(_text(lang, 'calendarTitle'))}</h2>
  <p class="muted">${_escapeHtml(_text(lang, 'calendarDescription'))}</p>
  <div class="calendar-strip">${dayCards.join()}</div>
  <div class="eyebrow">${_escapeHtml(_text(lang, 'calendarSelectedEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'calendarSelectedTitle', <String, Object>{
          'date': _formatShortDate(selectedDate)
        }))}</h3>
  <div class="agenda-list">$agendaHtml</div>
</section>
''';
  }

  String _analyticsSectionHtml({
    required String lang,
    required BookingAnalyticsSummary analytics,
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
<section class="filter-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'analyticsTitle'))}</h3>
  <p class="muted">${_escapeHtml(_text(lang, 'analyticsDescription'))}</p>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsCompletedRevenue'))}</div>
      <strong>${_escapeHtml(formatMoneyUzs(analytics.completedRevenue))}</strong>
      <div class="muted">${_escapeHtml(_text(lang, 'statCompletedSub'))}</div>
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
      <div class="muted">${_escapeHtml(_text(lang, 'statAllSub'))}</div>
    </div>
  </div>
  <div class="meta-grid">
    <div class="meta-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsTopServices'))}</div>
      $topServices
    </div>
    <div class="meta-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'analyticsTopVehicles'))}</div>
      $topVehicles
    </div>
  </div>
</section>
''';
  }

  Response? _requireAdmin(Request request) {
    if (adminAuthService.isAuthenticated(request)) {
      return null;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    return Response.seeOther(
      Uri(
        path: '/admin/login',
        queryParameters: <String, String>{
          'lang': lang,
          'next': _requestPathWithQuery(request, lang: lang),
        },
      ),
    );
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

  Uri _adminBookingsUri({
    String? lang,
    String? query,
    String? workshopId,
    String? status,
    DateTime? date,
    String? message,
    String? error,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (workshopId != null && workshopId.trim().isNotEmpty) {
      params['workshop'] = workshopId.trim();
    }
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
    return Uri(path: '/admin/bookings', queryParameters: params);
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

  String _weekdayShort(int weekday, String lang) {
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

  Uri _adminWorkshopsUri({String? lang}) => Uri(
        path: '/admin/workshops',
        queryParameters: <String, String>{
          'lang': _normalizeLang(lang),
        },
      );

  Uri _adminReviewsUri({String? lang}) => Uri(
        path: '/admin/reviews',
        queryParameters: <String, String>{
          'lang': _normalizeLang(lang),
        },
      );

  String _requestPathWithQuery(Request request, {required String lang}) {
    final String path = request.url.path.startsWith('/')
        ? request.url.path
        : '/${request.url.path}';
    final Map<String, String> params = <String, String>{
      ...request.url.queryParameters,
    };
    params.putIfAbsent('lang', () => _normalizeLang(lang));
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
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

  String _vehicleSummary(BookingModel booking, String lang) {
    final String vehicleType =
        vehicleTypePricingById(booking.vehicleTypeId).label(lang);
    final String vehicleModel = booking.vehicleModel.trim();
    if (vehicleModel.isEmpty) {
      return vehicleType;
    }
    return '$vehicleModel • $vehicleType';
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

  bool _matchesStatusFilter(BookingStatus bookingStatus, String filter) {
    if (filter == 'all') {
      return true;
    }
    if (filter == 'upcoming') {
      return bookingStatus == BookingStatus.upcoming ||
          bookingStatus == BookingStatus.rescheduled;
    }
    return bookingStatus.name == filter;
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
      'pageTitle': 'Usta Top Zakazlar Paneli',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Usta Top Zakazlar',
      'logout': 'Chiqish',
      'workshopsTab': 'Avtoservislar',
      'bookingsTab': 'Zakazlar',
      'reviewsTab': 'Sharhlar',
      'heroEyebrow': 'Zakaz Nazorati',
      'heroTitle':
          'Ilovadan tushgan zakazlarni bir joyda kuzating va statusini boshqaring.',
      'heroDescription':
          'Yangi buyurtma kelganda shu panelda mijoz, servis, vaqt va narx darhol ko‘rinadi. Ustaxona egasi uchun ustaxona bo‘yicha alohida inbox ham ochish mumkin.',
      'ownerEyebrow': 'Ustaxona Egasi',
      'ownerTitle': 'Ustaxona bo‘yicha kirish oqimi',
      'ownerFlowAll':
          'Ustaxona egasi uchun ustaxonani filterlab ishlatish eng qulay yo‘l. Pastdagi manzilni muayyan ustaxona bilan ochsangiz, faqat o‘sha servisning zakazlari chiqadi.',
      'ownerFlowSelected':
          'Tanlangan ustaxona uchun ustaxona egasi shu filtrlangan manzil orqali faqat o‘z zakazlarini ko‘radi: {link}',
      'calendarEyebrow': 'Kalendar ko‘rinishi',
      'calendarTitle': 'Keyingi 14 kunlik bandlik',
      'calendarDescription':
          'Kunlar bo‘yicha yuklama va tanlangan sana uchun agenda shu yerda ko‘rinadi.',
      'calendarSelectedEyebrow': 'Tanlangan kun',
      'calendarSelectedTitle': '{date} kunining agendasi',
      'calendarOpenLabel': 'Bo‘sh',
      'calendarClosedLabel': 'Dam olish',
      'calendarBookingsCount': '{count} ta zakaz',
      'calendarFirstAppointment': 'Birinchi bron: {time}',
      'calendarNoAppointments': 'Zakaz yo‘q',
      'calendarEmptyTitle': 'Bu kun uchun zakaz yo‘q',
      'calendarEmptyBody':
          'Tanlangan sana bo‘yicha hozircha birorta buyurtma ko‘rinmadi.',
      'weekdayShortMon': 'Du',
      'weekdayShortTue': 'Se',
      'weekdayShortWed': 'Cho',
      'weekdayShortThu': 'Pa',
      'weekdayShortFri': 'Ju',
      'weekdayShortSat': 'Sha',
      'weekdayShortSun': 'Yak',
      'statAll': 'Jami zakaz',
      'statAllSub': 'Barcha kelgan buyurtmalar soni.',
      'statUpcoming': 'Yangi / kutilmoqda',
      'statUpcomingSub': 'Hali bajarilmagan buyurtmalar.',
      'statAccepted': 'Qabul qilindi',
      'statAcceptedSub': 'Usta yoki admin qabul qilgan zakazlar.',
      'statCompleted': 'Yakunlangan',
      'statCompletedSub': 'Bajarib bo‘lingan buyurtmalar.',
      'statCancelled': 'Bekor qilingan',
      'statCancelledSub': 'Bekor bo‘lgan buyurtmalar.',
      'filterEyebrow': 'Qidiruv va Filtr',
      'searchLabel': 'Mijoz, telefon, servis yoki ID bo‘yicha qidiruv',
      'searchPlaceholder': 'Masalan: Tokhirjon, Cobalt, sedan, diagnostika...',
      'workshopFilter': 'Ustaxona filtri',
      'allWorkshops': 'Barcha avtoservislar',
      'statusFilter': 'Status filtri',
      'statusAll': 'Barcha statuslar',
      'statusUpcoming': 'Kutilmoqda',
      'statusRescheduled': 'Ko‘chirildi',
      'statusAccepted': 'Qabul qilindi',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'applyFilters': 'Filtrni qo‘llash',
      'resetFilters': 'Tozalash',
      'emptyEyebrow': 'Zakaz Yo‘q',
      'emptyTitle': 'Mos zakaz topilmadi',
      'emptyBody': 'Hozircha ilovadan hali birorta zakaz tushmagan.',
      'emptyFilteredBody':
          'Tanlangan qidiruv yoki filtr bo‘yicha mos zakaz topilmadi.',
      'orderId': 'Zakaz ID',
      'unknownCustomer': 'Mijoz nomi yo‘q',
      'noPhone': 'Telefon ko‘rsatilmagan',
      'garageLabel': 'Avtoservis',
      'masterLabel': 'Mas’ul usta',
      'serviceLabel': 'Xizmat',
      'vehicleLabel': 'Mashina',
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
      'appointmentLabel': 'Bron vaqti',
      'createdLabel': 'Tushgan vaqt',
      'ownerInboxLink': 'Shu ustaxona zakazlari',
      'callCustomer': 'Mijozga qo‘ng‘iroq',
      'statusUpdated': '{id} statusi {status} ga yangilandi',
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
      'analyticsEyebrow': 'Zakaz analitikasi',
      'analyticsTitle': 'Tushum va yuklama ko‘rinishi',
      'analyticsDescription':
          'Filtrlangan zakazlar bo‘yicha tushum, avans va eng ko‘p kelayotgan yo‘nalishlar shu yerda jamlanadi.',
      'analyticsCompletedRevenue': 'Yakunlangan tushum',
      'analyticsPrepaymentCollected': 'Yig‘ilgan avans',
      'analyticsScheduledToday': 'Bugungi bronlar',
      'analyticsCreatedToday': 'Bugun tushgan',
      'analyticsTopServices': 'Top xizmatlar',
      'analyticsTopVehicles': 'Top mashinalar',
      'analyticsNoData': 'Hozircha yetarli ma’lumot yo‘q.',
      'analyticsBookingsCount': '{count} ta zakaz',
    },
    'ru': <String, String>{
      'pageTitle': 'Панель заказов Usta Top',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Заказы Usta Top',
      'logout': 'Выйти',
      'workshopsTab': 'Автосервисы',
      'bookingsTab': 'Заказы',
      'reviewsTab': 'Отзывы',
      'heroEyebrow': 'Контроль Заказов',
      'heroTitle':
          'Следите за заказами из приложения в одном месте и управляйте их статусом.',
      'heroDescription':
          'Когда приходит новая заявка, здесь сразу видны клиент, услуга, время и стоимость. Для владельца сервиса можно открыть отдельный inbox по автосервису.',
      'ownerEyebrow': 'Владелец Сервиса',
      'ownerTitle': 'Поток по конкретному автосервису',
      'ownerFlowAll':
          'Для владельца сервиса удобнее всего работать через фильтр по автосервису. Если открыть адрес ниже с конкретным автосервисом, будут показаны только его заказы.',
      'ownerFlowSelected':
          'Для выбранного автосервиса владелец может видеть только свои заказы по этому адресу: {link}',
      'calendarEyebrow': 'Календарный вид',
      'calendarTitle': 'Загрузка на ближайшие 14 дней',
      'calendarDescription':
          'Здесь видно нагрузку по дням и agenda для выбранной даты.',
      'calendarSelectedEyebrow': 'Выбранный день',
      'calendarSelectedTitle': 'Agenda на {date}',
      'calendarOpenLabel': 'Свободно',
      'calendarClosedLabel': 'Выходной',
      'calendarBookingsCount': '{count} заказов',
      'calendarFirstAppointment': 'Первая запись: {time}',
      'calendarNoAppointments': 'Заказов нет',
      'calendarEmptyTitle': 'На этот день заказов нет',
      'calendarEmptyBody':
          'Для выбранной даты сейчас не найдено ни одной заявки.',
      'weekdayShortMon': 'Пн',
      'weekdayShortTue': 'Вт',
      'weekdayShortWed': 'Ср',
      'weekdayShortThu': 'Чт',
      'weekdayShortFri': 'Пт',
      'weekdayShortSat': 'Сб',
      'weekdayShortSun': 'Вс',
      'statAll': 'Всего заказов',
      'statAllSub': 'Общее число входящих заявок.',
      'statUpcoming': 'Новые / ожидают',
      'statUpcomingSub': 'Заказы, которые еще не завершены.',
      'statAccepted': 'Приняты',
      'statAcceptedSub': 'Заказы, уже принятые мастером или админом.',
      'statCompleted': 'Завершены',
      'statCompletedSub': 'Заказы, по которым работа уже выполнена.',
      'statCancelled': 'Отменены',
      'statCancelledSub': 'Заказы со статусом отмены.',
      'filterEyebrow': 'Поиск и Фильтр',
      'searchLabel': 'Поиск по клиенту, телефону, услуге или ID',
      'searchPlaceholder': 'Например: Tokhirjon, Cobalt, sedan, диагностика...',
      'workshopFilter': 'Фильтр автосервиса',
      'allWorkshops': 'Все автосервисы',
      'statusFilter': 'Фильтр статуса',
      'statusAll': 'Все статусы',
      'statusUpcoming': 'Ожидает',
      'statusRescheduled': 'Перенесен',
      'statusAccepted': 'Принят',
      'statusCompleted': 'Завершен',
      'statusCancelled': 'Отменен',
      'applyFilters': 'Применить',
      'resetFilters': 'Сбросить',
      'emptyEyebrow': 'Нет Заказов',
      'emptyTitle': 'Подходящий заказ не найден',
      'emptyBody': 'Пока из приложения не поступило ни одного заказа.',
      'emptyFilteredBody': 'По выбранному фильтру или поиску заказ не найден.',
      'orderId': 'ID заказа',
      'unknownCustomer': 'Имя клиента не указано',
      'noPhone': 'Телефон не указан',
      'garageLabel': 'Автосервис',
      'masterLabel': 'Ответственный мастер',
      'serviceLabel': 'Услуга',
      'vehicleLabel': 'Машина',
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
      'appointmentLabel': 'Время записи',
      'createdLabel': 'Время поступления',
      'ownerInboxLink': 'Заказы этого автосервиса',
      'callCustomer': 'Позвонить клиенту',
      'statusUpdated': 'Статус {id} обновлен на {status}',
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
      'analyticsEyebrow': 'Аналитика заказов',
      'analyticsTitle': 'Срез по выручке и нагрузке',
      'analyticsDescription':
          'Здесь собраны выручка, авансы и самые частые направления по отфильтрованным заказам.',
      'analyticsCompletedRevenue': 'Выручка по завершенным',
      'analyticsPrepaymentCollected': 'Собранный аванс',
      'analyticsScheduledToday': 'Брони на сегодня',
      'analyticsCreatedToday': 'Создано сегодня',
      'analyticsTopServices': 'Топ услуг',
      'analyticsTopVehicles': 'Топ машин',
      'analyticsNoData': 'Пока недостаточно данных.',
      'analyticsBookingsCount': '{count} заказов',
    },
    'en': <String, String>{
      'pageTitle': 'Usta Top Orders Panel',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Usta Top Orders',
      'logout': 'Log out',
      'workshopsTab': 'Workshops',
      'bookingsTab': 'Orders',
      'reviewsTab': 'Reviews',
      'heroEyebrow': 'Order Control',
      'heroTitle':
          'Track orders coming from the app in one place and manage their status.',
      'heroDescription':
          'When a new order arrives, the customer, service, time, and price are shown here immediately. You can also open a workshop-specific inbox for the owner.',
      'ownerEyebrow': 'Workshop Owner',
      'ownerTitle': 'Workshop-specific flow',
      'ownerFlowAll':
          'The cleanest flow for a workshop owner is to work from a workshop-filtered inbox. Open the URL below with a specific workshop to show only that service point’s orders.',
      'ownerFlowSelected':
          'For the selected workshop, the owner can watch only their own orders with this filtered URL: {link}',
      'calendarEyebrow': 'Calendar view',
      'calendarTitle': 'Next 14 days workload',
      'calendarDescription':
          'See day-by-day load and the agenda for the selected date here.',
      'calendarSelectedEyebrow': 'Selected day',
      'calendarSelectedTitle': 'Agenda for {date}',
      'calendarOpenLabel': 'Open',
      'calendarClosedLabel': 'Closed',
      'calendarBookingsCount': '{count} orders',
      'calendarFirstAppointment': 'First slot: {time}',
      'calendarNoAppointments': 'No orders',
      'calendarEmptyTitle': 'No orders for this day',
      'calendarEmptyBody':
          'There are no visible orders for the selected date yet.',
      'weekdayShortMon': 'Mon',
      'weekdayShortTue': 'Tue',
      'weekdayShortWed': 'Wed',
      'weekdayShortThu': 'Thu',
      'weekdayShortFri': 'Fri',
      'weekdayShortSat': 'Sat',
      'weekdayShortSun': 'Sun',
      'statAll': 'Total orders',
      'statAllSub': 'All incoming orders across the system.',
      'statUpcoming': 'New / upcoming',
      'statUpcomingSub': 'Orders that still need action.',
      'statAccepted': 'Accepted',
      'statAcceptedSub': 'Orders already accepted by staff.',
      'statCompleted': 'Completed',
      'statCompletedSub': 'Orders marked as finished.',
      'statCancelled': 'Cancelled',
      'statCancelledSub': 'Orders that were cancelled.',
      'filterEyebrow': 'Search and Filters',
      'searchLabel': 'Search by customer, phone, service, or ID',
      'searchPlaceholder':
          'For example: Tokhirjon, Cobalt, sedan, diagnostics...',
      'workshopFilter': 'Workshop filter',
      'allWorkshops': 'All workshops',
      'statusFilter': 'Status filter',
      'statusAll': 'All statuses',
      'statusUpcoming': 'Upcoming',
      'statusRescheduled': 'Rescheduled',
      'statusAccepted': 'Accepted',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'applyFilters': 'Apply filters',
      'resetFilters': 'Reset',
      'emptyEyebrow': 'No Orders',
      'emptyTitle': 'No matching order found',
      'emptyBody': 'No orders have arrived from the app yet.',
      'emptyFilteredBody':
          'No matching order was found for the selected filters or search.',
      'orderId': 'Order ID',
      'unknownCustomer': 'Unknown customer',
      'noPhone': 'No phone provided',
      'garageLabel': 'Workshop',
      'masterLabel': 'Lead mechanic',
      'serviceLabel': 'Service',
      'vehicleLabel': 'Vehicle',
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
      'appointmentLabel': 'Appointment time',
      'createdLabel': 'Received at',
      'ownerInboxLink': 'This workshop inbox',
      'callCustomer': 'Call customer',
      'statusUpdated': '{id} status was updated to {status}',
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
      'analyticsEyebrow': 'Order analytics',
      'analyticsTitle': 'Revenue and workload snapshot',
      'analyticsDescription':
          'Revenue, prepayments, and the busiest service and vehicle segments are summarized here for the filtered orders.',
      'analyticsCompletedRevenue': 'Completed revenue',
      'analyticsPrepaymentCollected': 'Collected prepayments',
      'analyticsScheduledToday': 'Scheduled today',
      'analyticsCreatedToday': 'Created today',
      'analyticsTopServices': 'Top services',
      'analyticsTopVehicles': 'Top vehicles',
      'analyticsNoData': 'Not enough data yet.',
      'analyticsBookingsCount': '{count} orders',
    },
  };
}
