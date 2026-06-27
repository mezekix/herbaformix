import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';
import 'package:herbaformix/core/logger.dart';

class CachedProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackImage();
    }

    // Google Drive vb. linkleri çevir
    final String finalUrl = ImageUtils.getDirectImageUrl(imageUrl!);

    return CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      },
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        AppLogger.error('Resim yüklenemedi: $url, Hata: $error', tag: 'CachedProductImage');
        return _buildFallbackImage();
      },
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/ph.webp',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // ph.webp de yüklenemezse basit bir gri kutu göster
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
        );
      },
    );
  }
}
