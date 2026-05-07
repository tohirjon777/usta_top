import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';
import '../models/review_analytics.dart';
import '../models/salon.dart';
import '../models/salon_review.dart';
import '../providers/saved_workshops_provider.dart';
import '../providers/workshop_provider.dart';
import '../services/navigation_launcher.dart';
import '../ui/review_composer_sheet.dart';
import '../widgets/app_reveal.dart';
import '../widgets/workshop_image_view.dart';
import 'booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  const SalonDetailScreen({
    super.key,
    required this.salon,
    this.initialReviewServiceId = '',
    this.highlightedReviewId = '',
    this.autoOpenReviewComposer = false,
    this.reviewPromptBookingId = '',
    this.lockInitialReviewServiceSelection = false,
    this.initialBookingServiceId = '',
    this.autoOpenBooking = false,
  });

  final Salon salon;
  final String initialReviewServiceId;
  final String highlightedReviewId;
  final bool autoOpenReviewComposer;
  final String reviewPromptBookingId;
  final bool lockInitialReviewServiceSelection;
  final String initialBookingServiceId;
  final bool autoOpenBooking;

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  late Salon _salon;
  bool _isRefreshingDetail = false;
  late String _selectedReviewServiceId;
  final GlobalKey _reviewsSectionKey = GlobalKey();
  final Map<String, GlobalKey> _reviewCardKeys = <String, GlobalKey>{};
  bool _handledInitialReviewNavigation = false;
  bool _handledInitialBookingNavigation = false;

  @override
  void initState() {
    super.initState();
    _salon = widget.salon;
    _selectedReviewServiceId = widget.initialReviewServiceId.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_initializeDetail());
    });
  }

  Future<void> _initializeDetail() async {
    await _reloadWorkshop();
    if (!mounted) {
      return;
    }
    await _applyInitialBookingNavigation();
    if (!mounted) {
      return;
    }
    await _applyInitialReviewNavigation();
  }

  List<SalonReview> get _visibleReviews {
    final List<SalonReview> reviews = _salon.reviews;
    if (_selectedReviewServiceId.isEmpty) {
      return reviews;
    }
    return reviews
        .where((SalonReview item) => item.serviceId == _selectedReviewServiceId)
        .toList(growable: false);
  }

  ReviewAnalytics get _reviewAnalytics => ReviewAnalytics.fromSalon(
        reviews: _salon.reviews,
        services: _salon.services,
      );

  Future<void> _openBooking({
    required BuildContext context,
    SalonService? preselected,
  }) async {
    final BookingItem? booking = await Navigator.of(context).push<BookingItem>(
      MaterialPageRoute<BookingItem>(
        builder: (_) => BookingScreen(
          salon: _salon,
          preselectedServiceId: preselected?.id,
        ),
      ),
    );

    if (!context.mounted || booking == null) {
      return;
    }

    Navigator.of(context).pop(booking);
  }

  Future<void> _applyInitialBookingNavigation() async {
    if (_handledInitialBookingNavigation || !widget.autoOpenBooking) {
      return;
    }
    _handledInitialBookingNavigation = true;

    final String serviceId = widget.initialBookingServiceId.trim();
    if (serviceId.isEmpty) {
      return;
    }

    SalonService? service;
    for (final SalonService item in _salon.services) {
      if (item.id == serviceId) {
        service = item;
        break;
      }
    }

    if (!mounted || service == null) {
      return;
    }

    await _openBooking(context: context, preselected: service);
  }

  Future<void> _reloadWorkshop() async {
    if (_isRefreshingDetail) {
      return;
    }
    setState(() {
      _isRefreshingDetail = true;
    });
    final Salon? refreshed =
        await context.read<WorkshopProvider>().refreshWorkshopById(_salon.id);
    if (!mounted) {
      return;
    }
    if (refreshed != null) {
      setState(() {
        _salon = refreshed;
      });
    }
    setState(() {
      _isRefreshingDetail = false;
    });
  }

  Future<void> _openReviewComposer({
    SalonService? preselectedService,
    String? preselectedServiceId,
    String? bookingId,
    bool lockServiceSelection = false,
    String? title,
    String? subtitle,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? effectiveServiceId =
        preselectedService?.id ?? _normalizedValue(preselectedServiceId);
    final Salon? updated = await showWorkshopReviewComposerSheet(
      context: context,
      salon: _salon,
      l10n: l10n,
      preselectedServiceId: effectiveServiceId,
      bookingId: _normalizedValue(bookingId),
      lockServiceSelection: lockServiceSelection,
      title: title,
      subtitle: subtitle,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _salon = updated;
      _selectedReviewServiceId = updated.reviews.isEmpty
          ? ''
          : (effectiveServiceId ?? _selectedReviewServiceId);
    });
  }

  Future<void> _applyInitialReviewNavigation() async {
    if (!mounted || _handledInitialReviewNavigation) {
      return;
    }

    _handledInitialReviewNavigation = true;
    final String highlightedReviewId = widget.highlightedReviewId.trim();
    if (highlightedReviewId.isNotEmpty) {
      final SalonReview? target = _reviewById(highlightedReviewId);
      if (target != null && target.serviceId.isNotEmpty) {
        setState(() {
          _selectedReviewServiceId = target.serviceId;
        });
      }
      await _scrollToReviewSection();
      await _scrollToHighlightedReview(highlightedReviewId);
      return;
    }

    final String initialServiceId = widget.initialReviewServiceId.trim();
    if (initialServiceId.isNotEmpty) {
      setState(() {
        _selectedReviewServiceId = initialServiceId;
      });
    }

    if (widget.autoOpenReviewComposer) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      final String? serviceName = _serviceNameById(initialServiceId);
      await _scrollToReviewSection();
      await _openReviewComposer(
        preselectedServiceId: initialServiceId,
        bookingId: widget.reviewPromptBookingId,
        lockServiceSelection: widget.lockInitialReviewServiceSelection,
        title: l10n.reviewReminderTitle,
        subtitle: serviceName == null
            ? l10n.reviewSheetSubtitle
            : l10n.reviewReminderSubtitle(serviceName, _salon.name),
      );
      return;
    }

    if (initialServiceId.isNotEmpty) {
      await _scrollToReviewSection();
    }
  }

  Future<void> _scrollToReviewSection() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }

    final BuildContext? sectionContext = _reviewsSectionKey.currentContext;
    if (sectionContext == null || !sectionContext.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _scrollToHighlightedReview(String reviewId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }

    final BuildContext? reviewContext =
        _reviewCardKeys[reviewId]?.currentContext;
    if (reviewContext == null || !reviewContext.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      reviewContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  SalonReview? _reviewById(String reviewId) {
    for (final SalonReview review in _salon.reviews) {
      if (review.id == reviewId) {
        return review;
      }
    }
    return null;
  }

  String? _serviceNameById(String serviceId) {
    final String normalizedServiceId = serviceId.trim();
    if (normalizedServiceId.isEmpty) {
      return null;
    }
    for (final SalonService service in _salon.services) {
      if (service.id == normalizedServiceId) {
        return service.name;
      }
    }
    return null;
  }

  String? _normalizedValue(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  GlobalKey _reviewKey(String reviewId) {
    return _reviewCardKeys.putIfAbsent(reviewId, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color heroStart = AppColors.primarySoftOf(context);
    final Color heroEnd = AppColors.accentSoftOf(context);
    final SavedWorkshopsProvider savedProvider =
        context.watch<SavedWorkshopsProvider>();
    final bool isSaved = savedProvider.isSaved(_salon.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_salon.name),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _isRefreshingDetail ? null : _reloadWorkshop,
            icon: _isRefreshingDetail
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: isSaved ? l10n.removeSavedWorkshop : l10n.saveWorkshop,
            onPressed: () => _toggleSaved(context, _salon),
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.fromPrice(
                        AppFormatters.moneyK(_salon.startingPrice),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryToneOf(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _salon.isOpen ? l10n.openNow : l10n.currentlyClosed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _salon.isOpen
                      ? () => _openBooking(context: context)
                      : null,
                  child: Text(
                    _salon.isOpen
                        ? l10n.bookNowFrom(
                            AppFormatters.moneyK(_salon.startingPrice),
                          )
                        : l10n.currentlyClosed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadWorkshop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: <Widget>[
            AppReveal(
              child: _DetailHeroCard(
                salon: _salon,
                l10n: l10n,
                heroStart: heroStart,
                heroEnd: heroEnd,
              ),
            ),
            const SizedBox(height: 16),
            AppReveal(
              delay: const Duration(milliseconds: 90),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _InsightTile(
                      label: l10n.reviewAverageLabel,
                      value: _salon.rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InsightTile(
                      label: l10n.services,
                      value: '${_salon.services.length}',
                      icon: Icons.tune_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InsightTile(
                      label: l10n.bookAppointment,
                      value: AppFormatters.moneyK(_salon.startingPrice),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppReveal(
              delay: const Duration(milliseconds: 140),
              child: _SectionCard(
                title: l10n.services,
                trailing: TextButton.icon(
                  onPressed: () => _openReviewComposer(),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(l10n.writeReview),
                ),
                child: Column(
                  children: _salon.services
                      .map(
                        (SalonService service) => Padding(
                          padding: EdgeInsets.only(
                            bottom: service == _salon.services.last ? 0 : 12,
                          ),
                          child: _ServiceActionCard(
                            l10n: l10n,
                            salon: _salon,
                            service: service,
                            onBook: () => _openBooking(
                              context: context,
                              preselected: service,
                            ),
                            onReview: () => _openReviewComposer(
                              preselectedService: service,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              key: _reviewsSectionKey,
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.reviewsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_salon.reviews.isNotEmpty)
                  Text(
                    l10n.reviewsCount(_salon.reviews.length),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryTextOf(context),
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _ReviewAnalyticsCard(
              analytics: _reviewAnalytics,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            if (_salon.reviews.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    FilterChip(
                      selected: _selectedReviewServiceId.isEmpty,
                      label: Text(l10n.allServicesLabel),
                      onSelected: (_) {
                        setState(() {
                          _selectedReviewServiceId = '';
                        });
                      },
                    ),
                    ..._salon.services.map((SalonService service) {
                      final int count = _salon.reviews
                          .where(
                            (SalonReview item) => item.serviceId == service.id,
                          )
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          selected: _selectedReviewServiceId == service.id,
                          label: Text('${service.name} ($count)'),
                          onSelected: (_) {
                            setState(() {
                              _selectedReviewServiceId = service.id;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (_visibleReviews.isEmpty)
              _ReviewEmptyState(
                title: l10n.reviewsEmptyTitle,
                subtitle: l10n.reviewsEmptySubtitle,
                onPressed: () => _openReviewComposer(),
              )
            else
              ..._visibleReviews.map(
                (SalonReview review) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(
                    key: _reviewKey(review.id),
                    review: review,
                    l10n: l10n,
                    isHighlighted: review.id == widget.highlightedReviewId,
                  ),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSaved(BuildContext context, Salon salon) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SavedWorkshopsProvider savedProvider =
        context.read<SavedWorkshopsProvider>();

    try {
      final bool saved = await savedProvider.toggleSaved(salon.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? l10n.savedWorkshopAdded(salon.name)
                : l10n.savedWorkshopRemoved(salon.name),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedWorkshopUpdateFailed)),
      );
    }
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.salon,
    required this.l10n,
    required this.heroStart,
    required this.heroEnd,
  });

  final Salon salon;
  final AppLocalizations l10n;
  final Color heroStart;
  final Color heroEnd;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Color.lerp(
                      AppColors.primaryToneOf(context), Colors.black, 0.18)!,
                  Color.lerp(AppColors.accentOf(context),
                      AppColors.primaryToneOf(context), 0.42)!,
                ]
              : <Color>[heroStart, heroEnd],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryToneOf(context).withValues(
              alpha: isDark ? 0.18 : 0.14,
            ),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                WorkshopImageView(
                  imageUrl: salon.imageUrl,
                  width: 70,
                  height: 70,
                  borderRadius: BorderRadius.circular(22),
                  fallbackIcon: Icons.car_repair,
                  iconSize: 34,
                  overlay: Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        salon.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        salon.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetaPill(
                  icon: Icons.star,
                  text: '${salon.rating} (${salon.reviewCount})',
                ),
                _MetaPill(
                  icon: Icons.place_outlined,
                  text: '${salon.distanceKm.toStringAsFixed(1)} km',
                ),
                _MetaPill(
                  icon: Icons.circle,
                  text: salon.isOpen ? l10n.openNow : l10n.closedNow,
                  color: salon.isOpen
                      ? AppColors.primaryToneOf(context)
                      : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      salon.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => NavigationLauncher.showNavigatorPicker(
                context,
                salon: salon,
              ),
              icon: const Icon(Icons.route_outlined),
              label: Text(l10n.routeToWorkshop),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primaryToneOf(context)),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ServiceActionCard extends StatelessWidget {
  const _ServiceActionCard({
    required this.l10n,
    required this.salon,
    required this.service,
    required this.onBook,
    required this.onReview,
  });

  final AppLocalizations l10n;
  final Salon salon;
  final SalonService service;
  final VoidCallback onBook;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          text: l10n.durationMinutes(service.durationMinutes),
                        ),
                        if (service.prepaymentPercent > 0)
                          _MetaPill(
                            icon: Icons.account_balance_wallet_outlined,
                            text: '${service.prepaymentPercent}%',
                            color: AppColors.primaryToneOf(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.fromPrice(
                  AppFormatters.moneyK(service.price),
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryToneOf(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: salon.isOpen ? onBook : null,
                child: Text(l10n.book),
              ),
              TextButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(l10n.writeReview),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    super.key,
    required this.review,
    required this.l10n,
    this.isHighlighted = false,
  });

  final SalonReview review;
  final AppLocalizations l10n;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHighlighted ? 4 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isHighlighted
              ? AppColors.primaryToneOf(context).withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        review.customerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.serviceName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.dateTime(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextOf(context),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List<Widget>.generate(5, (int index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: AppColors.starOf(context),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(review.comment),
            if (review.hasOwnerReply) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.workshopReplyLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryToneOf(context),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(review.ownerReply),
                    if (review.ownerReplyAt != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.dateTime(review.ownerReplyAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewAnalyticsCard extends StatelessWidget {
  const _ReviewAnalyticsCard({
    required this.analytics,
    required this.l10n,
  });

  final ReviewAnalytics analytics;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.reviewAnalyticsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reviewAnalyticsSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AnalyticsMetric(
                    label: l10n.reviewAverageLabel,
                    value: analytics.totalReviews == 0
                        ? '0.0'
                        : analytics.averageRating.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AnalyticsMetric(
                    label: l10n.reviewsCount(analytics.totalReviews),
                    value: '${analytics.totalReviews}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...analytics.starBuckets.map(
              (ReviewStarBucket bucket) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StarDistributionRow(
                  label: l10n.reviewStarsLabel(bucket.stars),
                  count: bucket.count,
                  share: bucket.share,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.reviewTopServicesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (analytics.topServices.isEmpty)
              Text(
                l10n.reviewTopServicesEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryTextOf(context),
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    analytics.topServices.map((ReviewServiceSummary item) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.chipBackgroundOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Text(
                      '${item.serviceName} • ${item.reviewCount} • ${item.averageRating.toStringAsFixed(1)}★',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }).toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  const _AnalyticsMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _StarDistributionRow extends StatelessWidget {
  const _StarDistributionRow({
    required this.label,
    required this.count,
    required this.share,
  });

  final String label;
  final int count;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 9,
              backgroundColor: AppColors.chipBackgroundOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryToneOf(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ),
      ],
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.rate_review_outlined,
              size: 40,
              color: AppColors.secondaryTextOf(context),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_outlined),
              label: Text(AppLocalizations.of(context).writeReview),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color ?? AppColors.starOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color ?? AppColors.secondaryTextOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
