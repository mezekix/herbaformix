import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../customers/screens/add_edit_customer_screen.dart'; // Hızlı erişim için
import '../../orders/screens/add_edit_order_screen.dart'; // Hızlı erişim için
import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../orders/providers/order_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../../widgets/app_drawer.dart'; // Drawer'ı import et

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required String value, Color? iconColor, VoidCallback? onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: iconColor ?? Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);

    final UserProfileModel? userProfile = authProvider.userProfile;
    final monthlyVPTarget = userProfile?.monthlyVPTarget ?? 0;
    final vpEarnedThisMonth = orderProvider.totalVpEarnedThisMonth;
    final vpProgress = monthlyVPTarget > 0 ? (vpEarnedThisMonth / monthlyVPTarget) : 0.0;

    return Scaffold(
      drawer: const AppDrawer(), // Drawer eklendi
      appBar: AppBar(
        title: const Text('HerbaForm Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profilim',
            onPressed: () {
              // ProfileScreen.routeName 'profile' olmalı (alt rota ismi)
              context.goNamed(ProfileScreen.routeName); 
            },
          ),
          // Çıkış yap butonu Drawer'a taşındığı için buradan kaldırıldı.
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Merhaba, ${userProfile?.name ?? authProvider.firebaseUser?.email?.split('@')[0] ?? 'Kullanıcı'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // VP Hedef Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bu Ayki VP Hedefiniz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${vpEarnedThisMonth.toStringAsFixed(2)} VP',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '/ ${monthlyVPTarget.toStringAsFixed(0)} VP',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: vpProgress > 1.0 ? 1.0 : vpProgress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary), // Temadan ikincil renk
                      borderRadius: BorderRadius.circular(5),
                    ),
                     const SizedBox(height: 8),
                    Text(
                      '%${(vpProgress * 100).toStringAsFixed(1)} Tamamlandı',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid Kartlar
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.people_alt_outlined,
                  title: 'Toplam Müşteri',
                  value: customerProvider.isLoading ? '...' : customerProvider.customersCount.toString(),
                  onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)), // 'customers'
                  iconColor: AppColors.laguna,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.pending_actions_outlined,
                  title: 'Bekleyen Sipariş',
                  value: orderProvider.isLoading ? '...' : orderProvider.pendingOrdersCount.toString(),
                  onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)), // 'orders'
                  iconColor: AppColors.mango,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'Ürünler',
                  value: 'Kataloğu Gör',
                  onTap: () => context.goNamed(ProductListScreen.routeName.substring(1)), // 'products'
                  iconColor: AppColors.blueberry,
                ),
                 _buildDashboardCard(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Tüm Siparişler',
                  value: 'Listeyi Gör',
                  onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)), // 'orders'
                  iconColor: AppColors.lake,
                ),
              ],
            ),
             const SizedBox(height: 24),
             Text(
              "Hızlı Erişim",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Yeni Sipariş Oluştur'),
              onPressed: () => context.goNamed(AddEditOrderScreen.routeName), // 'add-edit-order'
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Yeni Müşteri Ekle'),
              onPressed: () => context.goNamed(AddEditCustomerScreen.routeName), // 'add-edit-customer'
            ),
          ],
        ),
      ),
    );
  }
}