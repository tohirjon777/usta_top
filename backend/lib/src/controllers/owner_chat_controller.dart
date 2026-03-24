import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models.dart';
import '../owner_auth.dart';
import '../store.dart';
import '../user_notifications.dart';

class OwnerChatController {
  const OwnerChatController(
    this._store, {
    required this.ownerAuthService,
    required this.messagesFilePath,
    required this.userNotificationsService,
  });

  final InMemoryStore _store;
  final OwnerAuthService ownerAuthService;
  final String messagesFilePath;
  final UserNotificationsService userNotificationsService;

  Future<Response> chatPage(Request request, String bookingId) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    final String returnStatus =
        _normalizeStatus(request.url.queryParameters['status']);
    final String workshopId =
        ownerAuthService.workshopIdFromRequest(request) ?? '';
    final BookingModel? booking = _store.bookingForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    if (booking == null) {
      return Response.seeOther(
        _ownerBookingsUri(
          lang: lang,
          status: returnStatus,
          error: _text(lang, 'bookingNotFound'),
        ),
      );
    }

    final int marked = _store.markBookingMessagesReadForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    if (marked > 0) {
      await _store.saveBookingMessages(messagesFilePath);
    }

    final List<BookingChatMessageModel> messages =
        _store.bookingMessagesForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    final String? message = request.url.queryParameters['message'];
    final String? error = request.url.queryParameters['error'];

    final String messageItems = messages.isEmpty
        ? '''
<div class="empty-chat">${_escapeHtml(_text(lang, 'chatEmpty'))}</div>
'''
        : messages.map((BookingChatMessageModel item) {
            final bool isOwner =
                item.senderRole == BookingChatSenderRole.workshopOwner;
            return '''
<article class="msg ${isOwner ? 'owner' : 'customer'}">
  <div class="msg-meta">
    <strong>${_escapeHtml(item.senderName.isEmpty ? _senderLabel(item.senderRole, lang) : item.senderName)}</strong>
    <span>${_escapeHtml(_senderLabel(item.senderRole, lang))}</span>
    <span>${_escapeHtml(_formatDateTime(item.createdAt))}</span>
  </div>
  <div class="msg-body">${_escapeMultiline(item.text)}</div>
</article>
''';
          }).join();

    final String html = '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escapeHtml(_text(lang, 'chatPageTitle'))}</title>
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
      --shadow: 0 18px 60px rgba(56, 34, 12, 0.08);
      --soft: #fff7ef;
      --owner: #fff3e8;
      --customer: #eef6ff;
      --ok: #e8f7f0;
      --ok-text: #1f8a63;
      --err: #fff0ef;
      --err-text: #c54b49;
      --radius: 24px;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Avenir Next", "Trebuchet MS", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(255, 205, 154, 0.85) 0, transparent 28%),
        linear-gradient(180deg, #fcfaf7 0%, var(--bg) 100%);
      color: var(--text);
    }

    .wrap {
      max-width: 1100px;
      margin: 0 auto;
      padding: 24px 18px 40px;
      display: grid;
      gap: 18px;
    }

    .card, .topbar, .composer, .thread {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
    }

    .topbar {
      padding: 16px 18px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      flex-wrap: wrap;
    }

