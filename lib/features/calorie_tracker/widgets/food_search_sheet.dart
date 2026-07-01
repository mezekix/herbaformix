import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../services/ai/food_estimation_service.dart';
import '../../../services/repositories/food_repository.dart';
import '../models/food_item.dart';
import '../providers/calorie_provider.dart';

/// Öğün ekleme deneyimi — modal bottom sheet:
/// 1. Üstte arama kutusu (otomatik focus)
/// 2. Türkçe normalize edilmiş filtreli yemek listesi
/// 3. Yemek seçince [_PortionSheet] açılır — porsiyon çarpanı + kalori önizleme
/// 4. En altta "Listede yok mu? Elle ekle" — [_ManualMealSheet] açılır
///
/// Kullanıcının "uğraşmasın" felsefesine uygun:
/// - Otomatik klavye focus
/// - 0.5×/1×/2× hızlı butonlar
/// - Toplam kalori gerçek zamanlı hesaplanır
class FoodSearchSheet extends StatefulWidget {
  const FoodSearchSheet({super.key});

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<FoodItem> _results = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_runSearch);
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text;
    final results = await FoodRepository.instance.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Future<void> _onFoodTap(FoodItem food) async {
    final result = await showModalBottomSheet<_PortionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortionSheet(food: food),
    );
    if (result == null || !mounted) return;

    final provider = Provider.of<CalorieProvider>(context, listen: false);
    await provider.addMeal(result.name, result.calories);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onManualEntryTap() async {
    final result = await showModalBottomSheet<_PortionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualMealSheet(),
    );
    if (result == null || !mounted) return;

    final provider = Provider.of<CalorieProvider>(context, listen: false);
    await provider.addMeal(result.name, result.calories);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onAiEstimateTap() async {
    // Arama kutusundaki metni "ön doldurma" olarak AI sheet'e geçir.
    final initialQuery = _searchController.text.trim();
    final result = await showModalBottomSheet<_PortionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiEstimateSheet(initialQuery: initialQuery),
    );
    if (result == null || !mounted) return;

    final provider = Provider.of<CalorieProvider>(context, listen: false);
    await provider.addMeal(result.name, result.calories);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildList(scrollController)),
              _buildManualLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.textMutedLighter,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Öğün Ekle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Yemek ara… (örn: tavuk, pilav, çay)',
          prefixIcon: const Icon(Icons.search, size: 22),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textMutedLighter),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textMutedLighter),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Aramayı temizle',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _focusNode.requestFocus();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 40, color: AppColors.textMutedLight),
              const SizedBox(height: 8),
              Text(
                'Yemek bulunamadı.',
                style: TextStyle(color: AppColors.grey600),
              ),
              const SizedBox(height: 4),
              Text(
                'Aşağıdaki "Elle ekle" ile manuel girebilirsin.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _foodTile(_results[i]),
    );
  }

  Widget _foodTile(FoodItem food) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _categoryColor(food.category).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _categoryIcon(food.category),
          color: _categoryColor(food.category),
          size: 20,
        ),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${food.servingLabel(1)} • ${food.caloriesPerServing} kcal',
        style: TextStyle(fontSize: 12, color: AppColors.grey600),
      ),
      trailing: const Icon(Icons.add_circle_outline,
          color: AppColors.primary, size: 22),
      onTap: () => _onFoodTap(food),
    );
  }

  Widget _buildManualLink(BuildContext context) {
    final hasAi = FoodEstimationService.isConfigured;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.backgroundMuted)),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline, size: 18, color: AppColors.grey600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Listede yok mu?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey700,
                ),
              ),
            ),
            if (hasAi)
              TextButton.icon(
                onPressed: _onAiEstimateTap,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI tahmin'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            TextButton.icon(
              onPressed: _onManualEntryTap,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Elle ekle'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ana_yemek':
        return Icons.restaurant;
      case 'corba':
        return Icons.soup_kitchen;
      case 'kahvalti':
        return Icons.egg_outlined;
      case 'icecek':
        return Icons.local_drink;
      case 'meyve':
        return Icons.apple;
      case 'sebze':
        return Icons.eco;
      case 'tatli':
        return Icons.cake;
      case 'atistirmalik':
        return Icons.cookie;
      case 'et_urunu':
        return Icons.set_meal;
      case 'sut_urunu':
        return Icons.icecream;
      case 'fast_food':
        return Icons.fastfood;
      default:
        return Icons.lunch_dining;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ana_yemek':
        return Colors.orange.shade700;
      case 'corba':
        return Colors.red.shade400;
      case 'kahvalti':
        return Colors.amber.shade700;
      case 'icecek':
        return Colors.blue.shade400;
      case 'meyve':
        return Colors.pink.shade400;
      case 'sebze':
        return Colors.green.shade600;
      case 'tatli':
        return Colors.purple.shade400;
      case 'atistirmalik':
        return Colors.brown.shade400;
      case 'et_urunu':
        return Colors.red.shade700;
      case 'sut_urunu':
        return Colors.cyan.shade600;
      case 'fast_food':
        return Colors.deepOrange.shade400;
      default:
        return AppColors.grey600;
    }
  }
}

/// Yemek seçildikten sonra porsiyon çarpanı seçimi.
/// 0.5×, 1×, 1.5×, 2× hızlı butonlar + manuel girdi alanı.
class _PortionSheet extends StatefulWidget {
  final FoodItem food;
  const _PortionSheet({required this.food});

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  double _multiplier = 1.0;
  final _customController = TextEditingController();

