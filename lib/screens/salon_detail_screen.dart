import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../models/salon_review.dart';
import '../providers/saved_workshops_provider.dart';
import '../providers/workshop_provider.dart';
import '../services/navigation_launcher.dart';
import '../ui/review_composer_sheet.dart';
import 'booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  const SalonDetailScreen({super.key, required this.salon});

  final Salon salon;

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  late Salon _salon;
  bool _isRefreshingDetail = false;
  String _selectedReviewServiceId = '';

  @override
  void initState() {
    super.initState();
    _salon = widget.salon;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _reloadWorkshop();
    });
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
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Salon? updated = await showWorkshopReviewComposerSheet(
      context: context,
      salon: _salon,
      l10n: l10n,
      preselectedServiceId: preselectedService?.id,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _salon = updated;
      _selectedReviewServiceId = updated.reviews.isEmpty
          ? ''
          : (preselectedService?.id ?? _selectedReviewServiceId);
    });
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
      body: RefreshIndicator(
        onRefresh: _reloadWorkshop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: <Widget>[
            Container(
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[heroStart, heroEnd],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.car_repair,
                  size: 80,
                  color: AppColors.primaryToneOf(context),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(_salon.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _salon.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetaPill(
                  icon: Icons.star,
                  text: '${_salon.rating} (${_salon.reviewCount})',
                ),
                _MetaPill(
                  icon: Icons.place_outlined,
                  text: '${_salon.distanceKm} km',
                ),
                _MetaPill(
                  icon: Icons.circle,
                  text: _salon.isOpen ? l10n.openNow : l10n.closedNow,
                  color: _salon.isOpen
                      ? AppColors.primaryToneOf(context)
                      : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text(_salon.address)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => NavigationLauncher.showNavigatorPicker(
                context,
                salon: _salon,
              ),
              icon: const Icon(Icons.route_outlined),
              label: Text(l10n.routeToWorkshop),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.services,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openReviewComposer(),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(l10n.writeReview),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._salon.services.map(
              (SalonService service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.durationMinutes(
                                      service.durationMinutes,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              AppColors.secondaryTextOf(context),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.moneyK(service.price),
                              style: TextStyle(
                                color: AppColors.primaryToneOf(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: _salon.isOpen
                                  ? () => _openBooking(
                                        context: context,
                                        preselected: service,
                                      )
                                  : null,
                              child: Text(l10n.book),
                            ),
                            TextButton.icon(
                              onPressed: () => _openReviewComposer(
                                preselectedService: service,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(l10n.writeReview),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
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
                  child: _ReviewCard(review: review, l10n: l10n),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton(
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.l10n,
  });

  final SalonReview review;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                  borderRadius: BorderRadius.circular(14),
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
        padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(8),
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
