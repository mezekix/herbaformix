import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

/// Dönüşüm fotoğrafları sayfası.
///
/// Düzen:
///  1. Üstte carousel — Önce ilk sırada, sonra eklenenler sırayla, en son en sonda
///  2. Aşağıda büyük kartlar — aynı sıra
class ProgressPhotosScreen extends StatefulWidget {
  static const String routeName = 'progress-photos';
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  String? _beforePath;

  /// Sonra fotoğrafları: [{'path': '...', 'date': iso8601}], eskiden yeniye sıralı
  List<Map<String, String>> _afterPhotos = [];

  bool _isLoading = true;
  String _uid = 'guest';

  late final PageController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.88);
    _loadData();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  // ── Veri ─────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    _uid = context.read<AuthProvider>().firebaseUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();

    final beforePath = prefs.getString('before_photo_$_uid');
    final afterKeys = prefs.getStringList('after_photos_keys_$_uid') ?? [];

    final afterPhotos = <Map<String, String>>[];
    for (final key in afterKeys) {
      final path = prefs.getString('after_photo_${_uid}_$key');
      if (path != null && File(path).existsSync()) {
        afterPhotos.add({'path': path, 'date': key});
      }
    }

    if (mounted) {
      setState(() {
        _beforePath = (beforePath != null && File(beforePath).existsSync())
            ? beforePath
            : null;
        _afterPhotos = afterPhotos; // eskiden yeniye
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAfterPhotos(SharedPreferences prefs) async {
    final keys = _afterPhotos.map((e) => e['date']!).toList();
    await prefs.setStringList('after_photos_keys_$_uid', keys);
    for (final photo in _afterPhotos) {
      await prefs.setString(
          'after_photo_${_uid}_${photo['date']}', photo['path']!);
    }
  }

  // ── Fotoğraf işlemleri ────────────────────────────────────────────────────

  Future<void> _pickBefore() async {
    final source = await _showSourceDialog();
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('before_photo_$_uid', picked.path);
    setState(() => _beforePath = picked.path);
    _awardBadge();
  }

  Future<void> _deleteBefore() async {
    if (!await _confirmDelete('Önce fotoğrafını silmek istiyor musun?')) return;
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('before_photo_$_uid');
    setState(() => _beforePath = null);
  }

  Future<void> _addAfterPhoto() async {
    final source = await _showSourceDialog();
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked == null || !mounted) return;

    final dateKey = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    setState(() => _afterPhotos.add({'path': picked.path, 'date': dateKey}));
    await _saveAfterPhotos(prefs);
    _awardBadge();

    // Carousel'i en sona kaydır (önce + afterPhotos.length - 1)
    final lastPage = _allPhotos.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          lastPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteAfterPhoto(int afterIndex) async {
    if (!await _confirmDelete('Bu sonra fotoğrafını silmek istiyor musun?')) {
      return;
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _afterPhotos[afterIndex]['date']!;
    await prefs.remove('after_photo_${_uid}_$key');
    setState(() => _afterPhotos.removeAt(afterIndex));
    await _saveAfterPhotos(prefs);
  }

  void _awardBadge() {
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId != null) {
      context.read<ProgressProvider>().awardPhotoAddedBadge(userId);
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  /// Tüm fotoğraflar sıralı: önce ilk, sonra eklenenler eskiden yeniye
  List<_PhotoItem> get _allPhotos {
    final list = <_PhotoItem>[];
    if (_beforePath != null) {
      list.add(_PhotoItem(
        path: _beforePath!,
        label: 'ÖNCE',
        isBefore: true,
        afterIndex: null,
        date: null,
      ));
    }
    for (int i = 0; i < _afterPhotos.length; i++) {
      list.add(_PhotoItem(
        path: _afterPhotos[i]['path']!,
        label: 'SONRA ${i + 1}',
        isBefore: false,
        afterIndex: i,
        date: _afterPhotos[i]['date'],
      ));
    }
    return list;
  }

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Fotoğrafı Sil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMutedLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(String path, String label) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenPhotoView(path: path, label: label),
    ));
  }

  void _openCompare() {
    if (_beforePath == null || _afterPhotos.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CompareScreen(
        beforePath: _beforePath!,
        afterPhotos: _afterPhotos,
      ),
    ));
  }

  String _formatDate(String? isoKey) {
    if (isoKey == null) return '';
    try {
      return DateFormat('d MMM yyyy', 'tr_TR').format(DateTime.parse(isoKey));
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final photos = _allPhotos;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dönüşüm Fotoğrafları',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.nightSky),
        ),
        iconTheme: const IconThemeData(color: AppColors.nightSky),
        actions: [
          // Karşılaştırma butonu (önce + en az 1 sonra varsa)
          if (_beforePath != null && _afterPhotos.isNotEmpty)
            TextButton.icon(
              onPressed: _openCompare,
              icon: const Icon(Icons.compare,
                  color: AppColors.primary, size: 18),
              label: const Text(
                'Karşılaştır',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          TextButton.icon(
            onPressed: _addAfterPhoto,
            icon: const Icon(Icons.add_a_photo,
                color: AppColors.primary, size: 18),
            label: const Text(
              'Sonra Ekle',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : photos.isEmpty
              ? _buildEmptyState()
              : _buildContent(photos),
    );
  }

  Widget _buildContent(List<_PhotoItem> photos) {
    return CustomScrollView(
      slivers: [
        // ── Carousel ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _carouselController,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return _buildCarouselItem(photos[index]);
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Dot indikatör
              _buildDotIndicator(photos.length),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // ── Bölüm başlığı ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tüm Fotoğraflar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
                Text(
                  '${photos.length} fotoğraf',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),

        // ── Büyük kartlar listesi ──────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLargeCard(photos[index]),
            childCount: photos.length,
          ),
        ),

        // Önce fotoğrafı ekle butonu (yoksa)
        if (_beforePath == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _pickBefore,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Önce Fotoğrafı Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.grey600,
                  side: BorderSide(color: AppColors.textMutedLighter),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // ── Carousel item ─────────────────────────────────────────────────────────

  Widget _buildCarouselItem(_PhotoItem photo) {
    return AnimatedBuilder(
      animation: _carouselController,
      builder: (context, child) {
        double scale = 1.0;
        if (_carouselController.position.haveDimensions) {
          final page = _carouselController.page ?? 0;
          final index = _allPhotos.indexOf(photo);
          scale = (1 - (page - index).abs() * 0.08).clamp(0.92, 1.0);
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () => _openFullScreen(photo.path, photo.label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo.isBefore
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                            AppColors.textMuted, BlendMode.saturation),
                        child: Image.file(File(photo.path), fit: BoxFit.cover),
                      )
                    : Image.file(File(photo.path), fit: BoxFit.cover),
                // Gradient overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: photo.isBefore
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.primary.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                photo.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (photo.date != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(photo.date),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Icon(Icons.fullscreen,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int count) {
    return AnimatedBuilder(
      animation: _carouselController,
      builder: (context, _) {
        final current = _carouselController.hasClients
            ? (_carouselController.page ?? 0).round()
            : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final isActive = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMutedLighter,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Büyük kart ────────────────────────────────────────────────────────────

  Widget _buildLargeCard(_PhotoItem photo) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: photo.isBefore
              ? AppColors.backgroundMuted
              : AppColors.primary.withValues(alpha: 0.2),
          width: photo.isBefore ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: photo.isBefore
                        ? AppColors.backgroundMutedLight
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    photo.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: photo.isBefore
                          ? AppColors.grey600
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (photo.date != null)
                  Text(
                    _formatDate(photo.date),
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: AppColors.textMutedLight, size: 20),
                  onSelected: (v) {
                    if (v == 'view') {
                      _openFullScreen(photo.path, photo.label);
                    } else if (v == 'change' && photo.isBefore) {
                      _pickBefore();
                    } else if (v == 'delete') {
                      if (photo.isBefore) {
                        _deleteBefore();
                      } else {
                        _deleteAfterPhoto(photo.afterIndex!);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.fullscreen, size: 18),
                        SizedBox(width: 8),
                        Text('Tam Ekran'),
                      ]),
                    ),
                    if (photo.isBefore)
                      const PopupMenuItem(
                        value: 'change',
                        child: Row(children: [
                          Icon(Icons.swap_horiz, size: 18),
                          SizedBox(width: 8),
                          Text('Değiştir'),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text('Sil',
                            style:
                                TextStyle(color: Colors.red.shade400)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Fotoğraf
          GestureDetector(
            onTap: () => _openFullScreen(photo.path, photo.label),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: photo.isBefore
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          AppColors.textMuted, BlendMode.saturation),
                      child: Image.file(
                        File(photo.path),
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.file(
                      File(photo.path),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Boş durum ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 72, color: AppColors.textMutedLighter),
            const SizedBox(height: 20),
            Text(
              'Henüz fotoğraf yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Başlangıç fotoğrafını ekleyerek\ndönüşüm sürecini belgele',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _pickBefore,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Önce Fotoğrafı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Veri modeli ───────────────────────────────────────────────────────────────

class _PhotoItem {
  final String path;
  final String label;
  final bool isBefore;
  final int? afterIndex;
  final String? date;

  const _PhotoItem({
    required this.path,
    required this.label,
    required this.isBefore,
    required this.afterIndex,
    required this.date,
  });
}

// ── Tam Ekran Görüntüleyici ───────────────────────────────────────────────────

class _FullScreenPhotoView extends StatelessWidget {
  final String path;
  final String label;

  const _FullScreenPhotoView({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ── Before/After Karşılaştırma Ekranı ─────────────────────────────────────────

class _CompareScreen extends StatefulWidget {
  final String beforePath;
  final List<Map<String, String>> afterPhotos;

  const _CompareScreen({
    required this.beforePath,
    required this.afterPhotos,
  });

  @override
  State<_CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<_CompareScreen> {
  late int _selectedIndex;
  double _sliderPosition = 0.5; // 0.0 = tam önce, 1.0 = tam sonra

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.afterPhotos.length - 1; // en son fotoğraf
  }

  String _formatDate(String? isoKey) {
    if (isoKey == null) return '';
    try {
      return DateFormat('d MMM yyyy', 'tr_TR').format(DateTime.parse(isoKey));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final afterPath = widget.afterPhotos[_selectedIndex]['path']!;
    final afterDate = widget.afterPhotos[_selectedIndex]['date'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Önce / Sonra Karşılaştırma',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Karşılaştırma alanı
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final clipWidth = width * _sliderPosition;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPosition =
                          (details.localPosition.dx / width).clamp(0.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      // Sonra fotoğrafı (arka plan, tam)
                      Positioned.fill(
                        child: Image.file(
                          File(afterPath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Önce fotoğrafı (ön plan, kırpılmış)
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _LeftClipper(clipWidth),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                                AppColors.textMuted, BlendMode.saturation),
                            child: Image.file(
                              File(widget.beforePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Dikey çizgi + tutamak
                      Positioned(
                        left: clipWidth - 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.compare_arrows,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Dikey çizgi
                      Positioned(
                        left: clipWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.white,
                        ),
                      ),
                      // Etiketler
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ÖNCE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.nightSky,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            afterDate != null
                                ? 'SONRA — ${_formatDate(afterDate)}'
                                : 'SONRA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Sonra fotoğrafı seçici
          if (widget.afterPhotos.length > 1)
            Container(
              height: 80,
              color: Colors.black.withValues(alpha: 0.8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: widget.afterPhotos.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIndex = index),
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(widget.afterPhotos[index]['path']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Sol taraftan clipWidth kadarını gösteren clipper.
class _LeftClipper extends CustomClipper<Rect> {
  final double clipWidth;
  const _LeftClipper(this.clipWidth);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, clipWidth, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) =>
      oldClipper.clipWidth != clipWidth;
}
