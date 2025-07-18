import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isInLibrary;
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;
  final bool showProgress;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isInLibrary = false,
    this.width = 120, // Reduced from 140
    this.height = 160, // Reduced from 200
    this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 100, // Increased from 80 for bigger cover
        margin: margin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover on the left
            Stack(
              children: [
                Container(
                  width: 75, // Increased from 60 for bigger cover
                  height: 100, // Increased from 80 for bigger cover
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Book Cover Image or Placeholder
                        Hero(
                          tag: 'book_cover_${book.id}',
                          child: Container(
                            color: colorScheme.surfaceVariant,
                            child: book.coverUrl != null
                                ? Image.network(
                                    book.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderCover(context);
                                    },
                                  )
                                : _buildPlaceholderCover(context),
                          ),
                        ),
                        // Overlay for visual effect
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                colorScheme.shadow.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2.seconds, delay: 3.seconds),

                // Library Badge
                if (isInLibrary)
                  Positioned(
                    top: 6, // Increased from 4
                    right: 6, // Increased from 4
                    child: Container(
                      padding: const EdgeInsets.all(4), // Increased from 3
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.book,
                        size: 14, // Increased from 12
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),

                // Reading Progress
                if (showProgress && book.readingProgress != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3, // Increased from 2
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: book.readingProgress!.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Book Details on the right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16), // Increased from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Book Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms)
                        .moveX(begin: 10, end: 0),

                    // Author
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'by ${book.author!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.1,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms)
                          .moveX(begin: 10, end: 0),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 32, // Increased from 24
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 6), // Increased from 4
          Text(
            book.title.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: 18, // Increased from 16
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
