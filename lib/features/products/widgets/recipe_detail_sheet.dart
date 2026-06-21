import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/cloudinary_helper.dart';
import '../../../../models/recipe_model.dart';

/// Stitch tasarımına uygun tam ekran tarif detay sayfası.
/// SliverAppBar ile parallax efektli hero görsel ve pinned başlık sunar.
class RecipeDetailPage extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  /// Hedef badge renk ve etiketini belirler.
  static const _goalLabels = {
    'weight_loss': 'Kilo Ver',
    'weight_gain': 'Kilo Al',
  };

  String get _goalLabel {
    for (final entry in _goalLabels.entries) {
      if (recipe.goals.contains(entry.key)) return entry.value;
    }
    return 'Sağlıklı Yaşam';
  }

  Color get _goalColor {
    if (recipe.goals.contains('weight_loss')) return AppColors.grass;
    if (recipe.goals.contains('weight_gain')) return Colors.blue;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Başlık
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Süre, Kalori ve Hedef Badge
                  _buildBadgeRow(),
                  const SizedBox(height: 16),
                  // Açıklama
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Besin Değerleri
                  if (recipe.nutritionInfo != null) ...[
                    _buildSectionTitle('💊', 'Besin Değerleri'),
                    const SizedBox(height: 12),
                    _buildNutritionGrid(),
                    const SizedBox(height: 28),
                  ],
                  // Malzemeler
                  _buildSectionTitle('🛒', 'Malzemeler'),
                  const SizedBox(height: 16),
                  _buildIngredientsList(),
                  const SizedBox(height: 28),
                  // Hazırlanış
                  _buildSectionTitle('📝', 'Hazırlanışı'),
                  const SizedBox(height: 16),
                  _buildStepsList(),
                  const SizedBox(height: 20),
                  // İpucu
                  if (recipe.tips != null) ...[
                    _buildTipBox(),
                    const SizedBox(height: 24),
                  ],
                  // Alt boşluk (safe area)
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SliverAppBar: Parallax efektli hero görsel, scroll ile daralan başlık.
  Widget _buildSliverAppBar(BuildContext context) {
    const expandedHeight = 340.0;
    final imageUrl = CloudinaryHelper.optimizeImage(recipe.imageUrl);
    final hasVideo = recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: _buildCircularBackButton(context),
      title: null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Daraltma oranı: 1.0 = tamamen açık, 0.0 = tamamen kapalı
          final top = constraints.biggest.height;
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final minExtent = kToolbarHeight + statusBarHeight;
          final maxExtent = expandedHeight + statusBarHeight;
          final shrinkRatio = ((top - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);
          final isCollapsed = shrinkRatio < 0.15;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
            title: AnimatedOpacity(
              opacity: isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero Görsel
                if (hasVideo)
                  _RecipeVideoPlayer(
                    videoUrl: CloudinaryHelper.optimizeVideo(recipe.videoUrl!) ?? recipe.videoUrl!,
                    posterUrl: CloudinaryHelper.videoPoster(recipe.videoUrl!) ?? imageUrl,
                  )
                else if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.primary.withAlpha(25),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.primary.withAlpha(25),
                      child: const Center(
                        child: Icon(Icons.blender, size: 64, color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.primary.withAlpha(25),
                    child: const Center(
                      child: Icon(Icons.blender, size: 64, color: AppColors.primary),
                    ),
                  ),

                // Alt gradient — başlık okunabilirliği ve geçiş yumuşaklığı
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(80),
                        ],
                      ),
                    ),
                  ),
                ),

                // Resmin altında shake ismi (expanded durumda)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: AnimatedOpacity(
                    opacity: isCollapsed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Yuvarlak, yarı-saydam geri butonu.
  Widget _buildCircularBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(60),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  /// Süre, kalori ve hedef badge satırı.
  Widget _buildBadgeRow() {
    return Row(
      children: [
        _buildInfoPill(Icons.timer_outlined, '${recipe.prepTimeMin} dk'),
        const SizedBox(width: 8),
        _buildInfoPill(Icons.local_fire_department_outlined, '${recipe.calories} kcal'),
        const Spacer(),
        _buildGoalBadge(_goalLabel, _goalColor),
      ],
    );
  }

  /// Yuvarlak köşeli bilgi pill badge.
  Widget _buildInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Hedef badge (Kilo Al / Kilo Ver / Sağlıklı Yaşam).
  Widget _buildGoalBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Bölüm başlığı (emoji + metin).
  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// 4 sütunlu besin değerleri grid (Stitch tasarımına uygun).
  Widget _buildNutritionGrid() {
    final nutrition = recipe.nutritionInfo!;
    final items = [
      _NutritionData('Protein', '${nutrition.protein}g'),
      _NutritionData('Karb', '${nutrition.carbs}g'),
      _NutritionData('Yağ', '${nutrition.fat}g'),
      _NutritionData('Lif', '${nutrition.fiber}g'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => Column(
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  /// Malzeme listesi — Stitch formatı: ad solda, miktar sağda, not alt satırda.
  Widget _buildIngredientsList() {
    return Column(
      children: recipe.ingredients
          .map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yeşil bullet
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Malzeme adı
                    Expanded(
                      child: Text(
                        ing.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Miktar + not
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ing.amount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (ing.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ing.note!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Hazırlanış adımları — yeşil numaralı daireler.
  Widget _buildStepsList() {
    return Column(
      children: recipe.steps.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// İpucu kutusu — turuncu tonlarda.
  Widget _buildTipBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İpucu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.tips!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Besin değeri veri sınıfı.
class _NutritionData {
  final String label;
  final String value;
  const _NutritionData(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Oynatıcı — mevcut fonksiyonalite korundu
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;

  const _RecipeVideoPlayer({required this.videoUrl, this.posterUrl});

  @override
  State<_RecipeVideoPlayer> createState() => _RecipeVideoPlayerState();
}

class _RecipeVideoPlayerState extends State<_RecipeVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _loading = false;
  bool _showControls = true;

  Future<void> _initialize() async {
    if (_loading || _initialized) return;
    setState(() => _loading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      controller.addListener(_onTick);
      setState(() {
        _initialized = true;
        _loading = false;
      });
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
      _showControls = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.posterUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(color: AppColors.background),
            ),
          Container(color: Colors.black.withAlpha(80)),
          Center(
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : IconButton(
                    tooltip: 'Videoyu oynat',
                    iconSize: 64,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    onPressed: _initialize,
                  ),
          ),
        ],
      );
    }

    final c = _controller!;
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          if (_showControls) ...[
            Container(color: Colors.black.withAlpha(60)),
            Center(
              child: IconButton(
                tooltip: c.value.isPlaying ? 'Duraklat' : 'Oynat',
                iconSize: 56,
                icon: Icon(
                  c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: _togglePlay,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
