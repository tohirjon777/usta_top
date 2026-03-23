import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../admin_auth.dart';
import '../booking_cancellation.dart';
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
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final List<WorkshopModel> workshops = _store.workshops();
    final List<BookingModel> allBookings = _store.bookings();
    final List<BookingModel> filtered = allBookings.where((BookingModel item) {
      if (workshopId.isNotEmpty && item.workshopId != workshopId) {
        return false;
      }
      if (status != 'all' && item.status.name != status) {
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

    final int upcomingCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.upcoming)
        .length;
    final int completedCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.completed)
        .length;
    final int cancelledCount = allBookings
        .where((BookingModel item) => item.status == BookingStatus.cancelled)
        .length;

    final Uri workshopsUri = _adminWorkshopsUri(lang: lang);
    final Uri bookingsUri = _adminBookingsUri(
      lang: lang,
      query: query,
      workshopId: workshopId,
      status: status,
    );
    final Uri resetUri = _adminBookingsUri(lang: lang);
    final Uri langUzUri = _adminBookingsUri(
      lang: 'uz',
      query: query,
      workshopId: workshopId,
      status: status,
    );
    final Uri langRuUri = _adminBookingsUri(
      lang: 'ru',
      query: query,
      workshopId: workshopId,
      status: status,
    );
    final Uri langEnUri = _adminBookingsUri(
      lang: 'en',
      query: query,
      workshopId: workshopId,
      status: status,
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
            final String statusClass = switch (item.status) {
              BookingStatus.upcoming => 'status-upcoming',
              BookingStatus.completed => 'status-completed',
              BookingStatus.cancelled => 'status-cancelled',
            };
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
      <strong>${_escapeHtml(item.price.toString())}k</strong>
    </div>
    <div class="meta-card">
      <span>${_escapeHtml(_text(lang, 'basePriceLabel'))}</span>
      <strong>${_escapeHtml(item.basePrice.toString())}k</strong>
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
	  ${item.status == BookingStatus.cancelled ? '<div class="cancel-meta">${_escapeHtml(_text(lang, 'cancelledByLabel'))}: <strong>${_escapeHtml(bookingCancellationActorLabel(item.cancelledByRole, lang))}</strong> · ${_escapeHtml(_text(lang, 'cancelReasonLabel'))}: <strong>${_escapeHtml(_cancellationReasonLabel(item, lang))}</strong></div>' : ''}
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
      grid-template-columns: repeat(4, minmax(0, 1fr));
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
      .hero-grid, .filter-grid, .meta-grid, .stats-grid {
        grid-template-columns: 1fr 1fr;
      }
    }

    @media (max-width: 760px) {
      .wrap { padding: 18px 12px 36px; }
      .hero-grid, .filter-grid, .meta-grid, .stats-grid {
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

    <section class="filter-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'filterEyebrow'))}</div>
      <form method="get" action="/admin/bookings">
        <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
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

    try {
      final BookingModel updated = nextStatus == BookingStatus.cancelled
          ? _store.cancelBookingByAdmin(
              bookingId: bookingId,
              reasonId: cancellationReasonId,
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
    if (booking.status != BookingStatus.upcoming) {
      return '<span class="muted">${_escapeHtml(_text(lang, 'noFurtherActions'))}</span>';
    }

    final String completeForm = _statusActionForm(
      booking,
      BookingStatus.completed,
      lang,
      query,
      workshopId,
      status,
    );
    final String cancelForm = _cancelActionForm(
      booking: booking,
      lang: lang,
      query: query,
      workshopId: workshopId,
      status: status,
    );
    return '$completeForm$cancelForm';
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
      return '<span class="muted">${_escapeHtml(_text(lang, 'cancelGuardHint', <String, Object>{'minutes': workshopCancellationLeadTime.inMinutes}))}</span>';
    }

    final String options = bookingCancellationReasons
        .where((BookingCancellationReason item) => item.id != 'customer_request')
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
    if (message != null && message.trim().isNotEmpty) {
      params['message'] = message.trim();
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/admin/bookings', queryParameters: params);
  }

  Uri _adminWorkshopsUri({String? lang}) => Uri(
        path: '/admin/workshops',
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

  String _vehicleSummary(BookingModel booking, String lang) {
    final String vehicleType = vehicleTypePricingById(booking.vehicleTypeId)
        .label(lang);
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
      'heroEyebrow': 'Zakaz Nazorati',
      'heroTitle':
          'Ilovadan tushgan zakazlarni bir joyda kuzating va statusini boshqaring.',
      'heroDescription':
          'Yangi buyurtma kelganda shu panelda mijoz, servis, vaqt va narx darhol ko‘rinadi. Ustaxona egasi uchun workshop bo‘yicha alohida inbox ham ochish mumkin.',
      'ownerEyebrow': 'Ustaxona Egasi',
      'ownerTitle': 'Workshop bo‘yicha kirish oqimi',
      'ownerFlowAll':
          'Ustaxona egasi uchun workshopni filterlab ishlatish eng qulay yo‘l. Pastdagi manzilni muayyan workshop bilan ochsangiz, faqat o‘sha servisning zakazlari chiqadi.',
      'ownerFlowSelected':
          'Tanlangan workshop uchun ustaxona egasi shu filtrlangan manzil orqali faqat o‘z zakazlarini ko‘radi: {link}',
      'statAll': 'Jami zakaz',
      'statAllSub': 'Barcha kelgan buyurtmalar soni.',
      'statUpcoming': 'Yangi / kutilmoqda',
      'statUpcomingSub': 'Hali bajarilmagan buyurtmalar.',
      'statCompleted': 'Yakunlangan',
      'statCompletedSub': 'Bajarib bo‘lingan buyurtmalar.',
      'statCancelled': 'Bekor qilingan',
      'statCancelledSub': 'Bekor bo‘lgan buyurtmalar.',
      'filterEyebrow': 'Qidiruv va Filtr',
      'searchLabel': 'Mijoz, telefon, servis yoki ID bo‘yicha qidiruv',
      'searchPlaceholder': 'Masalan: Tokhirjon, Cobalt, sedan, diagnostika...',
      'workshopFilter': 'Workshop filtri',
      'allWorkshops': 'Barcha avtoservislar',
      'statusFilter': 'Status filtri',
      'statusAll': 'Barcha statuslar',
      'statusUpcoming': 'Kutilmoqda',
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
      'appointmentLabel': 'Bron vaqti',
      'createdLabel': 'Tushgan vaqt',
      'ownerInboxLink': 'Shu workshop zakazlari',
      'callCustomer': 'Mijozga qo‘ng‘iroq',
      'statusUpdated': '{id} statusi {status} ga yangilandi',
      'cancelButton': 'Bekor qilish',
      'cancelReasonLabel': 'Bekor qilish sababi',
      'cancelledByLabel': 'Bekor qildi',
      'cancelGuardHint':
          'Bekor qilish faqat bron vaqtigacha kamida {minutes} daqiqa qolganda mumkin.',
      'noFurtherActions': 'Bu zakaz uchun qo‘shimcha amal yo‘q.',
      'unknownReason': 'Ko‘rsatilmagan',
    },
    'ru': <String, String>{
      'pageTitle': 'Панель заказов Usta Top',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Заказы Usta Top',
      'logout': 'Выйти',
      'workshopsTab': 'Автосервисы',
      'bookingsTab': 'Заказы',
      'heroEyebrow': 'Контроль Заказов',
      'heroTitle':
          'Следите за заказами из приложения в одном месте и управляйте их статусом.',
      'heroDescription':
          'Когда приходит новая заявка, здесь сразу видны клиент, услуга, время и стоимость. Для владельца сервиса можно открыть отдельный inbox по workshop.',
      'ownerEyebrow': 'Владелец Сервиса',
      'ownerTitle': 'Поток по конкретному workshop',
      'ownerFlowAll':
          'Для владельца сервиса удобнее всего работать через фильтр по workshop. Если открыть адрес ниже с конкретным workshop, будут показаны только его заказы.',
      'ownerFlowSelected':
          'Для выбранного workshop владелец может видеть только свои заказы по этому адресу: {link}',
      'statAll': 'Всего заказов',
      'statAllSub': 'Общее число входящих заявок.',
      'statUpcoming': 'Новые / ожидают',
      'statUpcomingSub': 'Заказы, которые еще не завершены.',
      'statCompleted': 'Завершены',
      'statCompletedSub': 'Заказы, по которым работа уже выполнена.',
      'statCancelled': 'Отменены',
      'statCancelledSub': 'Заказы со статусом отмены.',
      'filterEyebrow': 'Поиск и Фильтр',
      'searchLabel': 'Поиск по клиенту, телефону, услуге или ID',
      'searchPlaceholder': 'Например: Tokhirjon, Cobalt, sedan, диагностика...',
      'workshopFilter': 'Фильтр workshop',
      'allWorkshops': 'Все автосервисы',
      'statusFilter': 'Фильтр статуса',
      'statusAll': 'Все статусы',
      'statusUpcoming': 'Ожидает',
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
      'appointmentLabel': 'Время записи',
      'createdLabel': 'Время поступления',
      'ownerInboxLink': 'Заказы этого workshop',
      'callCustomer': 'Позвонить клиенту',
      'statusUpdated': 'Статус {id} обновлен на {status}',
      'cancelButton': 'Отменить заказ',
      'cancelReasonLabel': 'Причина отмены',
      'cancelledByLabel': 'Кто отменил',
      'cancelGuardHint':
          'Отмена доступна только если до записи осталось не меньше {minutes} минут.',
      'noFurtherActions': 'Для этого заказа больше нет доступных действий.',
      'unknownReason': 'Не указано',
    },
    'en': <String, String>{
      'pageTitle': 'Usta Top Orders Panel',
      'brandEyebrow': 'Service Desk',
      'brandTitle': 'Usta Top Orders',
      'logout': 'Log out',
      'workshopsTab': 'Workshops',
      'bookingsTab': 'Orders',
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
      'statAll': 'Total orders',
      'statAllSub': 'All incoming orders across the system.',
      'statUpcoming': 'New / upcoming',
      'statUpcomingSub': 'Orders that still need action.',
      'statCompleted': 'Completed',
      'statCompletedSub': 'Orders marked as finished.',
      'statCancelled': 'Cancelled',
      'statCancelledSub': 'Orders that were cancelled.',
      'filterEyebrow': 'Search and Filters',
      'searchLabel': 'Search by customer, phone, service, or ID',
      'searchPlaceholder': 'For example: Tokhirjon, Cobalt, sedan, diagnostics...',
      'workshopFilter': 'Workshop filter',
      'allWorkshops': 'All workshops',
      'statusFilter': 'Status filter',
      'statusAll': 'All statuses',
      'statusUpcoming': 'Upcoming',
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
      'appointmentLabel': 'Appointment time',
      'createdLabel': 'Received at',
      'ownerInboxLink': 'This workshop inbox',
      'callCustomer': 'Call customer',
      'statusUpdated': '{id} status was updated to {status}',
      'cancelButton': 'Cancel order',
      'cancelReasonLabel': 'Cancellation reason',
      'cancelledByLabel': 'Cancelled by',
      'cancelGuardHint':
          'Cancellation is allowed only when at least {minutes} minutes remain before the appointment.',
      'noFurtherActions': 'No further actions are available for this order.',
      'unknownReason': 'Not specified',
    },
  };
}
