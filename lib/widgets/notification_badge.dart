// Archivo: lib/widgets/notification_badge.dart
// Widget personalizado #5: Badge con contador en tiempo real

import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? textColor;
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.onTap,
    this.badgeColor,
    this.textColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Botón de notificaciones
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            size: size,
          ),
          onPressed: onTap,
        ),
        
        // Badge con contador
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: count > 9 ? 4 : 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}