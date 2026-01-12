import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

class HashtagInputSection extends StatefulWidget {
  final List<Map<String, dynamic>> hashtags;
  final ValueChanged<List<Map<String, dynamic>>> onHashtagsChanged;
  final int maxHashtags;

  const HashtagInputSection({
    super.key,
    required this.hashtags,
    required this.onHashtagsChanged,
    this.maxHashtags = 5,
  });

  @override
  State<HashtagInputSection> createState() => _HashtagInputSectionState();
}

class _HashtagInputSectionState extends State<HashtagInputSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _activeHashtags =>
      widget.hashtags.where((h) => h['isDeleted'] != true).toList();

  List<Map<String, dynamic>> get _deletedHashtags =>
      widget.hashtags.where((h) => h['isDeleted'] == true).toList();

  List<Map<String, dynamic>> get _newHashtags =>
      _activeHashtags.where((h) => h['isOriginal'] != true).toList();

  List<Map<String, dynamic>> get _inheritedHashtags =>
      _activeHashtags.where((h) => h['isOriginal'] == true).toList();

  void _addHashtag(String text) {
    // Normalize: remove # prefix, trim, lowercase
    String normalized = text.trim().toLowerCase();
    if (normalized.startsWith('#')) {
      normalized = normalized.substring(1);
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), '-');

    if (normalized.isEmpty) return;
    if (_activeHashtags.length >= widget.maxHashtags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recipe.hashtag.maxError'.tr(namedArgs: {'max': '${widget.maxHashtags}'}))),
      );
      return;
    }
    if (widget.hashtags.any((h) => h['name'] == normalized && h['isDeleted'] != true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recipe.hashtag.duplicateError'.tr())),
      );
      return;
    }

    final newList = [
      ...widget.hashtags,
      {'name': normalized, 'isOriginal': false, 'isDeleted': false},
    ];
    widget.onHashtagsChanged(newList);
    _controller.clear();
  }

  void _removeHashtag(String hashtag) {
    final newList = widget.hashtags.map((h) {
      if (h['name'] == hashtag) {
        return {...h, 'isDeleted': true};
      }
      return h;
    }).toList();
    widget.onHashtagsChanged(newList);
  }

  void _restoreHashtag(String hashtag) {
    final newList = widget.hashtags.map((h) {
      if (h['name'] == hashtag) {
        return {...h, 'isDeleted': false};
      }
      return h;
    }).toList();
    widget.onHashtagsChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'recipe.hashtag.title'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_activeHashtags.length}/${widget.maxHashtags}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Input field with orange background
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.editableBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.editableBorder),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'recipe.hashtag.hint'.tr(),
                    hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    _addHashtag(value);
                    _focusNode.requestFocus();
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    _addHashtag(_controller.text);
                    _focusNode.requestFocus();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // New hashtag chips (user added)
        if (_newHashtags.isNotEmpty)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _newHashtags.map((tag) => _buildNewChip(tag['name'])).toList(),
          ),
        // Inherited hashtags section
        if (_inheritedHashtags.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _inheritedHashtags.map((tag) => _buildInheritedChip(tag['name'])).toList(),
          ),
        ],
        // Empty state
        if (_activeHashtags.isEmpty)
          Text(
            'recipe.hashtag.example'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        // Deleted section
        if (_deletedHashtags.isNotEmpty) _buildDeletedSection(),
      ],
    );
  }

  Widget _buildNewChip(String hashtag) {
    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 4.w, top: 6.h, bottom: 6.h),
      decoration: BoxDecoration(
        color: AppColors.editableBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.editableBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$hashtag',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => _removeHashtag(hashtag),
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInheritedChip(String hashtag) {
    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 4.w, top: 6.h, bottom: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$hashtag',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => _removeHashtag(hashtag),
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: AppColors.inheritedInteractive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedSection() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recipe.hashtag.deleted'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          ..._deletedHashtags.map((tag) => _buildDeletedRow(tag['name'])),
        ],
      ),
    );
  }

  Widget _buildDeletedRow(String hashtag) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '#$hashtag',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
                fontSize: 13.sp,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _restoreHashtag(hashtag),
            icon: Icon(Icons.undo, size: 16.sp),
            label: Text('recipe.hashtag.restore'.tr(), style: TextStyle(fontSize: 12.sp)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
