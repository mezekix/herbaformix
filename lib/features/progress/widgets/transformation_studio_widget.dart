import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/progress_photos_screen.dart';

/// Gelişim ekranındaki dönüşüm stüdyosu önizleme widget'ı.
/// Önce fotoğrafı + son 3 sonra fotoğrafını gösterir.
/// Tümünü görmek için ProgressPhotosScreen'e yönlendirir.
class TransformationStudioWidget extends StatefulWidget {
  const TransformationStudioWidget({super.key});

  @override
  State<TransformationStudioWidget> createState() =>
      _TransformationStudioWidgetState();
}

class _TransformationStudioWidgetState
    extends State<TransformationStudioWidget> {
  String? _beforePath;
  List<Map<String, String>> _afterPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final uid =
        context.read<AuthProvider>().firebaseUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();

    final beforePath = prefs.getString('before_photo_$uid');
    final afterKeys =
        prefs.getStringList('after_photos_keys_$uid') ?? [];

    final afterPhotos = <Map<String, String>>[];
    for (final key in afterKeys) {
      final path = prefs.getString('after_photo_${uid}_$key');
      if (path != null && File(path).existsSync()) {
        afterPhotos.add({'path': path, 'date': key});
      }
    }

    if (mounted) {
      setState(() {
        _beforePath =
            (beforePath != null && File(beforePath).existsSync())
                ? beforePath
                : null;
        _afterPhotos = afterPhotos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = _beforePath != null || _afterPhotos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            )
          : hasAny
              ? _buildPreview(context)
              : _buildEmptyState(context),
    );
  }

  Widget _buildPreview(BuildContext context) {
    // Son 3 sonra fotoğrafı (en yeniden)
    final recentAfter = _afterPhotos.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dönüşüm Stüdyosu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                  ),
                  Text(
                    '${_afterPhotos.length} sonra fotoğrafı',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.goNamed(ProgressPhotosScreen.routeName),
              child: Row(
                children: [
                  Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Önce + Son sonra fotoğrafları yan yana
        SizedBox(
          height: 160,
          child: Row(
            children: [
              // Önce fotoğrafı
              if (_beforePath != null)
                Expanded(
                  flex: recentAfter.isEmpty ? 2 : 1,
                  child: _buildThumb(
                    path: _beforePath!,
                    label: 'ÖNCE',
                    isGray: true,
                    isHighlight: false,
                  ),
                ),

              if (_beforePath != null && recentAfter.isNotEmpty)
                const SizedBox(width: 6),

              // Son sonra fotoğrafları
              ...recentAfter.asMap().entries.map((e) {
                final isLast = e.key == 0; // en yeni
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: e.key > 0 ? 6 : 0),
                    child: _buildThumb(
                      path: e.value['path']!,
                      label: isLast ? 'SON' : '',
                      isGray: false,
                      isHighlight: isLast,
                    ),
                  ),
                );
              }),

              // Önce yoksa ve sonra da yoksa — bu duruma düşmez (hasAny kontrolü var)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumb({
    required String path,
    required String label,
    required bool isGray,
    required bool isHighlight,
  }) {
    return GestureDetector(
      onTap: () => context.goNamed(ProgressPhotosScreen.routeName),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isGray
                ? ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: Image.file(File(path), fit: BoxFit.cover),
                  )
                : Image.file(File(path), fit: BoxFit.cover),
            if (label.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? AppColors.primary.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(ProgressPhotosScreen.routeName),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dönüşüm Stüdyosu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              Icon(Icons.add_a_photo,
                  color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 36, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Önce/Sonra fotoğrafı ekle',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
