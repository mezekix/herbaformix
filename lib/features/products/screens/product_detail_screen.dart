import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart'; // Renkler için
import '../../../models/product_model.dart';
import '../providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  static const String routeName = 'product-detail';
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
          '${widget.product.name} ürününü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      try {
        await productProvider.deleteProduct(widget.product.id);
        if (!mounted) return; // Widget hala ağaçta mı kontrol et
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("'${widget.product.name}' silindi."),
            backgroundColor: Colors.green,
          ),
        );
        if (router.canPop()) {
          router.pop();
        }
      } catch (e) {
        if (!mounted) return; // Widget hala ağaçta mı kontrol et
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Ürün silinirken bir hata oluştu: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _editProduct() {
    context.goNamed(AddEditProductScreen.routeName, extra: widget.product);
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String? content, {
    bool isFirst = false,
  }) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 24.0),
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

  Widget _buildRichTextTitle(String text) {
    final parts = text.split('-');
    if (parts.length < 2) {
      return Text(
        text,
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black87,
              offset: Offset(1, 1),
            ),
          ],
        ),
        children: [
          TextSpan(text: '${parts[0].trim()}-'),
          TextSpan(
            text: parts.sublist(1).join('-').trim(),
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Düzenle',
                  onPressed: _editProduct,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Sil',
                  onPressed: _deleteProduct,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: _buildRichTextTitle(widget.product.name),
                centerTitle: true,
                titlePadding: const EdgeInsets.only(
                  left: 48.0,
                  right: 48.0,
                  bottom: 56.0, // TabBar yüksekliği kadar boşluk
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.product.imageUrl != null &&
                            widget.product.imageUrl!.isNotEmpty
                        ? Hero(
                            tag: 'productImage_${widget.product.id}',
                            child: Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.contain,
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
                            color: AppColors.secondary.withAlpha(100),
                            child: const Icon(
                              Icons.shopping_bag,
                              size: 100,
                              color: AppColors.white,
                            ),
                          ),
                    // Arka plan karartması (scrim)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: AppColors.textOnPrimary.withAlpha(179),
                indicatorColor: AppColors.accent,
                tabs: const [
                  Tab(text: 'Genel Bakış'),
                  Tab(text: 'Özellikler'),
                  Tab(text: 'Kullanım'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context),
            _buildFeaturesTab(context),
            _buildUsageInfoTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({required List<Widget> children}) {
    return ListView(padding: const EdgeInsets.all(16.0), children: children);
  }

  Widget _buildOverviewTab(BuildContext context) {
    return _buildTabContent(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(
                '${widget.product.vp.toStringAsFixed(2)} VP',
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            if (widget.product.price != null)
              Text(
                '${widget.product.price!.toStringAsFixed(2)} TL',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.product.stockNo != null &&
            widget.product.stockNo!.isNotEmpty) ...[
          Text(
            'Stok No: ${widget.product.stockNo}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.product.category != null &&
            widget.product.category!.isNotEmpty) ...[
          Text(
            'Kategori: ${widget.product.category}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
        _buildDetailSection(context, 'Genel Bakış', widget.product.overview),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: const Text('Siparişe Ekle'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.product.name} siparişe eklenecek (henüz değil).',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeaturesTab(BuildContext context) {
    return _buildTabContent(
      children: [
        _buildDetailSection(
          context,
          'Özellikler',
          widget.product.features,
          isFirst: true,
        ),
        if (widget.product.features == null || widget.product.features!.isEmpty)
          const Center(child: Text('Bu ürün için özellik bilgisi bulunmuyor.')),
      ],
    );
  }

  Widget _buildUsageInfoTab(BuildContext context) {
    return _buildTabContent(
      children: [
        _buildDetailSection(
          context,
          'Kullanım Bilgisi',
          widget.product.usageInfo,
          isFirst: true,
        ),
        if (widget.product.usageInfo == null ||
            widget.product.usageInfo!.isEmpty)
          const Center(
            child: Text('Bu ürün için kullanım bilgisi bulunmuyor.'),
          ),
      ],
    );
  }
}
