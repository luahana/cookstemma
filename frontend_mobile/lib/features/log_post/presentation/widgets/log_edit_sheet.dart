import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_selector.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_input_section.dart';

class LogEditSheet extends ConsumerStatefulWidget {
  final LogPostDetail log;
  final VoidCallback onSuccess;

  const LogEditSheet({
    super.key,
    required this.log,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required LogPostDetail log,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LogEditSheet(log: log, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<LogEditSheet> createState() => _LogEditSheetState();
}

class _LogEditSheetState extends ConsumerState<LogEditSheet> {
  late TextEditingController _contentController;
  late LogOutcome _selectedOutcome;
  late List<String> _hashtags;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.log.content);
    _selectedOutcome = LogOutcome.fromString(widget.log.outcome) ?? LogOutcome.partial;
    _hashtags = widget.log.hashtags.map((h) => h.name).toList();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('logPost.memoHint'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    final repository = ref.read(logPostRepositoryProvider);
    final result = await repository.updateLog(
      widget.log.publicId,
      content: _contentController.text.trim(),
      outcome: _selectedOutcome.value,
      hashtags: _hashtags.isEmpty ? null : _hashtags,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.updateFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Invalidate the detail provider to refresh
        ref.invalidate(logPostDetailProvider(widget.log.publicId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.updateSuccess'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Text(
                    'logPost.edit'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Read-only images preview
                  if (widget.log.imageUrls.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'logPost.photos'.tr(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '(read-only)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.log.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedImage(
                                imageUrl: widget.log.imageUrls[index],
                                width: 80,
                                height: 80,
                                borderRadius: 8,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Outcome selector
                  Row(
                    children: [
                      const Icon(Icons.emoji_emotions, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'logPost.outcome'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CompactOutcomeSelector(
                    selectedOutcome: _selectedOutcome,
                    onOutcomeSelected: (outcome) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedOutcome = outcome);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Content text field
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'logPost.memo'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'logPost.contentHint'.tr(),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hashtags
                  HashtagInputSection(
                    hashtags: _hashtags,
                    onHashtagsChanged: (tags) {
                      setState(() => _hashtags = tags);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Save button
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'common.save'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
