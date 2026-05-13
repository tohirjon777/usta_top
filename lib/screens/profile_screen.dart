import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme_preference.dart';
import '../core/utils/formatters.dart';
import '../models/cashback_transaction.dart';
import '../models/saved_payment_card.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_reveal.dart';
import '../widgets/profile_avatar_view.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

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
    final String? avatarUrl =
        authProvider.currentUser?.avatarUrl?.trim().isEmpty ?? true
            ? null
            : authProvider.currentUser?.avatarUrl;
    final List<SavedPaymentCard> savedPaymentCards =
        authProvider.currentUser?.savedPaymentCards ??
            const <SavedPaymentCard>[];
    final List<CashbackTransaction> cashbackTransactions =
        authProvider.currentUser?.cashbackTransactions ??
            const <CashbackTransaction>[];
    final List<CashbackTransaction> latestCashbackTransactions =
        cashbackTransactions.take(5).toList(growable: false);
    final bool canManageCards =
        !isLoadingProfile && authProvider.currentUser != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          AppReveal(
            child: _ProfileHeroCard(
              fullName: fullName,
              phone: phone,
              avatarUrl: avatarUrl,
              isLoadingProfile: isLoadingProfile,
              refreshTooltip: l10n.refresh,
              editLabel: l10n.editProfile,
              passwordLabel: l10n.changePassword,
              changeAvatarLabel: l10n.changeAvatar,
              onRefresh: () => context.read<AuthProvider>().loadCurrentUser(),
              onChangeAvatar:
                  isLoadingProfile || authProvider.currentUser == null
                      ? null
                      : _pickAvatar,
              onEditProfile:
                  isLoadingProfile || authProvider.currentUser == null
                      ? null
                      : () => _showEditProfileSheet(
                            initialName: rawFullName,
                            initialPhone: rawPhone,
                          ),
              onChangePassword:
                  isLoadingProfile || authProvider.currentUser == null
                      ? null
                      : _showChangePasswordSheet,
            ),
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
          AppReveal(
            delay: const Duration(milliseconds: 90),
            child: _ProfileSectionHeader(
              title: l10n.totalBookings,
              subtitle: l10n.bookingHistorySubtitle,
            ),
          ),
          const SizedBox(height: 12),
          AppReveal(
            delay: const Duration(milliseconds: 130),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        label: l10n.totalBookings,
                        value: '${bookingProvider.totalBookings}',
                        icon: Icons.bar_chart_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: l10n.upcoming,
                        value: '${bookingProvider.upcomingBookings}',
                        icon: Icons.event_available_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StatCard(
                  label: l10n.cashbackTrialBalance,
                  value: AppFormatters.moneyK(
                    authProvider.currentUser?.cashbackBalance ?? 0,
                  ),
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppReveal(
            delay: const Duration(milliseconds: 165),
            child: _ProfileSectionHeader(
              title: l10n.cashbackHistoryTitle,
              subtitle: l10n.cashbackHistorySubtitle,
            ),
          ),
          const SizedBox(height: 12),
          if (cashbackTransactions.isEmpty)
            AppReveal(
              delay: const Duration(milliseconds: 190),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.cashbackHistoryEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryTextOf(context),
                        ),
                  ),
                ),
              ),
            )
          else
            ...latestCashbackTransactions.asMap().entries.map(
                  (MapEntry<int, CashbackTransaction> entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == latestCashbackTransactions.length - 1
                          ? 0
                          : 10,
                    ),
                    child: AppReveal(
                      delay: Duration(milliseconds: 190 + (entry.key * 35)),
                      child: _CashbackTransactionTile(
                        transaction: entry.value,
                        l10n: l10n,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 18),
          AppReveal(
            delay: const Duration(milliseconds: 170),
            child: _ProfileSectionHeader(
              title: l10n.savedCardsTitle,
              subtitle: l10n.savedCardsSubtitle,
            ),
          ),
          const SizedBox(height: 12),
          if (savedPaymentCards.isEmpty)
            AppReveal(
              delay: const Duration(milliseconds: 210),
              child: _EmptyCardsCard(
                title: l10n.noSavedCardsTitle,
                subtitle: l10n.noSavedCardsSubtitle,
                actionLabel: l10n.addPaymentCard,
                onTap: canManageCards ? _showAddPaymentCardSheet : null,
              ),
            )
          else
            ...savedPaymentCards.asMap().entries.map(
                  (MapEntry<int, SavedPaymentCard> entry) => Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            entry.key == savedPaymentCards.length - 1 ? 0 : 10),
                    child: AppReveal(
                      delay: Duration(milliseconds: 210 + (entry.key * 40)),
                      child: _PaymentCardTile(
                        card: entry.value,
                        editLabel: l10n.editPaymentCard,
                        deleteLabel: l10n.deletePaymentCard,
                        defaultLabel: l10n.paymentCardDefault,
                        onEdit: canManageCards
                            ? () => _showEditPaymentCardSheet(entry.value)
                            : null,
                        onDelete: canManageCards
                            ? () => _confirmDeletePaymentCard(entry.value)
                            : null,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          AppReveal(
            delay: Duration(
              milliseconds: savedPaymentCards.isEmpty
                  ? 250
                  : 240 + (savedPaymentCards.length * 40),
            ),
            child: OutlinedButton.icon(
              onPressed: canManageCards ? _showAddPaymentCardSheet : null,
              icon: const Icon(Icons.add_card_rounded),
              label: Text(l10n.addPaymentCard),
            ),
          ),
          const SizedBox(height: 18),
          AppReveal(
            delay: const Duration(milliseconds: 370),
            child: _ProfileSectionHeader(
              title: l10n.navProfile,
              subtitle: l10n.themeModeName(themePreference),
            ),
          ),
          const SizedBox(height: 12),
          AppReveal(
            delay: const Duration(milliseconds: 410),
            child: _MenuTile(
              icon: Icons.history,
              title: l10n.bookingHistory,
              subtitle: l10n.bookingHistorySubtitle,
              onTap: widget.onOpenBookingHistory,
            ),
          ),
          const SizedBox(height: 10),
          AppReveal(
            delay: const Duration(milliseconds: 450),
            child: _MenuTile(
              icon: Icons.favorite_outline,
              title: l10n.savedSalons,
              subtitle: l10n.savedSalonsSubtitle,
              onTap: widget.onOpenSavedSalons,
            ),
          ),
          const SizedBox(height: 10),
          AppReveal(
            delay: const Duration(milliseconds: 490),
            child: _MenuTile(
              icon: Icons.notifications_none,
              title: l10n.notifications,
              subtitle: notificationSettingsProvider.isEnabled
                  ? l10n.enabled
                  : l10n.disabled,
              onTap: _toggleNotifications,
            ),
          ),
          const SizedBox(height: 10),
          AppReveal(
            delay: const Duration(milliseconds: 530),
            child: _MenuTile(
              icon: Icons.language,
              title: l10n.language,
              subtitle: l10n.languageName(language),
              onTap: _showLanguagePicker,
            ),
          ),
          const SizedBox(height: 10),
          AppReveal(
            delay: const Duration(milliseconds: 570),
            child: _MenuTile(
              icon: Icons.bedtime_outlined,
              title: l10n.theme,
              subtitle: l10n.themeModeName(themePreference),
              onTap: _showThemePicker,
            ),
          ),
          const SizedBox(height: 12),
          AppReveal(
            delay: const Duration(milliseconds: 610),
            child: OutlinedButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout),
              label: Text(l10n.signOut),
            ),
          ),
          const SizedBox(height: 10),
          AppReveal(
            delay: const Duration(milliseconds: 650),
            child: OutlinedButton.icon(
              onPressed: isLoadingProfile ? null : _confirmDeleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.deleteAccount),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthProvider authProvider = context.read<AuthProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (file == null || !mounted) {
      return;
    }

    final List<int> bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    final bool success = await authProvider.uploadCurrentUserAvatar(
      bytes: bytes,
      fileName: file.name.isEmpty ? 'avatar.jpg' : file.name,
    );

    if (!mounted) {
      return;
    }

    final String? providerError = authProvider.errorMessage;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.avatarUpdated
              : (providerError?.trim().isNotEmpty ?? false)
                  ? providerError!
                  : l10n.avatarUpdateFailed,
        ),
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

  Future<void> _showAddPaymentCardSheet() {
    return _showPaymentCardSheet();
  }

  Future<void> _showEditPaymentCardSheet(SavedPaymentCard card) {
    return _showPaymentCardSheet(card: card);
  }

  Future<void> _showPaymentCardSheet({
    SavedPaymentCard? card,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController holderNameController = TextEditingController(
      text: card?.holderName ?? '',
    );
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryController = TextEditingController(
      text: card == null ? '' : card.expiryLabel,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final BuildContext parentContext = context;
    final AuthProvider authProvider = parentContext.read<AuthProvider>();
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(parentContext);
    bool isSaving = false;
    bool isDefault = card?.isDefault ??
        ((authProvider.currentUser?.savedPaymentCards.length ?? 0) == 0);

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

              final String holderName = holderNameController.text.trim();
              final String cardNumber = cardNumberController.text.trim();
              final ({int month, int year})? expiry = _parseExpiryInput(
                expiryController.text,
              );
              if (expiry == null) {
                return;
              }

              if (card != null &&
                  holderName == card.holderName &&
                  cardNumber.isEmpty &&
                  expiry.month == card.expiryMonth &&
                  expiry.year == card.expiryYear &&
                  isDefault == card.isDefault) {
                Navigator.of(context).pop();
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              bool shouldResetSaving = true;
              try {
                final bool success;
                if (card == null) {
                  success = await authProvider.addPaymentCard(
                    holderName: holderName,
                    cardNumber: cardNumber,
                    expiryMonth: expiry.month,
                    expiryYear: expiry.year,
                    isDefault: isDefault,
                  );
                } else {
                  success = await authProvider.updatePaymentCard(
                    cardId: card.id,
                    holderName: holderName,
                    cardNumber: cardNumber,
                    expiryMonth: expiry.month,
                    expiryYear: expiry.year,
                    isDefault: isDefault,
                  );
                }

                final String? providerError = authProvider.errorMessage;
                final String message = success
                    ? (card == null
                        ? l10n.paymentCardSaved
                        : l10n.paymentCardUpdated)
                    : (providerError?.trim().isNotEmpty ?? false)
                        ? providerError!
                        : l10n.paymentCardSaveFailed;

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
                        card == null
                            ? l10n.addPaymentCard
                            : l10n.editPaymentCard,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: holderNameController,
                        enabled: !isSaving,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: l10n.paymentCardHolderName,
                          hintText: l10n.paymentCardHolderHint,
                        ),
                        validator: (String? value) {
                          final String normalized = value?.trim() ?? '';
                          if (normalized.isEmpty) {
                            return l10n.paymentCardHolderRequired;
                          }
                          if (normalized.length < 2) {
                            return l10n.paymentCardHolderShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cardNumberController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.paymentCardNumber,
                          hintText: l10n.paymentCardNumberHint,
                          helperText: card == null
                              ? null
                              : '${l10n.paymentCardNumberEditHint}\n${card.maskedNumber}',
                        ),
                        validator: (String? value) {
                          final String digits =
                              SavedPaymentCard.normalizeDigits(
                            value ?? '',
                          );
                          if (card == null && digits.isEmpty) {
                            return l10n.paymentCardRequired;
                          }
                          if (digits.isEmpty) {
                            return null;
                          }
                          if (digits.length < 12 || digits.length > 19) {
                            return l10n.paymentCardInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: expiryController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.paymentCardExpiry,
                          hintText: l10n.paymentCardExpiryHint,
                        ),
                        validator: (String? value) {
                          final String normalized = value?.trim() ?? '';
                          if (normalized.isEmpty) {
                            return l10n.paymentCardExpiryRequired;
                          }
                          if (_parseExpiryInput(normalized) == null) {
                            return l10n.paymentCardExpiryInvalid;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isDefault,
                        onChanged: isSaving
                            ? null
                            : (bool value) {
                                setModalState(() {
                                  isDefault = value;
                                });
                              },
                        title: Text(l10n.paymentCardMarkDefault),
                        subtitle: Text(l10n.paymentCardDefault),
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

  Future<void> _confirmDeletePaymentCard(SavedPaymentCard card) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.paymentCardDeleteTitle),
          content: Text(l10n.paymentCardDeleteConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deletePaymentCard),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.deletePaymentCard(cardId: card.id);
    if (!mounted) {
      return;
    }

    final String? providerError = authProvider.errorMessage;
    final String message = success
        ? l10n.paymentCardDeleted
        : (providerError?.trim().isNotEmpty ?? false)
            ? providerError!
            : l10n.paymentCardDeleteFailed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  Future<void> _confirmDeleteAccount() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.deleteAccountConfirm),
              const SizedBox(height: 10),
              Text(
                l10n.deleteAccountWarning,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAccount),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final bool success = await authProvider.deleteAccount();
    final String? providerError = authProvider.errorMessage;
    final String message = success
        ? l10n.deleteAccountSuccess
        : (providerError?.trim().isNotEmpty ?? false)
            ? providerError!
            : l10n.deleteAccountFailed;
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

  ({int month, int year})? _parseExpiryInput(String raw) {
    final String normalized = raw.trim().replaceAll(' ', '');
    final List<String> parts = normalized.split('/');
    if (parts.length != 2) {
      return null;
    }

    final int? month = int.tryParse(parts[0]);
    final int? yearValue = int.tryParse(parts[1]);
    if (month == null || yearValue == null) {
      return null;
    }

    final int year = yearValue < 100 ? 2000 + yearValue : yearValue;
    if (month < 1 || month > 12 || year < 2000) {
      return null;
    }

    final DateTime now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return null;
    }

    return (month: month, year: year);
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.isLoadingProfile,
    required this.refreshTooltip,
    required this.editLabel,
    required this.passwordLabel,
    required this.changeAvatarLabel,
    required this.onRefresh,
    this.onChangeAvatar,
    this.onEditProfile,
    this.onChangePassword,
  });

  final String fullName;
  final String phone;
  final String? avatarUrl;
  final bool isLoadingProfile;
  final String refreshTooltip;
  final String editLabel;
  final String passwordLabel;
  final String changeAvatarLabel;
  final VoidCallback onRefresh;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Color.lerp(
                      AppColors.primaryToneOf(context), Colors.black, 0.16)!,
                  Color.lerp(
                    AppColors.accentOf(context),
                    AppColors.primaryToneOf(context),
                    0.42,
                  )!,
                ]
              : <Color>[
                  AppColors.primarySoftOf(context),
                  AppColors.accentSoftOf(context),
                ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryToneOf(context).withValues(
              alpha: isDark ? 0.18 : 0.12,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.borderOf(context),
              ),
            ),
            child: ProfileAvatarView(
              size: 74,
              initials: _initials(fullName),
              imageUrl: avatarUrl,
              onEdit: onChangeAvatar,
              editTooltip: changeAvatarLabel,
              isLoading: isLoadingProfile,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: isDark ? Colors.white : null,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.84)
                            : AppColors.secondaryTextOf(context),
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _HeroActionChip(
                      icon: Icons.edit_outlined,
                      label: editLabel,
                      onTap: onEditProfile,
                    ),
                    _HeroActionChip(
                      icon: Icons.lock_outline,
                      label: passwordLabel,
                      onTap: onChangePassword,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isLoadingProfile ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: refreshTooltip,
            color: isDark ? Colors.white : null,
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .cardColor
              .withValues(alpha: isDark ? 0.20 : 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : AppColors.borderOf(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white : AppColors.primaryToneOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark ? Colors.white : null,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardsCard extends StatelessWidget {
  const _EmptyCardsCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accentSoftOf(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.add_card_rounded,
                color: AppColors.accentOf(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCardTile extends StatelessWidget {
  const _PaymentCardTile({
    required this.card,
    required this.editLabel,
    required this.deleteLabel,
    required this.defaultLabel,
    this.onEdit,
    this.onDelete,
  });

  final SavedPaymentCard card;
  final String editLabel;
  final String deleteLabel;
  final String defaultLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ({Color start, Color end}) colors =
        _colorsForBrand(context, card.brand);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.start, colors.end],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.end.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          card.brandLabel,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.holderName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (card.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        defaultLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                card.maskedNumber,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CardMetaValue(
                      label: 'EXP',
                      value: card.expiryLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardMetaValue(
                      label: 'CARD',
                      value: card.last4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(editLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(deleteLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color start, Color end}) _colorsForBrand(
      BuildContext context, String brand) {
    switch (brand.trim().toLowerCase()) {
      case 'visa':
        return (
          start: const Color(0xFF163A8C),
          end: const Color(0xFF2C67F2),
        );
      case 'mastercard':
        return (
          start: const Color(0xFF7C2710),
          end: const Color(0xFFE46A2E),
        );
      case 'humo':
        return (
          start: const Color(0xFF006A6E),
          end: const Color(0xFF0AA4A3),
        );
      case 'uzcard':
        return (
          start: const Color(0xFF0C6E3E),
          end: const Color(0xFF28A85D),
        );
      default:
        return (
          start: AppColors.primaryToneOf(context),
          end: AppColors.accentOf(context),
        );
    }
  }
}

class _CardMetaValue extends StatelessWidget {
  const _CardMetaValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.68),
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryTextOf(context),
              ),
        ),
      ],
    );
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoftOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(icon, color: AppColors.primaryToneOf(context)),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
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

class _CashbackTransactionTile extends StatelessWidget {
  const _CashbackTransactionTile({
    required this.transaction,
    required this.l10n,
  });

  final CashbackTransaction transaction;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.amount > 0;
    final Color accent = isCredit
        ? AppColors.primaryToneOf(context)
        : Theme.of(context).colorScheme.error;
    final String amount = AppFormatters.moneyK(transaction.amount.abs());
    final String amountText = isCredit ? '+$amount' : '-$amount';
    final String subtitle = <String>[
      if (transaction.serviceName.isNotEmpty) transaction.serviceName,
      if (transaction.workshopName.isNotEmpty) transaction.workshopName,
      if (transaction.createdAt != null)
        AppFormatters.dateTime(transaction.createdAt!),
    ].join(' - ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(_iconForType(transaction.type), color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _titleForType(transaction.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    l10n.cashbackBalanceAfterLabel(
                      AppFormatters.moneyK(transaction.balanceAfter),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryTextOf(context),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amountText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForType(String type) {
    switch (type) {
      case 'earned':
        return l10n.cashbackTransactionEarned;
      case 'redeemed':
        return l10n.cashbackTransactionRedeemed;
      case 'refunded':
        return l10n.cashbackTransactionRefunded;
      default:
        return l10n.cashbackHistoryTitle;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'earned':
        return Icons.savings_outlined;
      case 'redeemed':
        return Icons.payments_outlined;
      case 'refunded':
        return Icons.undo_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Icon(icon, color: AppColors.primaryToneOf(context)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryTextOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
