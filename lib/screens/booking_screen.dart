import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../models/saved_vehicle_profile.dart';
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
  late String _selectedServiceId;
  late String _selectedVehicleTypeId;
  late String _selectedCatalogBrand;
  late String? _selectedCatalogVehicleId;
  late DateTime _selectedDate;
  late final TextEditingController _customBrandController;
  late final TextEditingController _customModelController;
  String _selectedTime = _timeSlots.first;
  bool _useCustomVehicle = false;
  bool _isSubmitting = false;
  bool _didHydrateVehicleSelection = false;

  static const List<String> _timeSlots = <String>[
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '18:00',
  ];

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

  String get _selectedVehicleBrand => _useCustomVehicle
      ? normalizeVehicleBrand(_customBrandController.text)
      : (_selectedCatalogVehicle?.brand ?? '');

  String get _selectedVehicleModelName => _useCustomVehicle
      ? normalizeVehicleModelName(_customModelController.text)
      : (_selectedCatalogVehicle?.model ?? '');

  String get _selectedVehicleDisplayName => formatVehicleDisplayName(
        brand: _selectedVehicleBrand,
        model: _selectedVehicleModelName,
      );

  int get _calculatedPrice => adjustedVehiclePrice(
        basePrice: _selectedService.price,
        vehicleTypeId: _selectedVehicleTypeId,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final List<SavedVehicleProfile> savedVehicles =
        authProvider.currentUser?.savedVehicles ??
            const <SavedVehicleProfile>[];
    final List<VehicleCatalogEntry> uzbekistanGmVehicles =
        uzbekistanGmVehicleCatalogEntries(limit: 10);
    final List<VehicleCatalogEntry> otherPopularVehicles =
        otherPopularVehicleCatalogEntries(limit: 6);
    final String selectedDateLabel =
        '${AppFormatters.shortDate(_selectedDate)} ${_selectedDate.year}';

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.vehicleCatalogMode),
                selected: !_useCustomVehicle,
                onSelected: (_) {
                  setState(() {
                    _useCustomVehicle = false;
                    if (_selectedCatalogVehicle == null &&
                        _brandVehicles.isNotEmpty) {
                      _selectCatalogVehicle(_brandVehicles.first);
                    }
                  });
                },
              ),
              ChoiceChip(
                label: Text(l10n.vehicleOtherOption),
                selected: _useCustomVehicle,
                onSelected: (_) {
                  setState(() {
                    _useCustomVehicle = true;
                    if (_customBrandController.text.trim().isEmpty &&
                        _selectedCatalogVehicle != null) {
                      _customBrandController.text =
                          _selectedCatalogVehicle!.brand;
                    }
                    if (_customModelController.text.trim().isEmpty &&
                        _selectedCatalogVehicle != null) {
                      _customModelController.text =
                          _selectedCatalogVehicle!.model;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_useCustomVehicle) ...<Widget>[
            _CatalogSection(
              title: l10n.uzbekistanGmVehiclesTitle,
              children: uzbekistanGmVehicles.map(_buildCatalogChip).toList(),
            ),
            const SizedBox(height: 8),
            _CatalogSection(
              title: l10n.otherPopularVehiclesTitle,
              children: otherPopularVehicles.map(_buildCatalogChip).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCatalogBrand,
              items: vehicleCatalogBrands()
                  .map(
                    (String brand) => DropdownMenuItem<String>(
                      value: brand,
                      child: Text(brand),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                final List<VehicleCatalogEntry> vehicles =
                    vehicleCatalogByBrand(value);
                if (vehicles.isEmpty) {
                  return;
                }
                setState(() {
                  _selectedCatalogBrand = value;
                  _selectCatalogVehicle(vehicles.first);
                });
              },
              decoration: InputDecoration(labelText: l10n.vehicleBrandField),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCatalogVehicle?.id,
              items: _brandVehicles
                  .map(
                    (VehicleCatalogEntry vehicle) => DropdownMenuItem<String>(
                      value: vehicle.id,
                      child: Text(vehicle.model),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                final VehicleCatalogEntry? vehicle =
                    vehicleCatalogEntryById(value);
                if (vehicle == null) {
                  return;
                }
                setState(() {
                  _selectCatalogVehicle(vehicle);
                });
              },
              decoration:
                  InputDecoration(labelText: l10n.vehicleCatalogModelField),
            ),
          ] else ...<Widget>[
            TextFormField(
              controller: _customBrandController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.vehicleBrandField,
                hintText: l10n.vehicleBrandHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customModelController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
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
                    child: Text(
                      '${type.label(l10n)}  •  ${type.percentLabel()}',
                    ),
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
            },
            decoration: InputDecoration(labelText: l10n.vehicleTypeField),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 45)),
              );

              if (picked == null) {
                return;
              }

              setState(() {
                _selectedDate = picked;
              });
            },
            icon: const Icon(Icons.date_range),
            label: Text(l10n.dateLabel(selectedDateLabel)),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.availableTimes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots
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
                  Text(l10n.timeLabel(_selectedTime)),
                  Text(
                    l10n.basePriceLabel(
                      AppFormatters.moneyK(_selectedService.price),
                    ),
                  ),
                  Text(
                    l10n.vehiclePriceAdjustmentLabel(
                      _selectedVehicleType.percentLabel(),
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
            onPressed: _isSubmitting ? null : _submitBooking,
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
    if (_useCustomVehicle != vehicle.isCustom) {
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
      _useCustomVehicle = false;
      _selectedCatalogBrand = catalogVehicle.brand;
      _selectedCatalogVehicleId = catalogVehicle.id;
      _customBrandController.clear();
      _customModelController.clear();
    } else {
      _useCustomVehicle = true;
      _customBrandController.text = vehicle.brand;
      _customModelController.text = vehicle.model;
    }
    _selectedVehicleTypeId = vehicle.vehicleTypeId;
  }

  void _selectCatalogVehicle(VehicleCatalogEntry vehicle) {
    _useCustomVehicle = false;
    _selectedCatalogBrand = vehicle.brand;
    _selectedCatalogVehicleId = vehicle.id;
    _selectedVehicleTypeId = vehicle.vehicleTypeId;
  }

  Future<void> _submitBooking() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String vehicleBrand = _selectedVehicleBrand;
    final String vehicleModelName = _selectedVehicleModelName;

    if (_useCustomVehicle && vehicleBrand.length < 2) {
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
    if (!_useCustomVehicle && _selectedCatalogVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleCatalogRequired)),
      );
      return;
    }

    final List<String> parts = _selectedTime.split(':');
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
                catalogVehicleId: _useCustomVehicle
                    ? ''
                    : (_selectedCatalogVehicle?.id ?? ''),
                isCustomVehicle: _useCustomVehicle,
                vehicleTypeId: _selectedVehicleTypeId,
                dateTime: bookingDateTime,
                basePrice: _selectedService.price,
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
                  _useCustomVehicle ? '' : (_selectedCatalogVehicle?.id ?? ''),
              isCustom: _useCustomVehicle,
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

  ChoiceChip _buildCatalogChip(VehicleCatalogEntry vehicle) {
    final bool isSelected =
        _selectedCatalogVehicle?.id == vehicle.id && !_useCustomVehicle;
    return ChoiceChip(
      label: Text(vehicle.displayName),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectCatalogVehicle(vehicle);
        });
      },
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}