    .back-link, .submit-btn {
      border-radius: 999px;
      padding: 10px 14px;
      font-weight: 700;
      text-decoration: none;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.82);
      color: var(--text);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      cursor: pointer;
    }

    .submit-btn {
      border-color: transparent;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
      color: white;
    }

    .hero {
      display: grid;
      gap: 14px;
      padding: 22px;
    }

    .eyebrow {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: var(--accent-strong);
      font-weight: 700;
    }

    h1, h2, h3, p { margin: 0; }

    h1 {
      font-family: "Iowan Old Style", "Palatino Linotype", serif;
      font-size: clamp(30px, 4vw, 42px);
      letter-spacing: -0.04em;
      line-height: 1;
    }

    .muted {
      color: var(--muted);
      line-height: 1.6;
    }

    .meta-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
    }

    .meta-card {
      border-radius: 18px;
      border: 1px solid var(--line);
      background: var(--soft);
      padding: 14px;
      display: grid;
      gap: 6px;
    }

    .meta-card span {
      font-size: 12px;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: var(--muted);
    }

    .flash {
      padding: 14px 16px;
      border-radius: 18px;
      font-weight: 700;
    }

    .flash.ok {
      background: var(--ok);
      color: var(--ok-text);
    }

    .flash.err {
      background: var(--err);
      color: var(--err-text);
    }

    .thread {
      padding: 18px;
      display: grid;
      gap: 12px;
    }

    .thread-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }

    .messages {
      display: grid;
      gap: 12px;
    }

    .msg {
      max-width: min(720px, 100%);
      border-radius: 22px;
      padding: 14px 16px;
      border: 1px solid var(--line);
      display: grid;
      gap: 8px;
    }

    .msg.owner {
      margin-left: auto;
      background: var(--owner);
    }

    .msg.customer {
      margin-right: auto;
      background: var(--customer);
    }

    .msg-meta {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      font-size: 12px;
      color: var(--muted);
    }

    .msg-body {
      line-height: 1.7;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .composer {
      padding: 18px;
      display: grid;
      gap: 12px;
    }

    textarea {
      width: 100%;
      min-height: 130px;
      border-radius: 20px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.92);
      padding: 14px 16px;
      font: inherit;
      resize: vertical;
    }

    .composer-foot {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }

    .empty-chat {
      padding: 24px;
      border-radius: 20px;
      border: 1px dashed var(--line);
      text-align: center;
      color: var(--muted);
      background: rgba(255, 255, 255, 0.7);
    }

    @media (max-width: 720px) {
      .wrap { padding-inline: 14px; }
      .hero, .thread, .composer { padding: 16px; }
      .msg { max-width: 100%; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="topbar">
      <a class="back-link" href="${_escapeHtml(_ownerBookingsUri(lang: lang, status: returnStatus).toString())}">${_escapeHtml(_text(lang, 'backToBookings'))}</a>
      <div class="muted">${_escapeHtml(_text(lang, 'chatGuard'))}</div>
    </div>

    ${_flashHtml(message: message, error: error)}

    <section class="card hero">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'chatEyebrow'))}</div>
      <h1>${_escapeHtml(_text(lang, 'chatPageTitle'))}</h1>
      <p class="muted">${_escapeHtml(_text(lang, 'chatDescription'))}</p>
      <div class="meta-grid">
        <div class="meta-card">
          <span>${_escapeHtml(_text(lang, 'orderId'))}</span>
          <strong>${_escapeHtml(booking.id)}</strong>
        </div>
        <div class="meta-card">
          <span>${_escapeHtml(_text(lang, 'customerLabel'))}</span>
          <strong>${_escapeHtml(booking.customerName.isEmpty ? _text(lang, 'unknownCustomer') : booking.customerName)}</strong>
        </div>
        <div class="meta-card">
          <span>${_escapeHtml(_text(lang, 'serviceLabel'))}</span>
          <strong>${_escapeHtml(booking.serviceName)}</strong>
        </div>
        <div class="meta-card">
          <span>${_escapeHtml(_text(lang, 'vehicleLabel'))}</span>
          <strong>${_escapeHtml(booking.vehicleModel)}</strong>
        </div>
        <div class="meta-card">
          <span>${_escapeHtml(_text(lang, 'appointmentLabel'))}</span>
          <strong>${_escapeHtml(_formatDateTime(booking.dateTime))}</strong>
        </div>
      </div>
    </section>

    <section class="thread">
      <div class="thread-head">
        <div>
          <div class="eyebrow">${_escapeHtml(_text(lang, 'conversationLabel'))}</div>
          <h2>${_escapeHtml(_text(lang, 'conversationTitle'))}</h2>
        </div>
        <div class="muted">${_escapeHtml(_text(lang, 'messageCount', <String, Object>{
          'count': messages.length
        }))}</div>
      </div>
      <div class="messages">
        $messageItems
      </div>
    </section>

    <section class="composer">
      <div class="eyebrow">${_escapeHtml(_text(lang, 'replyLabel'))}</div>
      <form id="chat-form" method="post" action="/owner/bookings/${Uri.encodeComponent(booking.id)}/chat?lang=${Uri.encodeQueryComponent(lang)}&status=${Uri.encodeQueryComponent(returnStatus)}">
        <input type="hidden" name="lang" value="${_escapeHtml(lang)}">
        <input type="hidden" name="returnStatus" value="${_escapeHtml(returnStatus)}">
        <textarea id="chat-textarea" name="text" maxlength="1000" placeholder="${_escapeHtml(_text(lang, 'chatPlaceholder'))}"></textarea>
        <div class="composer-foot">
          <div class="muted">${_escapeHtml(_text(lang, 'chatHint'))}</div>
          <button class="submit-btn" type="submit">${_escapeHtml(_text(lang, 'sendButton'))}</button>
        </div>
      </form>
    </section>
  </div>
  <script>
    (() => {
      const textarea = document.getElementById('chat-textarea');
      const form = document.getElementById('chat-form');
      if (!textarea || !form || !window.sessionStorage) {
        return;
      }

      const storageKey = 'usta-top-owner-chat-draft:${_escapeJs(booking.id)}';
      const savedDraft = window.sessionStorage.getItem(storageKey);
      if (savedDraft && !textarea.value) {
        textarea.value = savedDraft;
      }

      textarea.addEventListener('input', () => {
        window.sessionStorage.setItem(storageKey, textarea.value);
      });

      form.addEventListener('submit', () => {
        window.sessionStorage.removeItem(storageKey);
      });

      window.setInterval(() => {
        if (document.hidden) {
          return;
        }
        window.sessionStorage.setItem(storageKey, textarea.value);
        window.location.reload();
      }, 8000);
    })();
  </script>
