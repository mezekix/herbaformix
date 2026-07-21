import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../models/invite_code_model.dart';
import '../../../models/invite_status.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Distribütör profil ekranındaki davet kodları bölümü.
class InviteCodeSection extends StatefulWidget {
  const InviteCodeSection({super.key});

  /// Davet kodunu paylaşırken kullanılacak mesaj şablonu.
  static const String shareMessageTemplate =
      'Herbaformix platformuna katılman için davet kodun: {CODE}\n\nKayıt olurken bu kodu girerek benimle bağlantı kurabilirsin.';

  @override
  State<InviteCodeSection> createState() => _InviteCodeSectionState();
}

class _InviteCodeSectionState extends State<InviteCodeSection> {
  bool _isGenerating = false;
  bool _isCleaningExpired = false;

  Future<void> _generateCode() async {
    // Capture dependencies while this widget is definitely active.  The
    // Firestore write may finish after the enclosing profile route starts
    // leaving, when looking up an ancestor through `context` is unsafe.
    final authProvider = context.read<AuthProvider>();
    final firestoreService = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() => _isGenerating = true);
    try {
      final distributorId = authProvider.userProfile?.id;
      if (distributorId == null) return;

      await firestoreService.createInviteCode(distributorId);

      if (mounted) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Yeni davet kodu oluşturuldu'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _deleteCode(InviteCodeModel code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kodu Sil'),
        content: Text('${code.code} kodunu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<FirestoreService>().deleteInviteCode(code.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinemedi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cleanExpiredCodes() async {
    final authProvider = context.read<AuthProvider>();
    final firestoreService = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() => _isCleaningExpired = true);
    try {
      final distributorId = authProvider.userProfile?.id;
      if (distributorId == null) return;

      final count = await firestoreService.deleteExpiredInviteCodes(distributorId);

      if (mounted) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? '$count süresi geçmiş kod temizlendi'
                : 'Süresi geçmiş kod bulunamadı'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCleaningExpired = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final distributorId = authProvider.userProfile?.id;
    if (distributorId == null) return const SizedBox.shrink();

    return StreamBuilder<List<InviteCodeModel>>(
      stream: context
          .read<FirestoreService>()
          .getInviteCodesForDistributor(distributorId),
      builder: (context, snapshot) {
        final codes = snapshot.data ?? [];
        final hasExpired = codes.any((c) => c.effectiveStatus == InviteStatus.expired);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Davet Kodlarım',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (hasExpired)
                      _smallButton(
                        icon: Icons.cleaning_services_outlined,
                        label: 'Süresi Geçenleri Temizle',
                        isLoading: _isCleaningExpired,
                        onTap: _cleanExpiredCodes,
                      ),
                    const SizedBox(width: 8),
                    _smallButton(
                      icon: Icons.add_circle_outline,
                      label: 'Yeni Kod',
                      isLoading: _isGenerating,
                      onTap: _generateCode,
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste
            if (codes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Henüz davet kodunuz yok',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...codes.map((code) => _buildCodeTile(code)),
          ],
        );
      },
    );
  }

  Widget _buildCodeTile(InviteCodeModel code) {
    final effectiveStatus = code.effectiveStatus;
    final isUsed = effectiveStatus == InviteStatus.used;
    final isExpired = effectiveStatus == InviteStatus.expired;
    final isActive = !isUsed && !isExpired;

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.nightSky.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Kod
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(effectiveStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isUsed
                      ? '${code.customerName ?? "Bir müşteri"} tarafından kullanıldı'
                      : 'Son kullanma: ${dateFormat.format(code.expiresAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Eylemler (sadece aktif kodlarda)
          if (isActive) ...[
            IconButton(
              icon: const Icon(Icons.copy, color: AppColors.primary, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Davet kodu kopyalandı: ${code.code}'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Kopyala',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.papaya, size: 20),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: InviteCodeSection.shareMessageTemplate.replaceAll('{CODE}', code.code),
                    subject: 'Herbaformix Davet Kodu',
                  ),
                );
              },
              tooltip: 'Paylaş',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.withValues(alpha: 0.6), size: 20),
              onPressed: () => _deleteCode(code),
              tooltip: 'Kodu Sil',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(InviteStatus status) {
    switch (status) {
      case InviteStatus.used:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Kullanıldı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        );
      case InviteStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Süresi Geçti',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        );
      case InviteStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.papaya.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Aktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.papaya,
            ),
          ),
        );
    }
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppColors.primary : AppColors.nightSky,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
