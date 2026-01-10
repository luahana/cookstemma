import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

class ReorderableImageUploadSlotGroup extends StatelessWidget {
  final List<UploadItem> items;
  final VoidCallback onAddPressed;
  final Function(int) onRemovePressed;
  final Function(int) onRetryPressed;
  final Function(int, int) onReorder;

  const ReorderableImageUploadSlotGroup({
    super.key,
    required this.items,
    required this.onAddPressed,
    required this.onRemovePressed,
    required this.onRetryPressed,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.w,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + (items.length < 3 ? 1 : 0), // 최대 3장까지 허용
        onReorder: onReorder,
        proxyDecorator: (child, index, animation) =>
            child, // 드래그 시 투명도 등 효과 제거용
        itemBuilder: (context, index) {
          // 1. 추가 버튼 (리스트의 마지막에 위치)
          if (index == items.length) {
            return _buildAddButton(key: const ValueKey('add_button'));
          }

          // 2. 개별 이미지 슬롯
          final item = items[index];
          return _buildImageSlot(item, index, key: ValueKey(item.file!.path));
        },
      ),
    );
  }

  /// 이미지 추가 버튼 위젯
  Widget _buildAddButton({required Key key}) {
    return GestureDetector(
      key: key,
      onTap: onAddPressed,
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey[600]),
            SizedBox(height: 4.h),
            Text(
              "${items.length}/3",
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  /// 업로드 상태가 반영된 이미지 슬롯 위젯
  Widget _buildImageSlot(UploadItem item, int index, {required Key key}) {
    return Container(
      key: key,
      width: 100.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Stack(
        children: [
          // 배경 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              item.file!,
              width: 100.w,
              height: 100.w,
              fit: BoxFit.cover,
            ),
          ),

          // 상태별 오버레이
          if (item.status == UploadStatus.uploading)
            _buildOverlay(const CircularProgressIndicator(strokeWidth: 2)),

          if (item.status == UploadStatus.error)
            _buildOverlay(
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => onRetryPressed(index),
              ),
            ),

          // 삭제 버튼 (우측 상단)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: GestureDetector(
              onTap: () => onRemovePressed(index),
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16.sp, color: Colors.white),
              ),
            ),
          ),

          // 성공 표시 (선택사항)
          if (item.status == UploadStatus.success)
            Positioned(
              bottom: 4.h,
              right: 4.w,
              child: Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
            ),
        ],
      ),
    );
  }

  /// 공용 오버레이 배경
  Widget _buildOverlay(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(child: child),
    );
  }
}
