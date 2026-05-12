import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';

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
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('Resim yüklenemedi: $url, Hata: $error');
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
