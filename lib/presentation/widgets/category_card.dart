import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: isSelected
              ? Border.all(color: AppConstants.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 32,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDisplayName(category),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Icons.auto_stories;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'philosophy':
        return Icons.psychology;
      case 'poetry':
        return Icons.format_quote;
      case 'drama':
        return Icons.theater_comedy;
      case 'biography':
        return Icons.person;
      case 'adventure':
        return Icons.explore;
      case 'romance':
        return Icons.favorite;
      case 'mystery':
        return Icons.search;
      default:
        return Icons.book;
    }
  }

  String _getCategoryDisplayName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }
}
