import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

class HashtagInputSection extends StatefulWidget {
  final List<String> hashtags;
  final ValueChanged<List<String>> onHashtagsChanged;
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

  void _addHashtag(String text) {
    // Normalize: remove # prefix, trim, lowercase
    String normalized = text.trim().toLowerCase();
    if (normalized.startsWith('#')) {
      normalized = normalized.substring(1);
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with dashes

    if (normalized.isEmpty) return;
    if (widget.hashtags.length >= widget.maxHashtags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recipe.hashtag.maxError'.tr(namedArgs: {'max': '${widget.maxHashtags}'}))),
      );
      return;
    }
    if (widget.hashtags.contains(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recipe.hashtag.duplicateError'.tr())),
      );
      return;
    }

    final newList = [...widget.hashtags, normalized];
    widget.onHashtagsChanged(newList);
    _controller.clear();
  }

  void _removeHashtag(String hashtag) {
    final newList = widget.hashtags.where((h) => h != hashtag).toList();
    widget.onHashtagsChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tag, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'recipe.hashtag.title'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${widget.hashtags.length}/${widget.maxHashtags}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Input field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'recipe.hashtag.hint'.tr(),
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    _addHashtag(value);
                    _focusNode.requestFocus();
                  },
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
        const SizedBox(height: 12),
        // Hashtag chips
        if (widget.hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.hashtags.map((tag) => _buildChip(tag)).toList(),
          ),
        if (widget.hashtags.isEmpty)
          Text(
            'recipe.hashtag.example'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String hashtag) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$hashtag',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeHashtag(hashtag),
            child: Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
