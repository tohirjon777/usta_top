import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../models/salon.dart';
import '../models/salon_review.dart';
import '../providers/booking_provider.dart';
import '../providers/workshop_provider.dart';

Future<Salon?> showWorkshopReviewComposerSheet({
  required BuildContext context,
  required Salon salon,
  required AppLocalizations l10n,
  String? preselectedServiceId,
  String? bookingId,
  bool lockServiceSelection = false,
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<Salon>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return ReviewComposerSheet(
        salon: salon,
        l10n: l10n,
        preselectedServiceId: preselectedServiceId,
        bookingId: bookingId,
        lockServiceSelection: lockServiceSelection,
        title: title,
        subtitle: subtitle,
      );
    },
  );
}

class ReviewComposerSheet extends StatefulWidget {
  const ReviewComposerSheet({
    super.key,
    required this.salon,
    required this.l10n,
    this.preselectedServiceId,
    this.bookingId,
    this.lockServiceSelection = false,
    this.title,
    this.subtitle,
  });

  final Salon salon;
  final AppLocalizations l10n;
  final String? preselectedServiceId;
  final String? bookingId;
  final bool lockServiceSelection;
  final String? title;
  final String? subtitle;

  @override
  State<ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<ReviewComposerSheet> {
  late final TextEditingController _commentController;
  late String _selectedServiceId;
  int _rating = 5;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _selectedServiceId = widget.preselectedServiceId?.trim().isNotEmpty == true
        ? widget.preselectedServiceId!.trim()
        : widget.salon.services.first.id;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  SalonService get _selectedService {
    return widget.salon.services.firstWhere(
      (SalonService item) => item.id == _selectedServiceId,
      orElse: () => widget.salon.services.first,
    );
  }

  Future<void> _submit() async {
    final String comment = normalizeSalonReviewText(_commentController.text);
    if (comment.length < 3) {
      setState(() {
        _errorText = widget.l10n.reviewCommentValidation;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final Salon? updated = await context.read<WorkshopProvider>().submitReview(
          workshopId: widget.salon.id,
          serviceId: _selectedServiceId,
          rating: _rating,
          comment: comment,
          bookingId: widget.bookingId,
        );
    if (!mounted) {
      return;
    }
    if (updated == null) {
      setState(() {
        _isSubmitting = false;
        _errorText = context.read<WorkshopProvider>().errorMessage ??
            widget.l10n.reviewSubmitFailed;
      });
      return;
    }

    if (widget.bookingId != null && widget.bookingId!.trim().isNotEmpty) {
      try {
        context.read<BookingProvider>().markBookingReviewed(
              widget.bookingId!,
              submittedAt: DateTime.now(),
            );
      } catch (_) {
        // BookingProvider test yoki isolated kontekstda bo'lmasligi mumkin.
      }
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(updated);
    messenger.showSnackBar(
      SnackBar(content: Text(widget.l10n.reviewSubmitSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.title ?? widget.l10n.writeReview,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle ?? widget.l10n.reviewSheetSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
          const SizedBox(height: 16),
          if (widget.lockServiceSelection)
            InputDecorator(
              decoration: InputDecoration(
                labelText: widget.l10n.serviceSelectLabel,
              ),
              child: Text(_selectedService.name),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey<String>(_selectedServiceId),
              initialValue: _selectedServiceId,
              decoration: InputDecoration(
                labelText: widget.l10n.serviceSelectLabel,
              ),
              items: widget.salon.services.map((SalonService service) {
                return DropdownMenuItem<String>(
                  value: service.id,
                  child: Text(service.name),
                );
              }).toList(growable: false),
              onChanged: _isSubmitting
                  ? null
                  : (String? value) {
                      if (value == null || value.isEmpty) {
                        return;
                      }
                      setState(() {
                        _selectedServiceId = value;
                      });
                    },
            ),
          const SizedBox(height: 16),
          Text(
            widget.l10n.ratingLabel(_rating),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List<Widget>.generate(5, (int index) {
              final int star = index + 1;
              return IconButton.filledTonal(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _rating = star;
                        });
                      },
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: star <= _rating
                      ? AppColors.starOf(context)
                      : AppColors.secondaryTextOf(context),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !_isSubmitting,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: widget.l10n.commentLabel,
              hintText: widget.l10n.reviewHint,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(widget.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.l10n.sendReview),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
