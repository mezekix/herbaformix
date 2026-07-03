import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_colors.dart';
import '../../../models/scheduled_follow_up_model.dart';
import '../../../core/utils/whatsapp_helper.dart';

/// Tekil bir takip görevini gösteren kart widget'ı.
/// Dismiss ile hızlı tamamlama/silme, uzun basma ile düzenleme.
class FollowUpCard extends StatelessWidget {
  final ScheduledFollowUpModel followUp;
  final String? phoneNumber;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FollowUpCard({
    super.key,
    required this.followUp,
    this.phoneNumber,
    this.onComplete,
    this.onSnooze,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  /// Takibin durumuna göre renk döndürür.
  Color _statusColor() {
    if (followUp.isCompleted) return AppColors.secondary;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final dueDate = followUp.dueDate.toDate();

    if (dueDate.isBefore(startOfToday)) return AppColors.error;
    if (!dueDate.isBefore(startOfToday) && dueDate.isBefore(endOfToday)) {
      return AppColors.accent;
    }
    return AppColors.primary;
  }

  /// Durum metni.
  String _statusText() {
    if (followUp.isCompleted) return 'Tamamlandı';
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final dueDate = followUp.dueDate.toDate();

    if (dueDate.isBefore(startOfToday)) return 'Gecikmiş';
    if (!dueDate.isBefore(startOfToday) && dueDate.isBefore(endOfToday)) {
      return 'Bugün';
    }
    return DateFormat('dd MMM', 'tr').format(dueDate);
  }

  /// Durum ikonu.
  IconData _statusIcon() {
    if (followUp.isCompleted) return Icons.check_circle;
    final now = DateTime.now();
    final dueDate = followUp.dueDate.toDate();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (dueDate.isBefore(startOfToday)) return Icons.warning_amber_rounded;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final dateFormat = DateFormat('dd MMM yyyy', 'tr');

    return Dismissible(
      key: Key(followUp.id),
      direction: followUp.isCompleted
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete?.call();
          return false;
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Takip Sil'),
              content: const Text('Bu takibi silmek istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                    onDelete?.call();
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Sil'),
                ),
              ],
            ),
          ) ?? false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle, color: AppColors.secondary, size: 28),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: statusColor.withAlpha(60),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap ?? onEdit,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Sol — Durum göstergesi
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Orta — Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri adı + otomatik/manuel etiketi
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              followUp.customerFullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (followUp.isAutoGenerated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.laguna.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Otomatik',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.laguna,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Başlık
                      Text(
                        followUp.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          decoration: followUp.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Notlar (varsa)
                      if (followUp.notes != null && followUp.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            followUp.notes!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Sağ — Tarih ve durum
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(), size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusText(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(followUp.dueDate.toDate()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Aksiyonlar — sadece tamamlanmamış için
                if (!followUp.isCompleted) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      switch (value) {
                        case 'complete':
                          onComplete?.call();
                          break;
                        case 'snooze':
                          onSnooze?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'call':
                          if (phoneNumber != null) {
                            _callCustomer(context, phoneNumber!);
                          }
                          break;
                        case 'whatsapp':
                          if (phoneNumber != null) {
                            _whatsAppCustomer(context, phoneNumber!, followUp.customerFirstName);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) ...[
                        const PopupMenuItem(
                          value: 'call',
                          child: Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 18, color: AppColors.lake),
                              SizedBox(width: 8),
                              Text('Ara'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'whatsapp',
                          child: Row(
                            children: [
                              Icon(Icons.chat_outlined, size: 18, color: AppColors.grass),
                              SizedBox(width: 8),
                              Text('WhatsApp'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text('Tamamla'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'snooze',
                        child: Row(
                          children: [
                            Icon(Icons.snooze, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Ertele'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Sil'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context, String phone) async {
    final normalized = normalizePhoneForWhatsApp(phone);
    final dialNumber = normalized != null ? '+$normalized' : phone;
    final uri = Uri.parse('tel:$dialNumber');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama hatası: $e')),
        );
      }
    }
  }

  Future<void> _whatsAppCustomer(
    BuildContext context,
    String phone,
    String firstName,
  ) async {
    final normalized = normalizePhoneForWhatsApp(phone);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon numarası geçersiz.')),
      );
      return;
    }
    final greeting = firstName.trim().isEmpty ? 'Merhaba!' : 'Merhaba ${firstName.trim()}!';
    final message = '$greeting\nMüsait olduğunda kısaca konuşabilir miyiz?';
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp açılamadı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp hatası: $e')),
        );
      }
    }
  }
}
