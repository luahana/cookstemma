import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/services/permission_handler.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  // 사진 촬영
  Future<XFile?> takePhoto() async {
    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) return null;

    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // 용량 최적화
      maxWidth: 1080,
    );
  }

  // 갤러리에서 선택
  Future<XFile?> pickImage() async {
    final hasPermission = await PermissionService.requestGalleryPermission();
    if (!hasPermission) return null;

    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
  }
}
