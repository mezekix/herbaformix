import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/customer_model.dart';
import '../../../models/order_model.dart';

/// Dashboard'un "yaşam belirtisi": son 48 saatte gerçekleşen
/// distribütör aktivitelerinin birleşik akışı. En son 5 olay gösterilir.
///
/// Üç kaynak birleştirilir:
///   - Yeni siparişler (OrderProvider.orders)
///   - Yeni eklenen müşteriler (CustomerProvider.customers - firstContactDate)
///   - Uygulamayı aktive eden müşteriler (CustomerProvider - activatedAt)
class RecentActivityFeed extends StatelessWidget {
  final List<OrderModel> orders;
  final List<CustomerModel> customers;

  /// Aktivite penceresi (saat). Varsayılan 48 saat.
  final int windowHours;

  /// Maks. gösterilen satır sayısı.
  final int maxItems;

  const RecentActivityFeed({
    super.key,
    required this.orders,
    required this.customers,
    this.windowHours = 48,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final cutoff =
        DateTime.now().subtract(Duration(hours: windowHours));
    final activities = _buildActivityList(cutoff);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              'SON HAREKETLER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (activities.isEmpty)
            _EmptyActivityState(windowHours: windowHours)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.backgroundMuted),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < activities.length; i++) ...[
                    _ActivityRow(activity: activities[i]),
                    if (i < activities.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 56,
                        color: AppColors.backgroundMutedLight,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_Activity> _buildActivityList(DateTime cutoff) {
    final list = <_Activity>[];

    // 1) Siparişler
    for (final o in orders) {
      final date = o.orderDate.toDate();
      if (date.isAfter(cutoff)) {
        list.add(_Activity(
          kind: _ActivityKind.order,
          when: date,
          customerName: o.customerName,
          extra: o.totalVpEarned > 0
              ? '${o.totalVpEarned.toStringAsFixed(0)} VP'
              : null,
        ));
      }
    }

    // 2) Yeni müşteri kayıtları (firstContactDate)
    for (final c in customers) {
      final date = c.firstContactDate.toDate();
      if (date.isAfter(cutoff)) {
        list.add(_Activity(
          kind: _ActivityKind.newCustomer,
          when: date,
          customerName: '${c.firstName} ${c.lastName}'.trim(),
        ));
      }
    }

    // 3) Uygulama aktivasyonları
    for (final c in customers) {
      final activated = c.activatedAt?.toDate();
      if (activated != null && activated.isAfter(cutoff)) {
        list.add(_Activity(
          kind: _ActivityKind.activation,
          when: activated,
          customerName: '${c.firstName} ${c.lastName}'.trim(),
        ));
      }
    }

    list.sort((a, b) => b.when.compareTo(a.when));
    if (list.length > maxItems) {
      return list.sublist(0, maxItems);
    }
    return list;
  }
}

enum _ActivityKind { order, newCustomer, activation }

class _Activity {
  final _ActivityKind kind;
  final DateTime when;
  final String customerName;
  final String? extra;

  _Activity({
    required this.kind,
    required this.when,
    required this.customerName,
    this.extra,
  });
}

class _ActivityRow extends StatelessWidget {
  final _Activity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _resolveDisplay(activity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.nightSky,
                    ),
                    children: [
                      TextSpan(
                        text: activity.customerName.isEmpty
                            ? 'Bir müşteri'
                            : activity.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' $label',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (activity.extra != null) ...[
                        const TextSpan(
                          text: ' · ',
                          style: TextStyle(color: Colors.black38),
                        ),
                        TextSpan(
                          text: activity.extra,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRelative(activity.when),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _resolveDisplay(_Activity a) {
    switch (a.kind) {
      case _ActivityKind.order:
        return (
          Icons.shopping_bag_outlined,
          AppColors.laguna,
          'sipariş verdi',
        );
      case _ActivityKind.newCustomer:
        return (
          Icons.person_add_alt_outlined,
          AppColors.primary,
          'kayıt oldu',
        );
      case _ActivityKind.activation:
        return (
          Icons.auto_awesome_outlined,
          AppColors.mangoDeep,
          'uygulamayı aktive etti',
        );
    }
  }
}

/// Türkçe relative time: "Az önce", "12 dakika önce", "3 saat önce",
/// "Dün 21:30", "2 gün önce".
String _formatRelative(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';

  final isYesterday = now.day != when.day && diff.inDays <= 1;
  if (isYesterday) {
    final h = when.hour.toString().padLeft(2, '0');
    final m = when.minute.toString().padLeft(2, '0');
    return 'Dün $h:$m';
  }
  return '${diff.inDays} gün önce';
}

class _EmptyActivityState extends StatelessWidget {
  final int windowHours;
  const _EmptyActivityState({required this.windowHours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundMuted),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundMutedLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timeline_outlined,
              color: AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Henüz hareket yok',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nightSky,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Son $windowHours saatte sipariş, kayıt veya aktivasyon yok.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
