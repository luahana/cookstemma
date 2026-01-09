import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Banner showing offline/cache status
class CacheStatusBanner extends StatelessWidget {
  final bool isFromCache;
  final DateTime? cachedAt;
  final bool isLoading;

  const CacheStatusBanner({
    super.key,
    required this.isFromCache,
    this.cachedAt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFromCache || cachedAt == null) {
      return const SizedBox.shrink();
    }

    final timeText = _formatCacheTime(cachedAt!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 14,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${'home.offlineData'.tr()} · $timeText',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange[700],
              ),
            ),
        ],
      ),
    );
  }

  String _formatCacheTime(DateTime cachedAt) {
    final diff = DateTime.now().difference(cachedAt);

    if (diff.inMinutes < 1) {
      return 'common.justNow'.tr();
    } else if (diff.inMinutes < 60) {
      return 'common.minutesAgo'.tr(namedArgs: {'count': diff.inMinutes.toString()});
    } else if (diff.inHours < 24) {
      return 'common.hoursAgo'.tr(namedArgs: {'count': diff.inHours.toString()});
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
