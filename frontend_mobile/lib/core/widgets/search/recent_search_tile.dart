import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';

/// A tile displaying a recent search term with optional highlighting.
/// Shows clock icon, search term, and delete button.
class RecentSearchTile extends StatelessWidget {
  final String term;
  final String? query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const RecentSearchTile({
    super.key,
    required this.term,
    this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HighlightedText(
                text: term,
                query: query,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
