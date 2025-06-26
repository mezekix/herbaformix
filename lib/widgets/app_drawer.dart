import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart'; // Renkler için
import '../features/auth/providers/auth_provider.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.firebaseUser;
    final userProfile = authProvider.userProfile;

    String displayName = userProfile?.name ?? "Kullanıcı Adı";
    String displayEmail = user?.email ?? "E-posta adresi";
    // İsim boşsa ve e-posta varsa, e-postanın @ işaretinden öncesini al
    if ((userProfile?.name == null || userProfile!.name!.isEmpty) &&
        (user?.email != null && user!.email!.isNotEmpty)) {
      displayName = user.email!.split('@')[0];
    }

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
        style: TextStyle(
          color: AppColors.textOnPrimary.withAlpha(204),
        ), // 0.8 * 255 = ~204
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppColors.white.withAlpha(230), // 0.9 * 255 = ~230
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : "K",
          style: const TextStyle(fontSize: 40.0, color: AppColors.primary),
        ),
      ),
      decoration: const BoxDecoration(color: AppColors.primary),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
    bool isNamedRoute = true,
    Map<String, String>? pathParameters,
  }) {
    final currentRoute = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.fullPath;
    // Rota adları '/home/products' gibi olabilir, bu yüzden karşılaştırmayı buna göre yapmalıyız.
    // Ancak, GoRouter'da child rotaların tam yolu parent ile başlar.
    // Şimdilik basit bir kontrol yapalım, daha sonra iyileştirilebilir.
    bool isSelected =
        currentRoute.endsWith(routeName) ||
        (routeName == HomeScreen.routeName &&
            currentRoute == HomeScreen.routeName);

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
      selectedTileColor: AppColors.primary.withAlpha(26), // 0.1 * 255 = ~26
      onTap: () {
        Navigator.of(context).pop(); // Drawer'ı kapat
        if (isNamedRoute) {
          context.goNamed(routeName, pathParameters: pathParameters ?? {});
        } else {
          context.go(routeName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(context),
          _buildListTile(
            context,
            icon: Icons.home_outlined,
            title: 'Ana Sayfa',
            routeName: HomeScreen.routeName.substring(1), // 'home'
            isNamedRoute: true,
          ),
          _buildListTile(
            context,
            icon: Icons.person_outline,
            title: 'Profilim',
            routeName: ProfileScreen
                .routeName, // 'profile' (alt rota olduğu için / yok)
            isNamedRoute: true,
          ),
          _buildListTile(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Ürünler',
            routeName: ProductListScreen.routeName.substring(1), // 'products'
            isNamedRoute: true,
          ),
          _buildListTile(
            context,
            icon: Icons.people_alt_outlined,
            title: 'Müşterilerim',
            routeName: CustomerListScreen.routeName.substring(1), // 'customers'
            isNamedRoute: true,
          ),
          _buildListTile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Siparişlerim',
            routeName: OrderListScreen.routeName.substring(1), // 'orders'
            isNamedRoute: true,
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.water_drop_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text(
              'Su Takip',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Su Takip sayfası yakında!')),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text(
              'Kalori Sayacı',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kalori Sayacı sayfası yakında!')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app_outlined, color: AppColors.error),
            title: Text(
              'Çıkış Yap',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop(); // Drawer'ı kapat
              await authProvider.signOut();
              // GoRouter'ın redirect'i zaten LoginScreen'e yönlendirecektir.
            },
          ),
        ],
      ),
    );
  }
}
