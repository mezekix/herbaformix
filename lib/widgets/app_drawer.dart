import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/avatar_color_helper.dart';
import '../features/auth/providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../features/calorie_tracker/screens/calorie_tracker_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/water_tracker/screens/water_tracker_screen.dart';
import '../models/user_role.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Mevcut tam route path'ini döndürür.
  /// GoRouter'ın `routerDelegate.currentConfiguration.fullPath` bazen
  /// named route'larda segment adı döndürebilir; bu yüzden
  /// `GoRouterState.of(context).uri.toString()` daha güvenilir.
  String _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.toString();
    } catch (_) {
      return GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .fullPath;
    }
  }

  /// Bir drawer öğesinin aktif olup olmadığını belirler.
  ///
  /// [pathSegment]: URL'de aranacak segment, örn. '/customers'
  /// Tam eşleşme veya o segment ile başlayan alt route'lar için true döner.
  /// Örn: '/home/customers' ve '/home/customers/customer-detail' ikisi de
  /// 'customers' segmenti için true döner.
  bool _isActive(BuildContext context, String pathSegment) {
    final path = _currentPath(context);
    // Tam eşleşme veya alt route kontrolü
    return path == pathSegment ||
        path.contains('/$pathSegment') &&
            // Yanlış eşleşmeyi önle: '/customers-archive' gibi durumlar
            (path.contains('/$pathSegment/') ||
                path.endsWith('/$pathSegment'));
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.firebaseUser;
    final userProfile = authProvider.userProfile;
    final l = AppLocalizations.of(context);

    String displayName = userProfile?.name ?? l.drawerDefaultUserName;
    String displayEmail = user?.email ?? l.drawerDefaultEmail;
    if ((userProfile?.name == null || userProfile!.name!.isEmpty) &&
        (user?.email != null && user!.email!.isNotEmpty)) {
      displayName = user.email!.split('@')[0];
    }

    final initials = displayName.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bgColor = AvatarColorHelper.forUser(userProfile?.id);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    return UserAccountsDrawerHeader(
      accountName: Text(
        displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.textOnPrimary,
        ),
      ),
      accountEmail: Text(
        displayEmail,
        style: TextStyle(color: AppColors.textOnPrimary.withAlpha(204)),
      ),
      currentAccountPicture: _buildAvatar(userProfile, initials, bgColor, textColor),
      decoration: const BoxDecoration(color: AppColors.primary),
    );
  }

  Widget _buildAvatar(dynamic userProfile, String initials, Color bgColor, Color textColor) {
    final photoUrl = userProfile?.profilePhotoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isLocalPath = photoUrl.startsWith('/') || photoUrl.startsWith('file://');
      if (isLocalPath && !kIsWeb) {
        return CircleAvatar(
          backgroundColor: bgColor,
          child: ClipOval(
            child: Image.file(
              File(photoUrl.replaceFirst('file://', '')),
              width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitialsAvatar(initials, bgColor, textColor),
            ),
          ),
        );
      }
      if (!isLocalPath) {
        return CircleAvatar(
          backgroundColor: bgColor,
          child: ClipOval(
            child: Image.network(
              photoUrl, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitialsAvatar(initials, bgColor, textColor),
            ),
          ),
        );
      }
    }

    return _buildInitialsAvatar(initials, bgColor, textColor);
  }

  Widget _buildInitialsAvatar(String initials, Color bgColor, Color textColor) {
    return CircleAvatar(
      backgroundColor: bgColor,
      child: Text(
        initials.isNotEmpty ? initials : 'K',
        style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
    required String pathSegment,
    Map<String, String>? pathParameters,
  }) {
    final isSelected = _isActive(context, pathSegment);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.of(context).pop();
        context.goNamed(routeName, pathParameters: pathParameters ?? {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final l = AppLocalizations.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(context),
          const SizedBox(height: 8),
          _buildListTile(
            context,
            icon: Icons.home_outlined,
            title: l.drawerHome,
            routeName: HomeScreen.routeName.substring(1), // 'home'
            pathSegment: 'home',
          ),
          _buildListTile(
            context,
            icon: Icons.person_outline,
            title: l.drawerProfile,
            routeName: ProfileScreen.routeName, // 'profile'
            pathSegment: 'profile',
          ),
          _buildListTile(
            context,
            icon: Icons.shopping_bag_outlined,
            title: userProfile?.role == UserRole.customer
                ? l.drawerProductCatalog
                : l.drawerProducts,
            routeName: ProductListScreen.routeName.substring(1), // 'products'
            pathSegment: 'products',
          ),
          if (userProfile?.role != UserRole.customer)
            _buildListTile(
              context,
              icon: Icons.people_alt_outlined,
              title: l.drawerCustomers,
              routeName: CustomerListScreen.routeName.substring(1), // 'customers'
              pathSegment: 'customers',
            ),
          if (userProfile?.role != UserRole.customer)
            _buildListTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: l.drawerOrders,
              routeName: OrderListScreen.routeName.substring(1), // 'orders'
              pathSegment: 'orders',
            ),
          if (userProfile?.role != UserRole.customer)
            ListTile(
              leading: const Icon(
                Icons.swap_horiz_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                l.drawerPersonalDevelopment,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.nightSky,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.of(context).pop();
                authProvider.toggleCustomerMode();
              },
            ),
          if (userProfile?.role == UserRole.customer)
            _buildListTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: l.drawerOrderHistory,
              routeName: OrderListScreen.routeName.substring(1),
              pathSegment: 'orders',
            ),
          const Divider(indent: 16, endIndent: 16),
          _buildListTile(
            context,
            icon: Icons.water_drop_outlined,
            title: l.drawerWaterTracker,
            routeName: WaterTrackerScreen.routeName, // 'water-tracker'
            pathSegment: 'water-tracker',
          ),
          _buildListTile(
            context,
            icon: Icons.local_fire_department_outlined,
            title: l.drawerCalorieTracker,
            routeName: CalorieTrackerScreen.routeName,
            pathSegment: 'calorie-tracker',
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: Icon(Icons.exit_to_app_outlined, color: AppColors.error),
            title: Text(
              l.drawerSignOut,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
