import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_colors.dart';
import '../../../core/avatar_color_helper.dart';

/// Profil fotoğrafı seçme ve gösterme widget'ı.
///
/// - [photoUrl] doluysa dairesel avatar gösterir.
/// - [localFile] varsa seçilmiş dosyayı önizleme olarak gösterir.
/// - [isUploading] true iken yükleme göstergesi gösterir.
/// - [userId] ile kullanıcıya özel baş harf arka plan rengi üretilir.
/// - [photoUpdatedAt] 90 günden eskiyse sarı uyarı halkası gösterilir.
/// - Seçilen dosya 5 MB'ı aşarsa veya desteklenmeyen formattaysa hata gösterir.
class ProfilePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final File? localFile;
  final bool isUploading;
  final Function(File) onPhotoSelected;
  final double size;
  final String? userId;
  final String? userName;
  final DateTime? photoUpdatedAt;

  static const double _defaultSize = 100.0;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  const ProfilePhotoWidget({
    super.key,
    this.photoUrl,
    this.localFile,
    required this.isUploading,
    required this.onPhotoSelected,
    this.size = _defaultSize,
    this.userId,
    this.userName,
    this.photoUpdatedAt,
  });

  /// Fotoğraf 90 günden uzun süredir güncellenmemiş mi?
  bool get _isPhotoStale {
    if (photoUrl == null || photoUrl!.isEmpty) return false;
    if (photoUpdatedAt == null) return false;
    return DateTime.now().difference(photoUpdatedAt!).inDays > 90;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isPhotoStale ? 'Fotoğrafını güncelle' : '',
      child: GestureDetector(
        onTap: isUploading ? null : () => _showPickerBottomSheet(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dış halka — sarı (stale) veya gradient (normal)
            _buildOuterRing(),

            // Dairesel avatar
            _buildAvatar(context),

            // Yükleme göstergesi
            if (isUploading)
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withAlpha(200),
                  ),
                ),
              ),

            // Kamera edit badge
            if (!isUploading)
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildEditBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterRing() {
    if (_isPhotoStale) {
      // Sarı uyarı halkası
      return Container(
        width: size + 6,
        height: size + 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber.shade400, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(80),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }
    // Gradient border + shadow
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(child: _buildAvatarContent()),
    );
  }

  Widget _buildAvatarContent() {
    // 1. Yerel dosya önizlemesi
    if (localFile != null) {
      return Image.file(
        localFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsAvatar(),
      );
    }

    // 2. Kaydedilmiş fotoğraf
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final isLocalPath =
          photoUrl!.startsWith('/') || photoUrl!.startsWith('file://');
      if (isLocalPath && !kIsWeb) {
        return Image.file(
          File(photoUrl!.replaceFirst('file://', '')),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialsAvatar(),
        );
      }
      if (!isLocalPath) {
        return Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          },
          errorBuilder: (_, _, _) => _buildInitialsAvatar(),
        );
      }
    }

    // 3. Baş harf avatarı
    return _buildInitialsAvatar();
  }

  /// Kullanıcıya özel renkli baş harf avatarı
  Widget _buildInitialsAvatar() {
    final bgColor = AvatarColorHelper.forUser(userId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);
    final initials = _getInitials();

    return Container(
      width: size,
      height: size,
      color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (userName == null || userName!.trim().isEmpty) return '?';
    final parts = userName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Widget _buildEditBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
    );
  }

  void _showPickerBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textMutedLighter,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Fotoğraf Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Kameradan Çek'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                  title: const Text('Galeriden Seç'),
                  subtitle: const Text('JPG, PNG, WEBP • Maks. 5 MB',
                      style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (pickedFile == null) return;

      // Format kontrolü
      final ext = pickedFile.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Desteklenmeyen format. JPG, PNG veya WEBP seçin.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final file = File(pickedFile.path);
      final fileSizeBytes = await file.length();

      // 5 MB boyut kontrolü
      if (fileSizeBytes > _maxFileSizeBytes) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya 5 MB sınırını aşıyor. Daha küçük bir fotoğraf seçin.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      onPhotoSelected(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
