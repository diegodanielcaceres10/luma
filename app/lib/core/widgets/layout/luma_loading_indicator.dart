import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../app/theme/app_colors.dart';

/// A minimalist, premium loading indicator designed for the Luma personal finance mobile application.
///
/// Displays abstract financial-inspired elements: synchronized circular flow arcs,
/// floating balance tokens with subtle elevation, and a gentle central pulse.
///
/// Fully supports:
/// - Seamless infinite looping with fluid cubic-bezier easing.
/// - Transparent background for clean integration across both dark and light surfaces.
/// - Dynamic sizing (from compact 20px buttons up to full-screen loaders).
/// - Accessibility: respects [MediaQuery.disableAnimationsOf] (reduced motion).
/// - Graceful fallback to [CircularProgressIndicator] if assets fail to load.
class LumaLoadingIndicator extends StatelessWidget {
  static const assetPath = 'assets/animations/luma_loading.json';

  /// Standard size presets for consistent UI hierarchy.
  static const double sizeInline = 20.0;
  static const double sizeSmall = 24.0;
  static const double sizeMedium = 48.0;
  static const double sizeLarge = 80.0;

  /// The diameter (width and height) of the loading indicator canvas.
  final double size;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  const LumaLoadingIndicator({
    super.key,
    this.size = sizeMedium,
    this.semanticLabel = 'Loading',
  });

  /// Compact constructor optimized for inline placement inside buttons and headers.
  const LumaLoadingIndicator.inline({
    super.key,
    this.size = sizeInline,
    this.semanticLabel = 'Loading',
  });

  /// Compact constructor for list tiles and table cards.
  const LumaLoadingIndicator.small({
    super.key,
    this.size = sizeSmall,
    this.semanticLabel = 'Loading',
  });

  /// Larger constructor optimized for modal dialogs and fullscreen loading views.
  const LumaLoadingIndicator.page({
    super.key,
    this.size = sizeLarge,
    this.semanticLabel = 'Loading',
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: size,
        height: size,
        child: reduceMotion
            ? Center(
                child: SizedBox(
                  width: size * 0.65,
                  height: size * 0.65,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.authAccent),
                  ),
                ),
              )
            : Lottie.asset(
                assetPath,
                bundle: DefaultAssetBundle.of(context),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to minimal brand spinner if asset bundle fails
                  return Center(
                    child: SizedBox(
                      width: size * 0.65,
                      height: size * 0.65,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.authAccent),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
