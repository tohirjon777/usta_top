import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../admin_auth.dart';
import '../models.dart';
import '../store.dart';
import '../workshop_notifications.dart';

class AdminReviewsController {
  const AdminReviewsController(
    this._store, {
    required this.adminAuthService,
    required this.reviewsFilePath,
    required this.workshopsFilePath,
    required this.notificationsService,
  });

  final InMemoryStore _store;
  final AdminAuthService adminAuthService;
  final String reviewsFilePath;
  final String workshopsFilePath;
  final WorkshopNotificationsService notificationsService;

  Response reviewsPage(Request request) {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String query = (request.url.queryParameters['q'] ?? '').trim();
    final String workshopId =
        (request.url.queryParameters['workshop'] ?? '').trim();
    final String replyStatus =
        _normalizeReplyStatus(request.url.queryParameters['reply']);
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final List<WorkshopModel> workshops = _store.workshops();
    final List<_AdminReviewEntry> allEntries = workshops
        .expand(
          (WorkshopModel workshop) => _store
              .reviewsForWorkshop(
                workshopId: workshop.id,
                includeHidden: true,
              )
              .map(
                (WorkshopReviewModel review) => _AdminReviewEntry(
                  workshop: workshop,
                  review: review,
                ),
              ),
        )
        .toList(growable: false)
      ..sort((_AdminReviewEntry a, _AdminReviewEntry b) {
        if (a.review.hasOwnerReply == b.review.hasOwnerReply) {
          return b.review.createdAt.compareTo(a.review.createdAt);
        }
        return a.review.hasOwnerReply ? 1 : -1;
      });

    final List<_AdminReviewEntry> filtered = allEntries.where(
      (_AdminReviewEntry entry) {
        if (workshopId.isNotEmpty && entry.workshop.id != workshopId) {
          return false;
        }
        if (replyStatus == 'pending' && entry.review.hasOwnerReply) {
          return false;
        }
        if (replyStatus == 'answered' && !entry.review.hasOwnerReply) {
          return false;
        }
        if (query.isEmpty) {
          return true;
        }

        final String q = query.toLowerCase();
        return entry.workshop.name.toLowerCase().contains(q) ||
            entry.workshop.address.toLowerCase().contains(q) ||
            entry.review.serviceName.toLowerCase().contains(q) ||
            entry.review.customerName.toLowerCase().contains(q) ||
            entry.review.customerPhone.toLowerCase().contains(q) ||
            entry.review.comment.toLowerCase().contains(q) ||
            entry.review.ownerReply.toLowerCase().contains(q) ||
            entry.review.hiddenReason.toLowerCase().contains(q) ||
            entry.review.id.toLowerCase().contains(q);
      },
    ).toList(growable: false);

    final int totalCount = allEntries.length;
    final int pendingCount = allEntries
        .where(
          (_AdminReviewEntry item) =>
              !item.review.hasOwnerReply && !item.review.isHidden,
        )
        .length;
    final int answeredCount = allEntries
        .where(
          (_AdminReviewEntry item) =>
              item.review.hasOwnerReply && !item.review.isHidden,
        )
        .length;
    final int hiddenCount = allEntries
        .where((_AdminReviewEntry item) => item.review.isHidden)
        .length;

    final Uri workshopsUri = _adminWorkshopsUri(lang: lang);
    final Uri bookingsUri = _adminBookingsUri(lang: lang);
    final Uri reviewsUri = _adminReviewsUri(
      lang: lang,
      query: query,
      workshopId: workshopId,
      replyStatus: replyStatus,
    );
    final Uri resetUri = _adminReviewsUri(lang: lang);
    final Uri langUzUri = _adminReviewsUri(
      lang: 'uz',
      query: query,
      workshopId: workshopId,
      replyStatus: replyStatus,
    );
    final Uri langRuUri = _adminReviewsUri(
      lang: 'ru',
      query: query,
      workshopId: workshopId,
      replyStatus: replyStatus,
    );
    final Uri langEnUri = _adminReviewsUri(
      lang: 'en',
      query: query,
      workshopId: workshopId,
      replyStatus: replyStatus,
    );

    final String workshopOptions = workshops.map((WorkshopModel workshop) {
      final bool selected = workshop.id == workshopId;
      return '<option value="${_escapeHtml(workshop.id)}"${selected ? ' selected' : ''}>${_escapeHtml(workshop.name)}</option>';
    }).join();

    final String reviewCards = filtered.isEmpty
        ? '''
<section class="empty-card">
  <div class="eyebrow">${_escapeHtml(_text(lang, 'emptyEyebrow'))}</div>
  <h3>${_escapeHtml(_text(lang, 'emptyTitle'))}</h3>
  <p>${_escapeHtml(_text(lang, query.isEmpty && workshopId.isEmpty && replyStatus == 'all' ? 'emptyBody' : 'emptyFilteredBody'))}</p>
</section>
'''
        : filtered.map((_AdminReviewEntry entry) {
            final WorkshopReviewModel review = entry.review;
            final WorkshopModel workshop = entry.workshop;
            final bool answered = review.hasOwnerReply;
            final bool hidden = review.isHidden;
            final Uri workshopUri = _adminWorkshopsUri(
              lang: lang,
              query: workshop.name,
            );
            final Uri workshopBookingsUri = _adminBookingsUri(
              lang: lang,
              workshopId: workshop.id,
              status: 'upcoming',
            );
            final Uri ownerLoginUri = _ownerLoginUri(
              lang: lang,
              workshopId: workshop.id,
            );
            final String actionFields = _reviewActionHiddenFields(
              lang: lang,
              query: query,
              workshopId: workshopId,
              replyStatus: replyStatus,
            );
            final String ownerReplyMeta = review.ownerReplyAt == null
                ? _replySourceLabel(review.ownerReplySource, lang)
                : '${_replySourceLabel(review.ownerReplySource, lang)} • ${_formatDateTime(review.ownerReplyAt!)}';
            final String replyHtml = hidden
                ? '''
<div class="reply-box hidden-box">
  <strong>${_escapeHtml(_text(lang, 'hiddenReviewTitle'))}</strong>
  <div class="reply-meta">${_escapeHtml(_moderationReasonLabel(review.hiddenReason, lang))}</div>
  <div class="reply-meta">${_escapeHtml(_hiddenActorLabel(review.hiddenByRole, lang))}${review.hiddenAt == null ? '' : ' • ${_escapeHtml(_formatDateTime(review.hiddenAt!))}'}</div>
</div>
'''
                : answered
                ? '''
<div class="reply-box">
  <strong>${_escapeHtml(_text(lang, 'ownerReplyLabel'))}</strong>
  <div class="review-comment">${_escapeHtml(review.ownerReply)}</div>
  <div class="reply-meta">${_escapeHtml(ownerReplyMeta)}</div>
</div>
'''
                : '''
<div class="reply-box pending-box">
  <strong>${_escapeHtml(_text(lang, 'pendingReplyTitle'))}</strong>
  <div class="reply-meta">${_escapeHtml(_text(lang, 'pendingReplyBody'))}</div>
</div>
''';
            final String moderationAction = hidden
                ? '''
<form class="inline-form" method="post" action="/admin/reviews/${Uri.encodeComponent(review.id)}/unhide?lang=${Uri.encodeQueryComponent(lang)}">
  $actionFields
  <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'unhideReviewButton'))}</button>
</form>
'''
                : '''
<form class="inline-form" method="post" action="/admin/reviews/${Uri.encodeComponent(review.id)}/hide?lang=${Uri.encodeQueryComponent(lang)}">
  $actionFields
  <input type="hidden" name="reason" value="admin_flagged">
  <button class="danger-btn" type="submit">${_escapeHtml(_text(lang, 'hideReviewButton'))}</button>
</form>
''';
            final String reminderAction = (!hidden && !answered)
                ? '''
<form class="inline-form" method="post" action="/admin/reviews/${Uri.encodeComponent(review.id)}/remind?lang=${Uri.encodeQueryComponent(lang)}">
  $actionFields
  <button class="warning-btn" type="submit">${_escapeHtml(_text(lang, 'remindOwnerButton'))}</button>
</form>
'''
                : '';
            final String statusKey = hidden
                ? 'replyHidden'
                : (answered ? 'replyAnswered' : 'replyPending');
            final String statusClass = hidden
                ? 'status-hidden'
                : (answered ? 'status-answered' : 'status-pending');

            return '''
<article class="review-card ${hidden ? 'hidden' : (answered ? 'answered' : 'pending')}">
  <div class="review-head">
    <div class="review-copy">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'reviewIdLabel'))} ${_escapeHtml(review.id)}</div>
      <h3>${_escapeHtml(review.serviceName)}</h3>
      <div class="review-meta">
        <span>${_escapeHtml(workshop.name)}</span>
        <span>${_escapeHtml(review.customerName.isEmpty ? _text(lang, 'unknownCustomer') : review.customerName)}</span>
        <span>${_escapeHtml(review.customerPhone.isEmpty ? _text(lang, 'noPhone') : review.customerPhone)}</span>
        <span>${_escapeHtml(_formatDateTime(review.createdAt))}</span>
      </div>
    </div>
    <div class="review-side">
      <span class="status-pill $statusClass">${_escapeHtml(_text(lang, statusKey))}</span>
      <div class="stars">${_escapeHtml(_reviewStars(review.rating))} ${_escapeHtml(review.rating.toString())}/5</div>
    </div>
  </div>

  <div class="review-comment">${_escapeHtml(review.comment)}</div>
  $replyHtml

  <div class="quick-links">
    <a class="pill-link" href="${_escapeHtml(workshopUri.toString())}">${_escapeHtml(_text(lang, 'workshopLink'))}</a>
    <a class="pill-link" href="${_escapeHtml(workshopBookingsUri.toString())}">${_escapeHtml(_text(lang, 'bookingsLink'))}</a>
    <a class="pill-link" href="${_escapeHtml(ownerLoginUri.toString())}">${_escapeHtml(_text(lang, 'ownerLink'))}</a>
    $reminderAction
    $moderationAction
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

    .topbar, .hero-card, .card, .review-card, .empty-card {
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

    .top-actions, .tab-row, .filters, .stats-grid, .quick-links {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .pill-link, .ghost-btn, .submit-btn, .danger-btn, .warning-btn, select, input {
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.72);
      border-radius: 999px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 700;
      color: var(--ink);
    }

    input, select {
      width: 100%;
      min-height: 48px;
      border-radius: 16px;
      font-weight: 500;
    }

    .pill-link.active, .submit-btn {
      color: white;
      border-color: transparent;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
    }

    .danger-btn {
      color: #b23a34;
      background: #fff0ef;
      border-color: rgba(178, 58, 52, 0.16);
    }

    .warning-btn {
      color: var(--yellow);
      background: var(--yellow-soft);
      border-color: rgba(155, 107, 0, 0.16);
    }

    .hero-card, .card, .review-card, .empty-card {
      padding: 24px;
      display: grid;
      gap: 16px;
    }

    .hero-card {
      background:
        radial-gradient(circle at top right, rgba(255, 216, 176, 0.95) 0, transparent 30%),
        linear-gradient(135deg, rgba(255, 250, 243, 0.96) 0%, rgba(247, 238, 229, 0.92) 100%);
    }

    .hero-card p, .muted, .reply-meta {
      color: var(--muted);
      line-height: 1.65;
    }

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

    .filter-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 14px;
      align-items: end;
    }

    .field {
      display: grid;
      gap: 8px;
    }

    .field label {
      font-size: 13px;
      font-weight: 700;
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
      background: #fff0ef;
      color: #c54b49;
      border: 1px solid rgba(197, 75, 73, 0.15);
    }

    .review-list {
      display: grid;
      gap: 14px;
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

    .review-meta {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      font-size: 14px;
    }

    .review-side {
      display: grid;
      gap: 10px;
      justify-items: end;
    }

    .status-pill {
      padding: 9px 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
    }

    .status-pending {
      color: var(--yellow);
      background: var(--yellow-soft);
    }

    .status-answered {
      color: var(--mint);
      background: var(--mint-soft);
    }

    .status-hidden {
      color: #7c4d16;
      background: rgba(124, 77, 22, 0.12);
    }

    .stars {
      font-weight: 800;
      letter-spacing: 0.06em;
      color: var(--accent-strong);
    }

    .review-comment {
      white-space: pre-wrap;
      line-height: 1.7;
    }

    .reply-box {
      padding: 14px;
      border-radius: 18px;
      border: 1px solid rgba(31, 138, 99, 0.15);
      background: rgba(232, 247, 240, 0.9);
      display: grid;
      gap: 8px;
    }

    .pending-box {
      border-color: rgba(155, 107, 0, 0.14);
      background: rgba(255, 247, 223, 0.9);
    }

    .hidden-box {
      border-color: rgba(124, 77, 22, 0.16);
      background: rgba(255, 241, 224, 0.92);
    }

    .inline-form {
      margin: 0;
    }

    .empty-card {
      gap: 10px;
    }

    @media (max-width: 1100px) {
      .filter-grid, .stats-grid {
        grid-template-columns: 1fr 1fr;
      }
    }

    @media (max-width: 760px) {
      .wrap { padding: 18px 12px 36px; }
      .filter-grid, .stats-grid {
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
          <a class="pill-link" href="${_escapeHtml(bookingsUri.toString())}">${_escapeHtml(_text(lang, 'bookingsTab'))}</a>
          <a class="pill-link active" href="${_escapeHtml(reviewsUri.toString())}">${_escapeHtml(_text(lang, 'reviewsTab'))}</a>
        </div>
        <a class="pill-link${lang == 'uz' ? ' active' : ''}" href="${_escapeHtml(langUzUri.toString())}">UZ</a>
        <a class="pill-link${lang == 'ru' ? ' active' : ''}" href="${_escapeHtml(langRuUri.toString())}">RU</a>
        <a class="pill-link${lang == 'en' ? ' active' : ''}" href="${_escapeHtml(langEnUri.toString())}">EN</a>
        <form class="inline-form" method="post" action="/admin/logout?lang=${_escapeHtml(lang)}">
          <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'logout'))}</button>
        </form>
      </div>
    </div>

    <section class="hero-card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'heroEyebrow'))}</div>
      <h1>${_escapeHtml(_text(lang, 'heroTitle'))}</h1>
      <p>${_escapeHtml(_text(lang, 'heroDescription'))}</p>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statAll'))}</div>
          <strong>$totalCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statAllSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statPending'))}</div>
          <strong>$pendingCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statPendingSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statAnswered'))}</div>
          <strong>$answeredCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statAnsweredSub'))}</div>
        </div>
        <div class="stat-card">
          <div class="eyebrow">${_escapeHtml(_text(lang, 'statHidden'))}</div>
          <strong>$hiddenCount</strong>
          <div class="muted">${_escapeHtml(_text(lang, 'statHiddenSub'))}</div>
        </div>
      </div>
    </section>

    ${_flashHtml(message: message, error: error)}

    <section class="card">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'filterEyebrow'))}</div>
      <form method="get" action="/admin/reviews">
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
            <label>${_escapeHtml(_text(lang, 'replyFilter'))}</label>
            <select name="reply">
              <option value="all"${replyStatus == 'all' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'replyAll'))}</option>
              <option value="pending"${replyStatus == 'pending' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'replyPending'))}</option>
              <option value="answered"${replyStatus == 'answered' ? ' selected' : ''}>${_escapeHtml(_text(lang, 'replyAnswered'))}</option>
            </select>
          </div>
        </div>
        <div class="filters" style="margin-top: 14px;">
          <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'applyFilters'))}</button>
          <a class="pill-link" href="${_escapeHtml(resetUri.toString())}">${_escapeHtml(_text(lang, 'resetFilters'))}</a>
        </div>
      </form>
    </section>

    <section class="review-list">
      $reviewCards
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

  Future<Response> hideReview(Request request, String reviewId) async {
    return _setReviewHidden(request, reviewId, hidden: true);
  }

  Future<Response> unhideReview(Request request, String reviewId) async {
    return _setReviewHidden(request, reviewId, hidden: false);
  }

  Future<Response> remindReview(Request request, String reviewId) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final Uri redirectUri = _adminReviewsUri(
      lang: lang,
      query: form['q'],
      workshopId: form['workshop'],
      replyStatus: form['reply'],
    );

    final WorkshopReviewModel? review = _store.reviewById(reviewId);
    if (review == null) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'reviewNotFound'),
        ),
      );
    }

    if (review.isHidden) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'hiddenReviewReminderBlocked'),
        ),
      );
    }
    if (review.hasOwnerReply) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'answeredReviewReminderBlocked'),
        ),
      );
    }

    final WorkshopModel? workshop = _store.workshopById(review.workshopId);
    if (workshop == null) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'workshopNotFound'),
        ),
      );
    }

    try {
      await notificationsService.sendReviewReplyReminder(
        workshop: workshop,
        review: review,
      );
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          message: _text(
            lang,
            'reviewReminderSent',
            <String, Object>{'service': review.serviceName},
          ),
        ),
      );
    } on Exception catch (error) {
      return Response.seeOther(
        redirectUri.replace(
          queryParameters: <String, String>{
            ...redirectUri.queryParameters,
            'error': error.toString(),
          },
        ),
      );
    }
  }

  Future<Response> _setReviewHidden(
    Request request,
    String reviewId, {
    required bool hidden,
  }) async {
    final Response? authRedirect = _requireAdmin(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final WorkshopReviewModel? review = _store.reviewById(reviewId);
    if (review == null) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'reviewNotFound'),
        ),
      );
    }

    final WorkshopModel? workshop = _store.workshopById(review.workshopId);
    if (workshop == null) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: _text(lang, 'workshopNotFound'),
        ),
      );
    }

    try {
      final WorkshopReviewModel updated = _store.setWorkshopReviewHidden(
        workshopId: workshop.id,
        reviewId: review.id,
        hidden: hidden,
        actorRole: 'admin_panel',
        reason: form['reason'] ?? '',
      );
      await _store.saveReviews(reviewsFilePath);
      await _store.saveWorkshops(workshopsFilePath);
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          message: _text(
            lang,
            hidden ? 'reviewHidden' : 'reviewUnhidden',
            <String, Object>{'service': updated.serviceName},
          ),
        ),
      );
    } on StateError catch (error) {
      return Response.seeOther(
        _adminReviewsUri(
          lang: lang,
          query: form['q'],
          workshopId: form['workshop'],
          replyStatus: form['reply'],
          error: error.message,
        ),
      );
    }
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

  Uri _adminReviewsUri({
    String? lang,
    String? query,
    String? workshopId,
    String? replyStatus,
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
    final String normalizedReplyStatus = _normalizeReplyStatus(replyStatus);
    if (normalizedReplyStatus != 'all') {
      params['reply'] = normalizedReplyStatus;
    }
    if (message != null && message.trim().isNotEmpty) {
      params['message'] = message.trim();
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/admin/reviews', queryParameters: params);
  }

  String _reviewActionHiddenFields({
    required String lang,
    required String query,
    required String workshopId,
    required String replyStatus,
  }) {
    return '''
<input type="hidden" name="lang" value="${_escapeHtml(lang)}">
${query.trim().isEmpty ? '' : '<input type="hidden" name="q" value="${_escapeHtml(query.trim())}">'}
${workshopId.trim().isEmpty ? '' : '<input type="hidden" name="workshop" value="${_escapeHtml(workshopId.trim())}">'}
${_normalizeReplyStatus(replyStatus) == 'all' ? '' : '<input type="hidden" name="reply" value="${_escapeHtml(_normalizeReplyStatus(replyStatus))}">'}
''';
  }

  Uri _adminBookingsUri({
    String? lang,
    String? workshopId,
    String? status,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    if (workshopId != null && workshopId.trim().isNotEmpty) {
      params['workshop'] = workshopId.trim();
    }
    final String normalizedStatus = (status ?? '').trim().toLowerCase();
    if (normalizedStatus == 'upcoming' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'cancelled') {
      params['status'] = normalizedStatus;
    }
    return Uri(path: '/admin/bookings', queryParameters: params);
  }

  Uri _adminWorkshopsUri({
    String? lang,
    String? query,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    return Uri(path: '/admin/workshops', queryParameters: params);
  }

  Uri _ownerLoginUri({
    String? lang,
    String? workshopId,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    if (workshopId != null && workshopId.trim().isNotEmpty) {
      params['workshop'] = workshopId.trim();
    }
    return Uri(path: '/owner/login', queryParameters: params);
  }

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

  String _normalizeReplyStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'answered':
        return 'answered';
      default:
        return 'all';
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

  String _reviewStars(int rating) {
    final int normalized = rating.clamp(1, 5);
    return List<String>.filled(normalized, '★').join();
  }

  String _replySourceLabel(String source, String lang) {
    switch (source.trim()) {
      case 'owner_telegram':
        return _text(lang, 'replySourceTelegram');
      case 'owner_panel':
        return _text(lang, 'replySourcePanel');
      default:
        return _text(lang, 'replySourceUnknown');
    }
  }

  String _moderationReasonLabel(String reason, String lang) {
    switch (reason.trim()) {
      case 'admin_flagged':
        return _text(lang, 'moderationReasonFlagged');
      default:
        return reason.trim().isEmpty
            ? _text(lang, 'moderationReasonDefault')
            : reason.trim();
    }
  }

  String _hiddenActorLabel(String actorRole, String lang) {
    switch (actorRole.trim()) {
      case 'admin_panel':
        return _text(lang, 'hiddenByAdmin');
      default:
        return _text(lang, 'hiddenByUnknown');
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
      'pageTitle': 'Usta Top Sharhlar Paneli',
      'brandEyebrow': 'Review Desk',
      'brandTitle': 'Usta Top Sharhlar',
      'logout': 'Chiqish',
      'workshopsTab': 'Avtoservislar',
      'bookingsTab': 'Zakazlar',
      'reviewsTab': 'Sharhlar',
      'heroEyebrow': 'Sharh Nazorati',
      'heroTitle': 'Barcha mijoz sharhlarini bir joyda kuzating',
      'heroDescription':
          'Javobsiz sharhlar tepada ko‘rinadi. Admin shu yerdan muammoni tez aniqlab, workshop yoki owner inboxga o‘tadi.',
      'statAll': 'Jami sharh',
      'statAllSub': 'Barcha kelgan sharhlar soni.',
      'statPending': 'Javobsiz',
      'statPendingSub': 'Hali owner javob bermagan sharhlar.',
      'statAnswered': 'Javob berilgan',
      'statAnsweredSub': 'Workshop yoki Telegramdan javob yozilgan sharhlar.',
      'statHidden': 'Yashirilgan',
      'statHiddenSub': 'Moderatsiya orqali ko‘rinishdan olingan sharhlar.',
      'filterEyebrow': 'Qidiruv va Filtr',
      'searchLabel': 'Workshop, xizmat, mijoz, telefon yoki sharh bo‘yicha qidiruv',
      'searchPlaceholder': 'Masalan: diagnostika, Turbo, Toxirjon...',
      'workshopFilter': 'Workshop filtri',
      'allWorkshops': 'Barcha avtoservislar',
      'replyFilter': 'Javob holati',
      'replyAll': 'Barcha sharhlar',
      'replyPending': 'Javobsiz',
      'replyAnswered': 'Javob berilgan',
      'replyHidden': 'Yashirilgan',
      'applyFilters': 'Filtrni qo‘llash',
      'resetFilters': 'Tozalash',
      'emptyEyebrow': 'Sharh Yo‘q',
      'emptyTitle': 'Mos sharh topilmadi',
      'emptyBody': 'Hozircha servislar bo‘yicha sharhlar yo‘q.',
      'emptyFilteredBody':
          'Tanlangan qidiruv yoki filtr bo‘yicha sharh topilmadi.',
      'reviewIdLabel': 'Sharh ID',
      'unknownCustomer': 'Mijoz nomi yo‘q',
      'noPhone': 'Telefon ko‘rsatilmagan',
      'ownerReplyLabel': 'Usta javobi',
      'pendingReplyTitle': 'Owner javobi kutilmoqda',
      'pendingReplyBody':
          'Workshop egasi hali sharhga javob bermagan. Owner inbox yoki Telegram orqali javob berishi mumkin.',
      'hiddenReviewTitle': 'Sharh moderatsiya orqali yashirilgan',
      'hideReviewButton': 'Sharhni yashirish',
      'unhideReviewButton': 'Sharhni qayta ko‘rsatish',
      'remindOwnerButton': 'Ownerga eslatma yuborish',
      'reviewReminderSent': '{service} bo‘yicha ownerga eslatma yuborildi',
      'reviewHidden': '{service} bo‘yicha sharh yashirildi',
      'reviewUnhidden': '{service} bo‘yicha sharh qayta ko‘rsatildi',
      'reviewNotFound': 'Sharh topilmadi',
      'workshopNotFound': 'Workshop topilmadi',
      'hiddenReviewReminderBlocked':
          'Yashirilgan sharh uchun eslatma yuborib bo‘lmaydi',
      'answeredReviewReminderBlocked':
          'Javob berilgan sharh uchun eslatma kerak emas',
      'moderationReasonFlagged': 'Nojo‘ya yoki nomos sharh',
      'moderationReasonDefault': 'Admin moderatsiyasi',
      'hiddenByAdmin': 'Admin tomonidan yashirilgan',
      'hiddenByUnknown': 'Yashirgan manba ko‘rsatilmagan',
      'replySourceTelegram': 'Telegram orqali',
      'replySourcePanel': 'Owner panel orqali',
      'replySourceUnknown': 'Manba ko‘rsatilmagan',
      'workshopLink': 'Workshop kartasi',
      'bookingsLink': 'Workshop zakazlari',
      'ownerLink': 'Owner login',
    },
    'ru': <String, String>{
      'pageTitle': 'Панель отзывов Usta Top',
      'brandEyebrow': 'Review Desk',
      'brandTitle': 'Отзывы Usta Top',
      'logout': 'Выйти',
      'workshopsTab': 'Автосервисы',
      'bookingsTab': 'Заказы',
      'reviewsTab': 'Отзывы',
      'heroEyebrow': 'Контроль отзывов',
      'heroTitle': 'Следите за всеми отзывами клиентов в одном месте',
      'heroDescription':
          'Отзывы без ответа показываются сверху. Админ быстро видит проблему и может перейти в workshop или owner inbox.',
      'statAll': 'Всего отзывов',
      'statAllSub': 'Общее число отзывов по сервисам.',
      'statPending': 'Без ответа',
      'statPendingSub': 'Отзывы, где владелец еще не ответил.',
      'statAnswered': 'С ответом',
      'statAnsweredSub': 'Отзывы, где ответ уже дан из workshop или Telegram.',
      'statHidden': 'Скрытые',
      'statHiddenSub': 'Отзывы, скрытые модерацией.',
      'filterEyebrow': 'Поиск и фильтр',
      'searchLabel': 'Поиск по workshop, услуге, клиенту, телефону или отзыву',
      'searchPlaceholder': 'Например: диагностика, Turbo, Тохиржон...',
      'workshopFilter': 'Фильтр workshop',
      'allWorkshops': 'Все автосервисы',
      'replyFilter': 'Статус ответа',
      'replyAll': 'Все отзывы',
      'replyPending': 'Без ответа',
      'replyAnswered': 'С ответом',
      'replyHidden': 'Скрыт',
      'applyFilters': 'Применить',
      'resetFilters': 'Сбросить',
      'emptyEyebrow': 'Нет отзывов',
      'emptyTitle': 'Подходящие отзывы не найдены',
      'emptyBody': 'По автосервисам пока нет отзывов.',
      'emptyFilteredBody': 'По выбранным фильтрам отзывы не найдены.',
      'reviewIdLabel': 'ID отзыва',
      'unknownCustomer': 'Имя клиента не указано',
      'noPhone': 'Телефон не указан',
      'ownerReplyLabel': 'Ответ мастера',
      'pendingReplyTitle': 'Ожидается ответ owner',
      'pendingReplyBody':
          'Владелец сервиса еще не ответил. Он может ответить из owner inbox или через Telegram.',
      'hiddenReviewTitle': 'Отзыв скрыт модерацией',
      'hideReviewButton': 'Скрыть отзыв',
      'unhideReviewButton': 'Показать снова',
      'remindOwnerButton': 'Напомнить owner',
      'reviewReminderSent': 'Owner получил напоминание по услуге {service}',
      'reviewHidden': 'Отзыв по услуге {service} скрыт',
      'reviewUnhidden': 'Отзыв по услуге {service} снова показан',
      'reviewNotFound': 'Отзыв не найден',
      'workshopNotFound': 'Workshop не найден',
      'hiddenReviewReminderBlocked':
          'Нельзя отправить напоминание по скрытому отзыву',
      'answeredReviewReminderBlocked':
          'Для уже отвеченного отзыва напоминание не требуется',
      'moderationReasonFlagged': 'Нежелательный или неподходящий отзыв',
      'moderationReasonDefault': 'Модерация администратора',
      'hiddenByAdmin': 'Скрыто администратором',
      'hiddenByUnknown': 'Источник скрытия не указан',
      'replySourceTelegram': 'Через Telegram',
      'replySourcePanel': 'Через owner panel',
      'replySourceUnknown': 'Источник не указан',
      'workshopLink': 'Карточка workshop',
      'bookingsLink': 'Заказы workshop',
      'ownerLink': 'Owner login',
    },
    'en': <String, String>{
      'pageTitle': 'Usta Top Reviews Panel',
      'brandEyebrow': 'Review Desk',
      'brandTitle': 'Usta Top Reviews',
      'logout': 'Log out',
      'workshopsTab': 'Workshops',
      'bookingsTab': 'Bookings',
      'reviewsTab': 'Reviews',
      'heroEyebrow': 'Review Control',
      'heroTitle': 'Track all customer reviews in one place',
      'heroDescription':
          'Unanswered reviews stay at the top. Admin can quickly spot issues and jump into the workshop or owner inbox.',
      'statAll': 'Total reviews',
      'statAllSub': 'All reviews that have arrived.',
      'statPending': 'Waiting for reply',
      'statPendingSub': 'Reviews that still do not have an owner reply.',
      'statAnswered': 'Answered',
      'statAnsweredSub': 'Reviews answered from the workshop or Telegram.',
      'statHidden': 'Hidden',
      'statHiddenSub': 'Reviews hidden by moderation.',
      'filterEyebrow': 'Search and Filter',
      'searchLabel': 'Search by workshop, service, customer, phone, or review text',
      'searchPlaceholder': 'For example: diagnostics, Turbo, Tokhirjon...',
      'workshopFilter': 'Workshop filter',
      'allWorkshops': 'All workshops',
      'replyFilter': 'Reply status',
      'replyAll': 'All reviews',
      'replyPending': 'Pending reply',
      'replyAnswered': 'Answered',
      'replyHidden': 'Hidden',
      'applyFilters': 'Apply filters',
      'resetFilters': 'Reset',
      'emptyEyebrow': 'No Reviews',
      'emptyTitle': 'No matching reviews found',
      'emptyBody': 'There are no service reviews yet.',
      'emptyFilteredBody': 'No reviews match the current filters.',
      'reviewIdLabel': 'Review ID',
      'unknownCustomer': 'Unknown customer',
      'noPhone': 'No phone number',
      'ownerReplyLabel': 'Workshop reply',
      'pendingReplyTitle': 'Owner reply is pending',
      'pendingReplyBody':
          'The workshop owner has not replied yet. They can reply from the owner inbox or via Telegram.',
      'hiddenReviewTitle': 'This review is hidden by moderation',
      'hideReviewButton': 'Hide review',
      'unhideReviewButton': 'Unhide review',
      'remindOwnerButton': 'Send owner reminder',
      'reviewReminderSent': 'Owner reminder sent for {service}',
      'reviewHidden': 'Review hidden for {service}',
      'reviewUnhidden': 'Review restored for {service}',
      'reviewNotFound': 'Review not found',
      'workshopNotFound': 'Workshop not found',
      'hiddenReviewReminderBlocked':
          'A hidden review cannot receive a reminder',
      'answeredReviewReminderBlocked':
          'An answered review does not need a reminder',
      'moderationReasonFlagged': 'Inappropriate or off-topic review',
      'moderationReasonDefault': 'Admin moderation',
      'hiddenByAdmin': 'Hidden by admin',
      'hiddenByUnknown': 'Hidden source unavailable',
      'replySourceTelegram': 'Via Telegram',
      'replySourcePanel': 'Via owner panel',
      'replySourceUnknown': 'Source unavailable',
      'workshopLink': 'Workshop card',
      'bookingsLink': 'Workshop bookings',
      'ownerLink': 'Owner login',
    },
  };
}

class _AdminReviewEntry {
  const _AdminReviewEntry({
    required this.workshop,
    required this.review,
  });

  final WorkshopModel workshop;
  final WorkshopReviewModel review;
}
