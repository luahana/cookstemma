import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';

void main() {
  group('UserDto', () {
    group('fromJson', () {
      test('should parse level from JSON', () {
        final json = {
          'id': 'test-uuid',
          'username': 'testuser',
          'level': 5,
          'levelName': 'beginner',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.level, equals(5));
      });

      test('should parse levelName from JSON', () {
        final json = {
          'id': 'test-uuid',
          'username': 'testuser',
          'level': 10,
          'levelName': 'homeCook',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.levelName, equals('homeCook'));
      });

      test('should use default level=1 when missing', () {
        final json = {
          'id': 'test-uuid',
          'username': 'testuser',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.level, equals(1));
      });

      test('should use default levelName="beginner" when missing', () {
        final json = {
          'id': 'test-uuid',
          'username': 'testuser',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.levelName, equals('beginner'));
      });

      test('should parse all fields correctly', () {
        final json = {
          'id': 'test-uuid-123',
          'username': 'chef_master',
          'profileImageId': 'image-uuid',
          'profileImageUrl': 'https://example.com/image.jpg',
          'gender': 'MALE',
          'birthDate': '1990-01-15',
          'locale': 'en-US',
          'followerCount': 100,
          'followingCount': 50,
          'recipeCount': 25,
          'logCount': 75,
          'level': 15,
          'levelName': 'skilledCook',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.id, equals('test-uuid-123'));
        expect(dto.username, equals('chef_master'));
        expect(dto.profileImageId, equals('image-uuid'));
        expect(dto.profileImageUrl, equals('https://example.com/image.jpg'));
        expect(dto.gender, equals('MALE'));
        expect(dto.birthDate, equals('1990-01-15'));
        expect(dto.locale, equals('en-US'));
        expect(dto.followerCount, equals(100));
        expect(dto.followingCount, equals(50));
        expect(dto.recipeCount, equals(25));
        expect(dto.logCount, equals(75));
        expect(dto.level, equals(15));
        expect(dto.levelName, equals('skilledCook'));
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'test-uuid',
          'username': 'testuser',
          'level': 1,
          'levelName': 'beginner',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.profileImageId, isNull);
        expect(dto.profileImageUrl, isNull);
        expect(dto.gender, isNull);
        expect(dto.birthDate, isNull);
        expect(dto.locale, isNull);
      });
    });

    group('toJson', () {
      test('should serialize level to JSON', () {
        final dto = UserDto(
          id: 'test-uuid',
          username: 'testuser',
          level: 10,
          levelName: 'homeCook',
        );

        final json = dto.toJson();

        expect(json['level'], equals(10));
      });

      test('should serialize levelName to JSON', () {
        final dto = UserDto(
          id: 'test-uuid',
          username: 'testuser',
          level: 20,
          levelName: 'homeChef',
        );

        final json = dto.toJson();

        expect(json['levelName'], equals('homeChef'));
      });

      test('should serialize all fields to JSON', () {
        final dto = UserDto(
          id: 'test-uuid-456',
          username: 'master_chef',
          profileImageId: 'img-uuid',
          profileImageUrl: 'https://example.com/profile.jpg',
          gender: 'FEMALE',
          birthDate: '1985-06-20',
          locale: 'ko-KR',
          followerCount: 200,
          followingCount: 75,
          recipeCount: 50,
          logCount: 150,
          level: 26,
          levelName: 'masterChef',
        );

        final json = dto.toJson();

        expect(json['id'], equals('test-uuid-456'));
        expect(json['username'], equals('master_chef'));
        expect(json['profileImageId'], equals('img-uuid'));
        expect(json['profileImageUrl'], equals('https://example.com/profile.jpg'));
        expect(json['gender'], equals('FEMALE'));
        expect(json['birthDate'], equals('1985-06-20'));
        expect(json['locale'], equals('ko-KR'));
        expect(json['followerCount'], equals(200));
        expect(json['followingCount'], equals(75));
        expect(json['recipeCount'], equals(50));
        expect(json['logCount'], equals(150));
        expect(json['level'], equals(26));
        expect(json['levelName'], equals('masterChef'));
      });
    });

    group('round-trip serialization', () {
      test('should maintain level data after fromJson/toJson round-trip', () {
        final original = {
          'id': 'round-trip-uuid',
          'username': 'roundtripuser',
          'level': 18,
          'levelName': 'homeChef',
          'followerCount': 50,
          'followingCount': 30,
          'recipeCount': 10,
          'logCount': 20,
        };

        final dto = UserDto.fromJson(original);
        final serialized = dto.toJson();

        expect(serialized['level'], equals(original['level']));
        expect(serialized['levelName'], equals(original['levelName']));
      });
    });

    group('default values', () {
      test('should have sensible defaults when constructed directly', () {
        final dto = UserDto(
          id: 'direct-uuid',
          username: 'directuser',
        );

        expect(dto.level, equals(1));
        expect(dto.levelName, equals('beginner'));
        expect(dto.followerCount, equals(0));
        expect(dto.followingCount, equals(0));
        expect(dto.recipeCount, equals(0));
        expect(dto.logCount, equals(0));
      });
    });
  });
}
