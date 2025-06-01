import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter import'u
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import './product_detail_screen.dart'; // ProductDetailScreen'i import et

class ProductListScreen extends StatelessWidget {
  static const String routeName =
      '/products'; // Ana rota olarak kalabilir veya '/home/products' için 'products'
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(/* ... (Boş liste mesajı) ... */)
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ), // Temadan alabilir
                  child: ListTile(
                    leading: Hero(
                      // Animasyonlu geçiş için
                      tag: 'productImage_${product.id}',
                      child: CircleAvatar(
                        backgroundImage:
                            product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? NetworkImage(product.imageUrl!)
                            : null,
                        backgroundColor: Colors.grey[200],
                        child:
                            product.imageUrl == null ||
                                product.imageUrl!.isEmpty
                            ? Text(
                                product.name.isNotEmpty
                                    ? product.name[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'VP: ${product.vp.toStringAsFixed(2)}${product.price != null ? ' | Fiyat: ${product.price!.toStringAsFixed(2)} TL' : ''}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // ProductDetailScreen'e product nesnesini extra olarak göndererek git
                      context.goNamed(
                        ProductDetailScreen.routeName, // 'product-detail'
                        extra: product,
                        // Eğer rota '/home/products/:productId' şeklinde olsaydı:
                        // pathParameters: {'productId': product.id},
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
