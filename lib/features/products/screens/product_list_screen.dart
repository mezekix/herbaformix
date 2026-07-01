import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter import'u
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import './add_edit_product_screen.dart'; // AddEditProductScreen'i import et
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
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = '';
  List<String> _categories = ['Tümü'];
  String _selectedCategory = 'Tümü';
  bool _isGridView = false; // Görünüm modunu takip et

  @override
  void initState() {
    super.initState();
    // Başlangıçta tüm ürünleri göster
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    _filteredProducts = productProvider.products;

    // Arama metni değiştikçe listeyi filtrele
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterProducts();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupCategories();
    _filterProducts();
  }

  // Müşterilere yalnızca bu kategoriler gösterilir
  static const _customerVisibleCategories = {'İç Beslenme', 'Dış Beslenme'};

  bool _isCustomer() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userProfile?.role == UserRole.customer;
  }

  void _setupCategories() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final allProducts = productProvider.products;
    final isCustomer = _isCustomer();

    final uniqueCategories = allProducts
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        // Müşteri ise sadece iç/dış beslenme kategorilerini göster
        .where((c) => !isCustomer || _customerVisibleCategories.contains(c))
        .toSet()
        .toList();
    uniqueCategories.sort();
    setState(() {
      _categories = ['Tümü', ...uniqueCategories];
    });
  }

  void _filterProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final allProducts = productProvider.products;
    final isCustomer = _isCustomer();

    List<ProductModel> tempProducts = allProducts;

    // Müşteri ise basılı malzeme ve tanıtım ürünlerini gizle
    if (isCustomer) {
      tempProducts = tempProducts
          .where(
            (product) =>
                product.category != null &&
                _customerVisibleCategories.contains(product.category),
          )
          .toList();
    }

    // 1. Kategoriye göre filtrele
    if (_selectedCategory != 'Tümü') {
      tempProducts = tempProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // 2. Arama metnine göre filtrele
    if (_searchQuery.isNotEmpty) {
      tempProducts = tempProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      _filteredProducts = tempProducts;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // build içinde çağırmak, provider güncellendiğinde ekranın da güncellenmesini sağlar.
    _setupCategories();
    _filterProducts();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCustomer = authProvider.userProfile?.role == UserRole.customer;

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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _filterProducts();
                            });
                          },
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(204),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
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
          if (productProvider.isLoading && _filteredProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredProducts.isEmpty)
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
            _buildSliverGridView()
          else
            _buildSliverListView(),
        ],
      ),
    );
  }

  Widget _buildSliverListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = _filteredProducts[index];
          return _buildListItem(product);
        },
        childCount: _filteredProducts.length,
      ),
    );
  }

  Widget _buildListItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: Hero(
          tag: 'productImage_${product.id}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.backgroundMutedLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: CachedProductImage(
                imageUrl: product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: Text(
          'Fiyat: ${(product.price ?? 0).toStringAsFixed(2)} ₺',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Sepete ekle',
              icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ],
        ),
        onTap: () {
          context.pushNamed(
            ProductDetailScreen.routeName,
            pathParameters: {'productId': product.id},
          );
        },
      ),
    );
  }

  Widget _buildSliverGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(10.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return _buildGridItem(product);
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildGridItem(ProductModel product) {
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(product.price ?? 0).toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sepete ekle',
                        icon: const Icon(Icons.add_shopping_cart, size: 20, color: AppColors.primary),
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
