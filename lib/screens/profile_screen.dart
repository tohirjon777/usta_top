import 'package:flutter/material.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.onOpenBookingHistory,
    required this.onOpenSavedSalons,
    required this.onNotificationsChanged,
    required this.onLanguageChanged,
    required this.initialLanguage,
    required this.onSignOut,
  });

  final int totalBookings;
  final int upcomingBookings;
  final VoidCallback onOpenBookingHistory;
  final VoidCallback onOpenSavedSalons;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppLanguage initialLanguage;
  final VoidCallback onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLanguage != widget.initialLanguage) {
      _language = widget.initialLanguage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

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
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Tokhirjon',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+998 90 123 45 67',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: l10n.totalBookings,
                  value: '${widget.totalBookings}',
                  icon: Icons.bar_chart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: l10n.upcoming,
                  value: '${widget.upcomingBookings}',
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
            subtitle: l10n.languageName(_language),
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
    widget.onNotificationsChanged(_notificationsEnabled);
  }

  Future<void> _showLanguagePicker() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
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
                  trailing:
                      _language == language ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(language),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == _language) {
      return;
    }

    setState(() {
      _language = selected;
    });
    widget.onLanguageChanged(selected);
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

    widget.onSignOut();
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
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
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
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
