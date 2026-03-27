import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/utils/formatters.dart';
import '../models/app_navigation_intent.dart';
import '../models/booking_cancellation_reason.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/workshop_provider.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/saved_salons_screen.dart';
import '../screens/salon_detail_screen.dart';
import '../ui/review_composer_sheet.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const Duration _bookingRefreshInterval = Duration(seconds: 20);
  static const Duration _recentCompletionPromptWindow = Duration(hours: 24);

  int _currentIndex = 0;
  final Map<String, BookingItem> _bookingSnapshots = <String, BookingItem>{};
  final Set<String> _reviewPromptDismissed = <String>{};
  late final _LifecycleObserver _lifecycleObserver;
  late final AppNavigationProvider _appNavigationProvider;
  Timer? _bookingRefreshTimer;
  bool _isReviewPromptOpen = false;
  bool _isHandlingNavigationIntent = false;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LifecycleObserver(_handleAppResumed);
    _appNavigationProvider = context.read<AppNavigationProvider>();
    _appNavigationProvider.addListener(_handlePendingNavigationIntentChanged);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WorkshopProvider>().loadWorkshops();
      _bootstrapBookings();
      unawaited(_consumePendingNavigationIntent());
    });
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    _appNavigationProvider
        .removeListener(_handlePendingNavigationIntentChanged);
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _handlePendingNavigationIntentChanged() {
    unawaited(_consumePendingNavigationIntent());
  }

  Future<void> _consumePendingNavigationIntent() async {
    if (!mounted || _isHandlingNavigationIntent) {
      return;
    }

    final AppNavigationIntent? intent =
        _appNavigationProvider.consumePendingIntent();
    if (intent == null) {
      return;
    }

    _isHandlingNavigationIntent = true;
    try {
      switch (intent.target) {
        case AppNavigationTarget.bookings:
          if (!mounted) {
            return;
          }
          setState(() {
            _currentIndex = 2;
          });
          break;
        case AppNavigationTarget.workshopReview:
        case AppNavigationTarget.workshopReviewComposer:
          final WorkshopProvider workshopProvider =
              context.read<WorkshopProvider>();
          Salon? salon = workshopProvider.workshopById(intent.workshopId);
          salon ??=
              await workshopProvider.refreshWorkshopById(intent.workshopId);
          if (!mounted || salon == null) {
            return;
          }
          await _openSalonDetailRoute(
            salon: salon,
            initialReviewServiceId: intent.serviceId,
            highlightedReviewId: intent.reviewId,
            autoOpenReviewComposer:
                intent.target == AppNavigationTarget.workshopReviewComposer,
            reviewPromptBookingId: intent.bookingId,
            lockInitialReviewServiceSelection:
                intent.target == AppNavigationTarget.workshopReviewComposer,
          );
          break;
      }
    } finally {
      _isHandlingNavigationIntent = false;
    }
  }

  Future<BookingItem?> _openSalonDetailRoute({
    required Salon salon,
    String initialReviewServiceId = '',
    String highlightedReviewId = '',
    bool autoOpenReviewComposer = false,
    String reviewPromptBookingId = '',
    bool lockInitialReviewServiceSelection = false,
  }) {
    return Navigator.of(context).push<BookingItem>(
      MaterialPageRoute<BookingItem>(
        builder: (_) => SalonDetailScreen(
          salon: salon,
          initialReviewServiceId: initialReviewServiceId,
          highlightedReviewId: highlightedReviewId,
          autoOpenReviewComposer: autoOpenReviewComposer,
          reviewPromptBookingId: reviewPromptBookingId,
          lockInitialReviewServiceSelection: lockInitialReviewServiceSelection,
        ),
      ),
    );
  }

  Future<void> _openSalonDetail(Salon salon) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingItem? booking = await _openSalonDetailRoute(
      salon: salon,
    );

    if (booking == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.bookingAdded(booking.salonName))),
    );
  }

  void _openBookingHistory() {
    setState(() {
      _currentIndex = 2;
    });
  }

  Future<void> _openSavedSalons() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SavedSalonsScreen(onOpenSalon: _openSalonDetail),
      ),
    );
  }

  Future<void> _bootstrapBookings() async {
    await _refreshBookings(notifyOnTelegramCancellation: false);
    if (!mounted) {
      return;
    }
    _bookingRefreshTimer?.cancel();
    _bookingRefreshTimer = Timer.periodic(
      _bookingRefreshInterval,
      (_) => _refreshBookings(),
    );
  }

  Future<void> _handleAppResumed() async {
    await _refreshBookings();
  }

  Future<void> _refreshBookings({
    bool notifyOnTelegramCancellation = true,
  }) async {
    if (!mounted) {
      return;
    }

    final BookingProvider bookingProvider = context.read<BookingProvider>();
    final NotificationSettingsProvider notificationSettingsProvider =
        context.read<NotificationSettingsProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, BookingItem> previousSnapshots =
        Map<String, BookingItem>.from(_bookingSnapshots);

    await bookingProvider.loadBookings(silent: true);
    if (!mounted) {
      return;
    }

    final List<BookingItem> bookings = bookingProvider.bookings.toList();
    _bookingSnapshots
      ..clear()
      ..addEntries(
        bookings.map(
          (BookingItem booking) => MapEntry<String, BookingItem>(
            booking.id,
            booking,
          ),
        ),
      );

    if (notifyOnTelegramCancellation &&
        previousSnapshots.isNotEmpty &&
        notificationSettingsProvider.isEnabled) {
      String? message;

      final List<BookingItem> telegramCancelled =
          bookings.where((BookingItem item) {
        final BookingItem? previous = previousSnapshots[item.id];
        return previous != null &&
            _bookingFingerprint(previous) != _bookingFingerprint(item) &&
            item.status == BookingStatus.cancelled &&
            item.cancelledByRole == 'owner_telegram';
      }).toList(growable: false);

      if (telegramCancelled.isNotEmpty) {
        final BookingItem latest = telegramCancelled.first;
        message = l10n.telegramCancellationNotice(
          latest.salonName,
          bookingCancellationReasonLabel(latest.cancelReasonId, l10n),
        );
      } else {
        final List<BookingItem> cancelledBookings =
            bookings.where((BookingItem item) {
          final BookingItem? previous = previousSnapshots[item.id];
          return previous != null &&
              previous.status != item.status &&
              item.status == BookingStatus.cancelled;
        }).toList(growable: false);
        final List<BookingItem> rescheduledBookings =
            bookings.where((BookingItem item) {
          final BookingItem? previous = previousSnapshots[item.id];
          return previous != null &&
              item.status == BookingStatus.rescheduled &&
              (previous.status != item.status ||
                  previous.dateTime != item.dateTime);
        }).toList(growable: false);
        final List<BookingItem> acceptedBookings =
            bookings.where((BookingItem item) {
          final BookingItem? previous = previousSnapshots[item.id];
          return previous != null &&
              previous.status != item.status &&
              item.status == BookingStatus.accepted;
        }).toList(growable: false);
        final List<BookingItem> completedBookings =
            bookings.where((BookingItem item) {
          final BookingItem? previous = previousSnapshots[item.id];
          return previous != null &&
              previous.status != item.status &&
              item.status == BookingStatus.completed;
        }).toList(growable: false);

        if (cancelledBookings.isNotEmpty) {
          final BookingItem latest = cancelledBookings.first;
          message = l10n.bookingCancelledNotice(
            latest.salonName,
            bookingCancellationReasonLabel(latest.cancelReasonId, l10n),
          );
        } else if (rescheduledBookings.isNotEmpty) {
          final BookingItem latest = rescheduledBookings.first;
          message = l10n.bookingRescheduledNotice(
            latest.salonName,
            AppFormatters.dateTime(latest.dateTime),
          );
        } else if (acceptedBookings.isNotEmpty) {
          message =
              l10n.bookingAcceptedNotice(acceptedBookings.first.salonName);
        } else if (completedBookings.isNotEmpty) {
          message =
              l10n.bookingCompletedNotice(completedBookings.first.salonName);
        }
      }

      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: l10n.view,
              onPressed: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
          ),
        );
      }
    }

    await _maybePromptForCompletedReview(
      bookings: bookings,
      previousSnapshots: previousSnapshots,
    );
  }

  String _bookingFingerprint(BookingItem booking) {
    return '${booking.status.name}|${booking.cancelledByRole}|${booking.cancelReasonId}';
  }

  Future<void> _maybePromptForCompletedReview({
    required List<BookingItem> bookings,
    required Map<String, BookingItem> previousSnapshots,
  }) async {
    if (!mounted || _isReviewPromptOpen) {
      return;
    }

    final DateTime now = DateTime.now();
    final List<BookingItem> candidates = bookings.where((BookingItem item) {
      if (item.status != BookingStatus.completed ||
          item.hasReview ||
          _reviewPromptDismissed.contains(item.id)) {
        return false;
      }

      final BookingItem? previous = previousSnapshots[item.id];
      if (previous != null) {
        return previous.status != BookingStatus.completed;
      }

      final DateTime? completedAt = item.completedAt;
      return completedAt != null &&
          completedAt.isAfter(now.subtract(_recentCompletionPromptWindow));
    }).toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    await _openCompletedReviewPrompt(candidates.first);
  }

  Future<void> _openCompletedReviewPrompt(BookingItem booking) async {
    if (!mounted || _isReviewPromptOpen) {
      return;
    }

    _isReviewPromptOpen = true;
    try {
      final WorkshopProvider workshopProvider =
          context.read<WorkshopProvider>();
      final AppLocalizations l10n = AppLocalizations.of(context);
      Salon? salon = workshopProvider.workshopById(booking.workshopId);
      salon ??= await workshopProvider.refreshWorkshopById(booking.workshopId);
      if (!mounted || salon == null) {
        return;
      }

      final Salon? updated = await showWorkshopReviewComposerSheet(
        context: context,
        salon: salon,
        l10n: l10n,
        preselectedServiceId: booking.serviceId,
        bookingId: booking.id,
        lockServiceSelection: true,
        title: l10n.completedReviewTitle,
        subtitle: l10n.completedReviewSubtitle(
          booking.serviceName,
          booking.salonName,
        ),
      );

      if (!mounted) {
        return;
      }
      if (updated == null) {
        _reviewPromptDismissed.add(booking.id);
        return;
      }
      _reviewPromptDismissed.remove(booking.id);
    } finally {
      _isReviewPromptOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<Widget> pages = <Widget>[
      HomeScreen(onOpenSalon: _openSalonDetail),
      MapScreen(onOpenSalon: _openSalonDetail),
      const MyBookingsScreen(),
      ProfileScreen(
        onOpenBookingHistory: _openBookingHistory,
        onOpenSavedSalons: _openSavedSalons,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navBookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onResumed);

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResumed());
    }
  }
}
