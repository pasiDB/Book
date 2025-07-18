import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';

class ModernLoadingIndicator extends StatefulWidget {
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
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
        3,
        (index) => AnimationController(
              duration: const Duration(milliseconds: 800),
              vsync: this,
            ));

    _scaleAnimations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.3,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    _opacityAnimations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.4,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            )))
        .toList();

    // Start staggered animations
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.lottieAsset != null)
          Lottie.asset(
            widget.lottieAsset!,
            width: widget.size * 2,
            height: widget.size * 2,
            fit: BoxFit.contain,
          )
        else if (widget.useCircularIndicator)
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          )
        else
          _buildAnimatedDots(colorScheme),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAnimatedDots(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withOpacity(_opacityAnimations[index].value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary
                            .withOpacity(_opacityAnimations[index].value * 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
