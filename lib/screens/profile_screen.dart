import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenBookingHistory,
    required this.onOpenSavedSalons,
  });

  final VoidCallback onOpenBookingHistory;
  final VoidCallback onOpenSavedSalons;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final AuthProvider authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn &&
          authProvider.currentUser == null &&
          !authProvider.isLoadingProfile) {
        authProvider.loadCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingProvider bookingProvider = context.watch<BookingProvider>();
    final LanguageProvider languageProvider = context.watch<LanguageProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final AppLanguage language = languageProvider.language;
    final bool isLoadingProfile = authProvider.isLoadingProfile;
    final String? profileError = authProvider.errorMessage;
    final String fullName = _displayValue(
      authProvider.currentUser?.fullName,
      l10n.profileUnknownName,
    );
    final String phone = _displayValue(
      authProvider.currentUser?.phone,
      l10n.profileUnknownPhone,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryToneOf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isLoadingProfile
                    ? null
                    : () => context.read<AuthProvider>().loadCurrentUser(),
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refresh,
              ),
            ],
          ),
          if (isLoadingProfile) ...<Widget>[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ] else if (profileError != null &&
              authProvider.currentUser == null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              profileError,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: l10n.totalBookings,
                  value: '${bookingProvider.totalBookings}',
                  icon: Icons.bar_chart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: l10n.upcoming,
                  value: '${bookingProvider.upcomingBookings}',
                  icon: Icons.upcoming,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MenuTile(
            icon: Icons.history,
            title: l10n.bookingHistory,
            subtitle: l10n.bookingHistorySubtitle,
            onTap: widget.onOpenBookingHistory,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.favorite_outline,
            title: l10n.savedSalons,
            subtitle: l10n.savedSalonsSubtitle,
            onTap: widget.onOpenSavedSalons,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.notifications_none,
            title: l10n.notifications,
            subtitle: _notificationsEnabled ? l10n.enabled : l10n.disabled,
            onTap: _toggleNotifications,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.languageName(language),
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });

    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _notificationsEnabled
              ? l10n.notificationsEnabled
              : l10n.notificationsDisabled,
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LanguageProvider languageProvider = context.read<LanguageProvider>();
    final AppLanguage currentLanguage = languageProvider.language;
    final AppLanguage? selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...AppLanguage.values.map(
                (AppLanguage language) => ListTile(
                  title: Text(l10n.languageName(language)),
                  trailing: currentLanguage == language
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(language),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == currentLanguage) {
      return;
    }

    languageProvider.setLanguage(selected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.languageSwitched(l10n.languageName(selected)))),
    );
  }

  Future<void> _confirmSignOut() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.signOutTitle),
          content: Text(l10n.signOutConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await context.read<AuthProvider>().signOut();
  }

  String _displayValue(String? value, String fallback) {
    if (value == null) {
      return fallback;
    }

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    return normalized;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.primaryToneOf(context)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              label,
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primaryToneOf(context)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
