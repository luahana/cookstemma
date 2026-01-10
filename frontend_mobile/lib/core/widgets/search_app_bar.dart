import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A reusable AppBar with integrated search functionality.
/// Toggles between a title view and a search input field.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final String? currentQuery;

  const SearchAppBar({
    super.key,
    required this.title,
    required this.hintText,
    required this.onSearch,
    this.onClear,
    this.currentQuery,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    // If there's an existing query, show the search field
    if (widget.currentQuery != null && widget.currentQuery!.isNotEmpty) {
      _showSearchField = true;
      _controller.text = widget.currentQuery!;
    }
  }

  @override
  void didUpdateWidget(SearchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with external query changes
    if (widget.currentQuery != oldWidget.currentQuery) {
      if (widget.currentQuery == null || widget.currentQuery!.isEmpty) {
        _controller.clear();
        if (_showSearchField) {
          setState(() {
            _showSearchField = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
              onSubmitted: widget.onSearch,
            )
          : Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
      actions: [
        IconButton(
          icon: Icon(_showSearchField ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }
}
