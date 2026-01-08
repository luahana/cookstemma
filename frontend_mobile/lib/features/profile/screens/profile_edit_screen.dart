import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/user/update_profile_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';
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
  bool _isLoading = false;
  bool _hasChanges = false;

  // Gender options
  static const Map<String, String> _genderOptions = {
    'MALE': '남성',
    'FEMALE': '여성',
    'OTHER': '기타',
  };

  static const Map<String, String> _genderOptionsEn = {
    'MALE': 'Male',
    'FEMALE': 'Female',
    'OTHER': 'Other',
  };

  // Locale options
  static const Map<String, String> _localeOptions = {
    'ko-KR': '한국어',
    'en-US': 'English',
  };

  @override
  void initState() {
    super.initState();
    // Initialize values from current profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProfile();
    });
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
      });
    });
  }

  bool get _isKorean {
    final locale = ref.watch(localeProvider);
    return locale.startsWith('ko');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isKorean ? '프로필 수정' : 'Edit Profile'),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isKorean ? '저장' : 'Save',
                    style: TextStyle(
                      color: _hasChanges ? const Color(0xFF1A237E) : Colors.grey,
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
          child: Text(_isKorean ? '프로필을 불러올 수 없습니다' : 'Could not load profile'),
        ),
      ),
    );
  }

  Widget _buildForm(UserDto user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Birthday Section
          _buildSectionTitle(_isKorean ? '생년월일' : 'Birthday'),
          const SizedBox(height: 8),
          _buildBirthdayPicker(),
          const SizedBox(height: 24),

          // Gender Section
          _buildSectionTitle(_isKorean ? '성별' : 'Gender'),
          const SizedBox(height: 8),
          _buildGenderDropdown(),
          const SizedBox(height: 24),

          // Language Section
          _buildSectionTitle(_isKorean ? '언어 설정' : 'Language'),
          const SizedBox(height: 8),
          _buildLocaleDropdown(),
          const SizedBox(height: 16),
          Text(
            _isKorean
                ? '언어를 변경하면 앱 전체가 해당 언어로 표시됩니다.'
                : 'Changing language will update the entire app.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    final dateText = _selectedBirthDate != null
        ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
        : (_isKorean ? '생년월일을 선택하세요' : 'Select your birthday');

    return InkWell(
      onTap: _showDatePicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: TextStyle(
                fontSize: 16,
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

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: _isKorean ? const Locale('ko', 'KR') : const Locale('en', 'US'),
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _hasChanges = true;
      });
    }
  }

  Widget _buildGenderDropdown() {
    final options = _isKorean ? _genderOptions : _genderOptionsEn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: Text(_isKorean ? '성별을 선택하세요' : 'Select gender'),
          isExpanded: true,
          items: options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocale,
          hint: Text(_isKorean ? '언어를 선택하세요' : 'Select language'),
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
      );

      await dataSource.updateProfile(request);

      // Update locale in the app if changed
      if (_selectedLocale != null) {
        _updateAppLocale(_selectedLocale!);
      }

      // Refresh profile
      ref.invalidate(myProfileProvider);

      // Show success message
      ToastService.showSuccess(
        _isKorean ? '프로필이 수정되었습니다' : 'Profile updated',
      );

      // Go back
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ToastService.showError(
        _isKorean ? '프로필 수정에 실패했습니다' : 'Failed to update profile',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateAppLocale(String localeString) {
    // Update the localeProvider
    ref.read(localeProvider.notifier).state = localeString;

    // Update EasyLocalization
    final parts = localeString.split('-');
    if (parts.length == 2) {
      final newLocale = Locale(parts[0], parts[1]);
      context.setLocale(newLocale);
    }
  }

  void _handleBack(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isKorean ? '변경사항 삭제' : 'Discard changes'),
          content: Text(
            _isKorean
                ? '저장하지 않은 변경사항이 있습니다. 나가시겠습니까?'
                : 'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isKorean ? '취소' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.context.pop();
              },
              child: Text(
                _isKorean ? '나가기' : 'Leave',
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
