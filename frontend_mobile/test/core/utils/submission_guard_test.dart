import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/core/utils/submission_guard.dart';

/// Test class that uses the SubmissionGuard mixin
class _TestSubmissionGuard with SubmissionGuard {}

void main() {
  group('SubmissionGuard', () {
    late _TestSubmissionGuard testInstance;

    setUp(() {
      testInstance = _TestSubmissionGuard();
    });

    group('guardedSubmit', () {
      test('executes action when not submitting', () async {
        var executed = false;

        await testInstance.guardedSubmit(() async {
          executed = true;
          return 'result';
        });

        expect(executed, isTrue);
      });

      test('returns action result on success', () async {
        final result = await testInstance.guardedSubmit(() async {
          return 'success';
        });

        expect(result, 'success');
      });

      test('blocks concurrent calls and returns null', () async {
        final results = <String?>[];
        final completer = Completer<void>();

        // Start first call (will wait on completer)
        final firstFuture = testInstance.guardedSubmit(() async {
          await completer.future;
          return 'first';
        });

        // Try second call immediately (should be blocked)
        final secondResult = await testInstance.guardedSubmit(() async {
          return 'second';
        });

        // Second call should return null (blocked)
        results.add(secondResult);

        // Complete first call
        completer.complete();
        final firstResult = await firstFuture;
        results.add(firstResult);

        expect(results, [null, 'first']);
      });

      test('resets state after action completes', () async {
        // First call
        await testInstance.guardedSubmit(() async {
          return 'first';
        });

        // Second call should work (not blocked)
        final result = await testInstance.guardedSubmit(() async {
          return 'second';
        });

        expect(result, 'second');
      });

      test('resets state even when action throws', () async {
        // First call that throws
        try {
          await testInstance.guardedSubmit<String>(() async {
            throw Exception('Test error');
          });
        } catch (_) {
          // Expected
        }

        // Second call should work (not blocked)
        final result = await testInstance.guardedSubmit(() async {
          return 'recovered';
        });

        expect(result, 'recovered');
      });

      test('multiple sequential calls work correctly', () async {
        final results = <String?>[];

        for (var i = 0; i < 5; i++) {
          final result = await testInstance.guardedSubmit(() async {
            return 'call-$i';
          });
          results.add(result);
        }

        expect(results, ['call-0', 'call-1', 'call-2', 'call-3', 'call-4']);
      });
    });

    group('isSubmitting', () {
      test('returns false initially', () {
        expect(testInstance.isSubmitting, isFalse);
      });

      test('returns true during action execution', () async {
        final completer = Completer<void>();
        bool? stateWhileExecuting;

        final future = testInstance.guardedSubmit(() async {
          stateWhileExecuting = testInstance.isSubmitting;
          await completer.future;
          return 'done';
        });

        // Give the async function a chance to start
        await Future.delayed(Duration.zero);

        // Should be true while executing
        expect(testInstance.isSubmitting, isTrue);
        expect(stateWhileExecuting, isTrue);

        completer.complete();
        await future;

        // Should be false after completion
        expect(testInstance.isSubmitting, isFalse);
      });

      test('returns false after action throws', () async {
        try {
          await testInstance.guardedSubmit<void>(() async {
            throw Exception('Test error');
          });
        } catch (_) {
          // Expected
        }

        expect(testInstance.isSubmitting, isFalse);
      });
    });

    group('race condition scenarios', () {
      test('only first of many rapid calls executes', () async {
        var executionCount = 0;
        final completer = Completer<void>();

        // Start first call
        final firstFuture = testInstance.guardedSubmit(() async {
          executionCount++;
          await completer.future;
          return executionCount;
        });

        // Rapidly attempt many more calls
        final blockedResults = <int?>[];
        for (var i = 0; i < 10; i++) {
          final result = await testInstance.guardedSubmit(() async {
            executionCount++;
            return executionCount;
          });
          blockedResults.add(result);
        }

        // Complete first call
        completer.complete();
        final firstResult = await firstFuture;

        // Only first call should have executed
        expect(firstResult, 1);
        expect(executionCount, 1);
        expect(blockedResults, everyElement(isNull));
      });

      test('handles void return type', () async {
        var executed = false;

        await testInstance.guardedSubmit<void>(() async {
          executed = true;
        });

        expect(executed, isTrue);
      });
    });
  });
}
