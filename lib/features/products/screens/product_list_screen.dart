import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter import'u
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../orders/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import './add_edit_product_screen.dart'; // AddEditProductScreen'i import et
import './add_shake_recipe_screen.dart';
import './product_detail_screen.dart'; // ProductDetailScreen'i import et
import './recipes_list_screen.dart';
import '../../../widgets/cached_product_image.dart';

class ProductListScreen extends StatefulWidget {
  static const String routeName =
      '/products'; // Ana rota olarak kalabilir veya '/home/products' için 'products'
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool _isGridView = false; // Görünüm modunu takip et

  @override
  void initState() {
    super.initState();

    // Arama metni değiştikçe listeyi filtrele
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // Müşterilere yalnızca bu kategoriler gösterilir
  static const _customerVisibleCategories = {'İç Beslenme', 'Dış Beslenme'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isCustomer = authProvider.userProfile?.role == UserRole.customer;
    final favorites = context.watch<FavoritesProvider>();
    final favoriteIds = favorites.favoriteIds(FavoriteType.product);
    final allProducts = productProvider.products;

    // Kategorileri hesapla
    final uniqueCategories = allProducts
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        // Müşteri ise sadece iç/dış beslenme kategorilerini göster
        .where((c) => !isCustomer || _customerVisibleCategories.contains(c))
        .toSet()
        .toList();
    uniqueCategories.sort();
    final categories = ['Tümü', 'Favoriler', ...uniqueCategories];

    // Ürünleri filtrele
    List<ProductModel> filteredProducts = allProducts;
    if (isCustomer) {
      filteredProducts = filteredProducts
          .where(
            (product) =>
                product.category != null &&
                _customerVisibleCategories.contains(product.category),
          )
          .toList();
    }

    // 1. Kategoriye göre filtrele
    if (_selectedCategory == 'Favoriler') {
      filteredProducts = filteredProducts
          .where((product) => favoriteIds.contains(product.id))
          .toList();
    } else if (_selectedCategory != 'Tümü') {
      filteredProducts = filteredProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // 2. Arama metnine göre filtrele
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(isCustomer ? 'Ürün Kataloğu' : 'Ürünler'),
            pinned: true,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                tooltip: _isGridView ? 'Liste görünümü' : 'Izgara görünümü',
                icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Badge(
                    label: Text('${cart.itemCount}'),
                    isLabelVisible: cart.itemCount > 0,
                    backgroundColor: AppColors.accent,
                    textColor: AppColors.nightSky,
                    child: IconButton(
                      tooltip: 'Sepete git',
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        context.push('/home/cart');
                      },
                    ),
                  );
                },
              ),
              if (!isCustomer)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Yeni Ürün Ekle',
                  onPressed: () {
                    context.goNamed(AddEditProductScreen.routeName);
                  },
                ),
              if (!isCustomer)
                IconButton(
                  icon: const Icon(Icons.blender_outlined),
                  tooltip: 'Shake Tarifi Ekle',
                  onPressed: () {
                    context.goNamed(AddShakeRecipeScreen.routeName);
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Shake Tarif Kitabı Banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecipesListScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.grass],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '🥤',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shake Tarif Kitabı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Birbirinden lezzetli Formül 1 tariflerini keşfet!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Ürün Ara',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Aramayı temizle',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(204),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (productProvider.isLoading && filteredProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'Henüz ürün eklenmemiş.'
                      : 'Aramanızla eşleşen ürün bulunamadı.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          else if (_isGridView)
            _buildSliverGridView(filteredProducts, isCustomer: isCustomer)
          else
            _buildSliverListView(filteredProducts, isCustomer: isCustomer),
        ],
      ),
    );
  }

  Widget _buildSliverListView(
    List<ProductModel> filteredProducts, {
    required bool isCustomer,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final product = filteredProducts[index];
        return _buildListItem(product, isCustomer: isCustomer);
      }, childCount: filteredProducts.length),
    );
  }

  Widget _buildListItem(ProductModel product, {required bool isCustomer}) {
    return _buildModernListItem(product, isCustomer: isCustomer);
  }

  Widget _buildModernListItem(
    ProductModel product, {
    required bool isCustomer,
  }) {
    final detailText = _customerDetailText(product);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shadowColor: AppColors.garden.withValues(alpha: 0.16),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F8EE)],
          ),
        ),
        child: InkWell(
          onTap: () {
            context.pushNamed(
              ProductDetailScreen.routeName,
              pathParameters: {'productId': product.id},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'productImage_${product.id}',
                  child: Container(
                    width: 108,
                    height: 132,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.1,
                        colors: [Color(0xFFFFFFFF), Color(0xFFEAF3DF)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.garden.withValues(alpha: 0.13),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 8,
                          left: 7,
                          child: Icon(
                            Icons.eco_outlined,
                            size: 34,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                          child: CachedProductImage(
                            imageUrl: product.imageUrl,
                            width: 100,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 132),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Consumer<FavoritesProvider>(
                              builder: (context, favorites, _) {
                                final isFavorite = favorites.isFavorite(
                                  FavoriteType.product,
                                  product.id,
                                );
                                return IconButton(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 36,
                                    height: 36,
                                  ),
                                  padding: EdgeInsets.zero,
                                  tooltip: isFavorite
                                      ? 'Favorilerden çıkar'
                                      : 'Favorilere ekle',
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: isFavorite
                                        ? AppColors.garden
                                        : AppColors.textSecondary,
                                  ),
                                  onPressed: () => favorites.toggle(
                                    FavoriteType.product,
                                    product.id,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detailText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (!isCustomer)
                              Text(
                                '${(product.price ?? 0).toStringAsFixed(2)} ₺',
                                style: const TextStyle(
                                  color: AppColors.garden,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                context.pushNamed(
                                  ProductDetailScreen.routeName,
                                  pathParameters: {'productId': product.id},
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.garden,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                              ),
                              label: const Text(
                                'Ayrıntıları gör',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _customerDetailText(ProductModel product) {
    final overview = product.overview?.trim();
    if (overview != null && overview.isNotEmpty) return overview;

    final usageInfo = product.usageInfo?.trim();
    if (usageInfo != null && usageInfo.isNotEmpty) return usageInfo;

    return 'Ürün özelliklerini ve kullanım önerilerini inceleyin.';
  }

  Widget _buildSliverGridView(
    List<ProductModel> filteredProducts, {
    required bool isCustomer,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.all(10.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = filteredProducts[index];
          return _buildGridItem(product, isCustomer: isCustomer);
        }, childCount: filteredProducts.length),
      ),
    );
  }

  Widget _buildGridItem(ProductModel product, {required bool isCustomer}) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          ProductDetailScreen.routeName,
          pathParameters: {'productId': product.id},
        );
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'productImage_${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.backgroundMutedLight, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: CachedProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.name}\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCustomer)
                        Text(
                          '${(product.price ?? 0).toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favorites, _) => IconButton(
                          tooltip:
                              favorites.isFavorite(
                                FavoriteType.product,
                                product.id,
                              )
                              ? 'Favorilerden çıkar'
                              : 'Favorilere ekle',
                          icon: Icon(
                            favorites.isFavorite(
                                  FavoriteType.product,
                                  product.id,
                                )
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          onPressed: () => favorites.toggle(
                            FavoriteType.product,
                            product.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
