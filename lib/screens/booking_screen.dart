import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_availability.dart';
import '../models/booking_availability_calendar.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../models/saved_vehicle_profile.dart';
import '../models/service_price_quote.dart';
import '../models/vehicle_catalog.dart';
import '../models/vehicle_type.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_exception.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.salon,
    this.preselectedServiceId,
  });

  final Salon salon;
  final String? preselectedServiceId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const String _otherBrandValue = '__other_brand__';
  static const String _otherModelValue = '__other_model__';

  late String _selectedServiceId;
  late String _selectedVehicleTypeId;
  late String _selectedCatalogBrand;
  late String? _selectedCatalogVehicleId;
  late DateTime _selectedDate;
  late final TextEditingController _customBrandController;
  late final TextEditingController _customModelController;
  String? _selectedTime;
  bool _isOtherBrandSelected = false;
  bool _isOtherModelSelected = false;
  bool _isSubmitting = false;
  bool _didHydrateVehicleSelection = false;
  bool _isLoadingAvailability = false;
  bool _isClosedDay = false;
  String? _availabilityError;
  List<String> _availableSlots = const <String>[];
  int _availabilityRequestId = 0;
  bool _isLoadingCalendar = false;
  String? _calendarError;
  Map<String, BookingAvailabilityDay> _calendarDaysByDateKey =
      <String, BookingAvailabilityDay>{};
  DateTime? _nearestAvailableDate;
  String _nearestAvailableTime = '';
  int _calendarRequestId = 0;
  bool _isLoadingPriceQuote = false;
  String? _priceQuoteError;
  ServicePriceQuote? _priceQuote;
  int _priceQuoteRequestId = 0;
  Timer? _priceQuoteDebounce;

  static const int _calendarWindowDays = 45;

  @override
  void initState() {
    super.initState();

    final bool containsPreselected = widget.salon.services.any(
      (SalonService service) => service.id == widget.preselectedServiceId,
    );
    final VehicleCatalogEntry defaultVehicle = popularVehicleCatalogEntries(
      limit: 1,
    ).first;

    _selectedServiceId = containsPreselected
        ? widget.preselectedServiceId!
        : widget.salon.services.first.id;
    _selectedVehicleTypeId = defaultVehicle.vehicleTypeId;
    _selectedCatalogBrand = defaultVehicle.brand;
    _selectedCatalogVehicleId = defaultVehicle.id;
    _customBrandController = TextEditingController();
    _customModelController = TextEditingController();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAvailabilityCalendar(forceAdjustSelection: true);
      _schedulePriceQuoteRefresh(immediate: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateVehicleSelection) {
      return;
    }
    _didHydrateVehicleSelection = true;

    final List<SavedVehicleProfile> savedVehicles =
        context.read<AuthProvider>().currentUser?.savedVehicles ??
            const <SavedVehicleProfile>[];
    if (savedVehicles.isNotEmpty) {
      _applySavedVehicle(savedVehicles.first);
    }
  }

  @override
  void dispose() {
    _priceQuoteDebounce?.cancel();
    _customBrandController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  SalonService get _selectedService {
    return widget.salon.services.firstWhere(
      (SalonService service) => service.id == _selectedServiceId,
    );
  }

  VehicleTypeOption get _selectedVehicleType =>
      vehicleTypeById(_selectedVehicleTypeId);

  bool get _isCustomVehicle => _isOtherBrandSelected || _isOtherModelSelected;

  VehicleCatalogEntry? get _selectedCatalogVehicle {
    final String? selectedId = _selectedCatalogVehicleId;
    if (selectedId != null) {
      final VehicleCatalogEntry? direct = vehicleCatalogEntryById(selectedId);
      if (direct != null) {
        return direct;
      }
    }

    final List<VehicleCatalogEntry> brandItems =
        vehicleCatalogByBrand(_selectedCatalogBrand);
    return brandItems.isEmpty ? null : brandItems.first;
  }

  List<VehicleCatalogEntry> get _brandVehicles =>
      vehicleCatalogByBrand(_selectedCatalogBrand);

  String get _brandDropdownValue =>
      _isOtherBrandSelected ? _otherBrandValue : _selectedCatalogBrand;

  String? get _modelDropdownValue => _isOtherModelSelected
      ? _otherModelValue
      : _selectedCatalogVehicle?.id;

  String get _selectedVehicleBrand => _isOtherBrandSelected
      ? normalizeVehicleBrand(_customBrandController.text)
      : normalizeVehicleBrand(_selectedCatalogBrand);

  String get _selectedVehicleModelName => _isCustomVehicle
      ? normalizeVehicleModelName(_customModelController.text)
      : (_selectedCatalogVehicle?.model ?? '');

  String get _selectedVehicleDisplayName => formatVehicleDisplayName(
        brand: _selectedVehicleBrand,
        model: _selectedVehicleModelName,
      );

  int get _calculatedPrice => _quotedPrice;

  int get _quotedBasePrice => _priceQuote?.basePrice ?? _selectedService.price;

  int get _quotedPrice => _priceQuote?.price ?? _selectedService.price;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final List<SavedVehicleProfile> savedVehicles =
        authProvider.currentUser?.savedVehicles ??
            const <SavedVehicleProfile>[];
    final String selectedDateLabel =
        '${AppFormatters.shortDate(_selectedDate)} ${_selectedDate.year}';
    final List<DropdownMenuItem<String>> brandItems = <DropdownMenuItem<String>>[
      ...vehicleCatalogBrands().map(
        (String brand) => DropdownMenuItem<String>(
          value: brand,
          child: Text(brand),
        ),
      ),
      DropdownMenuItem<String>(
        value: _otherBrandValue,
        child: Text(l10n.vehicleOtherOption),
      ),
    ];
    final List<DropdownMenuItem<String>> modelItems = <DropdownMenuItem<String>>[
      ..._brandVehicles.map(
        (VehicleCatalogEntry vehicle) => DropdownMenuItem<String>(
          value: vehicle.id,
          child: Text(vehicle.model),
        ),
      ),
      DropdownMenuItem<String>(
        value: _otherModelValue,
        child: Text(l10n.vehicleOtherOption),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookAppointment)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(
            widget.salon.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.masterPrefix(widget.salon.master),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedServiceId,
            items: widget.salon.services
                .map(
                  (SalonService service) => DropdownMenuItem<String>(
                    value: service.id,
                    child: Text(
                      '${service.name}  •  ${l10n.durationMinutes(service.durationMinutes)}  •  ${AppFormatters.moneyK(service.price)}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedServiceId = value;
              });
              _refreshAvailabilityCalendar(forceAdjustSelection: true);
              _schedulePriceQuoteRefresh(immediate: true);
            },
            decoration: InputDecoration(labelText: l10n.service),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.vehicleSelectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (savedVehicles.isNotEmpty) ...<Widget>[
            Text(
              l10n.savedVehiclesTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: savedVehicles.map((SavedVehicleProfile vehicle) {
                final bool isSelected = _isSavedVehicleSelected(vehicle);
                return ChoiceChip(
                  label: Text(vehicle.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _applySavedVehicle(vehicle);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          DropdownButtonFormField<String>(
            initialValue: _brandDropdownValue,
            items: brandItems,
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              if (value == _otherBrandValue) {
                setState(() {
                  _isOtherBrandSelected = true;
                  _isOtherModelSelected = true;
                  if (_customBrandController.text.trim().isEmpty &&
                      _selectedCatalogVehicle != null) {
                    _customBrandController.text = _selectedCatalogVehicle!.brand;
                  }
                  if (_customModelController.text.trim().isEmpty &&
                      _selectedCatalogVehicle != null) {
                    _customModelController.text = _selectedCatalogVehicle!.model;
                  }
                  _selectedCatalogVehicleId = null;
                });
                _schedulePriceQuoteRefresh();
                return;
              }

              final List<VehicleCatalogEntry> vehicles =
                  vehicleCatalogByBrand(value);
              if (vehicles.isEmpty) {
                return;
              }
              setState(() {
                _isOtherBrandSelected = false;
                _selectedCatalogBrand = value;
                _isOtherModelSelected = false;
                _selectCatalogVehicle(vehicles.first);
              });
            },
            decoration: InputDecoration(labelText: l10n.vehicleBrandField),
          ),
          if (_isOtherBrandSelected) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customBrandController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
                _schedulePriceQuoteRefresh();
              },
              decoration: InputDecoration(
                labelText: l10n.vehicleBrandField,
                hintText: l10n.vehicleBrandHint,
              ),
            ),
          ],
          if (!_isOtherBrandSelected) ...<Widget>[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modelDropdownValue,
              items: modelItems,
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                if (value == _otherModelValue) {
                  setState(() {
                    _isOtherModelSelected = true;
                    if (_customModelController.text.trim().isEmpty &&
                        _selectedCatalogVehicle != null) {
                      _customModelController.text = _selectedCatalogVehicle!.model;
                    }
                  });
                  _schedulePriceQuoteRefresh();
                  return;
                }

                final VehicleCatalogEntry? vehicle = vehicleCatalogEntryById(value);
                if (vehicle == null) {
                  return;
                }
                setState(() {
                  _isOtherModelSelected = false;
                  _selectCatalogVehicle(vehicle);
                });
              },
              decoration:
                  InputDecoration(labelText: l10n.vehicleCatalogModelField),
            ),
          ],
          if (_isCustomVehicle) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customModelController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
                _schedulePriceQuoteRefresh();
              },
              decoration: InputDecoration(
                labelText: l10n.vehicleModelField,
                hintText: l10n.vehicleModelHint,
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleTypeId,
            items: vehicleTypes
                .map(
                  (VehicleTypeOption type) => DropdownMenuItem<String>(
                    value: type.id,
                    child: Text(type.label(l10n)),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedVehicleTypeId = value;
              });
              _schedulePriceQuoteRefresh();
            },
            decoration: InputDecoration(labelText: l10n.vehicleTypeField),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              if (_isLoadingCalendar) {
                return;
              }
              if (_calendarDaysByDateKey.isEmpty) {
                await _loadAvailabilityCalendar(
                  forceAdjustSelection: false,
                );
                if (!context.mounted) {
                  return;
                }
              }

              final DateTime? initialDate = _resolvedPickerInitialDate();
              if (initialDate == null) {
                final AppLocalizations postLoadL10n =
                    AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(postLoadL10n.noAvailableDates)),
                );
                return;
              }
              final DateTime now = DateTime.now();
              final DateTime firstDate =
                  DateTime(now.year, now.month, now.day);
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
              _loadAvailability();
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
                    if (_dateKey(_selectedDate) != _dateKey(_nearestAvailableDate!) ||
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
          else if (_availableSlots.isEmpty)
            _AvailabilityMessageCard(
              title: _isClosedDay
                  ? l10n.availableTimesClosedDay
                  : l10n.availableTimesEmpty,
              subtitle: _isClosedDay
                  ? l10n.availableTimesClosedDayHint
                  : l10n.availableTimesEmptyHint,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots
                  .map(
                    (String slot) => ChoiceChip(
                      label: Text(slot),
                      selected: slot == _selectedTime,
                      onSelected: (_) {
                        setState(() {
                          _selectedTime = slot;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_isLoadingPriceQuote) ...<Widget>[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  const SizedBox(height: 6),
                  Text(l10n.serviceLabel(_selectedService.name)),
                  Text(
                    l10n.vehicleModelLabel(
                      _selectedVehicleDisplayName.isEmpty
                          ? l10n.vehicleModelPending
                          : _selectedVehicleDisplayName,
                    ),
                  ),
                  Text(
                    l10n.vehicleTypeLabel(
                      _selectedVehicleType.label(l10n),
                    ),
                  ),
                  Text(
                    l10n.durationLabel(
                      l10n.durationMinutes(_selectedService.durationMinutes),
                    ),
                  ),
                  Text(l10n.dateLabel(selectedDateLabel)),
                  Text(
                    l10n.timeLabel(
                      _selectedTime ?? l10n.bookingTimePending,
                    ),
                  ),
                  Text(
                    l10n.basePriceLabel(
                      AppFormatters.moneyK(_quotedBasePrice),
                    ),
                  ),
                  if (_priceQuote?.matchedRule == true &&
                      _priceQuote!.matchedVehicleLabel.isNotEmpty)
                    Text(
                      l10n.vehiclePriceRuleLabel(
                        _priceQuote!.matchedVehicleLabel,
                      ),
                    ),
                  if (_priceQuoteError != null)
                    Text(
                      _priceQuoteError!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.totalLabel(
                      AppFormatters.moneyK(_calculatedPrice),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryToneOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting || _selectedTime == null
                ? null
                : _submitBooking,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirmBooking),
          ),
        ],
      ),
    );
  }

  bool _isSavedVehicleSelected(SavedVehicleProfile vehicle) {
    if (_isCustomVehicle != vehicle.isCustom) {
      return false;
    }

    return vehicle.matchesVehicle(
      brand: _selectedVehicleBrand,
      model: _selectedVehicleModelName,
    );
  }

  void _applySavedVehicle(SavedVehicleProfile vehicle) {
    final VehicleCatalogEntry? catalogVehicle = vehicle.catalogVehicleId.isEmpty
        ? vehicleCatalogEntryByBrandAndModel(
            brand: vehicle.brand,
            model: vehicle.model,
          )
        : vehicleCatalogEntryById(vehicle.catalogVehicleId);
    if (!vehicle.isCustom && catalogVehicle != null) {
      _isOtherBrandSelected = false;
      _isOtherModelSelected = false;
      _selectedCatalogBrand = catalogVehicle.brand;
      _selectedCatalogVehicleId = catalogVehicle.id;
      _customBrandController.clear();
      _customModelController.clear();
    } else {
      final String normalizedBrand = normalizeVehicleBrand(vehicle.brand);
      final List<VehicleCatalogEntry> brandVehicles =
          vehicleCatalogByBrand(normalizedBrand);
      if (brandVehicles.isNotEmpty) {
        _isOtherBrandSelected = false;
        _isOtherModelSelected = true;
        _selectedCatalogBrand = normalizedBrand;
        _selectedCatalogVehicleId = brandVehicles.first.id;
        _customBrandController.clear();
      } else {
        _isOtherBrandSelected = true;
        _isOtherModelSelected = true;
        _customBrandController.text = vehicle.brand;
        _selectedCatalogVehicleId = null;
      }
      _customModelController.text = vehicle.model;
    }
    _selectedVehicleTypeId = vehicle.vehicleTypeId;
    _schedulePriceQuoteRefresh(immediate: true);
  }

  void _selectCatalogVehicle(VehicleCatalogEntry vehicle) {
    _isOtherBrandSelected = false;
    _isOtherModelSelected = false;
    _selectedCatalogBrand = vehicle.brand;
    _selectedCatalogVehicleId = vehicle.id;
    _selectedVehicleTypeId = vehicle.vehicleTypeId;
    _schedulePriceQuoteRefresh(immediate: true);
  }

  bool get _canResolvePriceQuote {
    if (_isCustomVehicle) {
      return _selectedVehicleBrand.length >= 2 &&
          _selectedVehicleModelName.length >= 2;
    }
    return _selectedCatalogVehicle != null;
  }

  void _schedulePriceQuoteRefresh({bool immediate = false}) {
    _priceQuoteDebounce?.cancel();
    if (immediate) {
      unawaited(_loadPriceQuote());
      return;
    }
    _priceQuoteDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      unawaited(_loadPriceQuote());
    });
  }

  Future<void> _loadPriceQuote() async {
    if (!_canResolvePriceQuote) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPriceQuote = false;
        _priceQuoteError = null;
        _priceQuote = null;
      });
      return;
    }

    final int requestId = ++_priceQuoteRequestId;
    setState(() {
      _isLoadingPriceQuote = true;
      _priceQuoteError = null;
    });

    try {
      final ServicePriceQuote quote =
          await context.read<BookingProvider>().loadPriceQuote(
                workshopId: widget.salon.id,
                serviceId: _selectedService.id,
                catalogVehicleId: _isCustomVehicle
                    ? ''
                    : (_selectedCatalogVehicle?.id ?? ''),
                vehicleBrand: _selectedVehicleBrand,
                vehicleModelName: _selectedVehicleModelName,
                vehicleTypeId: _selectedVehicleTypeId,
                fallbackBasePrice: _selectedService.price,
              );
      if (!mounted || requestId != _priceQuoteRequestId) {
        return;
      }
      setState(() {
        _isLoadingPriceQuote = false;
        _priceQuote = quote;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _priceQuoteRequestId) {
        return;
      }
      setState(() {
        _isLoadingPriceQuote = false;
        _priceQuote = null;
        _priceQuoteError = error.message;
      });
    } catch (_) {
      if (!mounted || requestId != _priceQuoteRequestId) {
        return;
      }
      final AppLocalizations l10n = AppLocalizations.of(context);
      setState(() {
        _isLoadingPriceQuote = false;
        _priceQuote = null;
        _priceQuoteError = l10n.vehiclePriceLoadFailed;
      });
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
                workshopId: widget.salon.id,
                serviceId: _selectedService.id,
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
      if (forceAdjustSelection || !_isSelectableFromMap(daysByKey, _selectedDate)) {
        final DateTime? fallbackDate =
            resolvedNearestDate ?? _firstSelectableDateFromMap(daysByKey);
        if (fallbackDate != null) {
          nextSelectedDate = fallbackDate;
        }
      }

      setState(() {
        _isLoadingCalendar = false;
        _calendarDaysByDateKey = daysByKey;
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
        _calendarDaysByDateKey = <String, BookingAvailabilityDay>{};
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
        _calendarDaysByDateKey = <String, BookingAvailabilityDay>{};
        _nearestAvailableDate = null;
        _nearestAvailableTime = '';
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
                workshopId: widget.salon.id,
                serviceId: _selectedService.id,
                date: _selectedDate,
              );
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _isLoadingAvailability = false;
        _isClosedDay = availability.isClosedDay;
        _availableSlots = availability.slotTimes;
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
        _isClosedDay = false;
        _availableSlots = const <String>[];
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
        _isClosedDay = false;
        _availableSlots = const <String>[];
        _selectedTime = null;
        _availabilityError = l10n.availableTimesLoadFailed;
      });
    }
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final DateTime normalized = _normalizedDate(value);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  BookingAvailabilityDay? _calendarDay(DateTime value) {
    return _calendarDaysByDateKey[_dateKey(value)];
  }

  bool _isSelectableFromMap(
    Map<String, BookingAvailabilityDay> source,
    DateTime value,
  ) {
    final BookingAvailabilityDay? day = source[_dateKey(value)];
    return day != null && day.isSelectable;
  }

  bool _isSelectableDay(DateTime value) {
    final BookingAvailabilityDay? day = _calendarDay(value);
    return day != null && day.isSelectable;
  }

  DateTime? _firstSelectableDateFromMap(
    Map<String, BookingAvailabilityDay> source,
  ) {
    for (final BookingAvailabilityDay item in source.values) {
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

  Future<void> _submitBooking() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String vehicleBrand = _selectedVehicleBrand;
    final String vehicleModelName = _selectedVehicleModelName;

    if (_isOtherBrandSelected && vehicleBrand.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleBrandRequired)),
      );
      return;
    }
    if (vehicleModelName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleModelRequired)),
      );
      return;
    }
    if (!_isCustomVehicle && _selectedCatalogVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleCatalogRequired)),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingTimeRequired)),
      );
      return;
    }

    final List<String> parts = _selectedTime!.split(':');
    final DateTime bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts.first),
      int.parse(parts.last),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final BookingItem booking =
          await context.read<BookingProvider>().createBooking(
                workshopId: widget.salon.id,
                workshopName: widget.salon.name,
                masterName: widget.salon.master,
                serviceId: _selectedService.id,
                serviceName: _selectedService.name,
                vehicleBrand: vehicleBrand,
                vehicleModelName: vehicleModelName,
                catalogVehicleId: _isCustomVehicle
                    ? ''
                    : (_selectedCatalogVehicle?.id ?? ''),
                isCustomVehicle: _isCustomVehicle,
                vehicleTypeId: _selectedVehicleTypeId,
                dateTime: bookingDateTime,
                basePrice: _quotedBasePrice,
              );

      if (!mounted) {
        return;
      }

      context.read<AuthProvider>().rememberVehicleProfile(
            SavedVehicleProfile(
              id: '',
              brand: vehicleBrand,
              model: vehicleModelName,
              vehicleTypeId: _selectedVehicleTypeId,
              catalogVehicleId:
                  _isCustomVehicle ? '' : (_selectedCatalogVehicle?.id ?? ''),
              isCustom: _isCustomVehicle,
              lastUsedAt: DateTime.now(),
            ),
          );
      Navigator.of(context).pop(booking);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingCreateFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
