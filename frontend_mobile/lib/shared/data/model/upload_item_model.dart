import 'dart:io';

enum UploadStatus { initial, uploading, success, error }

class UploadItem {
  final File file;
  UploadStatus status;
  String? serverUrl; // 표시용 URL
  String? publicId; // 백엔드 저장용 UUID

  UploadItem({
    required this.file,
    this.status = UploadStatus.initial,
    this.serverUrl,
    this.publicId,
  });
}
