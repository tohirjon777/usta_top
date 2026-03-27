import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme_preference.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/push_notifications_provider.dart';
import '../providers/theme_provider.dart';

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
    final NotificationSettingsProvider notificationSettingsProvider =
        context.watch<NotificationSettingsProvider>();
    final PushNotificationsProvider pushNotificationsProvider =
        context.watch<PushNotificationsProvider>();
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final AppLanguage language = languageProvider.language;
    final AppThemePreference themePreference = themeProvider.preference;
    final bool isLoadingProfile = authProvider.isLoadingProfile;
    final String? profileError = authProvider.errorMessage;
    final String fullName = _displayValue(
      authProvider.currentUser?.fullName,
      l10n.profileUnknownName,
    );
    final String rawFullName = authProvider.currentUser?.fullName.trim() ?? '';
    final String rawPhone = authProvider.currentUser?.phone.trim() ?? '';
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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        TextButton.icon(
                          onPressed: isLoadingProfile ||
                                  authProvider.currentUser == null
                              ? null
                              : () => _showEditProfileSheet(
                                    initialName: rawFullName,
                                    initialPhone: rawPhone,
                                  ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l10n.editProfile),
                        ),
                        TextButton.icon(
                          onPressed: isLoadingProfile ||
                                  authProvider.currentUser == null
                              ? null
                              : _showChangePasswordSheet,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft,
                          ),
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: Text(l10n.changePassword),
                        ),
                      ],
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
            subtitle: notificationSettingsProvider.isEnabled
                ? l10n.enabled
                : l10n.disabled,
            onTap: _toggleNotifications,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.notification_add_outlined,
            title: l10n.testPushNotification,
            subtitle: pushNotificationsProvider.lastError ??
                (pushNotificationsProvider.isFirebaseReady
                    ? l10n.pushReady
                    : l10n.pushNotReady),
            onTap: authProvider.isLoggedIn ? () => _sendTestPush() : null,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.languageName(language),
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.brightness_6_outlined,
            title: l10n.theme,
            subtitle: l10n.themeModeName(themePreference),
            onTap: _showThemePicker,
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

  Future<void> _toggleNotifications() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NotificationSettingsProvider notificationSettingsProvider =
        context.read<NotificationSettingsProvider>();
    await notificationSettingsProvider.toggle();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationSettingsProvider.isEnabled
              ? l10n.notificationsEnabled
              : l10n.notificationsDisabled,
        ),
      ),
    );
  }

  Future<void> _sendTestPush() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool success = await context.read<AuthProvider>().sendTestPush();
    if (!mounted) {
      return;
    }
    final String message = success
        ? l10n.testPushSent
        : (context.read<AuthProvider>().errorMessage ?? l10n.testPushFailed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  Future<void> _showThemePicker() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeProvider themeProvider = context.read<ThemeProvider>();
    final AppThemePreference currentPreference = themeProvider.preference;
    final AppThemePreference? selected =
        await showModalBottomSheet<AppThemePreference>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...AppThemePreference.values.map(
                (AppThemePreference preference) => ListTile(
                  leading: Icon(_themeModeIcon(preference)),
                  title: Text(l10n.themeModeName(preference)),
                  trailing: currentPreference == preference
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(preference),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    await themeProvider.setPreference(selected);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.themeChanged(l10n.themeModeName(selected)))),
    );
  }

  IconData _themeModeIcon(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return Icons.brightness_auto_outlined;
      case AppThemePreference.light:
        return Icons.light_mode_outlined;
      case AppThemePreference.dark:
        return Icons.dark_mode_outlined;
    }
  }

  Future<void> _showEditProfileSheet({
    required String initialName,
    required String initialPhone,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController nameController =
        TextEditingController(text: initialName);
    final TextEditingController phoneController =
        TextEditingController(text: initialPhone);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final BuildContext parentContext = context;
    final AuthProvider authProvider = parentContext.read<AuthProvider>();
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(parentContext);
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              if (isSaving || !(formKey.currentState?.validate() ?? false)) {
                return;
              }

              final String nextName = nameController.text.trim();
              final String nextPhone = phoneController.text.trim();
              if (nextName == initialName.trim() &&
                  _normalizePhone(nextPhone) == _normalizePhone(initialPhone)) {
                Navigator.of(context).pop();
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              bool shouldResetSaving = true;
              try {
                final bool success =
                    await authProvider.updateCurrentUserProfile(
                  fullName: nextName,
                  phone: nextPhone,
                );
                final String? providerError = authProvider.errorMessage;
                final String message = success
                    ? l10n.profileUpdated
                    : (providerError?.trim().isNotEmpty ?? false)
                        ? providerError!
                        : l10n.profileUpdateFailed;

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                  shouldResetSaving = false;
                }

                if (parentContext.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } finally {
                if (shouldResetSaving && context.mounted) {
                  setModalState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.editProfile,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        enabled: !isSaving,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: l10n.profileNameField,
                          hintText: l10n.profileNameHint,
                        ),
                        validator: (String? value) {
                          final String normalized = value?.trim() ?? '';
                          if (normalized.isEmpty) {
                            return l10n.profileNameRequired;
                          }
                          if (normalized.length < 2) {
                            return l10n.profileNameTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          hintText: l10n.phoneHint,
                        ),
                        validator: (String? value) {
                          final String normalized =
                              _normalizePhone(value ?? '');
                          if (normalized.isEmpty) {
                            return l10n.phoneRequired;
                          }
                          if (normalized.length < 7) {
                            return l10n.phoneInvalid;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: isSaving ? null : submit,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.saveChanges),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordSheet() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final BuildContext parentContext = context;
    final AuthProvider authProvider = parentContext.read<AuthProvider>();
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(parentContext);
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              if (isSaving || !(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              bool shouldResetSaving = true;
              try {
                final bool success = await authProvider.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                final String? providerError = authProvider.errorMessage;
                final String message = success
                    ? l10n.passwordUpdated
                    : (providerError?.trim().isNotEmpty ?? false)
                        ? providerError!
                        : l10n.passwordUpdateFailed;

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                  shouldResetSaving = false;
                }

                if (parentContext.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } finally {
                if (shouldResetSaving && context.mounted) {
                  setModalState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.changePassword,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: currentPasswordController,
                        enabled: !isSaving,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.currentPassword,
                        ),
                        validator: (String? value) {
                          if ((value ?? '').isEmpty) {
                            return l10n.passwordRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        enabled: !isSaving,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.newPassword,
                        ),
                        validator: (String? value) {
                          final String normalized = value ?? '';
                          if (normalized.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (normalized.length < 6) {
                            return l10n.passwordLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        enabled: !isSaving,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                        ),
                        validator: (String? value) {
                          final String normalized = value ?? '';
                          if (normalized.isEmpty) {
                            return l10n.confirmPasswordRequired;
                          }
                          if (normalized != newPasswordController.text) {
                            return l10n.passwordsDoNotMatch;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: isSaving ? null : submit,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.saveChanges),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
