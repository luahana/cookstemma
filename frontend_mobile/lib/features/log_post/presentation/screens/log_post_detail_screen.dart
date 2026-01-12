import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/login_prompt_sheet.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_chips.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/log_recipe_lineage.dart';
import '../widgets/log_edit_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';

class LogPostDetailScreen extends ConsumerStatefulWidget {
  final String logId;

  const LogPostDetailScreen({super.key, required this.logId});

  @override
  ConsumerState<LogPostDetailScreen> createState() => _LogPostDetailScreenState();
}

class _LogPostDetailScreenState extends ConsumerState<LogPostDetailScreen> {
  bool _saveStateInitialized = false;
  bool _isDeleting = false;
  int _currentImageIndex = 0;
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _shareLog(LogPostDetail log) async {
    HapticFeedback.selectionClick();
    final shareUrl = 'https://api.pairingplanet.com/share/log/${log.publicId}';
    final title = log.linkedRecipe?.title ?? 'logPost.detail'.tr();
    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n$shareUrl',
        subject: title,
      ),
    );
  }

  bool _isCreator(LogPostDetail log) {
    final authState = ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated) return false;

    final profileAsync = ref.read(myProfileProvider);
    return profileAsync.maybeWhen(
      data: (profile) {
        // Compare UUID strings directly
        return profile.user.id == log.creatorPublicId;
      },
      orElse: () => false,
    );
  }

  void _showEditSheet(LogPostDetail log) {
    HapticFeedback.selectionClick();
    LogEditSheet.show(
      context: context,
      log: log,
      onSuccess: () {
        // Refresh list providers as well
        ref.invalidate(logPostPaginatedListProvider);
      },
    );
  }

  void _showDeleteConfirmation(LogPostDetail log) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logPost.delete'.tr()),
        content: Text('logPost.deleteConfirm'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLog(log);
            },
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLog(LogPostDetail log) async {
    setState(() => _isDeleting = true);

    final repository = ref.read(logPostRepositoryProvider);
    final result = await repository.deleteLog(log.publicId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.deleteFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Invalidate list providers and go back
        ref.invalidate(logPostPaginatedListProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.deleteSuccess'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(logPostDetailProvider(widget.logId));
    final saveState = ref.watch(saveLogProvider(widget.logId));

    // Initialize save state when log data loads
    ref.listen(logPostDetailProvider(widget.logId), (_, next) {
      next.whenData((log) {
        if (!_saveStateInitialized && log.isSavedByCurrentUser != null) {
          ref.read(saveLogProvider(widget.logId).notifier)
              .setInitialState(log.isSavedByCurrentUser!);
          _saveStateInitialized = true;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: logAsync.maybeWhen(
          data: (log) => Text(
            log.linkedRecipe?.foodName ?? 'logPost.detail'.tr(),
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => Text('logPost.detail'.tr()),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Share button
          logAsync.maybeWhen(
            data: (log) => IconButton(
              icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
              onPressed: () => _shareLog(log),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          // Bookmark button
          saveState.when(
            data: (isSaved) => IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.primary : Colors.grey[600],
              ),
              onPressed: () {
                final authStatus = ref.read(authStateProvider).status;
                if (authStatus != AuthStatus.authenticated) {
                  LoginPromptSheet.show(
                    context: context,
                    actionKey: 'guest.signInToSave',
                    pendingAction: () {
                      ref.read(saveLogProvider(widget.logId).notifier).toggle();
                    },
                  );
                  return;
                }
                ref.read(saveLogProvider(widget.logId).notifier).toggle();
              },
            ),
            loading: () => Padding(
              padding: EdgeInsets.all(12.r),
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
          // Edit/Delete menu (only for creator)
          logAsync.maybeWhen(
            data: (log) {
              if (!_isCreator(log)) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _showEditSheet(log);
                  if (value == 'delete') _showDeleteConfirmation(log);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert),
                enabled: !_isDeleting,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Text('logPost.edit'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('logPost.delete'.tr(), style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: logAsync.when(
        data: (log) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image gallery (full-width, edge-to-edge)
              _buildImageGallery(log.imageUrls),

              // Content with padding starts here
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // 2. Metadata row with styled badges
                    _buildMetadataRow(log),

                    // 2.5. Creator row (clickable username)
                    SizedBox(height: 12.h),
                    _buildCreatorRow(log),

                    // 3. Hashtags (after metadata, Instagram-style no header)
                    if (log.hashtags.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      HashtagChips(
                        hashtags: log.hashtags,
                        onHashtagTap: (tag) {
                          context.push('${RouteConstants.search}?q=%23$tag');
                        },
                      ),
                    ],
                    SizedBox(height: 24.h),

                    // 4. Review section with icon header
                    _buildSectionHeader(Icons.rate_review_outlined, 'logPost.myReview'.tr()),
                    SizedBox(height: 12.h),
                    Text(
                      log.content,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),

                    // 5. Recipe section (header is inside LogRecipeLineage widget)
                    if (log.linkedRecipe != null) ...[
                      SizedBox(height: 24.h),
                      LogRecipeLineage(linkedRecipe: log.linkedRecipe),
                    ],

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()}))),
      ),
    );
  }

  // Full-width image gallery with PageView and dots indicator
  Widget _buildImageGallery(List<String?> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    final validUrls = urls.whereType<String>().toList();
    if (validUrls.isEmpty) return const SizedBox.shrink();

    _pageController ??= PageController();

    // Single image - full width, edge-to-edge
    if (validUrls.length == 1) {
      return AppCachedImage(
        imageUrl: validUrls[0],
        width: double.infinity,
        height: 300.h,
        borderRadius: 0,
      );
    }

    // Multiple images - PageView with dots indicator
    return SizedBox(
      height: 300.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: validUrls.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return AppCachedImage(
                imageUrl: validUrls[index],
                width: double.infinity,
                height: 300.h,
                borderRadius: 0,
              );
            },
          ),
          // Page indicator dots
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                validUrls.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentImageIndex == index ? 8.w : 6.w,
                  height: _currentImageIndex == index ? 8.w : 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section header with icon + text (matching recipe detail pattern)
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.textPrimary),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Creator row (clickable username for profile navigation)
  Widget _buildCreatorRow(LogPostDetail log) {
    final hasCreatorId = log.creatorPublicId != null;

    return GestureDetector(
      onTap: hasCreatorId
          ? () {
              HapticFeedback.selectionClick();
              // Check if this is the current user's own profile (same logic as _isCreator)
              final isOwnProfile = _isCreator(log);

              if (isOwnProfile) {
                // Navigate to My Profile tab to avoid key conflicts
                context.go(RouteConstants.profile);
              } else {
                // Navigate to other user's profile
                context.push(RouteConstants.userProfilePath(log.creatorPublicId!));
              }
            }
          : null,
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16.sp,
            color: Colors.grey[400],
          ),
          SizedBox(width: 4.w),
          Text(
            log.creatorName ?? 'Unknown',
            style: TextStyle(
              color: hasCreatorId ? AppColors.primary : Colors.grey[600],
              fontSize: 13.sp,
              fontWeight: hasCreatorId ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Metadata row with styled date badge and outcome badge
  Widget _buildMetadataRow(LogPostDetail log) {
    return Row(
      children: [
        // Date badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Text(
                DateFormat('yyyy.MM.dd').format(log.createdAt),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        // Outcome badge
        OutcomeBadge.fromString(
          outcomeValue: log.outcome,
          variant: OutcomeBadgeVariant.compact,
        ),
      ],
    );
  }
}
