import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../utils/profile_validators.dart';
import 'change_password_dialog.dart';
import 'distributor_info_card.dart';
import 'profile_photo_widget.dart';

/// Müşteri profil formu widget'ı.
///
/// Kişisel bilgiler bölümünü içerir:
/// - Profil fotoğrafı (ProfilePhotoWidget)
/// - Ad-soyad (zorunlu)
/// - E-posta (salt okunur)
/// - Telefon (opsiyonel, E.164)
/// - Doğum tarihi (DatePicker)
/// - Cinsiyet (Dropdown)
///
/// Sağlık bilgileri bölümünü içerir:
/// - Boy (cm)
/// - Mevcut kilo (kg)
/// - Hedef kilo (kg)
/// - Sağlık durumu notları
/// - Alerji bilgileri
/// - İlaç kullanımı
///
/// Distribütör bilgisi bölümünü içerir:
/// - DistributorInfoCard (salt okunur)
///
/// Eylem butonları:
/// - Kaydet (form validasyonu → fotoğraf yükleme → profil kaydetme)
/// - Şifre Değiştir (ChangePasswordDialog)
/// - Çıkış Yap (onay diyalogu → signOut)
///
/// Gereksinimler: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7,
///               4.4, 4.5, 4.6, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6,
///               7.1, 8.1, 8.2, 8.3, 8.4, 8.5
class CustomerProfileView extends StatefulWidget {
  const CustomerProfileView({super.key});

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  final _formKey = GlobalKey<FormState>();

  // Kişisel bilgiler controller'ları
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  // Sağlık bilgileri controller'ları
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _healthNotesController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;

  // Cinsiyet seçimi
  String? _selectedGender;

  // Doğum tarihi
  DateTime? _selectedBirthDate;

  // Fotoğraf state
  File? _selectedPhotoFile;
  bool _isPhotoUploading = false;

  // Kaydetme işlemi yükleme state'i
  bool _isLoading = false;

  // İlk yükleme kontrolü
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
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _healthNotesController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicationsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      // Profil one-shot olarak çekildiği için, distribütörün arka planda
      // yaptığı değişiklikleri (ör. müşteri silme → assignedDistributorId
      // temizleme) yansıtmak adına sayfa açıldığında sessizce yenile.
      // ignore: discarded_futures
      authProvider.refreshProfile();

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

