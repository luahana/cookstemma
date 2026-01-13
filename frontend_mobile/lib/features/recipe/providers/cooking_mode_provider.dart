import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';

/// Timer state for a single step
class StepTimerState {
  final Duration totalDuration;
  final Duration remainingDuration;
  final bool isRunning;
  final bool isCompleted;

  const StepTimerState({
    required this.totalDuration,
    required this.remainingDuration,
    this.isRunning = false,
    this.isCompleted = false,
  });

  StepTimerState copyWith({
    Duration? totalDuration,
    Duration? remainingDuration,
    bool? isRunning,
    bool? isCompleted,
  }) {
    return StepTimerState(
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Format remaining duration as MM:SS or HH:MM:SS
  String get formattedRemaining {
    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    if (totalDuration.inSeconds == 0) return 0.0;
    return 1.0 - (remainingDuration.inSeconds / totalDuration.inSeconds);
  }
}

/// Main cooking mode state
class CookingModeState {
  final List<RecipeStep> steps;
  final List<Ingredient> ingredients;
  final int currentStepIndex;
  final Set<int> checkedIngredientIndices;
  final Map<int, StepTimerState> stepTimers;

  const CookingModeState({
    required this.steps,
    required this.ingredients,
    this.currentStepIndex = 0,
    this.checkedIngredientIndices = const {},
    this.stepTimers = const {},
  });

  CookingModeState copyWith({
    List<RecipeStep>? steps,
    List<Ingredient>? ingredients,
    int? currentStepIndex,
    Set<int>? checkedIngredientIndices,
    Map<int, StepTimerState>? stepTimers,
  }) {
    return CookingModeState(
      steps: steps ?? this.steps,
      ingredients: ingredients ?? this.ingredients,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      checkedIngredientIndices:
          checkedIngredientIndices ?? this.checkedIngredientIndices,
      stepTimers: stepTimers ?? this.stepTimers,
    );
  }

  /// Current step
  RecipeStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  /// Check if there is a next step
  bool get hasNextStep => currentStepIndex < steps.length - 1;

  /// Check if there is a previous step
  bool get hasPreviousStep => currentStepIndex > 0;

  /// Progress text (e.g., "Step 3 of 8")
  String get progressText => 'Step ${currentStepIndex + 1} of ${steps.length}';

  /// Progress value (0.0 to 1.0) for progress indicator
  double get progressValue {
    if (steps.isEmpty) return 0.0;
    return (currentStepIndex + 1) / steps.length;
  }

  /// Check if an ingredient is checked
  bool isIngredientChecked(int index) =>
      checkedIngredientIndices.contains(index);

  /// Get timer state for current step
  StepTimerState? get currentStepTimer => stepTimers[currentStepIndex];

  /// Get timer state for a specific step
  StepTimerState? getTimerForStep(int stepIndex) => stepTimers[stepIndex];
}

/// StateNotifier for cooking mode
class CookingModeNotifier extends StateNotifier<CookingModeState> {
  Timer? _activeTimer;
  int _activeTimerStepIndex = -1;

  CookingModeNotifier()
      : super(const CookingModeState(steps: [], ingredients: []));

  /// Initialize cooking mode with recipe data
  void initialize({
    required List<RecipeStep> steps,
    required List<Ingredient> ingredients,
  }) {
    _stopActiveTimer();
    state = CookingModeState(
      steps: steps,
      ingredients: ingredients,
      currentStepIndex: 0,
      checkedIngredientIndices: {},
      stepTimers: {},
    );
  }

  /// Navigate to a specific step
  void goToStep(int index) {
    if (index >= 0 && index < state.steps.length) {
      state = state.copyWith(currentStepIndex: index);
    }
  }

  /// Go to next step
  void nextStep() {
    if (state.hasNextStep) {
      goToStep(state.currentStepIndex + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.hasPreviousStep) {
      goToStep(state.currentStepIndex - 1);
    }
  }

  /// Toggle ingredient checked state
  void toggleIngredient(int index) {
    final newChecked = Set<int>.from(state.checkedIngredientIndices);
    if (newChecked.contains(index)) {
      newChecked.remove(index);
    } else {
      newChecked.add(index);
    }
    state = state.copyWith(checkedIngredientIndices: newChecked);
  }

  /// Set timer duration for a step
  void setTimer(int stepIndex, Duration duration) {
    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);
    newTimers[stepIndex] = StepTimerState(
      totalDuration: duration,
      remainingDuration: duration,
      isRunning: false,
      isCompleted: false,
    );
    state = state.copyWith(stepTimers: newTimers);
  }

  /// Start timer for a step
  void startTimer(int stepIndex) {
    final timerState = state.stepTimers[stepIndex];
    if (timerState == null || timerState.isCompleted) return;

    // Stop any currently running timer
    _stopActiveTimer();

    // Update state to running
    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);
    newTimers[stepIndex] = timerState.copyWith(isRunning: true);
    state = state.copyWith(stepTimers: newTimers);

    // Start countdown
    _activeTimerStepIndex = stepIndex;
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTimer(stepIndex);
    });
  }

  /// Pause timer for a step
  void pauseTimer(int stepIndex) {
    if (_activeTimerStepIndex == stepIndex) {
      _stopActiveTimer();
    }

    final timerState = state.stepTimers[stepIndex];
    if (timerState == null) return;

    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);
    newTimers[stepIndex] = timerState.copyWith(isRunning: false);
    state = state.copyWith(stepTimers: newTimers);
  }

  /// Reset timer for a step
  void resetTimer(int stepIndex) {
    if (_activeTimerStepIndex == stepIndex) {
      _stopActiveTimer();
    }

    final timerState = state.stepTimers[stepIndex];
    if (timerState == null) return;

    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);
    newTimers[stepIndex] = StepTimerState(
      totalDuration: timerState.totalDuration,
      remainingDuration: timerState.totalDuration,
      isRunning: false,
      isCompleted: false,
    );
    state = state.copyWith(stepTimers: newTimers);
  }

  /// Remove timer for a step
  void removeTimer(int stepIndex) {
    if (_activeTimerStepIndex == stepIndex) {
      _stopActiveTimer();
    }

    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);
    newTimers.remove(stepIndex);
    state = state.copyWith(stepTimers: newTimers);
  }

  /// Callback when timer completes
  void Function(int stepIndex)? onTimerComplete;

  void _tickTimer(int stepIndex) {
    final timerState = state.stepTimers[stepIndex];
    if (timerState == null || !timerState.isRunning) {
      _stopActiveTimer();
      return;
    }

    final newRemaining =
        timerState.remainingDuration - const Duration(seconds: 1);

    final newTimers = Map<int, StepTimerState>.from(state.stepTimers);

    if (newRemaining.inSeconds <= 0) {
      // Timer completed
      _stopActiveTimer();
      newTimers[stepIndex] = timerState.copyWith(
        remainingDuration: Duration.zero,
        isRunning: false,
        isCompleted: true,
      );
      state = state.copyWith(stepTimers: newTimers);

      // Notify completion
      onTimerComplete?.call(stepIndex);
    } else {
      newTimers[stepIndex] = timerState.copyWith(
        remainingDuration: newRemaining,
      );
      state = state.copyWith(stepTimers: newTimers);
    }
  }

  void _stopActiveTimer() {
    _activeTimer?.cancel();
    _activeTimer = null;
    _activeTimerStepIndex = -1;
  }

  /// Clean up resources
  void cleanup() {
    _stopActiveTimer();
    state = const CookingModeState(steps: [], ingredients: []);
  }

  @override
  void dispose() {
    _stopActiveTimer();
    super.dispose();
  }
}

/// Cooking mode provider
final cookingModeProvider =
    StateNotifierProvider<CookingModeNotifier, CookingModeState>((ref) {
  return CookingModeNotifier();
});
