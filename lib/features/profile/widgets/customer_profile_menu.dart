import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'delete_account_dialog.dart';

class CustomerProfileMenu extends StatelessWidget {
  const CustomerProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: userProfile?.profilePhotoUrl != null
                      ? NetworkImage(userProfile!.profilePhotoUrl!) // TODO: Handle file:// and initials properly as in HomeScreen
                      : null,
                  child: userProfile?.profilePhotoUrl == null
                      ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  userProfile?.name ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Menu Items
          _buildMenuSection(
            context,
            title: 'Hesap Ayarları',
            icon: Icons.person_outline,
            onTap: () => context.goNamed('personal-info'),
          ),
          _buildMenuSection(
            context,
            title: 'Hedeflerim & Tercihler',
            icon: Icons.track_changes,
            onTap: () => context.goNamed('health-goals'),
          ),
          _buildMenuSection(
            context,
            title: 'Uygulama',
            icon: Icons.settings_outlined,
            onTap: () => context.goNamed('app-settings'),
          ),
          _buildMenuSection(
            context,
            title: 'Destek',
            icon: Icons.help_outline,
            onTap: () => context.goNamed('support'),
          ),
          _buildMenuSection(
            context,
            title: userProfile?.distributorRequestStatus == 'pending'
                ? 'Distribütörlük Başvurusu (Onay Bekliyor)'
                : 'Distribütör Ol',
            icon: userProfile?.distributorRequestStatus == 'pending'
                ? Icons.pending_actions
                : Icons.business_center_outlined,
            trailing: userProfile?.distributorRequestStatus == 'pending'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : null,
            onTap: userProfile?.distributorRequestStatus == 'pending'
                ? () {}
                : () => _showDistributorRequestDialog(context, authProvider),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Hesabımı Sil — daha sade, küçük link gibi durarak yanlışlık
          // riskini azaltır. Gerçek friction onay diyaloğunda.
          Center(
            child: TextButton.icon(
              onPressed: () => DeleteAccountDialog.show(context),
              icon: Icon(
                Icons.delete_forever_outlined,
                size: 16,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
              label: Text(
                'Hesabımı Kalıcı Olarak Sil',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.error.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.nightSky,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _signOut(BuildContext context) async {
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılamadı: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDistributorRequestDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Distribütör Ol'),
        content: const Text(
          'Distribütör olmak için başvuruda bulunmak istiyor musunuz? '
          'Başvurunuz danışmanınız tarafından onaylandıktan sonra hesabınız distribütör olarak güncellenecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Başvur'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final updatedProfile = authProvider.userProfile!.copyWith(
        distributorRequestStatus: 'pending',
      );

      final success = await authProvider.updateUserProfile(updatedProfile);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Distribütörlük başvurunuz başarıyla alındı. Danışman onayından sonra hesabınız güncellenecektir.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted) {
        throw Exception('Profil güncellenemedi.');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Başvuru sırasında hata oluştu: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
