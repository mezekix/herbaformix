import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/avatar_color_helper.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import 'invite_code_section.dart';

/// Distribütör rolündeki kullanıcıların profil bilgilerini düzenleyebildiği widget.
///
/// İçerir:
/// - Ad-soyad (zorunlu)
/// - Distribütör seviyesi (DropdownButtonFormField)
/// - Aylık VP hedefi (sayısal)
/// - Rol seçimi (DropdownButtonFormField, sadece distribütör rolü için)
/// - InviteCodeSection (form altında)
/// - "Profili Kaydet" butonu
/// - "Çıkış Yap" butonu (onay diyalogu ile)
class DistributorProfileView extends StatefulWidget {
  const DistributorProfileView({super.key});

  @override
  State<DistributorProfileView> createState() => _DistributorProfileViewState();
}

class _DistributorProfileViewState extends State<DistributorProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vpGoalController;

  String? _distributorLevel;
  UserRole? _selectedRole;

  File? _selectedPhotoFile;
  bool _isPhotoUploading = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const List<String> _distributorLevels = [
    'Distribütör',
    'Supervisor',
    'World Team',
    'GET Team',
    'Millionaire Team',
    "President's Team",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _vpGoalController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;
      if (userProfile != null) {
        _nameController.text = userProfile.name ?? '';
        _phoneController.text = userProfile.phoneNumber ?? '';
        _vpGoalController.text = userProfile.monthlyVPTarget?.toString() ?? '';
        _distributorLevel = userProfile.distributorLevel;
        _selectedRole = userProfile.role;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vpGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isPhotoUploading = _selectedPhotoFile != null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentFirebaseUser = authProvider.firebaseUser;

    if (currentFirebaseUser == null) {
      _showSnackBar('Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.', isError: true);
      setState(() {
        _isLoading = false;
        _isPhotoUploading = false;
      });
      return;
    }

    String? newPhotoUrl;
    try {
      if (_selectedPhotoFile != null) {
        newPhotoUrl = await authProvider.uploadProfilePhoto(_selectedPhotoFile!);
        if (!mounted) return;
        setState(() => _isPhotoUploading = false);

        if (newPhotoUrl == null) {
          _showSnackBar('Fotoğraf yüklenemedi, diğer bilgiler kaydedilecek.', isError: false);
        }
      }

      final existingProfile = authProvider.userProfile;
      final updatedProfile = UserProfileModel(
        id: currentFirebaseUser.uid,
        email: currentFirebaseUser.email!,
        role: _selectedRole ?? existingProfile?.role ?? UserRole.distributor,
        name: _nameController.text.trim(),
        distributorLevel: _distributorLevel,
        monthlyVPTarget: int.tryParse(_vpGoalController.text.trim()),
        // Mevcut diğer alanları koru
        isOnboarded: existingProfile?.isOnboarded ?? false,
        age: existingProfile?.age,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        weight: existingProfile?.weight,
        height: existingProfile?.height,
        goal: existingProfile?.goal,
        targetWeight: existingProfile?.targetWeight,
        programStartDate: existingProfile?.programStartDate,
        userGoal: existingProfile?.userGoal,
        wakeTime: existingProfile?.wakeTime,
        lunchTime: existingProfile?.lunchTime,
        sleepTime: existingProfile?.sleepTime,
        birthDate: existingProfile?.birthDate,
        gender: existingProfile?.gender,
        healthNotes: existingProfile?.healthNotes,
        allergies: existingProfile?.allergies,
        medications: existingProfile?.medications,
        assignedDistributorId: existingProfile?.assignedDistributorId,
        profilePhotoUrl: newPhotoUrl ?? existingProfile?.profilePhotoUrl,
      );

      final success = await authProvider.updateUserProfile(updatedProfile);
      if (!mounted) return;

      if (success) {
        _showSnackBar('Profil başarıyla güncellendi!');
        if (newPhotoUrl != null) {
          setState(() => _selectedPhotoFile = null);
        }
      } else {
        _showSnackBar('Profil güncellenemedi.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Bir hata oluştu: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPhotoUploading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showSignOutConfirmDialog();
    if (!confirmed || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      // go_router redirect ile otomatik yönlendirme yapılacak
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Çıkış yapılırken bir hata oluştu: $e', isError: true);
    }
  }

  Future<bool> _showSignOutConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildProfileAvatar(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;
    final photoUrl = userProfile?.profilePhotoUrl;
    final userName = userProfile?.name;
    final userId = userProfile?.id;
    final initials = _getInitials(userName);
    final bgColor = AvatarColorHelper.forUser(userId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);
    const size = 110.0;

    return GestureDetector(
      onTap: _isPhotoUploading ? null : () => _showPhotoPicker(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 6,
            height: size + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF81C784)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: _buildAvatarContent(photoUrl, initials, bgColor, textColor, size),
            ),
          ),
          if (_isPhotoUploading)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withAlpha(200)),
              ),
            ),
          if (!_isPhotoUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(
    String? photoUrl, String initials, Color bgColor, Color textColor, double size,
  ) {
    // 1. Seçilmiş yerel dosya
    if (_selectedPhotoFile != null) {
      return Image.file(
        _selectedPhotoFile!,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsBox(initials, bgColor, textColor, size),
      );
    }

    // 2. Kaydedilmiş fotoğraf
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isLocalPath = photoUrl.startsWith('/') || photoUrl.startsWith('file://');
      if (isLocalPath) {
        return Image.file(
          File(photoUrl.replaceFirst('file://', '')),
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialsBox(initials, bgColor, textColor, size),
        );
      }
      return Image.network(
        photoUrl, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsBox(initials, bgColor, textColor, size),
      );
    }

    // 3. Baş harf avatarı
    return _buildInitialsBox(initials, bgColor, textColor, size);
  }

  Widget _buildInitialsBox(String initials, Color bgColor, Color textColor, double size) {
    return Container(
      width: size, height: size, color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first[0].toUpperCase();
  }

  void _showPhotoPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('Fotoğraf Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Kameradan Çek'),
                  onTap: () { Navigator.of(sheetContext).pop(); _pickImage(ImageSource.camera); },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Galeriden Seç'),
                  subtitle: const Text('JPG, PNG, WEBP • Maks. 5 MB', style: TextStyle(fontSize: 11)),
                  onTap: () { Navigator.of(sheetContext).pop(); _pickImage(ImageSource.gallery); },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSizeBytes = await file.length();
      if (fileSizeBytes > 5 * 1024 * 1024) {
        _showSnackBar('Dosya 5 MB sınırını aşıyor.', isError: true);
        return;
      }

      setState(() => _selectedPhotoFile = file);
    } catch (e) {
      _showSnackBar('Fotoğraf seçilirken hata: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profil fotoğrafı
            Center(
              child: _buildProfileAvatar(context),
            ),
            const SizedBox(height: 20),

            // E-posta (salt okunur)
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) => Text(
                'E-posta: ${authProvider.firebaseUser?.email ?? 'N/A'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 20),

            // Ad-Soyad (zorunlu)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Adınız Soyadınız',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen adınızı ve soyadınızı girin.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Telefon numarası
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+90 5XX XXX XX XX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Rol Seçimi (DropdownButtonFormField)
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Uygulama Rolünüz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              items: UserRole.values
                  .where((role) => role != UserRole.customer)
                  .map((UserRole role) => DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(role.name),
                      ))
                  .toList(),
              onChanged: (UserRole? newValue) {
                setState(() => _selectedRole = newValue);
              },
              validator: (value) =>
                  value == null ? 'Lütfen bir rol seçin.' : null,
            ),
            const SizedBox(height: 16),

            // Distribütör Seviyesi (DropdownButtonFormField)
            DropdownButtonFormField<String>(
              initialValue: _distributorLevel,
              decoration: const InputDecoration(
                labelText: 'Distribütör Seviyeniz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star_border_outlined),
              ),
              items: _distributorLevels
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _distributorLevel = value);
              },
            ),
            const SizedBox(height: 16),

            // Aylık VP Hedefi (sayısal)
            TextFormField(
              controller: _vpGoalController,
              decoration: const InputDecoration(
                labelText: 'Aylık VP Hedefiniz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.track_changes_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Lütfen geçerli bir sayı girin.';
                  }
                  if (int.parse(value) < 0) {
                    return 'Hedef negatif olamaz.';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Profili Kaydet butonu
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Profili Kaydet'),
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(height: 12),

            // Çıkış Yap butonu
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              onPressed: _isLoading ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withAlpha(204),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Davet Kodu Bölümü
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            const InviteCodeSection(),
          ],
        ),
      ),
    );
  }
}
