import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker;

  /// Creates a MediaService with an optional ImagePicker for testing
  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Take photo using camera
  /// Note: Let ImagePicker handle permissions natively - it handles
  /// permanentlyDenied cases better than permission_handler
  Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
    } catch (e) {
      return null;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      return null;
    }
  }
}
