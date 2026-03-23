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
  }) async {
    if (!isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }

    final String normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) {
      throw const TelegramBotException('Telegram chat ID kiritilmagan');
    }

    final Uri uri =
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.postUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object>{
          'chat_id': normalizedChatId,
          'text': text,
          'disable_web_page_preview': true,
        }),
      );

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String raw = await response.transform(utf8.decoder).join();
      final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram API xatoligi: HTTP ${response.statusCode}',
          ),
        );
      }

      if (decoded is Map<String, dynamic> && decoded['ok'] != true) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram xabari yuborilmadi',
          ),
        );
      }
    } on SocketException {
      throw const TelegramBotException('Telegram serveriga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const TelegramBotException('Telegram bilan xavfsiz ulanishda xato');
    } on FormatException {
      throw const TelegramBotException('Telegram javobini o‘qib bo‘lmadi');
    } on TelegramBotException {
      rethrow;
    } on Exception catch (error) {
      throw TelegramBotException('Telegram xabari yuborilmadi: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    if (!isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }

    final Uri uri = Uri.parse('https://api.telegram.org/bot$botToken/getMe');
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String raw = await response.transform(utf8.decoder).join();
      final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram API xatoligi: HTTP ${response.statusCode}',
          ),
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const TelegramBotException(
            'Telegram javobi kutilgan formatda emas');
      }

      if (decoded['ok'] != true) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram bot tekshiruvi muvaffaqiyatsiz tugadi',
          ),
        );
      }

      final dynamic result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const TelegramBotException('Telegram bot ma’lumoti topilmadi');
      }
      return result;
    } on SocketException {
      throw const TelegramBotException('Telegram serveriga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const TelegramBotException('Telegram bilan xavfsiz ulanishda xato');
    } on FormatException {
      throw const TelegramBotException('Telegram javobini o‘qib bo‘lmadi');
    } on TelegramBotException {
      rethrow;
    } on Exception catch (error) {
      throw TelegramBotException(
          'Telegram bot tekshiruvi muvaffaqiyatsiz: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Map<String, dynamic>>> getUpdates({
    int? offset,
    int limit = 100,
  }) async {
    if (!isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }

    final Uri uri = Uri.parse('https://api.telegram.org/bot$botToken/getUpdates')
        .replace(
      queryParameters: <String, String>{
        if (offset != null) 'offset': '$offset',
        'limit': '$limit',
      },
    );
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String raw = await response.transform(utf8.decoder).join();
      final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram API xatoligi: HTTP ${response.statusCode}',
          ),
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const TelegramBotException(
          'Telegram updates javobi kutilgan formatda emas',
        );
      }

      if (decoded['ok'] != true) {
        throw TelegramBotException(
          _telegramErrorMessage(
            decoded,
            fallback: 'Telegram updates tekshiruvi muvaffaqiyatsiz tugadi',
          ),
        );
      }

      final dynamic result = decoded['result'];
      if (result is! List) {
        return <Map<String, dynamic>>[];
      }

      return result
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } on SocketException {
      throw const TelegramBotException('Telegram serveriga ulanib bo‘lmadi');
    } on HandshakeException {
      throw const TelegramBotException('Telegram bilan xavfsiz ulanishda xato');
    } on FormatException {
      throw const TelegramBotException('Telegram updates javobini o‘qib bo‘lmadi');
    } on TelegramBotException {
      rethrow;
    } on Exception catch (error) {
      throw TelegramBotException(
        'Telegram updates tekshiruvi muvaffaqiyatsiz: $error',
      );
    } finally {
      client.close(force: true);
    }
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
