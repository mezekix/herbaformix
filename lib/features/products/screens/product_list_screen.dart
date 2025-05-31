import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';

class ProductListScreen extends StatelessWidget {
  static const String routeName = '/products';
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ProductProvider'ı dinle (listen: true olacak şekilde)
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(
              child: Text(
                'Gösterilecek ürün bulunamadı.\n(Firestore\'a ürün eklediniz mi?)',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      // Ürün görseli varsa göster, yoksa baş harf
                      backgroundImage: product.imageUrl != null
                          ? NetworkImage(product.imageUrl!)
                          : null,
                      child: product.imageUrl == null
                          ? Text(
                              product.name.isNotEmpty ? product.name[0] : '?',
                            )
                          : null,
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      'VP: ${product.vp.toStringAsFixed(2)}${product.price != null ? ' | Fiyat: ${product.price!.toStringAsFixed(2)} TL' : ''}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // TODO: Ürün detay ekranına gitme veya siparişe ekleme fonksiyonu eklenebilir.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} seçildi.')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
