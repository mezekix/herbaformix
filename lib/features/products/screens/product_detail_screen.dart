import 'package:flutter/material.dart';

import '../../../core/app_colors.dart'; // Renkler için
import '../../../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  static const String routeName = 'product-detail'; // Alt rota adı
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // TODO: Eğer HTML içerik varsa, flutter_html paketi kullanılabilir.
          // Şimdilik düz metin olarak gösteriyoruz.
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // _buildListSection is kept in case you need it for other list data in the future.
  // If not, you can remove it.
  Widget _buildListSection(
    BuildContext context,
    String title,
    List<String>? items,
  ) {
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background, // Temadan geliyor zaten
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0, // Resmin görüneceği yükseklik
            floating: false,
            pinned: true, // Scroll yukarı gidince AppBar sabit kalsın
            snap: false,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(
              color: AppColors.textOnPrimary,
            ), // Geri butonu rengi
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                product.name,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 18.0, // Biraz daha büyük
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 2.0, color: Colors.black54),
                  ], // Okunurluk için gölge
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              centerTitle: true, // Başlığı ortala
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 48.0,
                vertical: 12.0,
              ), // Başlık padding'i
              background:
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Hero(
                      // Animasyonlu geçiş için
                      tag: 'productImage_${product.id}',
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      // Resim yoksa varsayılan bir arka plan
                      color: AppColors.secondary.withAlpha(100),
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 100,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            '${product.vp.toStringAsFixed(2)} VP',
                            style: const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                        if (product.price != null)
                          Text(
                            '${product.price!.toStringAsFixed(2)} TL',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                    // Updated to use stockNo
                    if (product.stockNo != null && product.stockNo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Stok No: ${product.stockNo}', // Changed from SKU
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (product.category != null &&
                        product.category!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Kategori: ${product.category}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // Updated to use overview
              _buildDetailSection(
                context,
                'Genel Bakış', // Changed title from "Açıklama" to "Genel Bakış" (Overview)
                product.overview, // Changed from product.description ?? product.shortDescription
              ),
              // Section for Features
              _buildDetailSection(
                context,
                'Özellikler', // Title for Features
                product.features,
              ),
              // Section for Ingredients
              _buildDetailSection(
                context,
                'İçindekiler', // Title for Ingredients
                product.ingredients,
              ),
              _buildDetailSection(
                context,
                'Kullanım Bilgisi',
                product.usageInfo,
              ),
              // Removed _buildListSection for product.benefits
              // Removed _buildListSection for product.keyIngredients

              // Siparişe Ekle Butonu (Opsiyonel)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Siparişe Ekle'),
                  onPressed: () {
                    // TODO: Bu ürünü mevcut bir siparişe ekleme veya yeni sipariş başlatma mantığı
                    // Örneğin, bir dialog açıp adet sorabilir ve sonra sipariş ekranına yönlendirebilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${product.name} siparişe eklenecek (henüz değil).',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Alt boşluk
            ]),
          ),
        ],
      ),
    );
  }
}