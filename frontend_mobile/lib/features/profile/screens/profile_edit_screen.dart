import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
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
  bool _isLoading = false;
  bool _hasChanges = false;

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
      });
    });
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'common.save'.tr(),
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
          child: Text('profile.couldNotLoad'.tr()),
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
          _buildSectionTitle('profile.birthday'.tr()),
          const SizedBox(height: 8),
          _buildBirthdayPicker(),
          const SizedBox(height: 24),

          // Gender Section
          _buildSectionTitle('profile.gender'.tr()),
          const SizedBox(height: 8),
          _buildGenderDropdown(),
          const SizedBox(height: 24),

          // Language Section
          _buildSectionTitle('profile.language'.tr()),
          const SizedBox(height: 8),
          _buildLocaleDropdown(),
          const SizedBox(height: 16),
          Text(
            'profile.languageHint'.tr(),
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
        : 'profile.selectBirthday'.tr();

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
