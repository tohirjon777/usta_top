import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../models/vehicle_type.dart';
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
  late DateTime _selectedDate;
  late final TextEditingController _vehicleModelController;
  String _selectedTime = _timeSlots.first;
  bool _isSubmitting = false;

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

    _selectedServiceId = containsPreselected
        ? widget.preselectedServiceId!
        : widget.salon.services.first.id;
    _selectedVehicleTypeId = defaultVehicleType().id;
    _vehicleModelController = TextEditingController();

    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    super.dispose();
  }

  SalonService get _selectedService {
    return widget.salon.services.firstWhere(
      (SalonService service) => service.id == _selectedServiceId,
    );
  }

  VehicleTypeOption get _selectedVehicleType =>
      vehicleTypeById(_selectedVehicleTypeId);

  int get _calculatedPrice => adjustedVehiclePrice(
        basePrice: _selectedService.price,
        vehicleTypeId: _selectedVehicleTypeId,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String selectedDateLabel =
        '${AppFormatters.shortDate(_selectedDate)} ${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookAppointment)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(widget.salon.name,
              style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _vehicleModelController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: l10n.vehicleModelField,
              hintText: l10n.vehicleModelHint,
            ),
          ),
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
          Text(l10n.availableTimes,
              style: Theme.of(context).textTheme.titleMedium),
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
                  Text(l10n.summary,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(l10n.serviceLabel(_selectedService.name)),
                  Text(
                    l10n.vehicleModelLabel(
                      _vehicleModelController.text.trim().isEmpty
                          ? l10n.vehicleModelPending
                          : _vehicleModelController.text.trim(),
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

  Future<void> _submitBooking() async {
    final String vehicleModel = _vehicleModelController.text.trim();
    if (vehicleModel.length < 2) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleModelRequired)),
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
                vehicleModel: vehicleModel,
                vehicleTypeId: _selectedVehicleTypeId,
                dateTime: bookingDateTime,
                basePrice: _selectedService.price,
              );

      if (!mounted) {
        return;
      }
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
      final AppLocalizations l10n = AppLocalizations.of(context);
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
