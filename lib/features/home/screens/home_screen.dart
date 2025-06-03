import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../customers/screens/add_edit_customer_screen.dart';
import '../../orders/screens/add_edit_order_screen.dart';
import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../orders/providers/order_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../../widgets/app_drawer.dart'; // AppDrawer'ı import et

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required String value, Color? iconColor, VoidCallback? onTap}) {
    // ... (Bu fonksiyon aynı kalacak) ...
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 48, color: iconColor ?? AppColors.primary),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
      drawer: const AppDrawer(), // Drawer'ı Scaffold'a ekle
      appBar: AppBar(
        title: const Text('HerbaForm Panel'),
        // AppBar'ın actions'ları aynı kalabilir veya Drawer'a taşınabilir.
        // Şimdilik burada bırakalım.
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profilim',
            onPressed: () {
              context.goNamed(ProfileScreen.routeName);
            },
          ),
          // Çıkış yap butonu Drawer'a taşındığı için buradan kaldırılabilir.
          // IconButton(
          //   icon: const Icon(Icons.exit_to_app),
          //   tooltip: 'Çıkış Yap',
          //   onPressed: () async {
          //     await authProvider.signOut();
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ... (Dashboard içeriği aynı kalacak) ...
            Text('Merhaba, ${userProfile?.name ?? authProvider.firebaseUser?.email?.split('@')[0] ?? 'Kullanıcı'}!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bu Ayki VP Hedefiniz', style: Theme.of(context).textTheme.titleLarge,), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${vpEarnedThisMonth.toStringAsFixed(2)} VP', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),), Text('/ ${monthlyVPTarget.toStringAsFixed(0)} VP', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),),],), const SizedBox(height: 12), LinearProgressIndicator(value: vpProgress > 1.0 ? 1.0 : vpProgress, minHeight: 10, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary), borderRadius: BorderRadius.circular(5),), const SizedBox(height: 8), Text('%${(vpProgress * 100).toStringAsFixed(1)} Tamamlandı', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),),],),),),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(context, icon: Icons.people_alt_outlined, title: 'Toplam Müşteri', value: customerProvider.isLoading ? '...' : customerProvider.customersCount.toString(), onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)), iconColor: AppColors.laguna,),
                _buildDashboardCard(context, icon: Icons.pending_actions_outlined, title: 'Bekleyen Sipariş', value: orderProvider.isLoading ? '...' : orderProvider.pendingOrdersCount.toString(), onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)), iconColor: AppColors.mango,),
                _buildDashboardCard(context, icon: Icons.shopping_bag_outlined, title: 'Ürünler', value: '', onTap: () => context.goNamed(ProductListScreen.routeName.substring(1)), iconColor: AppColors.garden,),
                _buildDashboardCard(context, icon: Icons.receipt_long_outlined, title: 'Tüm Siparişler', value: '', onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)), iconColor: AppColors.aqua,),
              ],
            ),
             const SizedBox(height: 24),
             Text(
              "Hızlı Erişim",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
                
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(icon: const Icon(Icons.add_shopping_cart), label: const Text('Yeni Sipariş Oluştur'), onPressed: () => context.goNamed(AddEditOrderScreen.routeName), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textOnPrimary,),),
            const SizedBox(height: 10),
            OutlinedButton.icon(icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Yeni Müşteri Ekle'), onPressed: () => context.goNamed(AddEditCustomerScreen.routeName),),
          ],
        ),
      ),
    );
  }
}
