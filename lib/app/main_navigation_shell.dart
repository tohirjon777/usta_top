import 'package:flutter/material.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../data/repositories/salon_repository.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../screens/home_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/salon_detail_screen.dart';
import '../state/booking_controller.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    required this.bookingController,
    required this.salonRepository,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.onSignOut,
  });

  final BookingController bookingController;
  final SalonRepository salonRepository;
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onSignOut;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

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

    widget.bookingController.addBooking(booking);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.bookingAdded(booking.salonName))),
    );
  }

  void _cancelBooking(String bookingId) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool changed = widget.bookingController.cancelBooking(bookingId);
    if (!changed) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.bookingCancelled)));
  }

  void _openBookingHistory() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _openSavedSalons() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedSalonsConnectedHome)),
    );
  }

  void _onNotificationsChanged(bool enabled) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? l10n.notificationsEnabled : l10n.notificationsDisabled,
        ),
      ),
    );
  }

  void _onLanguageChanged(AppLanguage language) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    widget.onLanguageChanged(language);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.languageSwitched(l10n.languageName(language)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Salon> salons = widget.salonRepository.getFeaturedSalons();

    return AnimatedBuilder(
      animation: widget.bookingController,
      builder: (BuildContext context, _) {
        final List<Widget> pages = <Widget>[
          HomeScreen(salons: salons, onOpenSalon: _openSalonDetail),
          MyBookingsScreen(
            bookings: widget.bookingController.bookings,
            onCancel: _cancelBooking,
          ),
          ProfileScreen(
            totalBookings: widget.bookingController.totalBookings,
            upcomingBookings: widget.bookingController.upcomingBookings,
            onOpenBookingHistory: _openBookingHistory,
            onOpenSavedSalons: _openSavedSalons,
            onNotificationsChanged: _onNotificationsChanged,
            onLanguageChanged: _onLanguageChanged,
            initialLanguage: widget.currentLanguage,
            onSignOut: widget.onSignOut,
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
      },
    );
  }
}
