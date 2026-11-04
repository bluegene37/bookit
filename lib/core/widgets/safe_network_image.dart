// Gene - Nov, 05, 2026: Safe Network Image with Neumorphic loading skeleton and graceful fallback rendering
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBg = isDark ? NeumorphicColors.darkHighlight : NeumorphicColors.lightShadow.withValues(alpha: 0.3);
    final iconColor = isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted;

    final imageWidget = (imageUrl == null || imageUrl!.trim().isEmpty)
        ? _buildFallback(fallbackBg, iconColor)
        : Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: fallbackBg,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildFallback(fallbackBg, iconColor),
          );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback(Color bgColor, Color iconColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: (height != null && height! < 60) ? 20 : 36, color: iconColor),
    );
  }
}
