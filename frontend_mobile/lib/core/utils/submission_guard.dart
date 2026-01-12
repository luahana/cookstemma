/// Mixin to prevent double submission of forms.
///
/// Use this mixin in StatefulWidget states to guard against rapid double-taps
/// on submit buttons.
///
/// Example:
/// ```dart
/// class _MyFormState extends State<MyForm> with SubmissionGuard {
///   Future<void> _handleSubmit() async {
///     await guardedSubmit(() async {
///       // Your submission logic here
///     });
///   }
/// }
/// ```
mixin SubmissionGuard {
  bool _isSubmitting = false;

  /// Returns true if a submission is currently in progress.
  bool get isSubmitting => _isSubmitting;

  /// Executes [action] only if no submission is currently in progress.
  /// Automatically manages the submission state.
  ///
  /// Returns the result of [action], or null if blocked due to concurrent submission.
  Future<T?> guardedSubmit<T>(Future<T> Function() action) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;

    try {
      return await action();
    } finally {
      _isSubmitting = false;
    }
  }
}
