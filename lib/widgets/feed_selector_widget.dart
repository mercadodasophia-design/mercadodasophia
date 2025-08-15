import 'package:flutter/material.dart';
import '../models/feed.dart';
import '../theme/app_theme.dart';

class FeedSelectorWidget extends StatelessWidget {
  final List<Feed> feeds;
  final String selectedFeed;
  final Function(String) onFeedSelected;

  const FeedSelectorWidget({
    Key? key,
    required this.feeds,
    required this.selectedFeed,
    required this.onFeedSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          final feed = feeds[index];
          final isSelected = feed.feedName == selectedFeed;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                feed.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFeedSelected(feed.feedName);
                }
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              avatar: isSelected ? const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 16,
              ) : null,
            ),
          );
        },
      ),
    );
  }
}
