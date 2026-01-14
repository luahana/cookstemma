import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/user/update_profile_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedLocale;
  String? _originalLocale;  // Track original locale to detect changes
  String? _selectedFoodStyle;  // ISO country code (e.g., "KR", "US")
  bool _isLoading = false;
  bool _hasChanges = false;

  // Bio and social links
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  String? _bioError;
  String? _youtubeError;
  String? _instagramError;

  // Gender options - keys for translation
  static const List<String> _genderKeys = ['MALE', 'FEMALE', 'OTHER'];

  // Locale options
  static const Map<String, String> _localeOptions = {
    'ko-KR': '한국어',
    'en-US': 'English',
  };

  String _getGenderLabel(String key) {
    return switch (key) {
      'MALE' => 'profile.male'.tr(),
      'FEMALE' => 'profile.female'.tr(),
      'OTHER' => 'profile.other'.tr(),
      _ => key,
    };
  }

  @override
  void initState() {
    super.initState();
    // Initialize values from current profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProfile();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _youtubeController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _initializeFromProfile() {
    final profileAsync = ref.read(myProfileProvider);
    profileAsync.whenData((profile) {
      setState(() {
        // Parse birthDate string to DateTime
        if (profile.user.birthDate != null) {
          _selectedBirthDate = DateTime.tryParse(profile.user.birthDate!);
        }
        _selectedGender = profile.user.gender;
        _selectedLocale = profile.user.locale ?? ref.read(localeProvider);
        _originalLocale = _selectedLocale;  // Store original locale
        // Initialize food style from profile or derive from device locale
        _selectedFoodStyle = profile.user.defaultFoodStyle ?? _getDefaultFoodStyleFromDevice();
        // Initialize bio and social links
        _bioController.text = profile.user.bio ?? '';
        _youtubeController.text = profile.user.youtubeUrl ?? '';
        _instagramController.text = profile.user.instagramHandle ?? '';
      });
    });
  }

  /// Get default food style from device locale
  String _getDefaultFoodStyleFromDevice() {
    final deviceLocale = Platform.localeName; // e.g., "ko_KR", "en_US"
    final parts = deviceLocale.split('_');
    if (parts.length >= 2) {
      return parts[1].toUpperCase(); // "KR", "US"
    }
    return 'US'; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('profile.editProfile'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'common.save'.tr(),
                    style: TextStyle(
                      color: _hasChanges ? AppColors.textPrimary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildForm(profile.user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('profile.couldNotLoad'.tr()),
        ),
      ),
    );
  }

  Widget _buildForm(UserDto user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Birthday Section
          _buildSectionTitle('profile.birthday'.tr()),
          SizedBox(height: 8.h),
          _buildBirthdayPicker(),
          SizedBox(height: 24.h),

          // Gender Section
          _buildSectionTitle('profile.gender'.tr()),
          SizedBox(height: 8.h),
          _buildGenderDropdown(),
          SizedBox(height: 24.h),

          // Language Section
          _buildSectionTitle('profile.language'.tr()),
          SizedBox(height: 8.h),
          _buildLocaleDropdown(),
          SizedBox(height: 16.h),
          Text(
            'profile.languageHint'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),

          // Default Food Style Section
          _buildSectionTitle('foodStyle.preference'.tr()),
          SizedBox(height: 8.h),
          _buildFoodStylePicker(),
          SizedBox(height: 8.h),
          Text(
            'foodStyle.preferenceHelper'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),

          // Bio Section
          _buildSectionTitle('profile.bio'.tr()),
          SizedBox(height: 8.h),
          _buildBioField(),
          SizedBox(height: 24.h),

          // Social Links Section
          _buildSectionTitle('profile.socialLinks'.tr()),
          SizedBox(height: 8.h),
          _buildYoutubeField(),
          SizedBox(height: 12.h),
          _buildInstagramField(),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    final dateText = _selectedBirthDate != null
        ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
        : 'profile.selectBirthday'.tr();

    return InkWell(
      onTap: _showDatePicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: TextStyle(
                fontSize: 16.sp,
                color: _selectedBirthDate != null ? Colors.black : Colors.grey[500],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25);
    final currentLocale = context.locale;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: currentLocale,
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _hasChanges = true;
      });
    }
  }

  Widget _buildGenderDropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: Text('profile.selectGender'.tr()),
          isExpanded: true,
          items: _genderKeys.map((key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(_getGenderLabel(key)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
              _hasChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLocaleDropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocale,
          hint: Text('profile.selectLanguage'.tr()),
          isExpanded: true,
          items: _localeOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLocale = value;
              _hasChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFoodStylePicker() {
    Country? country;
    if (_selectedFoodStyle != null && _selectedFoodStyle != 'international') {
      try {
        country = CountryParser.parseCountryCode(_selectedFoodStyle!);
      } catch (_) {
        // Invalid code, ignore
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showFoodStylePicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                if (country != null) ...[
                  Text(country.flagEmoji, style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'foodStyle.style'.tr(),
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ] else if (_selectedFoodStyle == 'international') ...[
                  Text('🌍', style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'foodStyle.international'.tr(),
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ] else ...[
                  Text(
                    'foodStyle.select'.tr(),
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        // "Other/International" option button
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedFoodStyle = 'international';
              _hasChanges = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: _selectedFoodStyle == 'international'
                  ? AppColors.editableBackground
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _selectedFoodStyle == 'international'
                    ? AppColors.editableBorder
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌍', style: TextStyle(fontSize: 16.sp)),
                SizedBox(width: 6.w),
                Text(
                  'foodStyle.international'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _selectedFoodStyle == 'international'
                        ? AppColors.primary
                        : Colors.grey[600],
                    fontWeight: _selectedFoodStyle == 'international'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFoodStylePicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedFoodStyle = country.countryCode;
          _hasChanges = true;
        });
      },
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 16.sp, color: Colors.black87),
        searchTextStyle: TextStyle(fontSize: 16.sp, color: Colors.black87),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        inputDecoration: InputDecoration(
          hintText: 'foodStyle.searchHint'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _bioController,
          maxLength: 150,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'profile.bioHint'.tr(),
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
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorText: _bioError,
          ),
          onChanged: (value) {
            setState(() {
              _hasChanges = true;
              _bioError = _validateBio(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildYoutubeField() {
    return TextField(
      controller: _youtubeController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.play_circle_outline, color: Colors.red[600]),
        hintText: 'profile.youtubeHint'.tr(),
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
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorText: _youtubeError,
      ),
      onChanged: (value) {
        setState(() {
          _hasChanges = true;
          _youtubeError = _validateYoutubeUrl(value);
        });
      },
    );
  }

  Widget _buildInstagramField() {
    return TextField(
      controller: _instagramController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.camera_alt_outlined, color: const Color(0xFFE4405F)),
        hintText: 'profile.instagramHint'.tr(),
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
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorText: _instagramError,
      ),
      onChanged: (value) {
        setState(() {
          _hasChanges = true;
          _instagramError = _validateInstagramHandle(value);
        });
      },
    );
  }

  String? _validateBio(String value) {
    if (value.length > 150) {
      return 'profile.bioTooLong'.tr();
    }
    return null;
  }

  String? _validateYoutubeUrl(String value) {
    if (value.isEmpty) return null;
    final regex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com/(channel/|c/|user/|@)[\w-]+|youtu\.be/[\w-]+)/?$',
    );
    if (!regex.hasMatch(value)) {
      return 'profile.invalidYoutubeUrl'.tr();
    }
    return null;
  }

  String? _validateInstagramHandle(String value) {
    if (value.isEmpty) return null;
    final handleRegex = RegExp(r'^@?[a-zA-Z0-9._]{1,30}$');
    final urlRegex = RegExp(
      r'^(https?://)?(www\.)?instagram\.com/[a-zA-Z0-9._]{1,30}/?$',
    );
    if (!handleRegex.hasMatch(value) && !urlRegex.hasMatch(value)) {
      return 'profile.invalidInstagramHandle'.tr();
    }
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = UserRemoteDataSource(ref.read(dioProvider));

      // Prepare request
      final request = UpdateProfileRequestDto(
        gender: _selectedGender,
        birthDate: _selectedBirthDate != null
            ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
            : null,
        locale: _selectedLocale,
        defaultFoodStyle: _selectedFoodStyle,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        youtubeUrl: _youtubeController.text.isNotEmpty ? _youtubeController.text : null,
        instagramHandle: _instagramController.text.isNotEmpty ? _instagramController.text : null,
      );

      await dataSource.updateProfile(request);

      // Check if locale changed
      final localeChanged = _selectedLocale != _originalLocale;

      // Update locale in the app if changed (await to ensure save completes)
      if (_selectedLocale != null) {
        await _updateAppLocale(_selectedLocale!);
      }

      // Refresh profile
      ref.invalidate(myProfileProvider);

      if (!mounted) return;

      // If locale changed, show restart dialog
      if (localeChanged) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('profile.languageChangeTitle'.tr()),
            content: Text('profile.languageChangeMessage'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Phoenix.rebirth(context);
                },
                child: Text('profile.restart'.tr()),
              ),
            ],
          ),
        );
      } else {
        // Show success message and go back
        ToastService.showSuccess('profile.profileUpdated'.tr());
        context.pop();
      }
    } catch (e) {
      ToastService.showError('profile.profileUpdateFailed'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAppLocale(String localeString) async {
    final prefs = await SharedPreferences.getInstance();

    // Save to our key (this is read by LocaleApplier after Phoenix.rebirth())
    await prefs.setString('app_locale', localeString);

    // Update the localeProvider
    ref.read(localeProvider.notifier).state = localeString;
  }

  void _handleBack(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('profile.discardChanges'.tr()),
          content: Text('profile.unsavedChanges'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.pop();
              },
              child: Text(
                'profile.leave'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}
