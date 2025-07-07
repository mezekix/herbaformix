import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../widgets/app_drawer.dart'; // AppDrawer'ı import et
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/screens/add_edit_customer_screen.dart';
import '../../customers/screens/customer_detail_screen.dart'; // Navigasyon için
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/providers/order_provider.dart';
import '../../orders/screens/add_edit_order_screen.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../products/providers/product_provider.dart';
import '../../products/screens/add_edit_product_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../providers/home_provider.dart'; // Yeni provider'ımız

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: iconColor ?? AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
    final productProvider = Provider.of<ProductProvider>(context);

    final UserProfileModel? userProfile = authProvider.userProfile;
    final monthlyVPTarget = userProfile?.monthlyVPTarget ?? 0;
    final vpEarnedThisMonth = orderProvider.totalVpEarnedThisMonth;
    final vpProgress = monthlyVPTarget > 0
        ? (vpEarnedThisMonth / monthlyVPTarget)
        : 0.0;

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
      body: Consumer<HomeProvider>(
        // Ana içeriği HomeProvider ile sarmala
        builder: (context, homeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Merhaba, ${userProfile?.name ?? authProvider.firebaseUser?.email?.split('@')[0] ?? 'Kullanıcı'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Ayki VP Hedefiniz',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${vpEarnedThisMonth.toStringAsFixed(2)} VP',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                            Text(
                              '/ ${monthlyVPTarget.toStringAsFixed(0)} VP',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: vpProgress > 1.0 ? 1.0 : vpProgress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '%${(vpProgress * 100).toStringAsFixed(1)} Tamamlandı',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDashboardCard(
                      context,
                      icon: Icons.people_alt_outlined,
                      title: 'Toplam Müşteri',
                      value: customerProvider.isLoading
                          ? '...'
                          : customerProvider.customersCount.toString(),
                      onTap: () => context.goNamed(
                        CustomerListScreen.routeName.substring(1),
                      ),
                      iconColor: AppColors.laguna,
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.pending_actions_outlined,
                      title: 'Bekleyen Sipariş',
                      value: orderProvider.isLoading
                          ? '...'
                          : orderProvider.pendingOrdersCount.toString(),
                      onTap: () => context.goNamed(
                        OrderListScreen.routeName.substring(1),
                      ),
                      iconColor: AppColors.mango,
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'Ürünler',
                      value: productProvider.isLoading
                          ? '...'
                          : productProvider.products.length.toString(),
                      onTap: () => context.goNamed(
                        ProductListScreen.routeName.substring(1),
                      ),
                      iconColor: AppColors.garden,
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Tüm Siparişler',
                      value: orderProvider.isLoading
                          ? '...'
                          : orderProvider.orders.length.toString(),
                      onTap: () => context.goNamed(
                        OrderListScreen.routeName.substring(1),
                      ),
                      iconColor: AppColors.aqua,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildUpcomingFollowUps(context, homeProvider),
                const SizedBox(height: 20),
                Text(
                  "Hızlı Erişim",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildQuickAccessButtons(context),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickAddMenu(context);
        },
        tooltip: 'Hızlı Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Yaklaşan takip görevlerini gösteren ajanda widget'ı.
  Widget _buildUpcomingFollowUps(BuildContext context, HomeProvider provider) {
    final customerProvider = context.read<CustomerProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yaklaşan Takipler (7 Gün)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!provider.isLoading && provider.upcomingFollowUps.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Yaklaşan takip göreviniz bulunmuyor.'),
                ),
              ),
            if (provider.upcomingFollowUps.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.upcomingFollowUps.length,
                itemBuilder: (context, index) {
                  final task = provider.upcomingFollowUps[index];
                  final isOverdue = task.dueDate.toDate().isBefore(
                    DateTime.now(),
                  );

                  return ListTile(
                    leading: Icon(
                      Icons.person_pin_circle_outlined,
                      color: isOverdue
                          ? Colors.red.shade700
                          : AppColors.primary,
                    ),
                    title: Text(
                      '${task.customerFirstName} ${task.customerLastName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${task.title} - ${DateFormat('dd MMM, EEEE', 'tr_TR').format(task.dueDate.toDate())}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // İlgili müşteriyi bul ve detay sayfasına git.
                      try {
                        final customer = customerProvider.customers.firstWhere(
                          (c) => c.id == task.customerId,
                        );
                        context.goNamed(
                          CustomerDetailScreen.routeName,
                          extra: customer,
                        );
                      } catch (e) {
                        // Müşteri listede bulunamazsa (veri tutarsızlığı gibi nadir bir durumda)
                        // bir hata mesajı gösterilebilir veya hiçbir şey yapılmayabilir.
                        debugPrint(
                          "Navigasyon hatası: Müşteri bulunamadı. ID: ${task.customerId}",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Müşteri bilgisi bulunamadı. Lütfen verileri yenileyin.',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        _buildQuickAccessButton(
          context,
          icon: Icons.person_add,
          label: 'Müşteri Ekle',
          onPressed: () {
            context.goNamed(AddEditCustomerScreen.routeName);
          },
        ),
        _buildQuickAccessButton(
          context,
          icon: Icons.shopping_cart,
          label: 'Sipariş Oluştur',
          onPressed: () {
            context.goNamed(AddEditOrderScreen.routeName);
          },
        ),
        _buildQuickAccessButton(
          context,
          icon: Icons.people,
          label: 'Müşterilerim',
          onPressed: () {
            context.goNamed(CustomerListScreen.routeName.substring(1));
          },
        ),
        _buildQuickAccessButton(
          context,
          icon: Icons.receipt,
          label: 'Siparişlerim',
          onPressed: () {
            context.goNamed(OrderListScreen.routeName.substring(1));
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Yeni Müşteri Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditCustomerScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_checkout),
                title: const Text('Yeni Sipariş Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditOrderScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Yeni Ürün Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditProductScreen.routeName);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
