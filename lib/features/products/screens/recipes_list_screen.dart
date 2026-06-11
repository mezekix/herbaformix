import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGoal = 'all'; // 'all', 'weight_loss', 'weight_gain', 'healthy_living'

  final List<Map<String, String>> _goals = [
    {'key': 'all', 'label': 'Tüm Tarifler'},
    {'key': 'weight_loss', 'label': 'Kilo Verme'},
    {'key': 'weight_gain', 'label': 'Kilo Alma'},
    {'key': 'healthy_living', 'label': 'Sağlıklı Yaşam'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Tariflerin yüklendiğinden emin olmak için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final recipes = recipeProvider.recipes;
    final isLoading = recipeProvider.isLoading;

    // Filtreleme mantığı
    var filteredRecipes = recipes;
    
    // Hedef Filtreleme
    if (_selectedGoal != 'all') {
      filteredRecipes = filteredRecipes.where((r) => r.goals.contains(_selectedGoal)).toList();
    }

    // Arama Filtreleme
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredRecipes = filteredRecipes.where((r) {
        final titleMatch = r.title.toLowerCase().contains(query);
        final descMatch = r.description.toLowerCase().contains(query);
        final tagMatch = r.tags.any((t) => t.toLowerCase().contains(query));
        final ingredientMatch = r.ingredients.any((i) => i.name.toLowerCase().contains(query));
        return titleMatch || descMatch || tagMatch || ingredientMatch;
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Shake Tarif Dünyası',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.nightSky),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.nightSky, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tarif veya malzeme ara...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Hedef Filtreleme Chip'leri
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoal == goal['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: FilterChip(
                    label: Text(goal['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGoal = selected ? goal['key']! : 'all';
                      });
                    },
                    selectedColor: AppColors.primary.withAlpha(40),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Tarif Listesi
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.blender_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Aradığınız kriterlere uygun tarif bulunamadı.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: filteredRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = filteredRecipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            isGrid: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
