import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../profile/screens/app_settings_screen.dart';
import '../models/app_notification.dart';
import '../providers/app_notification_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  static const String routeName = 'notifications';

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  AppNotificationType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppNotificationProvider>();
    final visible = _selectedType == null
        ? provider.notifications
        : provider.notifications
              .where((notification) => notification.type == _selectedType)
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text(
                'Tümünü oku',
                style: TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            tooltip: 'Bildirim tercihleri',
            onPressed: () => context.goNamed(AppSettingsScreen.routeName),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedType: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
          ),
          Expanded(child: _buildBody(context, provider, visible)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppNotificationProvider provider,
    List<AppNotification> notifications,
  ) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(provider.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedType == null
                  ? 'Henüz bildiriminiz yok.'
                  : 'Bu kategoride bildirim yok.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () async {
            await provider.markAsRead(notification);
            if (!context.mounted) return;
            final path = notification.actionPath;
            if (path != null && path.startsWith('/home')) context.go(path);
          },
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedType, required this.onSelected});

  final AppNotificationType? selectedType;
  final ValueChanged<AppNotificationType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Tümü'),
              selected: selectedType == null,
              onSelected: (_) => onSelected(null),
            ),
            const SizedBox(width: 8),
            ...AppNotificationType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type.label),
                  selected: selectedType == type,
                  onSelected: (_) => onSelected(type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: notification.isRead
          ? Colors.transparent
          : AppColors.primary.withValues(alpha: 0.06),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _typeColor.withValues(alpha: 0.14),
          child: Icon(_typeIcon, color: _typeColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 5),
              Text(
                DateFormat(
                  'd MMM yyyy • HH:mm',
                  'tr_TR',
                ).format(notification.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 9, color: AppColors.primary),
      ),
    );
  }

  IconData get _typeIcon => switch (notification.type) {
    AppNotificationType.program => Icons.event_note_outlined,
    AppNotificationType.water => Icons.water_drop_outlined,
    AppNotificationType.measurement => Icons.monitor_weight_outlined,
    AppNotificationType.badge => Icons.emoji_events_outlined,
    AppNotificationType.followUp => Icons.person_search_outlined,
    AppNotificationType.order => Icons.shopping_bag_outlined,
    AppNotificationType.message => Icons.chat_bubble_outline,
    AppNotificationType.challenge => Icons.flag_outlined,
    AppNotificationType.motivation => Icons.auto_awesome_outlined,
    AppNotificationType.distributorRequest => Icons.how_to_reg_outlined,
    AppNotificationType.roleChange => Icons.manage_accounts_outlined,
  };

  Color get _typeColor => switch (notification.type) {
    AppNotificationType.water => AppColors.laguna,
    AppNotificationType.badge ||
    AppNotificationType.challenge => AppColors.mangoDeep,
    AppNotificationType.order => AppColors.blueberry,
    AppNotificationType.message => AppColors.lake,
    AppNotificationType.distributorRequest ||
    AppNotificationType.roleChange => AppColors.mangoDeep,
    _ => AppColors.primary,
  };
}
