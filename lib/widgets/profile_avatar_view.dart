import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/config/backend_config.dart';

class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({
    super.key,
    required this.size,
    required this.initials,
    this.imageUrl,
    this.onEdit,
    this.editTooltip,
    this.isLoading = false,
  });

  final double size;
  final String initials;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget avatarChild = _buildAvatarChild();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.32),
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.22),
                child: avatarChild,
              ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isLoading ? null : onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Tooltip(
                            message: editTooltip,
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarChild() {
    final String trimmed = imageUrl?.trim() ?? '';
    final Uint8List? memoryImage = _decodeDataUri(trimmed);
    final String? resolvedUrl = _resolveImageUrl(trimmed);

    if (memoryImage != null) {
      return Image.memory(
        memoryImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    if (resolvedUrl != null) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Uint8List? _decodeDataUri(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }

    final int commaIndex = value.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= value.length - 1) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  String? _resolveImageUrl(String value) {
    if (value.isEmpty || value.startsWith('data:image/')) {
      return null;
    }

    final Uri? parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    return Uri.parse(BackendConfig.resolveBaseUrl()).resolve(value).toString();
  }
}
