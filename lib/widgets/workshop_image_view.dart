import 'package:flutter/material.dart';

import '../core/config/backend_config.dart';
import '../core/theme/app_colors.dart';

class WorkshopImageView extends StatelessWidget {
  const WorkshopImageView({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fallbackIcon,
    required this.iconSize,
    this.overlay,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final double iconSize;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.primarySoftOf(context),
                AppColors.accentSoftOf(context),
              ],
            ),
          ),
          child: _buildImage(context),
        ),
      ),
    );

    if (overlay == null) {
      return content;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: content),
          overlay!,
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final String? resolvedUrl = _resolveImageUrl(imageUrl);
    if (resolvedUrl == null) {
      return _fallback(context);
    }

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(context),
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) {
        if (progress == null) {
          return child;
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _fallback(context),
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryToneOf(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fallback(BuildContext context) {
    return Center(
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: AppColors.primaryToneOf(context),
      ),
    );
  }

  String? _resolveImageUrl(String? rawValue) {
    final String value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    final Uri? parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    return Uri.parse(BackendConfig.resolveBaseUrl()).resolve(value).toString();
  }
}
