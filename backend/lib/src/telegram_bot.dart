import 'dart:convert';
import 'dart:io';

class TelegramBotService {
  const TelegramBotService({
    required this.botToken,
  });

  final String botToken;

  bool get isConfigured => botToken.trim().isNotEmpty;

  Future<void> sendMessage({
    required String chatId,
    required String text,
    Map<String, Object>? replyMarkup,
  }) async {
    final String normalizedChatId = _normalizeChatId(chatId);
    await _post(
      method: 'sendMessage',
      payload: <String, Object?>{
        'chat_id': normalizedChatId,
        'text': text,
        'disable_web_page_preview': true,
        'reply_markup': replyMarkup,
      },
      fallbackError: 'Telegram xabari yuborilmadi',
    );
  }

  Future<void> answerCallbackQuery({
    required String callbackQueryId,
    String? text,
    bool showAlert = false,
  }) async {
    final String normalizedCallbackId = callbackQueryId.trim();
    if (normalizedCallbackId.isEmpty) {
      throw const TelegramBotException('Telegram callback ID topilmadi');
    }

    await _post(
      method: 'answerCallbackQuery',
      payload: <String, Object?>{
        'callback_query_id': normalizedCallbackId,
        'text': text?.trim().isEmpty ?? true ? null : text!.trim(),
        'show_alert': showAlert,
      },
      fallbackError: 'Telegram callback javobini yuborib bo‘lmadi',
    );
  }

  Future<void> editMessageReplyMarkup({
    required String chatId,
    required int messageId,
    Map<String, Object>? replyMarkup,
  }) async {
    final String normalizedChatId = _normalizeChatId(chatId);
    if (messageId <= 0) {
      throw const TelegramBotException('Telegram message ID topilmadi');
    }

    await _post(
      method: 'editMessageReplyMarkup',
      payload: <String, Object?>{
        'chat_id': normalizedChatId,
        'message_id': messageId,
        if (replyMarkup != null) 'reply_markup': replyMarkup,
      },
      fallbackError: 'Telegram tugmalarini yangilab bo‘lmadi',
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final Map<String, dynamic> decoded = await _get(
      method: 'getMe',
      fallbackError: 'Telegram bot tekshiruvi muvaffaqiyatsiz tugadi',
    );

    final dynamic result = decoded['result'];
    if (result is! Map<String, dynamic>) {
      throw const TelegramBotException('Telegram bot ma’lumoti topilmadi');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getUpdates({
    int? offset,
    int limit = 100,
  }) async {
    final Map<String, dynamic> decoded = await _get(
      method: 'getUpdates',
      queryParameters: <String, String>{
        if (offset != null) 'offset': '$offset',
        'limit': '$limit',
      },
      fallbackError: 'Telegram updates tekshiruvi muvaffaqiyatsiz tugadi',
    );

    final dynamic result = decoded['result'];
    if (result is! List) {
      return <Map<String, dynamic>>[];
    }

    return result.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  String _normalizeChatId(String raw) {
    if (!isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }

    final String normalizedChatId = raw.trim();
    if (normalizedChatId.isEmpty) {
      throw const TelegramBotException('Telegram chat ID kiritilmagan');
    }
    return normalizedChatId;
  }

  Uri _methodUri(
    String method, {
    Map<String, String>? queryParameters,
  }) {
    if (!isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }
    return Uri.parse('https://api.telegram.org/bot$botToken/$method')
        .replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> _get({
    required String method,
    Map<String, String>? queryParameters,
    required String fallbackError,
  }) async {
    final Uri uri = _methodUri(method, queryParameters: queryParameters);
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String raw = await response.transform(utf8.decoder).join();
      final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);
      return _decodeResponse(
        decoded,
        response.statusCode,
        fallbackError: fallbackError,
      );
    } on SocketException {
      throw const TelegramBotException('Telegram serveriga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const TelegramBotException('Telegram bilan xavfsiz ulanishda xato');
    } on FormatException {
      throw const TelegramBotException('Telegram javobini o‘qib bo‘lmadi');
    } on TelegramBotException {
      rethrow;
    } on Exception catch (error) {
      throw TelegramBotException('$fallbackError: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _post({
    required String method,
    required Map<String, Object?> payload,
    required String fallbackError,
  }) async {
    final Uri uri = _methodUri(method);
    final HttpClient client = HttpClient();

    final Map<String, Object> cleanedPayload = <String, Object>{};
    payload.forEach((String key, Object? value) {
      if (value != null) {
        cleanedPayload[key] = value;
      }
    });

    try {
      final HttpClientRequest request =
          await client.postUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(cleanedPayload));

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String raw = await response.transform(utf8.decoder).join();
      final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);
      return _decodeResponse(
        decoded,
        response.statusCode,
        fallbackError: fallbackError,
      );
    } on SocketException {
      throw const TelegramBotException('Telegram serveriga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const TelegramBotException('Telegram bilan xavfsiz ulanishda xato');
    } on FormatException {
      throw const TelegramBotException('Telegram javobini o‘qib bo‘lmadi');
    } on TelegramBotException {
      rethrow;
    } on Exception catch (error) {
      throw TelegramBotException('$fallbackError: $error');
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decodeResponse(
    dynamic decoded,
    int statusCode, {
    required String fallbackError,
  }) {
    if (statusCode < 200 || statusCode >= 300) {
      throw TelegramBotException(
        _telegramErrorMessage(
          decoded,
          fallback: 'Telegram API xatoligi: HTTP $statusCode',
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const TelegramBotException('Telegram javobi kutilgan formatda emas');
    }

    if (decoded['ok'] != true) {
      throw TelegramBotException(
        _telegramErrorMessage(
          decoded,
          fallback: fallbackError,
        ),
      );
    }
    return decoded;
  }

  String _telegramErrorMessage(
    dynamic decoded, {
    required String fallback,
  }) {
    if (decoded is Map<String, dynamic>) {
      final String description =
          (decoded['description'] ?? '').toString().trim();
      if (description.isNotEmpty) {
        return description;
      }
    }
    return fallback;
  }
}

class TelegramBotException implements Exception {
  const TelegramBotException(this.message);

  final String message;

  @override
  String toString() => message;
}
