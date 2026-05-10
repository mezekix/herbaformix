import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/customer_profile_menu.dart';
import '../widgets/distributor_profile_view.dart';

/// Profil ekranı — rol bazlı koşullu render wrapper'ı.
///
/// - `UserRole.customer` → `CustomerProfileView`
/// - Diğer roller → `DistributorProfileView`
/// - Yükleme durumu (`AuthStatus.authenticating` veya profil null) → `CircularProgressIndicator`
///
/// Gereksinimler: 2.1, 9.1
class ProfileScreen extends StatelessWidget {
  static const String routeName = 'profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Yükleme durumu: kimlik doğrulanıyor veya profil henüz yüklenmedi
    if (authProvider.status == AuthStatus.authenticating ||
        authProvider.userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilim')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final role = authProvider.userProfile!.role;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: role == UserRole.customer
          ? const CustomerProfileMenu()
          : const DistributorProfileView(),
    );
  }
}
