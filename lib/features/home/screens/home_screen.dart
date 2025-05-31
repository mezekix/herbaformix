import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart'; // Profil ekranını import et

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home'; // go_router için rota adı
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // final user = authProvider.user; // Mevcut kullanıcı bilgisi

    return Scaffold(
      appBar: AppBar(
        title: const Text('HerbaForm Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Profil sayfasına gitmek için go_router'ı kullan
              context.goNamed(ProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authProvider.signOut();
              // go_router'daki redirect kuralı, kullanıcıyı otomatik olarak LoginScreen'e yönlendirecektir.
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hoş Geldiniz!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (authProvider.user?.email != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(authProvider.user!.email!),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Ürün listeleme sayfasına git
                // context.go('/products');
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ürünler sayfası henüz hazır değil.')),
                );
              },
              child: const Text('Ürünleri Görüntüle'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Müşteri listeleme sayfasına git
                // context.go('/customers');
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Müşteriler sayfası henüz hazır değil.')),
                );
              },
              child: const Text('Müşterilerim'),
            ),
            const SizedBox(height: 12),
             ElevatedButton(
              onPressed: () {
                // TODO: Siparişler sayfasına git
                // context.go('/orders');
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Siparişler sayfası henüz hazır değil.')),
                );
              },
              child: const Text('Siparişlerim'),
            ),
          ],
        ),
      ),
    );
  }
}