  static const _quickOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _setMultiplier(double m) {
    setState(() {
      _multiplier = m;
      _customController.clear();
    });
  }

  void _setFromCustom(String value) {
    final v = double.tryParse(value.replaceAll(',', '.'));
    if (v != null && v > 0) {
      setState(() => _multiplier = v);
    }
  }

  void _onConfirm() {
    final food = widget.food;
    final calories = food.caloriesFor(_multiplier);
    final servingText = food.servingLabel(_multiplier);
    Navigator.of(context).pop(_PortionResult(
      name: '${food.name} ($servingText)',
      calories: calories,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final food = widget.food;
    final calories = food.caloriesFor(_multiplier);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textMutedLighter,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Varsayılan: ${food.servingLabel(1)} = ${food.caloriesPerServing} kcal',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ne kadar yedin?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickOptions
                      .map((opt) => _quickChip(opt, food))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Manuel çarpan (örn: 1.3)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: _setFromCustom,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.servingLabel(_multiplier),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$calories kcal',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle,
                          color: AppColors.primary, size: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _onConfirm,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickChip(double mult, FoodItem food) {
    final selected = _multiplier == mult && _customController.text.isEmpty;
    final label = mult == mult.truncateToDouble()
        ? '${mult.toInt()}×'
        : '$mult×';
    return ChoiceChip(
      label: Text(
        '$label  •  ${food.caloriesFor(mult)} kcal',
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: (_) => _setMultiplier(mult),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.textMutedLighter,
      ),
    );
  }
}

/// Listede olmayan yemek için manuel giriş — eski "Öğün Ekle" formu.
class _ManualMealSheet extends StatefulWidget {
  const _ManualMealSheet();

  @override
  State<_ManualMealSheet> createState() => _ManualMealSheetState();
}

class _ManualMealSheetState extends State<_ManualMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_PortionResult(
      name: _nameController.text.trim(),
      calories: int.parse(_caloriesController.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.textMutedLighter,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Elle Öğün Ekle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listede bulamadığın yemekleri kendi yazabilirsin.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Öğün Adı',
                      hintText: 'Örn: Annemin köftesi',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Lütfen bir isim girin.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kalori (kcal)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Kalori miktarı girin.';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Geçerli bir sayı girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onConfirm,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hem porsiyon sheet'i hem manuel sheet için ortak dönüş tipi.
class _PortionResult {
  final String name;
  final int calories;
  const _PortionResult({required this.name, required this.calories});
}

/// Yemek adını alır, Gemini Flash'a gönderir, dönen kalori tahminini önizleme
/// olarak gösterir. Kullanıcı onaylarsa eklenir, düzeltebilir veya iptal eder.
class _AiEstimateSheet extends StatefulWidget {
  final String initialQuery;

  const _AiEstimateSheet({this.initialQuery = ''});

  @override
  State<_AiEstimateSheet> createState() => _AiEstimateSheetState();
}

class _AiEstimateSheetState extends State<_AiEstimateSheet> {
  final _queryController = TextEditingController();
  final _service = FoodEstimationService();

  bool _isLoading = false;
  String? _errorMessage;
  FoodEstimate? _estimate;

  // Kullanıcı onay aşamasında kalori veya ismi düzeltebilir
  final _editNameController = TextEditingController();
  final _editCaloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _editNameController.dispose();
    _editCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _runEstimate() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _estimate = null;
    });
    try {
      final estimate = await _service.estimate(query);
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _editNameController.text = estimate.displayName;
        _editCaloriesController.text = estimate.calories.toString();
      });
    } on FoodEstimationException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Beklenmeyen hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onConfirm() {
    final name = _editNameController.text.trim();
    final calories = int.tryParse(_editCaloriesController.text.trim());
    if (name.isEmpty || calories == null || calories <= 0) {
      setState(() => _errorMessage = 'Geçerli bir isim ve kalori girilmelidir.');
      return;
    }
    Navigator.of(context).pop(_PortionResult(name: name, calories: calories));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textMutedLighter,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AI ile Tahmin',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Yemek adını ve porsiyonunu yaz, kalori tahminini alalım.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _queryController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Yemek',
                    hintText: 'Örn: Annemin köftesi, 2 dilim ev pizzası',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    prefixIcon: const Icon(Icons.restaurant, size: 20),
                  ),
                  onSubmitted: (_) => _runEstimate(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runEstimate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label:
                        Text(_isLoading ? 'Tahmin ediliyor...' : 'Tahmin Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _errorBox(_errorMessage!),
                ],
                if (_estimate != null) ...[
                  const SizedBox(height: 16),
                  _previewBox(_estimate!),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editNameController,
                    decoration: const InputDecoration(
                      labelText: 'İsim (düzenleyebilirsin)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _editCaloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kalori (düzenleyebilirsin)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onConfirm,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBox(FoodEstimate estimate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estimate.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '~${estimate.calories} kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _confidenceBadge(estimate.confidence),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceBadge(String confidence) {
    final color = switch (confidence) {
      'high' => Colors.green.shade700,
      'low' => Colors.orange.shade700,
      _ => AppColors.grey700,
    };
    final label = switch (confidence) {
      'high' => 'yüksek güven',
      'low' => 'düşük güven',
      _ => 'orta güven',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
