import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/cloudinary_helper.dart';
import '../../../../models/recipe_model.dart';

class RecipeDetailSheet extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailSheet({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(76),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarif Görseli / Videosu
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMedia(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık ve Etiketler
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(Icons.timer_outlined, '${recipe.prepTimeMin} dk'),
                      const SizedBox(width: 8),
                      _buildInfoChip(Icons.local_fire_department_outlined, '${recipe.calories} kcal'),
                      const Spacer(),
                      if (recipe.goals.contains('weight_loss'))
                        _buildGoalBadge('Kilo Ver', AppColors.grass)
                      else if (recipe.goals.contains('weight_gain'))
                        _buildGoalBadge('Kilo Al', Colors.blue)
                      else
                        _buildGoalBadge('Sağlıklı Yaşam', AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Besin Değerleri
                  if (recipe.nutritionInfo != null) ...[
                    const Text(
                      '💊 Besin Değerleri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutritionItem('Protein', '${recipe.nutritionInfo!.protein}g'),
                          _buildNutritionItem('Karb', '${recipe.nutritionInfo!.carbs}g'),
                          _buildNutritionItem('Yağ', '${recipe.nutritionInfo!.fat}g'),
                          _buildNutritionItem('Lif', '${recipe.nutritionInfo!.fiber}g'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Malzemeler
                  const Text(
                    '🛒 Malzemeler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map((ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                ing.name,
                                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              ing.amount,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            if (ing.note != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${ing.note})',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ]
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  // Hazırlanış
                  const Text(
                    '📝 Hazırlanış',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  // İpuçları
                  if (recipe.tips != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'İpucu',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.tips!,
                                  style: TextStyle(color: Colors.amber.shade900, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // Kapat Butonu
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Anladım ✓', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final videoUrl = recipe.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return _RecipeVideoPlayer(
        videoUrl: CloudinaryHelper.optimizeVideo(videoUrl) ?? videoUrl,
        posterUrl: CloudinaryHelper.videoPoster(videoUrl) ??
            CloudinaryHelper.optimizeImage(recipe.imageUrl),
      );
    }
    final imageUrl = CloudinaryHelper.optimizeImage(recipe.imageUrl);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) => const Center(
          child: Icon(Icons.blender, size: 48, color: AppColors.primary),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.blender, size: 64, color: AppColors.primary),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

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
