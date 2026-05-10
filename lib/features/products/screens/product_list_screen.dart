import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter import'u
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_provider.dart';
import './add_edit_product_screen.dart'; // AddEditProductScreen'i import et
import './product_detail_screen.dart'; // ProductDetailScreen'i import et

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
      appBar: AppBar(
        title: Text(isCustomer ? 'Ürün Kataloğu' : 'Ürünler'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
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
      body: Column(
        children: [
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
          Expanded(
            child: productProvider.isLoading && _filteredProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Henüz ürün eklenmemiş.'
                          : 'Aramanızla eşleşen ürün bulunamadı.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
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
                    colors: [Colors.grey.shade100, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? NetworkImage(product.imageUrl!)
                      : const AssetImage('assets/logo/logo.png')
                            as ImageProvider,
                  backgroundColor:
                      Colors.transparent, // Gradyanın görünmesi için
                ),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Fiyat: ${(product.price ?? 0).toStringAsFixed(2)} ₺',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.pushNamed(
                ProductDetailScreen.routeName,
                pathParameters: {'productId': product.id},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Yan yana 2 ürün
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75, // Kartların en-boy oranı
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildGridItem(product);
      },
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
                      colors: [Colors.grey.shade100, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                        )
                      : Image.asset(
                          'assets/logo/logo.png', // Varsayılan resim
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      // Örnek rating gösterimi
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
