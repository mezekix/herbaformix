import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../products/screens/product_list_screen.dart'; // ProductListScreen'i import et

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Scaffold ve AppBar aynı kalacak) ...
    return Scaffold(
      appBar: AppBar(/* ... */),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ... (Hoş Geldiniz yazısı aynı kalacak) ...
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Ürünler sayfasına gitmek için go_router'ı kullan
                context.go(ProductListScreen.routeName);
              },
              child: const Text('Ürünleri Görüntüle'),
            ),
            // ... (Diğer butonlar aynı kalacak) ...
          ],
        ),
      ),
    );
  }
}
