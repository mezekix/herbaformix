import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/recipe_provider.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../products/widgets/recipe_card.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  static const routeName = 'favorites';

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final productIds = favorites.favoriteIds(FavoriteType.product);
    final recipeIds = favorites.favoriteIds(FavoriteType.recipe);
    final products = context.watch<ProductProvider>().products.where((item) => productIds.contains(item.id)).toList();
    final recipes = context.watch<RecipeProvider>().recipes.where((item) => recipeIds.contains(item.id)).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Favorilerim'), bottom: const TabBar(tabs: [Tab(text: 'Ürünler'), Tab(text: 'Tarifler')])),
        body: TabBarView(children: [
          products.isEmpty
              ? const _EmptyFavorites('Henüz favori ürününüz yok.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: products.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    title: Text(products[index].name), trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('${ProductDetailScreen.routeName}/${products[index].id}'),
                  )),
          recipes.isEmpty
              ? const _EmptyFavorites('Henüz favori tarifiniz yok.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: recipes.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecipeCard(recipe: recipes[index], isHorizontal: true),
                  )),
        ]),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.favorite_outline, size: 52, color: AppColors.grey600),
    const SizedBox(height: 12), Text(message),
  ]));
}
