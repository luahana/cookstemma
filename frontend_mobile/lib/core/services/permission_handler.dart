import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // 카메라 권한 확인 및 요청
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  // 갤러리 권한 확인 및 요청
  static Future<bool> requestGalleryPermission() async {
    var status = await Permission.photos.status;
    if (status.isGranted) return true;

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  // 권한 거부 시 설정창으로 유도
  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
