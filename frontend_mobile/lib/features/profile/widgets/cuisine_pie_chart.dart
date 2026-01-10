import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/user/cuisine_stat_dto.dart';

/// Donut chart showing cuisine distribution
class CuisinePieChart extends StatefulWidget {
  final List<CuisineStatDto> cuisineDistribution;
  final int totalLogs;

  const CuisinePieChart({
    super.key,
    required this.cuisineDistribution,
    required this.totalLogs,
  });

  @override
  State<CuisinePieChart> createState() => _CuisinePieChartState();
}

class _CuisinePieChartState extends State<CuisinePieChart> {
  int touchedIndex = -1;

  static final List<Color> _colors = [
    AppColors.textPrimary, // Deep Blue
    Color(0xFFE65100), // Orange
    Color(0xFF2E7D32), // Green
    Color(0xFFC2185B), // Pink
    Color(0xFF6A1B9A), // Purple
    Color(0xFF78909C), // Grey (for "other")
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.cuisineDistribution.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.cuisineDistribution'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              // Pie chart
              SizedBox(
                width: 120.w,
                height: 120.w,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2.w,
                    centerSpaceRadius: 30.w,
                    sections: _buildSections(),
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildLegend(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.cuisineDistribution.asMap().entries.map((entry) {
      final index = entry.key;
      final cuisine = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 14.0.sp : 11.0.sp;
      final radius = isTouched ? 35.0.w : 30.0.w;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: cuisine.count.toDouble(),
        title: '${cuisine.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    return widget.cuisineDistribution.asMap().entries.map((entry) {
      final index = entry.key;
      final cuisine = entry.value;
      final color = _colors[index % _colors.length];

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _getCuisineDisplayName(cuisine.categoryCode),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${cuisine.count}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getCuisineDisplayName(String categoryCode) {
    // Try to get localized name, fallback to category code
    final key = 'cuisine.$categoryCode';
    final translated = key.tr();
    return translated == key ? _formatCategoryCode(categoryCode) : translated;
  }

  String _formatCategoryCode(String code) {
    // Convert "korean_food" to "Korean Food"
    return code
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'profile.noCuisineData'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
