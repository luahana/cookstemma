import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to trigger scroll-to-top events for navigation tabs.
/// Each tab index has its own counter that increments when the tab is re-tapped.
/// Screens watch their respective counter and scroll to top when it changes.
final scrollToTopProvider = StateProvider.family<int, int>((ref, tabIndex) => 0);

/// Helper extension to trigger scroll-to-top for a specific tab
extension ScrollToTopTrigger on WidgetRef {
  /// Trigger scroll-to-top for the given tab index
  void triggerScrollToTop(int tabIndex) {
    read(scrollToTopProvider(tabIndex).notifier).state++;
  }
}
