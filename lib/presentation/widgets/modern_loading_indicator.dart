import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';

class ModernLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool useCircularIndicator;
  final String? lottieAsset;
  final double size;

  const ModernLoadingIndicator({
    super.key,
    this.message,
    this.useCircularIndicator = false,
    this.lottieAsset,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lottieAsset != null)
          Lottie.asset(
            lottieAsset!,
            width: size * 2,
            height: size * 2,
            fit: BoxFit.contain,
          )
        else if (useCircularIndicator)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          )
        else
          _buildPulsingDots(colorScheme),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPulsingDots(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class ModernRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final String? lottieAsset;

  const ModernRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: colorScheme.surface,
      color: colorScheme.primary,
      strokeWidth: 3,
      displacement: 40,
      child: child,
    );
  }
}
