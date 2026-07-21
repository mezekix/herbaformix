import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../providers/app_notification_provider.dart';
import '../screens/notification_center_screen.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor = Colors.white,
    this.backgroundColor,
    this.margin = EdgeInsets.zero,
  });

  final Color iconColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<AppNotificationProvider, int>(
      (provider) => provider.unreadCount,
    );
    final button = IconButton(
      tooltip: 'Bildirimler',
      onPressed: () => context.goNamed(NotificationCenterScreen.routeName),
      icon: Icon(Icons.notifications_outlined, color: iconColor, size: 26),
    );

    return Center(
      child: Container(
        margin: margin,
        decoration: backgroundColor == null
            ? null
            : BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Badge(
          isLabelVisible: unreadCount > 0,
          backgroundColor: AppColors.error,
          label: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: button,
        ),
      ),
    );
  }
}
