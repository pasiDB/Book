import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.lottieAsset,
    this.icon,
    this.onActionPressed,
    this.actionLabel,
  }) : assert(lottieAsset != null || icon != null,
            'Either lottieAsset or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation or Icon
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  icon!,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Action Button
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoResultsFound extends StatelessWidget {
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const NoResultsFound({
    super.key,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No Results Found',
      message:
          'We couldn\'t find what you\'re looking for. Try different keywords or browse our categories.',
      lottieAsset: 'assets/animations/no-results.json',
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
    );
  }
}

class NoBooksSaved extends StatelessWidget {
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const NoBooksSaved({
    super.key,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'Your Library is Empty',
      message:
          'Start adding books to your library to keep track of your reading journey.',
      lottieAsset: 'assets/animations/empty-library.json',
      onActionPressed: onActionPressed,
      actionLabel: actionLabel ?? 'Browse Books',
    );
  }
}

class ErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'Oops! Something Went Wrong',
      message: message ??
          'An error occurred while processing your request. Please try again.',
      lottieAsset: 'assets/animations/error.json',
      onActionPressed: onActionPressed,
      actionLabel: actionLabel ?? 'Try Again',
    );
  }
}
