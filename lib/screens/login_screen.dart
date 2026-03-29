import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../ui/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_reveal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              AppReveal(
                child: _AuthHeroCard(
                  title: l10n.appTitle,
                  subtitle: l10n.signInDescription,
                ),
              ),
              const SizedBox(height: 18),
              AppReveal(
                delay: const Duration(milliseconds: 100),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Column(
                            children: <Widget>[
                              Image.asset(
                                AppAssets.logo,
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                              ),
                              AppSpacing.h12,
                              Text(
                                l10n.welcomeBack,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              AppSpacing.h4,
                              Text(
                                l10n.findTrustedMasters,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.secondaryTextOf(context),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.h20,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _AuthFeaturePill(
                              icon: Icons.flash_on_rounded,
                              label: l10n.fastConfirmation,
                            ),
                            _AuthFeaturePill(
                              icon: Icons.verified_outlined,
                              label: l10n.verifiedMasters,
                            ),
                          ],
                        ),
                        AppSpacing.h20,
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.phoneNumber,
                            hintText: l10n.phoneHint,
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                          validator: (String? value) =>
                              _validatePhone(value, l10n),
                        ),
                        AppSpacing.h12,
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (String? value) => _validatePassword(
                            value,
                            l10n,
                            requiredMessage: l10n.passwordRequired,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isSubmitting ? null : _showForgotPasswordSheet,
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                        AppSpacing.h8,
                        AppPrimaryButton(
                          label: l10n.signIn,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppSpacing.h20,
              AppReveal(
                delay: const Duration(milliseconds: 180),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.noAccountYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AppSpacing.h4,
                        Text(
                          l10n.signUpDescription,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondaryTextOf(context),
                                  ),
                        ),
                        AppSpacing.h12,
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                _isSubmitting ? null : _showRegistrationSheet,
                            child: Text(l10n.createAccount),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final AuthProvider authProvider = context.read<AuthProvider>();
    final bool success = await authProvider.signIn(
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      return;
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final String message = authProvider.errorMessage?.trim().isNotEmpty == true
        ? authProvider.errorMessage!
        : l10n.loginFailed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showRegistrationSheet() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final BuildContext parentContext = context;
    final AuthProvider authProvider = parentContext.read<AuthProvider>();
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(parentContext);
    bool isSaving = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

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

              final bool success = await authProvider.signUp(
                fullName: fullNameController.text.trim(),
                phone: phoneController.text.trim(),
                password: passwordController.text,
              );
              if (!mounted) {
                return;
              }

              final String? providerError = authProvider.errorMessage;
              if (success) {
                _phoneController.text = phoneController.text.trim();
                _passwordController.text = passwordController.text;
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                return;
              }

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    (providerError?.trim().isNotEmpty ?? false)
                        ? providerError!
                        : l10n.signUpFailed,
                  ),
                ),
              );

              if (context.mounted) {
                setModalState(() {
                  isSaving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.signUp,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AppSpacing.h4,
                    Text(
                      l10n.signUpDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: fullNameController,
                      enabled: !isSaving,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.fullName),
                      validator: (String? value) =>
                          _validateFullName(value, l10n),
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: phoneController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumber,
                        hintText: l10n.phoneHint,
                      ),
                      validator: (String? value) => _validatePhone(value, l10n),
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: passwordController,
                      enabled: !isSaving,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (String? value) => _validatePassword(
                        value,
                        l10n,
                        requiredMessage: l10n.passwordRequired,
                      ),
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: confirmPasswordController,
                      enabled: !isSaving,
                      obscureText: obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        final String? base = _validatePassword(
                          value,
                          l10n,
                          requiredMessage: l10n.confirmPasswordRequired,
                        );
                        if (base != null) {
                          return base;
                        }
                        if ((value ?? '') != passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => submit(),
                    ),
                    AppSpacing.h16,
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
                                : Text(l10n.createAccount),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showForgotPasswordSheet() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController phoneController =
        TextEditingController(text: _phoneController.text.trim());
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final BuildContext parentContext = context;
    final AuthProvider authProvider = parentContext.read<AuthProvider>();
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(parentContext);
    bool isSaving = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

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

              final String phone = phoneController.text.trim();
              final String newPassword = passwordController.text;
              final bool success = await authProvider.resetPassword(
                phone: phone,
                newPassword: newPassword,
              );
              if (!mounted) {
                return;
              }

              final String? providerError = authProvider.errorMessage;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.passwordResetSuccess
                        : (providerError?.trim().isNotEmpty ?? false)
                            ? providerError!
                            : l10n.passwordResetFailed,
                  ),
                ),
              );

              if (success) {
                _phoneController.text = phone;
                _passwordController.text = newPassword;
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                return;
              }

              if (context.mounted) {
                setModalState(() {
                  isSaving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.resetPassword,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AppSpacing.h4,
                    Text(
                      l10n.forgotPasswordDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: phoneController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumber,
                        hintText: l10n.phoneHint,
                      ),
                      validator: (String? value) => _validatePhone(value, l10n),
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: passwordController,
                      enabled: !isSaving,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.newPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (String? value) => _validatePassword(
                        value,
                        l10n,
                        requiredMessage: l10n.passwordRequired,
                      ),
                    ),
                    AppSpacing.h12,
                    TextFormField(
                      controller: confirmPasswordController,
                      enabled: !isSaving,
                      obscureText: obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        final String? base = _validatePassword(
                          value,
                          l10n,
                          requiredMessage: l10n.confirmPasswordRequired,
                        );
                        if (base != null) {
                          return base;
                        }
                        if ((value ?? '') != passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => submit(),
                    ),
                    AppSpacing.h16,
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
                                : Text(l10n.resetPassword),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  String? _validateFullName(String? value, AppLocalizations l10n) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return l10n.profileNameRequired;
    }
    if (normalized.length < 2) {
      return l10n.profileNameTooShort;
    }
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    final String normalized = _normalizePhone(value ?? '');
    if (normalized.isEmpty) {
      return l10n.phoneRequired;
    }
    if (normalized.length < 7) {
      return l10n.phoneInvalid;
    }
    return null;
  }

  String? _validatePassword(
    String? value,
    AppLocalizations l10n, {
    required String requiredMessage,
  }) {
    final String normalized = value ?? '';
    if (normalized.isEmpty) {
      return requiredMessage;
    }
    if (normalized.length < 6) {
      return l10n.passwordLength;
    }
    return null;
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
  }
}

class _AuthHeroCard extends StatelessWidget {
  const _AuthHeroCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primarySoftOf(context),
            AppColors.accentSoftOf(context),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _AuthFeaturePill extends StatelessWidget {
  const _AuthFeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primaryToneOf(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
