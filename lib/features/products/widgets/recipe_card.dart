import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/cloudinary_helper.dart';
import '../../../../models/recipe_model.dart';
import 'recipe_detail_sheet.dart'; // RecipeDetailPage burada tanımlı

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final bool isHorizontal;
  final bool isCompact;
  final bool isGrid;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.isHorizontal = true,
    this.isCompact = false,
    this.isGrid = false,
  });

  void _showDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipe: recipe),
      ),
    );
  }

  String get _firstSummarySentence {
    final description = recipe.description.trim();
    if (description.isEmpty) return '';

    final sentenceEnd = description.indexOf(RegExp(r'[.!?]'));
    if (sentenceEnd == -1) return description;
    return description.substring(0, sentenceEnd + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    if (isGrid) {
      return _buildGridCard(context);
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        width: isHorizontal ? 240 : double.infinity,
        margin: EdgeInsets.only(
          right: isHorizontal ? 16 : 0,
          bottom: isHorizontal ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim Alanı
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: AppColors.background,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildThumb(),
              ),
            ),
            
            // İçerik Alanı
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTimeMin} dk',
                        style: TextStyle(fontSize: 12, color: AppColors.grey600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.calories} kcal',
                        style: TextStyle(fontSize: 12, color: AppColors.grey600),
                      ),
                    ],
                  ),
                  if (_firstSummarySentence.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _firstSummarySentence,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: recipe.tags.take(2).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb() {
    final hasVideo = recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty;
    final thumbUrl = hasVideo
        ? CloudinaryHelper.videoPoster(recipe.videoUrl) ??
            CloudinaryHelper.optimizeImage(recipe.imageUrl, width: 480)
        : CloudinaryHelper.optimizeImage(recipe.imageUrl, width: 480);

    if (thumbUrl == null || thumbUrl.isEmpty) {
      return const Icon(Icons.blender, color: AppColors.primary, size: 40);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: thumbUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
          errorWidget: (_, _, _) => const Icon(Icons.blender, color: AppColors.primary, size: 40),
        ),
        if (hasVideo)
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
          ),
      ],
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kare görsel
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildSquareThumb(),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: AppColors.grey600),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.prepTimeMin} dk',
                        style: TextStyle(fontSize: 11, color: AppColors.grey600),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department_outlined, size: 12, color: Colors.orange.shade400),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.calories} kcal',
                        style: TextStyle(fontSize: 11, color: AppColors.grey600),
                      ),
                    ],
                  ),
                  if (_firstSummarySentence.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _firstSummarySentence,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareThumb() {
    final hasVideo = recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty;
    final thumbUrl = hasVideo
        ? CloudinaryHelper.videoPoster(recipe.videoUrl) ??
            CloudinaryHelper.optimizeImage(recipe.imageUrl, width: 480)
        : CloudinaryHelper.optimizeImage(recipe.imageUrl, width: 480);

    if (thumbUrl == null || thumbUrl.isEmpty) {
      return Container(
        color: AppColors.primary.withAlpha(15),
        alignment: Alignment.center,
        child: const Icon(Icons.blender, color: AppColors.primary, size: 44),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.background),
        CachedNetworkImage(
          imageUrl: thumbUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (_, _, _) => Container(
            color: AppColors.primary.withAlpha(15),
            alignment: Alignment.center,
            child: const Icon(Icons.blender, color: AppColors.primary, size: 44),
          ),
        ),
        if (hasVideo)
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
          ),
      ],
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.blender, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🥤 Bugünkü Öneri Tarif',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.garden,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
