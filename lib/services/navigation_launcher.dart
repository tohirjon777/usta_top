import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../models/salon.dart';

class NavigationLauncher {
  const NavigationLauncher._();

  static Future<void> showNavigatorPicker(
    BuildContext context, {
    required Salon salon,
    LatLng? origin,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double? lat = salon.latitude;
    final double? lon = salon.longitude;
    if (lat == null || lon == null) {
      _showMessage(context, l10n.mapNoCoordinates);
      return;
    }

    final List<_NavigationOption> options = await _availableOptions(
      l10n: l10n,
      latitude: lat,
      longitude: lon,
      origin: origin,
    );
    if (!context.mounted) {
      return;
    }

    if (options.isEmpty) {
      _showMessage(context, l10n.navigatorNoApps);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.chooseNavigatorTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseNavigatorSubtitle(salon.name),
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryTextOf(sheetContext),
                      ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (_NavigationOption option) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primarySoftOf(sheetContext),
                          foregroundColor:
                              AppColors.primaryToneOf(sheetContext),
                          child: Icon(option.icon),
                        ),
                        title: Text(option.label),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final bool opened = await _openOption(option);
                          if (!context.mounted || opened) {
                            return;
                          }
                          _showMessage(context, l10n.navigatorOpenFailed);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<List<_NavigationOption>> _availableOptions({
    required AppLocalizations l10n,
    required double latitude,
    required double longitude,
    required LatLng? origin,
  }) async {
    final String latText = latitude.toStringAsFixed(6);
    final String lonText = longitude.toStringAsFixed(6);
    final String destination = '$latText,$lonText';
    final String? from = origin == null
        ? null
        : '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final bool useAppleMaps = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final bool useAndroidMaps =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final List<_NavigationCandidate> candidates = <_NavigationCandidate>[
      _NavigationCandidate(
        label: l10n.navigatorGoogleMaps,
        icon: Icons.map_outlined,
        appUri: useAndroidMaps
            ? Uri.parse('google.navigation:q=$destination&mode=d')
            : Uri.parse(
                'comgooglemaps://?daddr=$destination&directionsmode=driving',
              ),
        fallbackUri: Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
        ),
      ),
      _NavigationCandidate(
        label: l10n.navigatorYandexNavigator,
        icon: Icons.navigation_outlined,
        appUri: Uri.parse(
          'yandexnavi://build_route_on_map?lat_to=$latText&lon_to=$lonText',
        ),
      ),
      _NavigationCandidate(
        label: l10n.navigatorYandexMaps,
        icon: Icons.location_on_outlined,
        appUri: Uri.parse(
          from == null
              ? 'yandexmaps://maps.yandex.com/?rtext=~$destination&rtt=auto'
              : 'yandexmaps://maps.yandex.com/?rtext=$from~$destination&rtt=auto',
        ),
        fallbackUri: Uri.parse(
          from == null
              ? 'https://yandex.com/maps/?rtext=~$destination&rtt=auto'
              : 'https://yandex.com/maps/?rtext=$from~$destination&rtt=auto',
        ),
      ),
      if (useAppleMaps)
        _NavigationCandidate(
          label: l10n.navigatorAppleMaps,
          icon: Icons.map_rounded,
          appUri: Uri.parse('http://maps.apple.com/?daddr=$destination&dirflg=d'),
        ),
      _NavigationCandidate(
        label: l10n.navigatorWaze,
        icon: Icons.alt_route_rounded,
        appUri: Uri.parse('waze://?ll=$destination&navigate=yes'),
      ),
      _NavigationCandidate(
        label: l10n.navigatorBrowserMaps,
        icon: Icons.public,
        fallbackUri: Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
        ),
      ),
    ];

    final List<_NavigationOption> options = <_NavigationOption>[];
    for (final _NavigationCandidate candidate in candidates) {
      Uri? launchUri;

      if (candidate.appUri != null) {
        try {
          if (await canLaunchUrl(candidate.appUri!)) {
            launchUri = candidate.appUri;
          }
        } catch (_) {
          launchUri = null;
        }
      }

      if (launchUri == null && candidate.fallbackUri != null) {
        try {
          if (await canLaunchUrl(candidate.fallbackUri!)) {
            launchUri = candidate.fallbackUri;
          }
        } catch (_) {
          launchUri = null;
        }
      }

      if (launchUri == null) {
        continue;
      }

      options.add(
        _NavigationOption(
          label: candidate.label,
          icon: candidate.icon,
          launchUri: launchUri,
        ),
      );
    }

    return options;
  }

  static Future<bool> _openOption(_NavigationOption option) {
    return launchUrl(
      option.launchUri,
      mode: LaunchMode.externalApplication,
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _NavigationCandidate {
  const _NavigationCandidate({
    required this.label,
    required this.icon,
    this.appUri,
    this.fallbackUri,
  });

  final String label;
  final IconData icon;
  final Uri? appUri;
  final Uri? fallbackUri;
}

class _NavigationOption {
  const _NavigationOption({
    required this.label,
    required this.icon,
    required this.launchUri,
  });

  final String label;
  final IconData icon;
  final Uri launchUri;
}
