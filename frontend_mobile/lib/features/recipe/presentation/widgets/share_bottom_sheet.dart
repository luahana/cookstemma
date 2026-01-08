import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:share_plus/share_plus.dart';

/// Data class for share option configuration.
class _ShareOptionData {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ShareOptionData({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
    required this.onTap,
  });
}

/// Bottom sheet for sharing a recipe to various platforms.
/// Shows locale-specific share options (e.g., KakaoTalk for Korea, WhatsApp for others).
class ShareBottomSheet extends ConsumerWidget {
  final String recipePublicId;
  final String recipeTitle;

  const ShareBottomSheet({
    super.key,
    required this.recipePublicId,
    required this.recipeTitle,
  });

  /// Show the share bottom sheet.
  static void show(BuildContext context, {
    required String recipePublicId,
    required String recipeTitle,
  }) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => ShareBottomSheet(
        recipePublicId: recipePublicId,
        recipeTitle: recipeTitle,
      ),
    );
  }

  String get shareUrl => 'https://api.pairingplanet.com/share/recipe/$recipePublicId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isKorean = locale.startsWith('ko');
    final shareOptions = _buildShareOptions(context, isKorean);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            isKorean ? '공유하기' : 'Share',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            recipeTitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20.h),

          // Share options grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: shareOptions
                .map((option) => _ShareOption(
                      icon: option.icon,
                      label: option.label,
                      color: option.color,
                      iconColor: option.iconColor,
                      onTap: option.onTap,
                    ))
                .toList(),
          ),
          SizedBox(height: 20.h),

          // URL preview
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    shareUrl,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyLink(context, isKorean),
                  child: Icon(Icons.copy, size: 16.sp, color: Colors.indigo),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  /// Build share options based on user's locale.
  List<_ShareOptionData> _buildShareOptions(BuildContext context, bool isKorean) {
    return [
      // Universal: Copy Link (always first)
      _ShareOptionData(
        icon: Icons.link,
        label: isKorean ? '링크 복사' : 'Copy Link',
        color: Colors.grey[700]!,
        onTap: () => _copyLink(context, isKorean),
      ),

      // Korea-only: KakaoTalk
      if (isKorean)
        _ShareOptionData(
          icon: Icons.chat_bubble,
          label: '카카오톡',
          color: const Color(0xFFFEE500),
          iconColor: Colors.black,
          onTap: () => _shareToKakao(context),
        ),

      // Non-Korea: WhatsApp
      if (!isKorean)
        _ShareOptionData(
          icon: Icons.message,
          label: 'WhatsApp',
          color: const Color(0xFF25D366),
          onTap: () => _shareToWhatsApp(context, isKorean),
        ),

      // Universal: X (Twitter)
      _ShareOptionData(
        icon: Icons.alternate_email,
        label: isKorean ? 'X (트위터)' : 'X',
        color: Colors.black,
        onTap: () => _shareToTwitter(context, isKorean),
      ),

      // Universal: More (native share sheet)
      _ShareOptionData(
        icon: Icons.more_horiz,
        label: isKorean ? '더보기' : 'More',
        color: Colors.grey[600]!,
        onTap: () => _shareMore(context),
      ),
    ];
  }

  void _copyLink(BuildContext context, bool isKorean) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    Navigator.pop(context);
    ToastService.showSuccess(isKorean ? '링크가 복사되었습니다' : 'Link copied');
  }

  void _shareToKakao(BuildContext context) {
    // TODO: Implement KakaoTalk sharing with KakaoSDK
    // For now, copy link and show message
    Clipboard.setData(ClipboardData(text: shareUrl));
    Navigator.pop(context);
    ToastService.showInfo('카카오톡 공유는 준비 중입니다. 링크가 복사되었습니다.');
  }

  void _shareToWhatsApp(BuildContext context, bool isKorean) {
    // TODO: Implement WhatsApp deep linking
    // For now, copy link and show message
    Clipboard.setData(ClipboardData(text: shareUrl));
    Navigator.pop(context);
    ToastService.showInfo(isKorean
        ? '왓츠앱 공유는 준비 중입니다. 링크가 복사되었습니다.'
        : 'WhatsApp sharing coming soon. Link copied.');
  }

  void _shareToTwitter(BuildContext context, bool isKorean) {
    // TODO: Implement Twitter sharing
    // For now, copy link and show message
    Clipboard.setData(ClipboardData(text: shareUrl));
    Navigator.pop(context);
    ToastService.showInfo(isKorean
        ? '트위터 공유는 준비 중입니다. 링크가 복사되었습니다.'
        : 'X sharing coming soon. Link copied.');
  }

  void _shareMore(BuildContext context) async {
    Navigator.pop(context);
    await Share.share(
      '$recipeTitle\n$shareUrl',
      subject: recipeTitle,
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
