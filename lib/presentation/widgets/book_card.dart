import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/book.dart';
import '../../core/constants/app_constants.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: book.coverImageUrl != null
                      ? Image.network(
                          book.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.book,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.book,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.authorNames,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (book.subjects.isNotEmpty)
                      Text(
                        book.subjects.take(3).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (book.hasTextFormat)
                          const Chip(
                            label: Text('TXT'),
                            backgroundColor: AppConstants.primaryColor,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        if (book.hasTextFormat && book.hasEpubFormat)
                          const SizedBox(width: 8),
                        if (book.hasEpubFormat)
                          const Chip(
                            label: Text('EPUB'),
                            backgroundColor: AppConstants.secondaryColor,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
