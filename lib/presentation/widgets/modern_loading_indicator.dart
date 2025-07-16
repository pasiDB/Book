import 'package:flutter/material.dart';

class ModernLoadingIndicator extends StatelessWidget {
  const ModernLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 64,
        height: 64,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 6.28319, // 2*pi
              child: child,
            );
          },
          onEnd: () {},
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return SweepGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ],
                stops: const [0.0, 0.7, 1.0],
                startAngle: 0.0,
                endAngle: 6.28319,
                tileMode: TileMode.clamp,
              ).createShader(bounds);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.transparent,
                  width: 8,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
