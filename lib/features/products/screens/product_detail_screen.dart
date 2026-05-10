import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart'; // Renkler için
import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  static const String routeName = 'product-detail';
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProductDetails();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId) {
      _fetchProductDetails();
    }
  }

  void _fetchProductDetails() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    try {
      final product = productProvider.products.firstWhere(
        (p) => p.id == widget.productId,
      );
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ürün bulunamadı.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    if (_product == null) return;
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
          '${_product!.name} ürününü silmek istediğinizden emin misiniz?',
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
      try {
        await productProvider.deleteProduct(_product!.id);
        if (!mounted) return; // Widget hala ağaçta mı kontrol et
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("'${_product!.name}' silindi."),
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
    if (_product == null) return;
    context.goNamed(AddEditProductScreen.routeName, extra: _product);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ürün yüklenemedi.')),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCustomer = authProvider.userProfile?.role == UserRole.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (!isCustomer)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editProduct,
              tooltip: 'Düzenle',
            ),
          if (!isCustomer)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteProduct,
              tooltip: 'Sil',
              color: Colors.red,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(height: 24),
              _buildProductInfo(),
              const SizedBox(height: 24),
              _buildSectionTitle('Açıklama'),
              const SizedBox(height: 8),
              _buildDescription(),
              const SizedBox(height: 24),
              _buildSectionTitle('İçindekiler'),
              const SizedBox(height: 8),
              _buildIngredients(),
              const SizedBox(height: 24),
              _buildSectionTitle('Kullanım Bilgisi'),
              const SizedBox(height: 8),
              _buildUsage(),
              const SizedBox(height: 24),
              _buildReviewsSection(),
              const SizedBox(height: 24),
              _buildRelatedProductsSection(),
              const SizedBox(height: 90), // For bottom button spacing
            ],
          ),
        ),
      ),
      bottomSheet: _buildAddToCartButton(),
    );
  }

  Widget _buildProductImage() {
    return Center(
      child: _product!.imageUrl != null && _product!.imageUrl!.isNotEmpty
          ? Image.network(
              _product!.imageUrl!,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 60),
              ),
            )
          : Container(
              height: 250,
              color: Colors.grey[200],
              child: const Icon(Icons.shopping_bag, size: 60),
            ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'A delicious and nutritious meal replacement shake that provides essential nutrients and helps support weight management.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDescription() {
    return Text(
      _product!.overview ??
          "Our Formula 1 shake is a blend of high-quality protein, fiber, vitamins, and minerals. It's designed to provide a balanced meal replacement that supports healthy weight management and overall well-being.",
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }

  Widget _buildIngredients() {
    // Dummy data for now
    final ingredients =
        'Soy protein isolate, fructose, cellulose powder, corn bran, guar gum, calcium caseinate, potassium phosphate, magnesium oxide, vitamin C, vitamin E, niacinamide, ferrous fumarate, zinc oxide, vitamin A palmitate, copper gluconate, calcium pantothenate, pyridoxine hydrochloride, thiamine hydrochloride, riboflavin, folic acid, potassium iodide, biotin, vitamin B12.';
    return Text(
      _product!.ingredients ?? ingredients,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }

  Widget _buildUsage() {
    return Text(
      _product!.usageInfo ??
          'Mix 2 scoops (25g) with 8 fl oz of nonfat milk or soy milk. Blend or shake well. Enjoy as a meal replacement or a healthy snack.',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Değerlendirmeler'),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('4.5', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 30),
            const SizedBox(width: 16),
            const Text('125 reviews'),
          ],
        ),
        const SizedBox(height: 16),
        _buildRatingBar(5, 0.4),
        _buildRatingBar(4, 0.3),
        _buildRatingBar(3, 0.15),
        _buildRatingBar(2, 0.10),
        _buildRatingBar(1, 0.05),
        const SizedBox(height: 24),
        _buildReviewItem(
          'Sophia Bennett',
          '2 weeks ago',
          'I love this shake! It\'s delicious and keeps me full for hours. I\'ve been using it for a month and have already seen great results.',
        ),
        const SizedBox(height: 16),
        _buildReviewItem(
          'Ethan Carter',
          '1 month ago',
          'This shake is a convenient and healthy option for busy days. The taste is good, and it\'s easy to prepare.',
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$star'),
          const SizedBox(width: 8),
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(percentage * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String date, String review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(
                5,
                (index) => Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(review),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.thumb_up_alt_outlined, size: 18),
            const SizedBox(width: 4),
            const Text('15'),
            const SizedBox(width: 16),
            const Icon(Icons.thumb_down_alt_outlined, size: 18),
            const SizedBox(width: 4),
            const Text('2'),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final allProducts = productProvider.products;
    final relatedProducts = allProducts
        .where((p) => p.id != _product!.id)
        .toList();

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İlgili Ürünler'),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              return _buildRelatedProductItem(relatedProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductItem(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detail screen of the tapped product
        context.pushNamed(
          ProductDetailScreen.routeName,
          pathParameters: {'productId': product.id},
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              color: Colors.grey[200],
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image, size: 40)),
                    )
                  : const Center(child: Icon(Icons.image, size: 40)),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product.category ?? 'Snack',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Sepete Ekle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
