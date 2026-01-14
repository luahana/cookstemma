import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalAgreementScreen extends ConsumerStatefulWidget {
  const LegalAgreementScreen({super.key});

  @override
  ConsumerState<LegalAgreementScreen> createState() =>
      _LegalAgreementScreenState();
}

class _LegalAgreementScreenState extends ConsumerState<LegalAgreementScreen> {
  bool _termsAccepted = false;
  bool _marketingAgreed = false;
  bool _isSubmitting = false;
  Timer? _debounce;

  static const String _termsUrl = 'https://pairingplanet.com/terms';
  static const String _privacyUrl = 'https://pairingplanet.com/privacy';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onContinue() async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_isSubmitting || !_termsAccepted) return;

      setState(() => _isSubmitting = true);

      await ref
          .read(authStateProvider.notifier)
          .acceptLegalTerms(marketingAgreed: _marketingAgreed);

      if (!mounted) return;
      context.go(RouteConstants.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('legal.title'.tr()),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    SizedBox(height: 24.h),
                    _buildTermsSummary(),
                    SizedBox(height: 16.h),
                    _buildPrivacySummary(),
                    SizedBox(height: 24.h),
                    _buildCheckboxes(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'legal.welcomeTitle'.tr(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'legal.welcomeSubtitle'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSummary() {
    return _buildLegalCard(
      title: 'legal.termsOfService'.tr(),
      icon: Icons.description_outlined,
      points: [
        'legal.termsSummary1'.tr(),
        'legal.termsSummary2'.tr(),
        'legal.termsSummary3'.tr(),
      ],
      onReadMore: () => _launchUrl(_termsUrl),
    );
  }

  Widget _buildPrivacySummary() {
    return _buildLegalCard(
      title: 'legal.privacyPolicy'.tr(),
      icon: Icons.privacy_tip_outlined,
      points: [
        'legal.privacySummary1'.tr(),
        'legal.privacySummary2'.tr(),
        'legal.privacySummary3'.tr(),
      ],
      onReadMore: () => _launchUrl(_privacyUrl),
    );
  }

  Widget _buildLegalCard({
    required String title,
    required IconData icon,
    required List<String> points,
    required VoidCallback onReadMore,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24.sp, color: Colors.orange[700]),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...points.map((point) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u2022 ',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style:
                            TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onReadMore,
            child: Text(
              'legal.readFullDocument'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxes() {
    return Column(
      children: [
        _buildCheckboxRow(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              children: [
                TextSpan(text: 'legal.agreeToTermsPrefix'.tr()),
                TextSpan(
                  text: 'legal.termsOfService'.tr(),
                  style: TextStyle(
                    color: Colors.orange[700],
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchUrl(_termsUrl),
                ),
                TextSpan(text: 'legal.and'.tr()),
                TextSpan(
                  text: 'legal.privacyPolicy'.tr(),
                  style: TextStyle(
                    color: Colors.orange[700],
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchUrl(_privacyUrl),
                ),
                TextSpan(text: 'legal.required'.tr()),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        _buildCheckboxRow(
          value: _marketingAgreed,
          onChanged: (value) =>
              setState(() => _marketingAgreed = value ?? false),
          child: Text(
            'legal.agreeToMarketing'.tr(),
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.orange[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _termsAccepted && !_isSubmitting ? _onContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'common.continue'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
