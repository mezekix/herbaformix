import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/recipe_model.dart';
import '../providers/recipe_provider.dart';

class AddShakeRecipeScreen extends StatefulWidget {
  static const String routeName = 'add-shake-recipe';

  const AddShakeRecipeScreen({super.key});

  @override
  State<AddShakeRecipeScreen> createState() => _AddShakeRecipeScreenState();
}

class _AddShakeRecipeScreenState extends State<AddShakeRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '5');
  final _caloriesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final _tipsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final Set<String> _selectedGoals = {'healthy_living'};
  bool _isRecommended = false;
  bool _isSaving = false;

  static const _goals = <String, String>{
    'weight_loss': 'Kilo Verme',
    'healthy_living': 'Sağlıklı Yaşam',
    'weight_gain': 'Kilo Alma',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _caloriesController.dispose();
    _tagsController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _tipsController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  List<RecipeIngredient> _parseIngredients() {
    return _ingredientsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          return RecipeIngredient(
            name: parts.first,
            amount: parts.length > 1 ? parts[1] : '',
            note: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
          );
        })
        .toList();
  }

  List<String> _parseLines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String _recipeId(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '${slug.isEmpty ? 'shake' : slug}-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedGoals.isEmpty) {
      if (_selectedGoals.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('En az bir hedef seçin.')));
      }
      return;
    }

    final ingredients = _parseIngredients();
    final steps = _parseLines(_stepsController.text);
    if (ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir malzeme ve hazırlama adımı girin.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final recipe = RecipeModel(
        id: _recipeId(_titleController.text.trim()),
        productId: 'formul1_id',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isEmpty
            ? null
            : _videoUrlController.text.trim(),
        prepTimeMin: int.parse(_prepTimeController.text),
        calories: int.parse(_caloriesController.text),
        goals: _selectedGoals.toList(),
        tags: _parseLines(_tagsController.text.replaceAll(',', '\n')),
        ingredients: ingredients,
        steps: steps,
        tips: _tipsController.text.trim().isEmpty
            ? null
            : _tipsController.text.trim(),
        isRecommended: _isRecommended,
      );
      await context.read<RecipeProvider>().addRecipe(recipe);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shake tarifi yayınlandı.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tarif kaydedilemedi. Yetkinizi ve bağlantınızı kontrol edin.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName zorunludur.';
    return null;
  }

  String? _positiveInt(String? value, String fieldName) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'Geçerli bir $fieldName girin.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shake Tarifi Ekle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tarif yayınlandığında müşteriler programlarını açtıklarında bilgilendirilir.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tarif adı'),
                validator: (value) => _required(value, 'Tarif adı'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Kısa açıklama'),
                minLines: 2,
                maxLines: 4,
                validator: (value) => _required(value, 'Açıklama'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Hazırlama süresi (dk)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _positiveInt(value, 'süre'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(labelText: 'Kalori'),
                      keyboardType: TextInputType.number,
                      validator: (value) => _positiveInt(value, 'kalori'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Uygun hedefler',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                children: _goals.entries.map((entry) {
                  return FilterChip(
                    label: Text(entry.value),
                    selected: _selectedGoals.contains(entry.key),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _selectedGoals.add(entry.key)
                          : _selectedGoals.remove(entry.key);
                    }),
                  );
                }).toList(),
              ),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiketler (virgülle ayırın)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Malzemeler',
                  hintText: 'Muz | 1 adet\nFormül 1 | 2 ölçek | Vanilya',
                ),
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(
                  labelText: 'Hazırlama adımları',
                  hintText: 'Her adımı yeni satıra yazın',
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipsController,
                decoration: const InputDecoration(
                  labelText: 'İpucu (isteğe bağlı)',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL (isteğe bağlı)',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL (isteğe bağlı)',
                ),
                keyboardType: TextInputType.url,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Önerilen tarif olarak göster'),
                value: _isRecommended,
                onChanged: (value) => setState(() => _isRecommended = value),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(_isSaving ? 'Yayınlanıyor...' : 'Tarifi Yayınla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
