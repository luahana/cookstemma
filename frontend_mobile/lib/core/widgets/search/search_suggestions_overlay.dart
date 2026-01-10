import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/recent_search_tile.dart';

/// A dropdown overlay showing search suggestions (recent searches).
/// Uses CompositedTransformFollower for positioning relative to the search bar.
class SearchSuggestionsOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final String query;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onRemoveTap;
  final VoidCallback onClearAllTap;
  final double width;

  const SearchSuggestionsOverlay({
    super.key,
    required this.layerLink,
    required this.query,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onRemoveTap,
    required this.onClearAllTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if no suggestions
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, kToolbarHeight),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.white,
          child: Container(
            constraints: BoxConstraints(maxHeight: 300.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with clear all button (only when showing history, not filtered)
                  if (query.isEmpty) _buildHeader(),
                  // Suggestions list
                  ...suggestions.map(
                    (term) => RecentSearchTile(
                      term: term,
                      query: query.isEmpty ? null : query,
                      onTap: () => onSuggestionTap(term),
                      onRemove: () => onRemoveTap(term),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '최근 검색',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          GestureDetector(
            onTap: onClearAllTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              '전체 삭제',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
