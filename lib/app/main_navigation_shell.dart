import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../models/booking_cancellation_reason.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../providers/booking_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/workshop_provider.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/saved_salons_screen.dart';
import '../screens/salon_detail_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const Duration _bookingRefreshInterval = Duration(seconds: 20);

  int _currentIndex = 0;
  final Map<String, BookingItem> _bookingSnapshots = <String, BookingItem>{};
  late final _LifecycleObserver _lifecycleObserver;
  Timer? _bookingRefreshTimer;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LifecycleObserver(_handleAppResumed);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WorkshopProvider>().loadWorkshops();
      _bootstrapBookings();
    });
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _openSalonDetail(Salon salon) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingItem? booking = await Navigator.of(context).push<BookingItem>(
      MaterialPageRoute<BookingItem>(
        builder: (_) => SalonDetailScreen(salon: salon),
      ),
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

    if (!notifyOnTelegramCancellation ||
        previousSnapshots.isEmpty ||
        !notificationSettingsProvider.isEnabled) {
      return;
    }

    final List<BookingItem> ownerReplies = bookings.where((BookingItem item) {
      final BookingItem? previous = previousSnapshots[item.id];
      return previous != null &&
          item.lastMessageSenderRole == 'workshop_owner' &&
          item.unreadForCustomerCount > previous.unreadForCustomerCount;
    }).toList(growable: false);

    if (ownerReplies.isNotEmpty) {
      final BookingItem latest = ownerReplies.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatNewReplyNotice(latest.salonName)),
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
      return;
    }

    final List<BookingItem> telegramCancelled =
        bookings.where((BookingItem item) {
      final BookingItem? previous = previousSnapshots[item.id];
      return previous != null &&
          _bookingFingerprint(previous) != _bookingFingerprint(item) &&
          item.status == BookingStatus.cancelled &&
          item.cancelledByRole == 'owner_telegram';
    }).toList(growable: false);

    if (telegramCancelled.isEmpty) {
      return;
    }

    final BookingItem latest = telegramCancelled.first;
    final String message = l10n.telegramCancellationNotice(
      latest.salonName,
      bookingCancellationReasonLabel(latest.cancelReasonId, l10n),
    );
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

  String _bookingFingerprint(BookingItem booking) {
    return '${booking.status.name}|${booking.cancelledByRole}|${booking.cancelReasonId}|${booking.messageCount}|${booking.unreadForCustomerCount}|${booking.lastMessageSenderRole}|${booking.lastMessageAt?.toIso8601String() ?? ''}';
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
