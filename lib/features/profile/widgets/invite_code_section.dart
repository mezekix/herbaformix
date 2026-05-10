import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/invite_code_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Distribütör profil ekranında davet kodu oluşturma ve listeleme bölümü.
///
/// - "Davet Kodu Oluştur" butonu ile yeni kod üretir.
/// - Oluşturulan kodu büyük, monospace fontla gösterir.
/// - Tek dokunuşla panoya kopyalama (SnackBar bildirimi ile).
/// - Distribütörün kullanılmamış (`isUsed: false`) kodlarını
///   oluşturulma tarihine göre sıralı listeler.
/// - Hata durumunda SnackBar ile bildirim gösterir.
/// - Yükleme sırasında buton devre dışı + CircularProgressIndicator.
class InviteCodeSection extends StatefulWidget {
  const InviteCodeSection({super.key});

  @override
  State<InviteCodeSection> createState() => _InviteCodeSectionState();
}

class _InviteCodeSectionState extends State<InviteCodeSection> {
  bool _isCreating = false;

  /// Yeni davet kodu oluşturur ve hata durumunda SnackBar gösterir.
  Future<void> _createInviteCode() async {
    final firestoreService = context.read<FirestoreService>();
    final authProvider = context.read<AuthProvider>();

    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) {
      _showErrorSnackBar('Kullanıcı oturumu bulunamadı.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      await firestoreService.createInviteCode(uid);
      // Başarı: stream otomatik olarak listeyi güncelleyecek.
      // Ek bir bildirim göstermiyoruz; yeni kod listenin başında görünecek.
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Davet kodu oluşturulamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Kodu panoya kopyalar ve SnackBar ile bildirim gösterir.
  Future<void> _copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$code" panoya kopyalandı.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firestoreService = context.read<FirestoreService>();
    final uid = authProvider.firebaseUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bölüm başlığı
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Davet Kodları',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(height: 8),

        // "Davet Kodu Oluştur" butonu
        ElevatedButton.icon(
          onPressed: _isCreating ? null : _createInviteCode,
          icon: _isCreating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_circle_outline),
          label: Text(_isCreating ? 'Oluşturuluyor...' : 'Davet Kodu Oluştur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),

        // Kullanılmamış davet kodları listesi (stream)
        if (uid != null)
          StreamBuilder<QuerySnapshot<InviteCodeModel>>(
            stream: firestoreService.inviteCodesRef
                .where('distributorId', isEqualTo: uid)
                .where('isUsed', isEqualTo: false)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorMessage(
                  message: 'Kodlar yüklenirken hata oluştu: ${snapshot.error}',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const _EmptyCodesMessage();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kullanılmamış Kodlarınız (${docs.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...docs.map(
                    (doc) => _InviteCodeCard(
                      inviteCode: doc.data(),
                      onCopy: _copyToClipboard,
                    ),
                  ),
                ],
              );
            },
          )
        else
          const _ErrorMessage(message: 'Kullanıcı oturumu bulunamadı.'),
      ],
    );
  }
}

/// Tek bir davet kodunu büyük, okunabilir biçimde gösteren kart.
class _InviteCodeCard extends StatelessWidget {
  final InviteCodeModel inviteCode;
  final Future<void> Function(String code) onCopy;

  const _InviteCodeCard({
    required this.inviteCode,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(inviteCode.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onCopy(inviteCode.code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Kod metni — büyük, monospace
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inviteCode.code,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oluşturulma: $dateStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Kopyala ikonu
              Tooltip(
                message: 'Panoya kopyala',
                child: Icon(
                  Icons.copy_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kullanılmamış kod yokken gösterilen bilgi mesajı.
class _EmptyCodesMessage extends StatelessWidget {
  const _EmptyCodesMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Henüz kullanılmamış davet kodunuz yok.\n"Davet Kodu Oluştur" butonuna basarak yeni bir kod oluşturabilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hata durumunda gösterilen mesaj widget'ı.
class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
