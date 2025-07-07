import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter import'u
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
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

  void _setupCategories() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final allProducts = productProvider.products;
    final uniqueCategories = allProducts
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
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

    List<ProductModel> tempProducts = allProducts;

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

    // build içinde filtreleme yapmak, provider güncellendiğinde ekranın da güncellenmesini sağlar.
    _filterProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
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
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: Hero(
                            tag: 'productImage_${product.id}',
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? NetworkImage(product.imageUrl!)
                                  : null,
                              child:
                                  product.imageUrl == null ||
                                      product.imageUrl!.isEmpty
                                  ? const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'VP: ${product.vp.toStringAsFixed(2)} - Fiyat: ${product.price?.toStringAsFixed(2) ?? 'N/A'} TL',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            context.pushNamed(
                              ProductDetailScreen.routeName,
                              pathParameters: {'productId': product.id},
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
