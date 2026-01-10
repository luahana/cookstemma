import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

void main() {
  group('LogPostSummaryDto', () {
    test('should create DTO with default isPending as false', () {
      // Act
      final dto = LogPostSummaryDto(
        publicId: 'test-id',
        title: 'Test Log',
        outcome: 'SUCCESS',
        thumbnailUrl: 'https://example.com/image.jpg',
        creatorName: 'testuser',
      );

      // Assert
      expect(dto.publicId, 'test-id');
      expect(dto.title, 'Test Log');
      expect(dto.outcome, 'SUCCESS');
      expect(dto.thumbnailUrl, 'https://example.com/image.jpg');
      expect(dto.creatorName, 'testuser');
      expect(dto.isPending, isFalse);
    });

    test('should create DTO with isPending true', () {
      // Act
      final dto = LogPostSummaryDto(
        publicId: 'pending-id',
        title: 'Pending Log',
        isPending: true,
      );

      // Assert
      expect(dto.isPending, isTrue);
    });

    test('fromSyncQueueItem should create DTO with isPending true', () {
      // Arrange - content and outcome are required fields
      final syncItem = SyncQueueItem(
        id: 'sync-123',
        localId: 'local-456',
        type: SyncOperationType.createLogPost,
        payload:
            '{"title":"Quick Log","content":"Test content","outcome":"SUCCESS","localPhotoPaths":["/path/to/photo.jpg"],"recipePublicId":"recipe-789"}',
        status: SyncStatus.pending,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 0,
      );

      // Act
      final dto = LogPostSummaryDto.fromSyncQueueItem(syncItem);

      // Assert
      expect(dto.publicId, 'local-456'); // Uses localId when available
      expect(dto.title, 'Quick Log');
      expect(dto.outcome, 'SUCCESS');
      expect(dto.thumbnailUrl, 'file:///path/to/photo.jpg');
      expect(dto.creatorName, isNull);
      expect(dto.isPending, isTrue);
    });

    test('fromSyncQueueItem should use id when localId is null', () {
      // Arrange - content and outcome are required fields
      final syncItem = SyncQueueItem(
        id: 'sync-123',
        type: SyncOperationType.createLogPost,
        payload: '{"title":"Test","content":"Test content","outcome":"SUCCESS","localPhotoPaths":[]}',
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      // Act
      final dto = LogPostSummaryDto.fromSyncQueueItem(syncItem);

      // Assert
      expect(dto.publicId, 'sync-123'); // Falls back to id
    });

    test('fromSyncQueueItem should use default title when null', () {
      // Arrange - content and outcome are required fields
      final syncItem = SyncQueueItem(
        id: 'sync-123',
        type: SyncOperationType.createLogPost,
        payload: '{"content":"Some content","outcome":"PARTIAL","localPhotoPaths":["/path/photo.jpg"]}',
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      // Act
      final dto = LogPostSummaryDto.fromSyncQueueItem(syncItem);

      // Assert
      expect(dto.title, 'Quick Log'); // Default title
    });

    test('fromSyncQueueItem should handle empty photo paths', () {
      // Arrange - content and outcome are required fields
      final syncItem = SyncQueueItem(
        id: 'sync-123',
        type: SyncOperationType.createLogPost,
        payload: '{"title":"No Photo Log","content":"Test","outcome":"FAILED","localPhotoPaths":[]}',
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      // Act
      final dto = LogPostSummaryDto.fromSyncQueueItem(syncItem);

      // Assert
      expect(dto.thumbnailUrl, isNull);
    });

    test('toEntity should preserve isPending field', () {
      // Arrange
      final dto = LogPostSummaryDto(
        publicId: 'test-id',
        title: 'Test Log',
        outcome: 'PARTIAL',
        thumbnailUrl: 'https://example.com/img.jpg',
        creatorName: 'user123',
        isPending: true,
      );

      // Act
      final entity = dto.toEntity();

      // Assert
      expect(entity.id, 'test-id');
      expect(entity.title, 'Test Log');
      expect(entity.outcome, 'PARTIAL');
      expect(entity.thumbnailUrl, 'https://example.com/img.jpg');
      expect(entity.creatorName, 'user123');
      expect(entity.isPending, isTrue);
    });

    test('toEntity should default isPending to false', () {
      // Arrange
      final dto = LogPostSummaryDto(
        publicId: 'test-id',
        title: 'Test',
      );

      // Act
      final entity = dto.toEntity();

      // Assert
      expect(entity.isPending, isFalse);
    });

    test('fromJson should not include isPending field', () {
      // Arrange
      final json = {
        'publicId': 'json-id',
        'title': 'From JSON',
        'outcome': 'FAILED',
        'thumbnailUrl': null,
        'creatorName': 'jsonuser',
      };

      // Act
      final dto = LogPostSummaryDto.fromJson(json);

      // Assert
      expect(dto.publicId, 'json-id');
      expect(dto.title, 'From JSON');
      expect(dto.isPending, isFalse); // Default value since not in JSON
    });

    test('toJson should not include isPending field', () {
      // Arrange
      final dto = LogPostSummaryDto(
        publicId: 'test-id',
        title: 'Test',
        isPending: true,
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json.containsKey('isPending'), isFalse);
      expect(json['publicId'], 'test-id');
      expect(json['title'], 'Test');
    });
  });
}
