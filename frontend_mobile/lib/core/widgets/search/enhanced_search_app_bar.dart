import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/providers/search_history_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/search_suggestions_overlay.dart';
import 'package:pairing_planet2_frontend/data/datasources/search/search_local_data_source.dart';

/// An enhanced search AppBar with suggestions overlay and history support.
/// Extends the functionality of SearchAppBar with recent search suggestions.
class EnhancedSearchAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final String? currentQuery;
  final SearchType searchType;
  final List<Widget>? actions;

  const EnhancedSearchAppBar({
    super.key,
    required this.title,
    required this.hintText,
    required this.onSearch,
    this.onClear,
    this.currentQuery,
    required this.searchType,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<EnhancedSearchAppBar> createState() =>
      _EnhancedSearchAppBarState();
}

class _EnhancedSearchAppBarState extends ConsumerState<EnhancedSearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  bool _showSearchField = false;
  OverlayEntry? _overlayEntry;

  StateNotifierProvider<SearchHistoryNotifier, List<String>> get _historyProvider {
    return widget.searchType == SearchType.recipe
        ? recipeSearchHistoryProvider
        : logPostSearchHistoryProvider;
  }

  @override
  void initState() {
    super.initState();
    // If there's an existing query, show the search field
    if (widget.currentQuery != null && widget.currentQuery!.isNotEmpty) {
      _showSearchField = true;
      _controller.text = widget.currentQuery!;
    }

    // Listen to focus changes
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(EnhancedSearchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with external query changes
    if (widget.currentQuery != oldWidget.currentQuery) {
      if (widget.currentQuery == null || widget.currentQuery!.isEmpty) {
        _controller.clear();
        if (_showSearchField) {
          setState(() {
            _showSearchField = false;
          });
          _hideOverlay();
        }
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay hiding to allow tap on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _hideOverlay(); // Remove any existing overlay first

    final suggestions = ref.read(_historyProvider.notifier).getSuggestions(
          _controller.text,
        );

    if (suggestions.isEmpty && _controller.text.isEmpty) {
      return; // Don't show overlay if no history and no query
    }

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentSuggestions = ref
              .read(_historyProvider.notifier)
              .getSuggestions(_controller.text);

          return Stack(
            children: [
              // Dismiss area
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _focusNode.unfocus();
                    _hideOverlay();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Overlay content
              SearchSuggestionsOverlay(
                layerLink: _layerLink,
                query: _controller.text,
                suggestions: currentSuggestions,
                width: width - 32, // Account for padding
                onSuggestionTap: (term) {
                  _controller.text = term;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: term.length),
                  );
                  widget.onSearch(term);
                  ref.read(_historyProvider.notifier).addSearch(term);
                  _hideOverlay();
                  _focusNode.unfocus();
                },
                onRemoveTap: (term) {
                  ref.read(_historyProvider.notifier).removeSearch(term);
                  _updateOverlay();
                },
                onClearAllTap: () {
                  ref.read(_historyProvider.notifier).clearAll();
                  _hideOverlay();
                },
              ),
            ],
          );
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _updateOverlay();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value);
    });
  }

  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(_historyProvider.notifier).addSearch(value.trim());
      widget.onSearch(value);
      _hideOverlay();
      _focusNode.unfocus();
    }
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    _updateOverlay();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        // Give focus to the text field when opening
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        // Clear search when closing
        _clearSearch();
        _hideOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: _showSearchField
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20.sp),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
                style: TextStyle(fontSize: 16.sp),
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
              )
            : Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          if (widget.actions != null && !_showSearchField) ...widget.actions!,
          IconButton(
            icon: Icon(_showSearchField ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }
}
