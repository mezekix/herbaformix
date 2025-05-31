import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/screens/order_list_screen.dart'; // OrderListScreen'i import et

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar( title: const Text('HerbaForm Ana Sayfa'), actions: [ IconButton(icon: const Icon(Icons.person_outline), onPressed: () { context.goNamed(ProfileScreen.routeName);},), IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () async { await authProvider.signOut();},),],),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (Hoş Geldiniz ve diğer butonlar) ...
              Text('Hoş Geldiniz!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              if (authProvider.firebaseUser?.email != null) Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 20.0), child: Text(authProvider.firebaseUser!.email!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
              ElevatedButton.icon(icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Ürünleri Görüntüle'), onPressed: () => context.go(ProductListScreen.routeName), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))),
              const SizedBox(height: 12),
              ElevatedButton.icon(icon: const Icon(Icons.people_alt_outlined), label: const Text('Müşterilerim'), onPressed: () => context.go(CustomerListScreen.routeName), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Siparişlerim'),
                onPressed: () {
                  // Siparişler sayfasına git
                  context.go(OrderListScreen.routeName);
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}