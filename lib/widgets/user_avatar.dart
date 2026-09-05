import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/user_notifier.dart';

/// High-performance, anti-flicker avatar widget.
/// Uses memoized Uint8List bytes with gaplessPlayback so frame re-renders
/// never flash, blank, or reload when parent widgets rebuild.
class UserAvatar extends StatelessWidget {
  final double size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final double fontSize;
  final Color? fallbackBackgroundColor;
  final String? fallbackName;

  const UserAvatar({
    super.key,
    this.size = 40,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = true,
    this.fontSize = 18,
    this.fallbackBackgroundColor,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;

    return ValueListenableBuilder<Uint8List?>(
      valueListenable: UserNotifier.avatarBytes,
      builder: (context, bytes, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: UserNotifier.avatarUrl,
          builder: (context, url, _) {
            return ValueListenableBuilder<String>(
              valueListenable: UserNotifier.username,
              builder: (context, currentUsername, _) {
                final effectiveName = fallbackName ??
                    (currentUsername.isNotEmpty ? currentUsername : 'U');
                final initial = effectiveName.isNotEmpty
                    ? effectiveName[0].toUpperCase()
                    : 'U';

                Widget content;

                if (bytes != null && bytes.isNotEmpty) {
                  content = Image.memory(
                    bytes,
                    width: effectiveWidth,
                    height: effectiveHeight,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (ctx, err, stack) =>
                        _buildFallback(initial, effectiveWidth, effectiveHeight),
                  );
                } else if (url != null && url.isNotEmpty && url.startsWith('http')) {
                  content = Image.network(
                    url,
                    width: effectiveWidth,
                    height: effectiveHeight,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (ctx, err, stack) =>
                        _buildFallback(initial, effectiveWidth, effectiveHeight),
                  );
                } else {
                  content =
                      _buildFallback(initial, effectiveWidth, effectiveHeight);
                }

                if (isCircle) {
                  return ClipOval(child: content);
                } else if (borderRadius != null) {
                  return ClipRRect(
                      borderRadius: borderRadius!, child: content);
                }
                return content;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFallback(String initial, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: fallbackBackgroundColor ?? const Color(0xFFB00710),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
