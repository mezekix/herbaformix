import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/product_model.dart';
import '../../orders/providers/cart_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../products/screens/recipes_list_screen.dart';
import '../../../widgets/cached_product_image.dart';

/// Müşteri "Ürünler" sekmesi — İç/Dış Beslenme ürün kataloğu (embedded, AppBar yok)
class CustomerProductsScreen extends StatefulWidget {
  const CustomerProductsScreen({super.key});

  @override
  State<CustomerProductsScreen> createState() => _CustomerProductsScreenState();
}

class _CustomerProductsScreenState extends State<CustomerProductsScreen> {
  static const _visibleCategories = {'İç Beslenme', 'Dış Beslenme'};
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  bool _isGridView = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _getFilteredProducts(
    List<ProductModel> all,
    Set<String> favoriteIds,
  ) {
    var filtered = all
        .where(
          (p) => p.category == null || _visibleCategories.contains(p.category),
        )
        .toList();

    if (_selectedCategory == 'Favoriler') {
      filtered = filtered.where((p) => favoriteIds.contains(p.id)).toList();
    } else if (_selectedCategory != 'Tümü') {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final isLoading = context.watch<ProductProvider>().isLoading;
    final favoriteIds = context.watch<FavoritesProvider>().favoriteIds(
      FavoriteType.product,
    );
    final filtered = _getFilteredProducts(products, favoriteIds);

    final categories = ['Tümü', 'Favoriler', ..._visibleCategories];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ürünler',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.nightSky,
                        ),
                      ),
                    ],
                  ),
                ),
                // Shopping Cart Badge Button
                Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return Badge(
                      label: Text('${cart.itemCount}'),
                      isLabelVisible: cart.itemCount > 0,
                      backgroundColor: AppColors.accent,
                      textColor: AppColors.nightSky,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          tooltip: 'Sepete git',
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            context.push('/home/cart');
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Görünüm toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _ViewToggleButton(
                        icon: Icons.view_list_rounded,
                        isActive: !_isGridView,
                        onTap: () => setState(() => _isGridView = false),
                      ),
                      _ViewToggleButton(
                        icon: Icons.grid_view_rounded,
                        isActive: _isGridView,
                        onTap: () => setState(() => _isGridView = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarif Kitabı Banner'ı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecipesListScreen()),
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
                      child: const Text('🥤', style: TextStyle(fontSize: 24)),
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
          const SizedBox(height: 16),

          // Arama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ürün ara...',
                  hintStyle: TextStyle(
                    color: AppColors.textMutedLight,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMutedLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Aramayı temizle',
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Kategori filtreleri
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.backgroundMuted,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat == 'Favoriler') ...[
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Ürün listesi
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.textMutedLighter,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          products.isEmpty
                              ? 'Henüz ürün eklenmemiş'
                              : 'Ürün bulunamadı',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _ProductGridCard(product: product);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _ProductCard(product: product);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ürün görseli
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedProductImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Ürün bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nightSky,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: product.category == 'İç Beslenme'
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: product.category == 'İç Beslenme'
                              ? AppColors.primary
                              : Colors.purple.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // VP & Add to Cart
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.vp > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMutedLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${product.vp.toStringAsFixed(0)} VP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Sepete ekle',
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    context.read<CartProvider>().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} sepete eklendi!'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ), // Container
    ); // GestureDetector
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün görseli
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedProductImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Ürün adı
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.nightSky,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Kategori + VP + Sepete Ekle satırı
            Row(
              children: [
                if (product.category != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.category == 'İç Beslenme'
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: product.category == 'İç Beslenme'
                              ? AppColors.primary
                              : Colors.purple.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (product.vp > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${product.vp.toStringAsFixed(0)} VP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    context.read<CartProvider>().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} sepete eklendi!'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
