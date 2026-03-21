import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../providers/booking_provider.dart';
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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WorkshopProvider>().loadWorkshops();
      context.read<BookingProvider>().loadBookings();
    });
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
