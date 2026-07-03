import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart'; // Renkler için
import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../../orders/providers/cart_provider.dart';
import 'add_edit_product_screen.dart';
import '../../../widgets/cached_product_image.dart';
import 'product_image_viewer_screen.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';

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
  List<ProductModel> _relatedProducts = [];
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCustomer = authProvider.userProfile?.role == UserRole.customer;

    try {
      final product = productProvider.products.firstWhere(
        (p) => p.id == widget.productId,
      );
      setState(() {
        _product = product;
        
        const visibleCategories = {'İç Beslenme', 'Dış Beslenme'};
        // Benzer ürünleri hazırla (kendisi hariç, müşteri ise sadece izinli kategoriler, karıştırılmış ve ilk 6 ürün)
        _relatedProducts = productProvider.products
            .where((p) => p.id != product.id)
            .where((p) => !isCustomer || (p.category != null && visibleCategories.contains(p.category)))
            .toList()
          ..shuffle();
        if (_relatedProducts.length > 6) {
          _relatedProducts = _relatedProducts.sublist(0, 6);
        }
        
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isCustomer),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildRecipeSuggestions(),
                  const SizedBox(height: 24),
                  _buildRelatedProductsSection(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildAddToCartButton(),
    );
  }

  Widget _buildSliverAppBar(bool isCustomer) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      leading: IconButton(
        tooltip: 'Geri',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      // Üst bar'da title YOK — isim FlexibleSpaceBar.title'da
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
      flexibleSpace: FlexibleSpaceBar(
        // Ürün ismi: açıkken altta, scroll'da yukarıya taşınır
        title: Text(
          _product!.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsetsDirectional.only(
          start: 56,
          bottom: 16,
          end: 56,
        ),
        collapseMode: CollapseMode.pin,
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 60, bottom: 48),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  pageBuilder: (_, _, _) => ProductImageViewerScreen(
                    imageUrl: _product!.imageUrl,
                    heroTag: 'productImage_${_product!.id}',
                    productName: _product!.name,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'productImage_${_product!.id}',
              child: CachedProductImage(
                imageUrl: _product!.imageUrl,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildRecipeSuggestions() {
    final recipes = context.watch<RecipeProvider>().getRecipesForProduct(_product!);
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🥤 Tarif Önerileri'),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(recipe: recipes[index], isHorizontal: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection() {
    if (_relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İlgi Duyabilirsiniz'),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedProducts.length,
            itemBuilder: (context, index) {
              return _buildRelatedProductItem(_relatedProducts[index]);
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
              color: AppColors.backgroundMuted,
              child: CachedProductImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
    if (_product == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            context.read<CartProvider>().addItem(_product!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_product!.name} sepete eklendi!'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Sepete Git',
                  textColor: Colors.white,
                  onPressed: () {
                    context.push('/home/cart');
                  },
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
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