        // Sağlık bilgileri
        if (userProfile.height != null) {
          _heightController.text = userProfile.height!.toString();
        }
        if (userProfile.weight != null) {
          _weightController.text = userProfile.weight!.toString();
        }
        if (userProfile.targetWeight != null) {
          _targetWeightController.text = userProfile.targetWeight!.toString();
        }
        _healthNotesController.text = userProfile.healthNotes ?? '';
        _allergiesController.text = userProfile.allergies ?? '';
        _medicationsController.text = userProfile.medications ?? '';
      } else {
        // Profil henüz yüklenmediyse e-postayı Firebase Auth'tan al
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
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _healthNotesController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  /// Tarihi "dd.MM.yyyy" formatında döner.
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Doğum tarihi seçici açar.
  Future<void> _selectBirthDate() async {
    // Maksimum tarih: bugünden bir gün öncesi
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

  /// Fotoğraf seçildiğinde çağrılır.
  void _onPhotoSelected(File file) {
    setState(() {
      _selectedPhotoFile = file;
    });
  }

  /// Tüm form alanlarından güncellenmiş [UserProfileModel] oluşturur.
  ///
  /// Mevcut profildeki korunan alanları (assignedDistributorId, profilePhotoUrl vb.)
  /// olduğu gibi aktarır; yalnızca form alanlarını günceller.
  UserProfileModel _buildUpdatedProfile({String? newPhotoUrl}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();
    final targetWeightText = _targetWeightController.text.trim();
    final healthNotesText = _healthNotesController.text.trim();
    final allergiesText = _allergiesController.text.trim();
    final medicationsText = _medicationsController.text.trim();

    return UserProfileModel(
      id: userProfile?.id ?? authProvider.firebaseUser!.uid,
      email: userProfile?.email ?? authProvider.firebaseUser!.email ?? '',
      role: userProfile?.role ?? UserRole.customer,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      birthDate: _selectedBirthDate,
      gender: _selectedGender,
      height: double.tryParse(heightText),
      weight: double.tryParse(weightText),
      targetWeight: double.tryParse(targetWeightText),
      healthNotes: healthNotesText.isEmpty ? null : healthNotesText,
      allergies: allergiesText.isEmpty ? null : allergiesText,
      medications: medicationsText.isEmpty ? null : medicationsText,
      // Mevcut profildeki korunan alanları koru
      assignedDistributorId: userProfile?.assignedDistributorId,
      profilePhotoUrl: newPhotoUrl ?? userProfile?.profilePhotoUrl,
      // Diğer mevcut alanları koru
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

  /// Profil kaydetme akışı:
  /// 1. Form validasyonu
  /// 2. Fotoğraf yükleme (varsa)
  /// 3. Profil kaydetme
  Future<void> _saveProfile() async {
    // Form validasyonu
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isPhotoUploading = _selectedPhotoFile != null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? newPhotoUrl;

    try {
      // Fotoğraf yükleme (varsa)
      if (_selectedPhotoFile != null) {
        newPhotoUrl = await authProvider.uploadProfilePhoto(_selectedPhotoFile!);
        if (!mounted) return;

        setState(() {
          _isPhotoUploading = false;
        });

        // Fotoğraf yükleme başarısız olsa bile profil kaydına devam et
        // (Gereksinim 4.6: fotoğraf hatası profil kaydını iptal etmez)
        if (newPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf yüklenemedi, profil bilgileri kaydedilecek.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Güncellenmiş profil modelini oluştur
      final updatedProfile = _buildUpdatedProfile(newPhotoUrl: newPhotoUrl);

      // Profili kaydet
      final success = await authProvider.updateUserProfile(updatedProfile);

      if (!mounted) return;

      if (success) {
        // Başarı bildirimi (Gereksinim 6.3)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profiliniz başarıyla kaydedildi.'),
            backgroundColor: Colors.green,
          ),
        );
        // Fotoğraf seçimini temizle (artık kaydedildi)
        if (newPhotoUrl != null) {
          setState(() {
            _selectedPhotoFile = null;
          });
        }
      } else {
        // Hata bildirimi — form değerlerini koru (Gereksinim 6.4)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Hata bildirimi — form değerlerini koru (Gereksinim 6.4)
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

  /// Çıkış yapma akışı: onay diyalogu → signOut (Gereksinim 8.2, 8.3, 8.4, 8.5)
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Uygulamadan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      // Yönlendirme AuthProvider'ın _onAuthStateChanged tarafından yapılır
    } catch (e) {
      if (!mounted) return;
      // Hata bildirimi (Gereksinim 8.5)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılamadı: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profil Fotoğrafı ──────────────────────────────────────────
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

            // ── Kişisel Bilgiler Başlığı ──────────────────────────────────
            _SectionHeader(title: 'Kişisel Bilgiler'),
            const SizedBox(height: 16),

            // Ad-Soyad (zorunlu)
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

            // E-posta (salt okunur)
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
                  borderSide: BorderSide(
                    color: AppColors.textMutedLighter,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Telefon (opsiyonel, E.164)
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

            // Doğum Tarihi (DatePicker)
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

            // Cinsiyet (Dropdown)
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Cinsiyet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              hint: const Text('Seçiniz'),
              items: _genderOptions
                  .map(
                    (gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // ── Sağlık Bilgileri Başlığı ──────────────────────────────────
            _SectionHeader(title: 'Sağlık Bilgileri'),
            const SizedBox(height: 16),

            // Boy (cm)
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validateHeight,
            ),
            const SizedBox(height: 16),

            // Mevcut kilo (kg)
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Kilo (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validateWeight,
            ),
            const SizedBox(height: 16),

            // Hedef kilo (kg)
            TextFormField(
              controller: _targetWeightController,
              decoration: const InputDecoration(
                labelText: 'Hedef Kilo (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validateWeight,
            ),
            const SizedBox(height: 16),

            // Sağlık durumu notları
            TextFormField(
              controller: _healthNotesController,
              decoration: const InputDecoration(
                labelText: 'Sağlık Durumu Notları',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              validator: validateHealthField,
            ),
            const SizedBox(height: 16),

            // Alerji bilgileri
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Alerji Bilgileri',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              validator: validateHealthField,
            ),
            const SizedBox(height: 16),

            // İlaç kullanımı
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'İlaç Kullanımı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 1000,
              validator: validateHealthField,
            ),
            const SizedBox(height: 24),

            // ── Distribütör Bilgisi ───────────────────────────────────────
            _SectionHeader(title: 'Distribütörüm'),
            const SizedBox(height: 16),

            // DistributorInfoCard — salt okunur distribütör bilgisi (Gereksinim 5.1–5.5)
            DistributorInfoCard(
              assignedDistributorId: userProfile?.assignedDistributorId,
            ),
            const SizedBox(height: 32),

            // ── Eylem Butonları ───────────────────────────────────────────

            // Kaydet butonu (Gereksinim 6.1–6.6, 4.4, 4.5)
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Şifre Değiştir butonu (Gereksinim 7.1, 7.2)
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => ChangePasswordDialog.show(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Şifre Değiştir',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Çıkış Yap butonu (Gereksinim 8.1–8.5)
            OutlinedButton(
              onPressed: _isLoading ? null : _signOut,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Bölüm başlığı widget'ı.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
