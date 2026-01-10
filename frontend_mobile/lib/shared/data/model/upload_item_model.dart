import 'dart:io';

enum UploadStatus { initial, uploading, success, error }

class UploadItem {
  final File? file; // Local file for new uploads
  final String? remoteUrl; // Remote URL for existing images
  UploadStatus status;
  String? serverUrl; // 표시용 URL
  String? publicId; // 백엔드 저장용 UUID

  UploadItem({
    this.file,
    this.remoteUrl,
    this.status = UploadStatus.initial,
    this.serverUrl,
    this.publicId,
  }) : assert(file != null || remoteUrl != null,
            'Either file or remoteUrl must be provided');

  /// Create an UploadItem from a new file (for new uploads)
  factory UploadItem.fromFile(File file) {
    return UploadItem(file: file, status: UploadStatus.initial);
  }

  /// Create an UploadItem from an existing remote image (for editing)
  factory UploadItem.fromRemote({
    required String url,
    required String publicId,
  }) {
    return UploadItem(
      remoteUrl: url,
      publicId: publicId,
      status: UploadStatus.success, // Already uploaded
    );
  }

  /// Whether this item is from a remote URL (existing image)
  bool get isRemote => remoteUrl != null;
}
