import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/services/phone_auth_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

/// Phone verification screen for Korean PIPA compliance
/// Allows users to verify their phone number via SMS OTP
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  /// Whether this is optional (user can skip) or required
  final bool isOptional;

  const PhoneVerificationScreen({
    super.key,
    this.isOptional = true,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  PhoneVerificationState _state = PhoneVerificationState.initial;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('phoneVerification.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: widget.isOptional
            ? [
                TextButton(
                  onPressed: _skipVerification,
                  child: Text(
                    'common.skip'.tr(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              SizedBox(height: 32.h),

              // Phone input
              _buildPhoneInput(),

              if (_state == PhoneVerificationState.codeSent ||
                  _state == PhoneVerificationState.verifying) ...[
                SizedBox(height: 24.h),
                _buildCodeInput(),
              ],

              if (_errorMessage != null) ...[
                SizedBox(height: 16.h),
                _buildErrorMessage(),
              ],

              SizedBox(height: 32.h),

              // Action button
              _buildActionButton(),

              if (_state == PhoneVerificationState.codeSent) ...[
                SizedBox(height: 16.h),
                _buildResendButton(),
              ],

              SizedBox(height: 32.h),

              // Info section
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phoneVerification.headline'.tr(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'phoneVerification.description'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phoneVerification.phoneNumber'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          keyboardType: TextInputType.phone,
          enabled: _state == PhoneVerificationState.initial ||
              _state == PhoneVerificationState.error,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _KoreanPhoneFormatter(),
          ],
          decoration: InputDecoration(
            prefixText: '+82 ',
            hintText: 'phoneVerification.phoneHint'.tr(),
            filled: true,
            fillColor:
                _state == PhoneVerificationState.initial ||
                        _state == PhoneVerificationState.error
                    ? Colors.grey[100]
                    : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phoneVerification.verificationCode'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'phoneVerification.codeHint'.tr(),
            counterText: '',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          style: TextStyle(
            fontSize: 24.sp,
            letterSpacing: 8.w,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20.sp, color: Colors.red[700]),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!.tr(),
              style: TextStyle(fontSize: 13.sp, color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final buttonText = switch (_state) {
      PhoneVerificationState.initial => 'phoneVerification.sendCode'.tr(),
      PhoneVerificationState.codeSent => 'phoneVerification.verify'.tr(),
      PhoneVerificationState.verifying => 'phoneVerification.verifying'.tr(),
      PhoneVerificationState.verified => 'phoneVerification.verified'.tr(),
      PhoneVerificationState.error => 'phoneVerification.retry'.tr(),
    };

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    final canResend = _resendCountdown == 0;

    return Center(
      child: TextButton(
        onPressed: canResend ? _resendCode : null,
        child: Text(
          canResend
              ? 'phoneVerification.resendCode'.tr()
              : 'phoneVerification.resendCountdown'.tr(args: [_resendCountdown.toString()]),
          style: TextStyle(
            color: canResend ? AppColors.primary : Colors.grey,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.sp, color: Colors.blue[700]),
              SizedBox(width: 8.w),
              Text(
                'phoneVerification.whyVerify'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'phoneVerification.whyVerifyDescription'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.blue[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String input) {
    // Remove all non-digit characters
    final digits = input.replaceAll(RegExp(r'\D'), '');

    // Remove leading 0 if present
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;

    // Format as +82xxxxxxxxxx
    return '+82$normalized';
  }

  Future<void> _handleAction() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_state == PhoneVerificationState.initial ||
          _state == PhoneVerificationState.error) {
        await _sendVerificationCode();
      } else if (_state == PhoneVerificationState.codeSent) {
        await _verifyCode();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendVerificationCode() async {
    final phoneNumber = _formatPhoneNumber(_phoneController.text);

    if (phoneNumber.length < 12) {
      setState(() {
        _errorMessage = 'phoneVerification.invalidPhoneNumber';
        _isLoading = false;
      });
      return;
    }

    final phoneService = ref.read(phoneAuthServiceProvider);

    await phoneService.sendVerificationCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _state = PhoneVerificationState.codeSent;
            _startResendCountdown();
          });
          _codeFocusNode.requestFocus();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _state = PhoneVerificationState.error;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'phoneVerification.invalidCode';
      });
      return;
    }

    setState(() {
      _state = PhoneVerificationState.verifying;
    });

    final phoneService = ref.read(phoneAuthServiceProvider);
    final result = await phoneService.verifySmsCode(code);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _state = PhoneVerificationState.verified;
      });

      // Mark verification as complete and navigate explicitly
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ref.read(authStateProvider.notifier).confirmPhoneVerification();
        // Navigate explicitly to avoid router redirect race condition
        context.go(RouteConstants.home);
      }
    } else {
      setState(() {
        _state = PhoneVerificationState.codeSent;
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final phoneNumber = _formatPhoneNumber(_phoneController.text);
    final phoneService = ref.read(phoneAuthServiceProvider);

    await phoneService.resendCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _startResendCountdown();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      },
    );
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _skipVerification() {
    // Mark as complete (skipped) and navigate explicitly
    ref.read(authStateProvider.notifier).confirmPhoneVerification();
    // Navigate explicitly to avoid router redirect race condition
    context.go(RouteConstants.home);
  }
}

/// Formatter for Korean phone numbers (10-XXXX-XXXX format)
class _KoreanPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    String formatted = '';
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 2 || i == 6) {
        formatted += '-';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
