import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isConfirmationValid = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_validateConfirmation);
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _validateConfirmation() {
    final text = _confirmController.text.trim().toUpperCase();
    final confirmWord = 'settings.deleteConfirmWord'.tr().toUpperCase();

    setState(() {
      // Accept "DELETE" or the localized confirmation word (e.g., "삭제")
      _isConfirmationValid = text == 'DELETE' || text == confirmWord;
    });
  }

  Future<void> _deleteAccount() async {
    if (!_isConfirmationValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = UserRemoteDataSource(ref.read(dioProvider));
      await dataSource.deleteAccount();

      if (!mounted) return;

      // Show success message
      ToastService.showSuccess('settings.deleteSuccess'.tr());

      // Logout the user
      ref.read(authStateProvider.notifier).logout();
    } catch (e) {
      if (!mounted) return;
      ToastService.showError('settings.deleteFailed'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('settings.deleteAccount'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Icon
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48.sp,
                  color: Colors.red[700],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Warning Title
            Center(
              child: Text(
                'settings.deleteWarningTitle'.tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),

            // Warning Body
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.deleteWarningBody'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red[900],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildWarningItem('settings.deleteItemRecipes'.tr()),
                  _buildWarningItem('settings.deleteItemLogs'.tr()),
                  _buildWarningItem('settings.deleteItemFollowers'.tr()),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Grace Period Info
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.growth.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.growth.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.growth),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'settings.deleteGracePeriod'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.growth.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Confirmation Input
            Text(
              'settings.typeToConfirm'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: 'DELETE',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 32.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirmationValid && !_isLoading
                        ? _deleteAccount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      disabledBackgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'settings.deleteButton'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 16.sp, color: Colors.red[700]),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }
}
