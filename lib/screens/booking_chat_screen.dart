import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_chat_message.dart';
import '../models/booking_item.dart';
import '../providers/booking_provider.dart';

class BookingChatScreen extends StatefulWidget {
  const BookingChatScreen({
    super.key,
    required this.booking,
  });

  final BookingItem booking;

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen>
    with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(seconds: 12);

  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadMessages());
      _refreshTimer = Timer.periodic(
        _refreshInterval,
        (_) => unawaited(_loadMessages(markRead: false)),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadMessages());
    }
  }

  Future<void> _loadMessages({bool markRead = true}) async {
    await context.read<BookingProvider>().loadBookingMessages(
          widget.booking.id,
          markRead: markRead,
        );
    if (!mounted) {
      return;
    }
    if (markRead) {
      _jumpToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String text = _messageController.text;
    final bool sent = await context.read<BookingProvider>().sendBookingMessage(
          bookingId: widget.booking.id,
          text: text,
        );
    if (!mounted) {
      return;
    }
    if (!sent) {
      final String message = context.read<BookingProvider>().messageError(
                widget.booking.id,
              ) ??
          l10n.chatSendFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    _messageController.clear();
    _jumpToBottom();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition position = _scrollController.position;
      if (!position.hasContentDimensions) {
        return;
      }
      final double targetOffset = position.maxScrollExtent;
      if (targetOffset <= position.pixels) {
        return;
      }
      _scrollController.jumpTo(targetOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingProvider bookingProvider = context.watch<BookingProvider>();
    final List<BookingChatMessage> messages = bookingProvider
        .messagesForBooking(widget.booking.id)
        .toList(growable: false);
    final bool isLoading = bookingProvider.isLoadingMessages(widget.booking.id);
    final bool isSending = bookingProvider.isSendingMessage(widget.booking.id);
    final String? errorMessage =
        bookingProvider.messageError(widget.booking.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatWithWorkshop),
        actions: <Widget>[
          IconButton(
            onPressed: isLoading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.booking.salonName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.serviceLabel(widget.booking.serviceName)),
                    Text(l10n.vehicleModelLabel(widget.booking.vehicleModel)),
                    Text(
                      l10n.dateLabel(
                        AppFormatters.dateTime(widget.booking.dateTime),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.chatReplyHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (errorMessage != null && messages.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: messages.isEmpty ? 1 : messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (messages.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: _EmptyChatState(
                                title: l10n.chatEmptyTitle,
                                subtitle: l10n.chatEmptySubtitle,
                              ),
                            );
                          }

                          final BookingChatMessage message = messages[index];
                          final bool isMine = message.isFromCustomer;
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? AppColors.primarySoftOf(context)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    isMine
                                        ? l10n.chatSenderYou
                                        : (message.senderName.isEmpty
                                            ? l10n.chatSenderWorkshop
                                            : message.senderName),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.secondaryTextOf(
                                            context,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(message.text),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppFormatters.dateTime(message.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.secondaryTextOf(
                                            context,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.chatInputHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: isSending ? null : _sendMessage,
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(l10n.chatSend),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 54,
              color: AppColors.secondaryTextOf(context),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
