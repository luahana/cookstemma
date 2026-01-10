import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// A reusable empty state widget for search results.
/// Shows helpful tips when no results are found.
class SearchEmptyState extends StatelessWidget {
  final String query;
  final String entityName;
  final VoidCallback? onClearSearch;

  const SearchEmptyState({
    super.key,
    required this.query,
    required this.entityName,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48.sp,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24.h),

                // Query text
                Text(
                  "'$query'",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // No results message
                Text(
                  '검색 결과가 없습니다',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),

                // Tips container
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildTip('다른 키워드로 검색해보세요'),
                      SizedBox(height: 8.h),
                      _buildTip('검색어의 철자를 확인해주세요'),
                      SizedBox(height: 8.h),
                      _buildTip('더 일반적인 검색어를 사용해보세요'),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Clear search button
                if (onClearSearch != null)
                  TextButton.icon(
                    onPressed: onClearSearch,
                    icon: Icon(Icons.refresh, size: 18.sp),
                    label: const Text('검색 초기화'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 16.sp,
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