</body>
</html>
''';

    return Response.ok(
      html,
      headers: <String, String>{'content-type': 'text/html; charset=utf-8'},
    );
  }

  Future<Response> sendMessage(Request request, String bookingId) async {
    final Response? authRedirect = _requireOwner(request);
    if (authRedirect != null) {
      return authRedirect;
    }

    final Map<String, String> form = await _readForm(request);
    final String lang = _normalizeLang(form['lang']);
    final String returnStatus = _normalizeStatus(form['returnStatus']);
    final String workshopId =
        ownerAuthService.workshopIdFromRequest(request) ?? '';

    try {
      final BookingChatMessageModel message =
          _store.createWorkshopBookingMessage(
        workshopId: workshopId,
        bookingId: bookingId,
        text: form['text'] ?? '',
      );
      await _store.saveBookingMessages(messagesFilePath);
      final BookingModel? booking = _store.bookingForWorkshop(
        workshopId: workshopId,
        bookingId: bookingId,
      );
      if (booking != null) {
        await _notifyUserAboutChatMessage(booking: booking, message: message);
      }
      return Response.seeOther(
        _ownerChatUri(
          bookingId,
          lang: lang,
          status: returnStatus,
          message: _text(lang, 'messageSent'),
        ),
      );
    } on StateError catch (error) {
      return Response.seeOther(
        _ownerChatUri(
          bookingId,
          lang: lang,
          status: returnStatus,
          error: error.message,
        ),
      );
    }
  }

  Future<void> _notifyUserAboutChatMessage({
    required BookingModel booking,
    required BookingChatMessageModel message,
  }) async {
    final UserModel? user = _store.userById(booking.userId);
    if (user == null) {
      return;
    }

    try {
      await userNotificationsService.sendBookingChatNotification(
        user: user,
        booking: booking,
        message: message,
      );
    } on Exception {
      // Push sozlanmagan bo'lsa owner chat oqimini to'xtatmaymiz.
    }
  }

  Uri _ownerChatUri(
    String bookingId, {
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
    return Uri(
      path: '/owner/bookings/${Uri.encodeComponent(bookingId)}/chat',
      queryParameters: params,
    );
  }

  Uri _ownerBookingsUri({
    String? lang,
    String? status,
    String? error,
  }) {
    final Map<String, String> params = <String, String>{
      'lang': _normalizeLang(lang),
    };
    final String normalizedStatus = _normalizeStatus(status);
    if (normalizedStatus != 'all') {
      params['status'] = normalizedStatus;
    }
    if (error != null && error.trim().isNotEmpty) {
      params['error'] = error.trim();
    }
    return Uri(path: '/owner/bookings', queryParameters: params);
  }

  Response? _requireOwner(Request request) {
    if (ownerAuthService.isAuthenticated(request)) {
      return null;
    }

    final String lang = _normalizeLang(request.url.queryParameters['lang']);
    return Response.seeOther(
      Uri(
          path: '/owner/login',
          queryParameters: <String, String>{'lang': lang}),
    );
  }

  Future<Map<String, String>> _readForm(Request request) async {
    final String body = await request.readAsString();
    if (body.trim().isEmpty) {
      return <String, String>{};
    }
    return Uri.splitQueryString(body);
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

  String _senderLabel(BookingChatSenderRole role, String lang) {
    switch (role) {
      case BookingChatSenderRole.customer:
        return _text(lang, 'senderCustomer');
      case BookingChatSenderRole.workshopOwner:
        return _text(lang, 'senderOwner');
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

  String _escapeJs(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  String _escapeMultiline(String value) {
    return _escapeHtml(value).replaceAll('\n', '<br>');
  }

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'uz': <String, String>{
      'chatPageTitle': 'Mijoz bilan chat',
      'chatEyebrow': 'Booking Chat',
      'chatDescription':
          'Bu suhbat aynan shu zakazga biriktirilgan. Mijoz yozgan xabarlar shu yerda qoladi.',
      'backToBookings': 'Zakazlarga qaytish',
      'chatGuard': 'Faqat shu zakaz bo‘yicha aniq ma’lumot yozing.',
      'bookingNotFound': 'Zakaz topilmadi',
      'customerLabel': 'Mijoz',
      'serviceLabel': 'Xizmat',
      'vehicleLabel': 'Mashina',
      'appointmentLabel': 'Bron vaqti',
      'orderId': 'Zakaz ID',
      'unknownCustomer': 'Mijoz nomi yo‘q',
      'conversationLabel': 'Suhbat oqimi',
      'conversationTitle': 'Xabarlar tarixi',
      'replyLabel': 'Javob yozish',
      'chatPlaceholder':
          'Mijozga kerakli izoh, aniqlashtirish yoki tayyor bo‘lish vaqti haqida yozing...',
      'chatHint': 'Xabar saqlanadi va mijoz ilovasida keyin ham ko‘rinadi.',
      'sendButton': 'Xabar yuborish',
      'messageSent': 'Xabar mijozga yuborildi.',
      'chatEmpty':
          'Hali xabarlar yo‘q. Suhbatni birinchi bo‘lib siz boshlashingiz mumkin.',
      'senderCustomer': 'Mijoz',
      'senderOwner': 'Usta',
      'messageCount': '{count} ta xabar',
    },
    'ru': <String, String>{
      'chatPageTitle': 'Чат с клиентом',
      'chatEyebrow': 'Booking Chat',
      'chatDescription':
          'Этот диалог привязан именно к данному заказу. Сообщения клиента остаются здесь.',
      'backToBookings': 'Назад к заказам',
      'chatGuard': 'Пишите только по существу этого заказа.',
      'bookingNotFound': 'Заказ не найден',
      'customerLabel': 'Клиент',
      'serviceLabel': 'Услуга',
      'vehicleLabel': 'Автомобиль',
      'appointmentLabel': 'Время записи',
      'orderId': 'ID заказа',
      'unknownCustomer': 'Имя клиента не указано',
      'conversationLabel': 'Диалог',
      'conversationTitle': 'История сообщений',
      'replyLabel': 'Ответ клиенту',
      'chatPlaceholder':
          'Напишите уточнение, комментарий или время готовности машины...',
      'chatHint': 'Сообщение сохранится и будет видно клиенту в приложении.',
      'sendButton': 'Отправить',
      'messageSent': 'Сообщение отправлено клиенту.',
      'chatEmpty': 'Сообщений пока нет. Вы можете начать диалог первым.',
      'senderCustomer': 'Клиент',
      'senderOwner': 'Мастер',
      'messageCount': '{count} сообщений',
    },
    'en': <String, String>{
      'chatPageTitle': 'Customer chat',
      'chatEyebrow': 'Booking Chat',
      'chatDescription':
          'This conversation is attached to the selected booking, so all context stays in one place.',
      'backToBookings': 'Back to bookings',
      'chatGuard': 'Keep messages focused on this booking.',
      'bookingNotFound': 'Booking was not found',
      'customerLabel': 'Customer',
      'serviceLabel': 'Service',
      'vehicleLabel': 'Vehicle',
      'appointmentLabel': 'Appointment time',
      'orderId': 'Booking ID',
      'unknownCustomer': 'Customer name missing',
      'conversationLabel': 'Conversation',
      'conversationTitle': 'Message history',
      'replyLabel': 'Reply to customer',
      'chatPlaceholder':
          'Write an update, clarification, or expected ready time for the customer...',
      'chatHint':
          'The message is saved and will stay visible in the customer app.',
      'sendButton': 'Send message',
      'messageSent': 'Message was sent to the customer.',
      'chatEmpty': 'No messages yet. You can start the conversation first.',
      'senderCustomer': 'Customer',
      'senderOwner': 'Technician',
      'messageCount': '{count} messages',
    },
  };
}
