import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
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
  late TextEditingController _vpGoalController;

  String? _distributorLevel;
  UserRole? _selectedRole;

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
    _vpGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentFirebaseUser = authProvider.firebaseUser;

    if (currentFirebaseUser == null) {
      _showSnackBar('Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.', isError: true);
      setState(() => _isLoading = false);
      return;
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
      phoneNumber: existingProfile?.phoneNumber,
      weight: existingProfile?.weight,
      height: existingProfile?.height,
      goal: existingProfile?.goal,
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
      profilePhotoUrl: existingProfile?.profilePhotoUrl,
    );

    try {
      final success = await authProvider.updateUserProfile(updatedProfile);
      if (!mounted) return;

      if (success) {
        _showSnackBar('Profil başarıyla güncellendi!');
      } else {
        _showSnackBar('Profil güncellenemedi.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Bir hata oluştu: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
