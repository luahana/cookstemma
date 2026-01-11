import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_chips.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('HashtagChips', () {
    group('rendering', () {
      testWidgets('should render hashtags with # prefix', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'cooking'),
          Hashtag(publicId: '2', name: 'recipe'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#cooking'), findsOneWidget);
        expect(find.text('#recipe'), findsOneWidget);
      });

      testWidgets('should render empty widget when hashtags is empty', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const HashtagChips(hashtags: []),
        ));

        expect(find.byType(HashtagChips), findsOneWidget);
        expect(find.byType(SizedBox), findsWidgets);
        expect(find.byType(Wrap), findsNothing);
      });

      testWidgets('should render single hashtag', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'solo'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#solo'), findsOneWidget);
      });

      testWidgets('should render multiple hashtags', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'korean'),
          Hashtag(publicId: '2', name: 'food'),
          Hashtag(publicId: '3', name: 'homemade'),
          Hashtag(publicId: '4', name: 'delicious'),
          Hashtag(publicId: '5', name: 'dinner'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#korean'), findsOneWidget);
        expect(find.text('#food'), findsOneWidget);
        expect(find.text('#homemade'), findsOneWidget);
        expect(find.text('#delicious'), findsOneWidget);
        expect(find.text('#dinner'), findsOneWidget);
      });

      testWidgets('should use Wrap widget for layout', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'tag1'),
          Hashtag(publicId: '2', name: 'tag2'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.byType(Wrap), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('should call onHashtagTap with hashtag name when tapped', (tester) async {
        String? tappedHashtag;
        final hashtags = [
          Hashtag(publicId: '1', name: 'cooking'),
          Hashtag(publicId: '2', name: 'recipe'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(
            hashtags: hashtags,
            onHashtagTap: (name) => tappedHashtag = name,
          ),
        ));

        await tester.tap(find.text('#cooking'));
        await tester.pumpAndSettle();

        expect(tappedHashtag, 'cooking');
      });

      testWidgets('should call onHashtagTap for second hashtag', (tester) async {
        String? tappedHashtag;
        final hashtags = [
          Hashtag(publicId: '1', name: 'first'),
          Hashtag(publicId: '2', name: 'second'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(
            hashtags: hashtags,
            onHashtagTap: (name) => tappedHashtag = name,
          ),
        ));

        await tester.tap(find.text('#second'));
        await tester.pumpAndSettle();

        expect(tappedHashtag, 'second');
      });

      testWidgets('should not crash when tapped without callback', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'noCallback'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        // Should not throw
        await tester.tap(find.text('#noCallback'));
        await tester.pumpAndSettle();

        expect(find.text('#noCallback'), findsOneWidget);
      });

      testWidgets('should have GestureDetector for each hashtag', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'tag1'),
          Hashtag(publicId: '2', name: 'tag2'),
          Hashtag(publicId: '3', name: 'tag3'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(
            hashtags: hashtags,
            onHashtagTap: (_) {},
          ),
        ));

        // Each hashtag is wrapped in GestureDetector
        expect(find.byType(GestureDetector), findsNWidgets(3));
      });
    });

    group('hashtag name formatting', () {
      testWidgets('should handle single word hashtag', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'simple'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#simple'), findsOneWidget);
      });

      testWidgets('should handle multi-word hashtag (camelCase)', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'homeMade'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#homeMade'), findsOneWidget);
      });

      testWidgets('should handle numeric hashtag', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: '2024'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#2024'), findsOneWidget);
      });

      testWidgets('should handle mixed alphanumeric hashtag', (tester) async {
        final hashtags = [
          Hashtag(publicId: '1', name: 'recipe123'),
        ];

        await tester.pumpWidget(createTestWidget(
          HashtagChips(hashtags: hashtags),
        ));

        expect(find.text('#recipe123'), findsOneWidget);
      });
    });
  });

  group('Hashtag entity', () {
    test('should create hashtag with publicId and name', () {
      final hashtag = Hashtag(publicId: 'abc123', name: 'cooking');

      expect(hashtag.publicId, 'abc123');
      expect(hashtag.name, 'cooking');
    });

    test('should store different publicIds', () {
      final hashtag1 = Hashtag(publicId: 'id1', name: 'tag');
      final hashtag2 = Hashtag(publicId: 'id2', name: 'tag');

      expect(hashtag1.publicId, isNot(equals(hashtag2.publicId)));
    });

    test('should store different names', () {
      final hashtag1 = Hashtag(publicId: 'id', name: 'korean');
      final hashtag2 = Hashtag(publicId: 'id', name: 'japanese');

      expect(hashtag1.name, isNot(equals(hashtag2.name)));
    });
  });
}
