import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/cloudinary_helper.dart';
import '../../../../models/recipe_model.dart';

/// Stitch tasarımına uygun tam ekran tarif detay sayfası.
/// SliverAppBar ile parallax efektli hero görsel ve pinned başlık sunar.
class RecipeDetailPage extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late final ScrollController _scrollController;

  RecipeModel get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const expandedHeight = 340.0;
    final imageUrl = CloudinaryHelper.optimizeImage(recipe.imageUrl);
    final hasVideo = recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFC4C4C4), // Gri arkaplan
      body: Stack(
        children: [
          // 1. Arkaplan Resmi (Hero Görsel) - Scroll ile birlikte hareket eder (Parallax)
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
              return Positioned(
                top: offset > 0 ? -offset : 0, // Parallax yerine normal hızda yukarı kaysın ve kaybolsun
                left: 0,
                right: 0,
                height: expandedHeight + (offset < 0 ? -offset : 0), // Yukarı çekerken stretch efekti
                child: child!,
              );
            },
            child: _buildHeroBackground(hasVideo, imageUrl),
          ),
          
          // 2. Kaydırılabilir İçerik
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // İçerik ve alt dekorasyon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Beyaz Kart
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // Altta 24px padding bıraktık
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  // İpucu
                                  if (recipe.tips != null) ...[
                                    const SizedBox(height: 24),
                                    _buildTipBox(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Alt Dekorasyon Barı (Beyaz kart bittikten hemen sonra, altında)
                          Padding(
                            padding: const EdgeInsets.only(left: 24), // İçeriğe hizalı
                            child: Container(
                              width: 120,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary, // Primary color yapıldı
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Sağ üstte beyaz karta yapışık sekme (tab)
                      Positioned(
                        right: 32, // Köşeden biraz içeride olsun (radius'a denk gelmesin)
                        top: -22, // Kendi boyu kadar yukarıda olsun ki altı karta yapışsın
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${recipe.calories} kalori (${recipe.prepTimeMin} dk)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(bool hasVideo, String? imageUrl) {
    if (hasVideo) {
      return _RecipeVideoPlayer(
        videoUrl: CloudinaryHelper.optimizeVideo(recipe.videoUrl!) ?? recipe.videoUrl!,
        posterUrl: CloudinaryHelper.videoPoster(recipe.videoUrl!) ?? imageUrl,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
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
      );
    } else {
      return Container(
        color: AppColors.primary.withAlpha(25),
        child: const Center(
          child: Icon(Icons.blender, size: 64, color: AppColors.primary),
        ),
      );
    }
  }

  /// SliverAppBar: Sadece başlık ve kavisli çizgiyi içerir. Arkaplan resmini Stack altından alır.
  Widget _buildSliverAppBar(BuildContext context) {
    const expandedHeight = 260.0; // Overlap'i artırmak için yüksekliği daha da kıstık (340 - 260 = 80px overlap)
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent, // Altındaki resmi göstermek için şeffaf
      foregroundColor: Colors.white,
      elevation: 0,
      leading: _buildCircularBackButton(context),
      title: null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final minExtent = kToolbarHeight + statusBarHeight;
          final maxExtent = expandedHeight + statusBarHeight;
          final shrinkRatio = ((top - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);
          final isCollapsed = shrinkRatio < 0.15;
          
          // Kaydırdıkça Appbar'ın yeşil olmasını sağlayan opacity
          final colorOpacity = (1.0 - shrinkRatio * 1.5).clamp(0.0, 1.0);

          return Container(
            color: AppColors.primary.withAlpha((colorOpacity * 255).toInt()),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Collapsed durumdaki küçük başlık
                Positioned(
                  left: 56,
                  bottom: 16,
                  right: 16,
                  child: AnimatedOpacity(
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
                ),

                // Resmin altında shake ismi (expanded durumda) - Ortalanmış ve Kavisli Çizgili
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: 32, // Yazıyı biraz daha yukarı aldık (kartla arasındaki mesafeyi korumak için)
                  child: AnimatedOpacity(
                    opacity: isCollapsed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Curved Line (Kavisli çizgi)
                          Positioned(
                            bottom: -4, // Yazıya yaklaştırıldı (eski değer -10)
                            left: -12, // Dışarı taşması azaltıldı (eski değer -20)
                            right: -12,
                            child: Container(
                              height: 16,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white, width: 2.5),
                                  left: BorderSide(color: Colors.white, width: 2.5),
                                  right: BorderSide(color: Colors.white, width: 2.5),
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          // Başlık Metni
                          Text(
                            recipe.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16, // Font boyutu 16 yapıldı
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5, // Harf aralığı daraltıldı
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  blurRadius: 24,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
      _NutritionData('PROTEİN', '${nutrition.protein}g'),
      _NutritionData('KARB', '${nutrition.carbs}g'),
      _NutritionData('YAĞ', '${nutrition.fat}g'),
      _NutritionData('LİF', '${nutrition.fiber}g'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // bg-gray-50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5CB85C), // label-green
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E), // text-gray-400
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Yeşil bullet
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5CB85C), // green-500
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Malzeme adı
                    Expanded(
                      child: Text(
                        ing.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242), // text-gray-700
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Miktar + not
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ing.amount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (ing.note != null && ing.note!.isNotEmpty)
                          Text(
                            ing.note!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
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
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF5CB85C), // label-green
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                      color: Color(0xFF575757), // text-gray-600
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
        color: const Color(0xFFFFFDF9), // Çok hafif turuncu
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)), // border-orange-100
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
                const Text(
                  'İpucu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFF57C00), // orange-600/500
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.tips!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE65100),
                    height: 1.4,
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
