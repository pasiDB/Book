import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant.withOpacity(0.4),
      highlightColor: colorScheme.surfaceVariant.withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerBookCard extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerBookCard({
    super.key,
    this.width = 140,
    this.height = 200,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerLoading(
          width: width,
          height: height,
          borderRadius: 12,
          margin: margin,
        ),
        const SizedBox(height: 8),
        ShimmerLoading(
          width: width * 0.8,
          height: 16,
          borderRadius: 4,
        ),
        const SizedBox(height: 4),
        ShimmerLoading(
          width: width * 0.6,
          height: 14,
          borderRadius: 4,
        ),
      ],
    );
  }
}

class ShimmerBookList extends StatelessWidget {
  final int itemCount;
  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;

  const ShimmerBookList({
    super.key,
    this.itemCount = 10,
    this.scrollDirection = Axis.horizontal,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return const ShimmerBookCard(
              margin: EdgeInsets.only(right: 16),
            );
          },
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const ShimmerLoading(
                width: 80,
                height: 120,
                borderRadius: 8,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 120,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 12),
                    ShimmerLoading(
                      width: double.infinity,
                      height: 40,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
