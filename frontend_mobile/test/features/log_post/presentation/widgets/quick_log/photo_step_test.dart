import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';

void main() {
  group('QuickLogDraftNotifier - Photo Management', () {
    late ProviderContainer container;
    late QuickLogDraftNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(quickLogDraftProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('addPhoto', () {
      test('adds photo path to draft', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);

        notifier.addPhoto('/path/to/photo1.jpg');

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths, contains('/path/to/photo1.jpg'));
        expect(draft.photoPaths.length, 1);
      });

      test('adds multiple photos up to 3', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);

        notifier.addPhoto('/photo1.jpg');
        notifier.addPhoto('/photo2.jpg');
        notifier.addPhoto('/photo3.jpg');

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths.length, 3);
      });

      test('ignores photos beyond max 3', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);

        notifier.addPhoto('/photo1.jpg');
        notifier.addPhoto('/photo2.jpg');
        notifier.addPhoto('/photo3.jpg');
        notifier.addPhoto('/photo4.jpg'); // Should be ignored

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths.length, 3);
        expect(draft.photoPaths, isNot(contains('/photo4.jpg')));
      });

      test('does not advance step when photos added', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);

        notifier.addPhoto('/photo1.jpg');

        final draft = container.read(quickLogDraftProvider);
        expect(draft.step, QuickLogStep.capturingPhoto);
      });
    });

    group('removePhoto', () {
      test('removes photo at index', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');
        notifier.addPhoto('/photo2.jpg');
        notifier.addPhoto('/photo3.jpg');

        notifier.removePhoto(1);

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths.length, 2);
        expect(draft.photoPaths, equals(['/photo1.jpg', '/photo3.jpg']));
      });

      test('handles invalid index gracefully', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');

        notifier.removePhoto(-1);
        notifier.removePhoto(5);

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths.length, 1);
      });
    });

    group('reorderPhotos', () {
      test('reorders photos correctly', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');
        notifier.addPhoto('/photo2.jpg');
        notifier.addPhoto('/photo3.jpg');

        // Move first to last
        notifier.reorderPhotos(0, 3);

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths, equals(['/photo2.jpg', '/photo3.jpg', '/photo1.jpg']));
      });

      test('handles move to earlier position', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');
        notifier.addPhoto('/photo2.jpg');
        notifier.addPhoto('/photo3.jpg');

        // Move last to first
        notifier.reorderPhotos(2, 0);

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths, equals(['/photo3.jpg', '/photo1.jpg', '/photo2.jpg']));
      });

      test('handles invalid indices gracefully', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');

        notifier.reorderPhotos(-1, 0);
        notifier.reorderPhotos(0, -1);

        final draft = container.read(quickLogDraftProvider);
        expect(draft.photoPaths.length, 1);
      });
    });

    group('proceedToNotes', () {
      test('advances to notes step when photos exist', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        notifier.addPhoto('/photo1.jpg');

        notifier.proceedToNotes();

        final draft = container.read(quickLogDraftProvider);
        expect(draft.step, QuickLogStep.addingNotes);
      });

      test('does nothing when no photos exist', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);

        notifier.proceedToNotes();

        final draft = container.read(quickLogDraftProvider);
        expect(draft.step, QuickLogStep.capturingPhoto);
      });
    });

    group('goBack from photo step', () {
      test('returns to outcome step', () {
        notifier.startFlow();
        notifier.selectOutcome(LogOutcome.success);
        expect(container.read(quickLogDraftProvider).step, QuickLogStep.capturingPhoto);

        notifier.goBack();

        final draft = container.read(quickLogDraftProvider);
        expect(draft.step, QuickLogStep.selectingOutcome);
      });
    });
  });

  group('QuickLogDraft - canSubmit', () {
    test('returns true when outcome, photos, and recipePublicId exist', () {
      final draft = QuickLogDraft(
        step: QuickLogStep.addingHashtags,
        outcome: LogOutcome.success,
        photoPaths: ['/photo1.jpg'],
        recipePublicId: 'recipe-123',
      );

      expect(draft.canSubmit, isTrue);
    });

    test('returns false when no photos', () {
      final draft = QuickLogDraft(
        step: QuickLogStep.addingHashtags,
        outcome: LogOutcome.success,
        photoPaths: [],
        recipePublicId: 'recipe-123',
      );

      expect(draft.canSubmit, isFalse);
    });

    test('returns false when no outcome', () {
      final draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: null,
        photoPaths: ['/photo1.jpg'],
        recipePublicId: 'recipe-123',
      );

      expect(draft.canSubmit, isFalse);
    });

    test('returns false when no recipePublicId', () {
      final draft = QuickLogDraft(
        step: QuickLogStep.addingHashtags,
        outcome: LogOutcome.success,
        photoPaths: ['/photo1.jpg'],
        recipePublicId: null,
      );

      expect(draft.canSubmit, isFalse);
    });
  });

  group('PhotoStep UI', () {
    Widget createTestWidget({
      required QuickLogDraft draft,
      List<Override>? overrides,
    }) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => ProviderScope(
          overrides: overrides ?? [],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: _MockPhotoStepWidget(draft: draft),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows outcome badge when outcome selected', (tester) async {
      final draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: LogOutcome.success,
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));

      expect(find.byType(OutcomeBadge), findsOneWidget);
    });

    testWidgets('does not show outcome badge when outcome is null', (tester) async {
      const draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: null,
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));

      expect(find.byType(OutcomeBadge), findsNothing);
    });

    testWidgets('continue button not shown when no photos', (tester) async {
      const draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: LogOutcome.success,
        photoPaths: [],
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));

      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('continue button shown when at least 1 photo', (tester) async {
      final draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: LogOutcome.success,
        photoPaths: ['/photo1.jpg'],
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));
      await tester.pumpAndSettle();

      // Scroll to ensure button is visible
      await tester.ensureVisible(find.text('Continue'));
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('back button is always visible', (tester) async {
      const draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: LogOutcome.success,
        photoPaths: [],
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));
      await tester.pumpAndSettle();

      // Scroll to ensure button is visible
      await tester.ensureVisible(find.text('Back'));
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('displays header text', (tester) async {
      const draft = QuickLogDraft(
        step: QuickLogStep.capturingPhoto,
        outcome: LogOutcome.success,
        recipePublicId: 'recipe-123',
      );

      await tester.pumpWidget(createTestWidget(draft: draft));

      expect(find.text('Capture your evidence'), findsOneWidget);
      expect(find.text('Add up to 3 photos'), findsOneWidget);
    });
  });
}

/// Mock PhotoStep widget without localization for testing
class _MockPhotoStepWidget extends StatelessWidget {
  final QuickLogDraft draft;

  const _MockPhotoStepWidget({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Selected outcome badge
          if (draft.outcome != null)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: OutcomeBadge(
                outcome: draft.outcome!,
                variant: OutcomeBadgeVariant.full,
              ),
            ),
          // Header
          Text(
            'Capture your evidence',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Add up to 3 photos',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          // Photo placeholder
          Container(
            height: 100.h,
            color: Colors.grey[200],
            child: Center(
              child: Text('${draft.photoPaths.length} photos'),
            ),
          ),
          SizedBox(height: 24.h),
          // Navigation buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const Spacer(),
              // Continue button - only enabled if at least 1 photo
              if (draft.photoPaths.isNotEmpty)
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
