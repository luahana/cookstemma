import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceSheet extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const ImageSourceSheet({super.key, required this.onSourceSelected});

  // 💡 호출을 편리하게 만들기 위한 정적 메서드
  static Future<void> show({
    required BuildContext context,
    required Function(ImageSource) onSourceSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) =>
          ImageSourceSheet(onSourceSelected: onSourceSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              "사진 추가",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text("카메라로 촬영"),
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("갤러리에서 선택"),
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.gallery);
            },
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}
