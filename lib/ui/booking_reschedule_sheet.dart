import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_availability.dart';
import '../models/booking_availability_calendar.dart';
import '../models/booking_item.dart';
import '../providers/booking_provider.dart';
import '../services/api_exception.dart';

Future<bool?> showBookingRescheduleSheet({
  required BuildContext context,
  required BookingItem booking,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return _BookingRescheduleSheet(booking: booking);
    },
  );
}

class _BookingRescheduleSheet extends StatefulWidget {
  const _BookingRescheduleSheet({
    required this.booking,
  });

  final BookingItem booking;

  @override
  State<_BookingRescheduleSheet> createState() =>
      _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState extends State<_BookingRescheduleSheet> {
  static const int _calendarWindowDays = 45;

  final Map<String, BookingAvailabilityDay> _calendarDaysByDateKey =
      <String, BookingAvailabilityDay>{};
  List<BookingAvailabilitySlot> _slotItems = const <BookingAvailabilitySlot>[];
  late DateTime _selectedDate;
  String? _selectedTime;
  bool _isLoadingCalendar = true;
  bool _isLoadingAvailability = true;
  bool _isClosedDay = false;
  bool _isSubmitting = false;
  String? _calendarError;
  String? _availabilityError;
  DateTime? _nearestAvailableDate;
  String _nearestAvailableTime = '';
  int _calendarRequestId = 0;
  int _availabilityRequestId = 0;

  List<String> get _availableSlots => _slotItems
      .where((BookingAvailabilitySlot slot) => slot.isAvailable)
      .map((BookingAvailabilitySlot slot) => slot.time)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizedDate(widget.booking.dateTime);
    unawaited(_refreshAvailabilityCalendar(forceAdjustSelection: false));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final String selectedDateLabel =
        '${AppFormatters.shortDate(_selectedDate)} ${_selectedDate.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.rescheduleBookingTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.rescheduleBookingSubtitle(
                widget.booking.serviceName,
                widget.booking.salonName,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.rescheduleCurrentTimeLabel(
                AppFormatters.dateTime(widget.booking.dateTime),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                if (_isLoadingCalendar) {
                  return;
                }
                if (_calendarDaysByDateKey.isEmpty) {
                  await _refreshAvailabilityCalendar(
                    forceAdjustSelection: false,
                  );
                  if (!context.mounted) {
                    return;
                  }
                }

                final DateTime? initialDate = _resolvedPickerInitialDate();
                if (initialDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noAvailableDates)),
                  );
                  return;
                }

                final DateTime now = DateTime.now();
                final DateTime firstDate = DateTime(now.year, now.month, now.day);
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: firstDate.add(
                    const Duration(days: _calendarWindowDays - 1),
                  ),
                  selectableDayPredicate: _isSelectableDay,
                );
                if (picked == null) {
                  return;
                }

                setState(() {
                  _selectedDate = picked;
                });
                await _loadAvailability();
              },
              icon: const Icon(Icons.date_range),
              label: Text(l10n.dateLabel(selectedDateLabel)),
            ),
            if (_calendarError != null) ...<Widget>[
              const SizedBox(height: 10),
              _AvailabilityMessageCard(
                title: _calendarError!,
                subtitle: l10n.availableTimesRetryHint,
              ),
            ] else if (_nearestAvailableDate != null) ...<Widget>[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.nearestAvailableTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.nearestAvailableSubtitle(
                          '${AppFormatters.shortDate(_nearestAvailableDate!)} ${_nearestAvailableDate!.year}',
                          _nearestAvailableTime,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                      ),
                      if (_dateKey(_selectedDate) !=
                              _dateKey(_nearestAvailableDate!) ||
                          _selectedTime != _nearestAvailableTime) ...<Widget>[
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: _selectNearestAvailableSlot,
                          child: Text(l10n.selectNearestAvailable),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l10n.availableTimes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isLoadingAvailability)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              )
            else if (_availabilityError != null)
              _AvailabilityMessageCard(
                title: _availabilityError!,
                subtitle: l10n.availableTimesRetryHint,
              )
            else if (_slotItems.isEmpty)
              _AvailabilityMessageCard(
                title: _isClosedDay
                    ? l10n.availableTimesClosedDay
                    : l10n.availableTimesEmpty,
                subtitle: _isClosedDay
                    ? l10n.availableTimesClosedDayHint
                    : l10n.availableTimesEmptyHint,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_availableSlots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AvailabilityMessageCard(
                        title: _isClosedDay
                            ? l10n.availableTimesClosedDay
                            : l10n.availableTimesEmpty,
                        subtitle: _isClosedDay
                            ? l10n.availableTimesClosedDayHint
                            : l10n.availableTimesEmptyHint,
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slotItems
                        .map(
                          (BookingAvailabilitySlot slot) => ChoiceChip(
                            label: Text(
                              slot.time,
                              style: TextStyle(
                                color: slot.isAvailable
                                    ? null
                                    : AppColors.secondaryTextOf(context),
                              ),
                            ),
                            selected: slot.time == _selectedTime,
                            backgroundColor: slot.isAvailable
                                ? null
                                : AppColors.chipBackgroundOf(context),
                            side: BorderSide(
                              color: slot.isAvailable
                                  ? AppColors.borderOf(context)
                                  : AppColors.borderOf(context)
                                      .withValues(alpha: 0.6),
                            ),
                            onSelected: slot.isAvailable
                                ? (_) {
                                    setState(() {
                                      _selectedTime = slot.time;
                                    });
                                  }
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting || _selectedTime == null
                  ? null
                  : _submitReschedule,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.rescheduleConfirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReschedule() async {
    final String? time = _selectedTime;
    if (time == null) {
      return;
    }
    final List<String> parts = time.split(':');
    if (parts.length != 2) {
      return;
    }
    final DateTime nextDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.tryParse(parts.first) ?? 0,
      int.tryParse(parts.last) ?? 0,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bool changed = await context.read<BookingProvider>().rescheduleBookingRequest(
            bookingId: widget.booking.id,
            dateTime: nextDateTime,
          );
      if (!mounted) {
        return;
      }
      if (!changed) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        final String message = context.read<BookingProvider>().errorMessage ??
            l10n.availableTimesLoadFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _refreshAvailabilityCalendar({
    required bool forceAdjustSelection,
  }) async {
    await _loadAvailabilityCalendar(
      forceAdjustSelection: forceAdjustSelection,
    );
    if (!mounted) {
      return;
    }
    await _loadAvailability();
  }

  Future<void> _loadAvailabilityCalendar({
    required bool forceAdjustSelection,
  }) async {
    final int requestId = ++_calendarRequestId;
    setState(() {
      _isLoadingCalendar = true;
      _calendarError = null;
    });

    final DateTime fromDate = DateTime.now();
    try {
      final BookingAvailabilityCalendar calendar =
          await context.read<BookingProvider>().loadAvailabilityCalendar(
                workshopId: widget.booking.workshopId,
                serviceId: widget.booking.serviceId,
                fromDate: fromDate,
                days: _calendarWindowDays,
              );
      if (!mounted || requestId != _calendarRequestId) {
        return;
      }

      final Map<String, BookingAvailabilityDay> daysByKey =
          <String, BookingAvailabilityDay>{
        for (final BookingAvailabilityDay item in calendar.days)
          _dateKey(item.date): item,
      };
      final DateTime? resolvedNearestDate = calendar.nearestAvailableDate == null
          ? null
          : _normalizedDate(calendar.nearestAvailableDate!);
      DateTime nextSelectedDate = _selectedDate;
      if (forceAdjustSelection ||
          !_isSelectableFromMap(daysByKey, _selectedDate)) {
        final DateTime? fallbackDate =
            resolvedNearestDate ?? _firstSelectableDateFromMap(daysByKey);
        if (fallbackDate != null) {
          nextSelectedDate = fallbackDate;
        }
      }

      setState(() {
        _isLoadingCalendar = false;
        _calendarError = null;
        _calendarDaysByDateKey
          ..clear()
          ..addAll(daysByKey);
        _nearestAvailableDate = resolvedNearestDate;
        _nearestAvailableTime = calendar.nearestAvailableTime;
        _selectedDate = nextSelectedDate;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _calendarRequestId) {
        return;
      }
      setState(() {
        _isLoadingCalendar = false;
        _calendarError = error.message;
        _calendarDaysByDateKey.clear();
        _nearestAvailableDate = null;
        _nearestAvailableTime = '';
      });
    } catch (_) {
      if (!mounted || requestId != _calendarRequestId) {
        return;
      }
      final AppLocalizations l10n = AppLocalizations.of(context);
      setState(() {
        _isLoadingCalendar = false;
        _calendarError = l10n.availableCalendarLoadFailed;
        _calendarDaysByDateKey.clear();
        _nearestAvailableDate = null;
        _nearestAvailableTime = '';
      });
    }
  }

  Future<void> _loadAvailability({
    String? preferredTime,
  }) async {
    final int requestId = ++_availabilityRequestId;
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
    });

    try {
      final BookingAvailability availability =
          await context.read<BookingProvider>().loadAvailability(
                workshopId: widget.booking.workshopId,
                serviceId: widget.booking.serviceId,
                date: _selectedDate,
              );
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _isLoadingAvailability = false;
        _isClosedDay = availability.isClosedDay;
        _slotItems = availability.slots;
        if (preferredTime != null && _availableSlots.contains(preferredTime)) {
          _selectedTime = preferredTime;
        } else if (_selectedTime == null ||
            !_availableSlots.contains(_selectedTime)) {
          _selectedTime = _availableSlots.isEmpty ? null : _availableSlots.first;
        }
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }
      setState(() {
        _isLoadingAvailability = false;
        _slotItems = const <BookingAvailabilitySlot>[];
        _selectedTime = null;
        _availabilityError = error.message;
      });
    } catch (_) {
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }
      final AppLocalizations l10n = AppLocalizations.of(context);
      setState(() {
        _isLoadingAvailability = false;
        _slotItems = const <BookingAvailabilitySlot>[];
        _selectedTime = null;
        _availabilityError = l10n.availableTimesLoadFailed;
      });
    }
  }

  void _selectNearestAvailableSlot() {
    final DateTime? nearestDate = _nearestAvailableDate;
    final String nearestTime = _nearestAvailableTime;
    if (nearestDate == null || nearestTime.isEmpty) {
      return;
    }

    setState(() {
      _selectedDate = nearestDate;
      _selectedTime = nearestTime;
    });
    unawaited(_loadAvailability(preferredTime: nearestTime));
  }

  bool _isSelectableDay(DateTime value) {
    return _isSelectableFromMap(_calendarDaysByDateKey, value);
  }

  bool _isSelectableFromMap(
    Map<String, BookingAvailabilityDay> daysByKey,
    DateTime value,
  ) {
    final BookingAvailabilityDay? item = daysByKey[_dateKey(value)];
    return item?.isSelectable == true;
  }

  DateTime? _firstSelectableDateFromMap(
    Map<String, BookingAvailabilityDay> daysByKey,
  ) {
    for (final BookingAvailabilityDay item in daysByKey.values) {
      if (item.isSelectable) {
        return _normalizedDate(item.date);
      }
    }
    return null;
  }

  DateTime? _resolvedPickerInitialDate() {
    if (_isSelectableDay(_selectedDate)) {
      return _selectedDate;
    }
    if (_nearestAvailableDate != null) {
      return _nearestAvailableDate;
    }
    return _firstSelectableDateFromMap(_calendarDaysByDateKey);
  }

  DateTime _normalizedDate(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dateKey(DateTime value) {
    final DateTime normalized = _normalizedDate(value);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

class _AvailabilityMessageCard extends StatelessWidget {
  const _AvailabilityMessageCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
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
    );
  }
}
