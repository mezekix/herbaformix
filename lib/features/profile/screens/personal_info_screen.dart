import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../utils/profile_validators.dart';
import '../widgets/distributor_info_card.dart';
import '../widgets/profile_photo_widget.dart';

class PersonalInfoScreen extends StatefulWidget {
  static const String routeName = 'personal-info';

  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  String? _selectedGender;
  DateTime? _selectedBirthDate;

  File? _selectedPhotoFile;
  bool _isPhotoUploading = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const List<String> _genderOptions = [
    'Kadın',
    'Erkek',
  ];

  static final DateTime _minDate = DateTime(1900, 1, 1);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthDateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      if (userProfile != null) {
        _nameController.text = userProfile.name ?? '';
        _emailController.text = userProfile.email;
        _phoneController.text = userProfile.phoneNumber ?? '';
        _selectedGender = userProfile.gender == 'Belirtmek İstemiyorum'
            ? null
            : userProfile.gender;

        if (userProfile.birthDate != null) {
          _selectedBirthDate = userProfile.birthDate;
          _birthDateController.text = _formatDate(userProfile.birthDate!);
        }
      } else {
        final firebaseUser = authProvider.firebaseUser;
        if (firebaseUser != null) {
          _emailController.text = firebaseUser.email ?? '';
        }
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _selectBirthDate() async {
    final maxDate = DateTime.now().subtract(const Duration(days: 1));
    final initialDate = _selectedBirthDate ?? maxDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(_minDate) ? _minDate : initialDate,
      firstDate: _minDate,
      lastDate: maxDate,
      helpText: 'Doğum Tarihi Seçin',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  void _onPhotoSelected(File file) {
    setState(() {
      _selectedPhotoFile = file;
    });
  }

  UserProfileModel _buildUpdatedProfile({String? newPhotoUrl}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    return UserProfileModel(
      id: userProfile?.id ?? authProvider.firebaseUser!.uid,
      email: userProfile?.email ?? authProvider.firebaseUser!.email ?? '',
      role: userProfile?.role ?? UserRole.customer,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      birthDate: _selectedBirthDate,
      gender: _selectedGender,
      
      // Diğer sayfaların alanlarını koru
      height: userProfile?.height,
      weight: userProfile?.weight,
      targetWeight: userProfile?.targetWeight,
      healthNotes: userProfile?.healthNotes,
      allergies: userProfile?.allergies,
      medications: userProfile?.medications,
      
      assignedDistributorId: userProfile?.assignedDistributorId,
      profilePhotoUrl: newPhotoUrl ?? userProfile?.profilePhotoUrl,
      distributorLevel: userProfile?.distributorLevel,
      monthlyVPTarget: userProfile?.monthlyVPTarget,
      isOnboarded: userProfile?.isOnboarded ?? false,
      age: userProfile?.age,
      programStartDate: userProfile?.programStartDate,
      userGoal: userProfile?.userGoal,
      wakeTime: userProfile?.wakeTime,
      lunchTime: userProfile?.lunchTime,
      sleepTime: userProfile?.sleepTime,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isPhotoUploading = _selectedPhotoFile != null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? newPhotoUrl;

    try {
      if (_selectedPhotoFile != null) {
        newPhotoUrl = await authProvider.uploadProfilePhoto(_selectedPhotoFile!);
        if (!mounted) return;

        setState(() {
          _isPhotoUploading = false;
        });

        if (newPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf yüklenemedi, profil bilgileri kaydedilecek.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final updatedProfile = _buildUpdatedProfile(newPhotoUrl: newPhotoUrl);
      final success = await authProvider.updateUserProfile(updatedProfile);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişisel bilgiler başarıyla kaydedildi.'),
            backgroundColor: Colors.green,
          ),
        );
        if (newPhotoUrl != null) {
          setState(() {
            _selectedPhotoFile = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgiler kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPhotoUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayarları'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ProfilePhotoWidget(
                  photoUrl: userProfile?.profilePhotoUrl,
                  localFile: _selectedPhotoFile,
                  isUploading: _isPhotoUploading,
                  onPhotoSelected: _onPhotoSelected,
                  size: 110,
                  userId: userProfile?.id,
                  userName: userProfile?.name,
                  photoUpdatedAt: userProfile?.profilePhotoUpdatedAt,
                ),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.background,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '05551234567',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Doğum Tarihi',
                  hintText: 'gg.aa.yyyy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: _selectBirthDate,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                hint: const Text('Seçiniz'),
                items: _genderOptions
                    .map((gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Distribütör bilgisi buraya eklendi (eski formda vardı)
              const Text(
                'Danışmanım',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.nightSky),
              ),
              const SizedBox(height: 8),
              DistributorInfoCard(
                assignedDistributorId: userProfile?.assignedDistributorId,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
