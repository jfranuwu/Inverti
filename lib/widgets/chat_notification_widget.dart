// File: lib/widgets/chat_notification_widget.dart
// Widget para mostrar notificaciones de mensajes de chat en tiempo real

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/notification_service.dart';

class ChatNotificationWidget extends StatelessWidget {
  final String userId;
  final VoidCallback? onTap;

  const ChatNotificationWidget({
    super.key,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.totalUnreadCount;
        
        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 16.0,
                ),
                const SizedBox(width: 6.0),
                Text(
                  '$unreadCount ${unreadCount == 1 ? 'mensaje' : 'mensajes'} nuevos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Badge de notificación simple para iconos
class ChatNotificationBadge extends StatelessWidget {
  final Widget child;
  final String userId;

  const ChatNotificationBadge({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, widget) {
        final unreadCount = chatProvider.totalUnreadCount;
        
        return Stack(
          children: [
            child,
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16.0,
                    minHeight: 16.0,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Widget de notificaciones en tiempo real para una conversación específica
class ChatMessageNotificationWidget extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatMessageNotificationWidget({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatMessageNotificationWidget> createState() => _ChatMessageNotificationWidgetState();
}

class _ChatMessageNotificationWidgetState extends State<ChatMessageNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Mostrar animación cuando llegue un mensaje nuevo
  void _showNotification() {
    setState(() {
      _isVisible = true;
    });
    _animationController.forward();
    
    // Ocultar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chat = chatProvider.getChatById(widget.chatId);
        
        if (chat == null || !chat.hasUnreadMessages(widget.currentUserId)) {
          return const SizedBox.shrink();
        }

        // Mostrar notificación si hay mensajes no leídos y no se está mostrando
        if (!_isVisible && chat.hasUnreadMessages(widget.currentUserId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNotification();
          });
        }

        if (!_isVisible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 80.0,
          left: 16.0,
          right: 16.0,
          child: ScaleTransition(
            scale: _animation,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Nuevos mensajes de ${chat.getOtherParticipantName(widget.currentUserId)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Marcar como leídos
                      chatProvider.markMessagesAsRead(widget.chatId, widget.currentUserId);
                      _animationController.reverse().then((_) {
                        if (mounted) {
                          setState(() {
                            _isVisible = false;
                          });
                        }
                      });
                    },
                    child: const Text(
                      'Ver',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Banner de notificación persistente para la lista de chats
class ChatListNotificationBanner extends StatelessWidget {
  final String userId;
  final VoidCallback? onMarkAllRead;

  const ChatListNotificationBanner({
    super.key,
    required this.userId,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadChats = chatProvider.getUnreadChats(userId);
        
        if (unreadChats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).primaryColor,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Tienes ${unreadChats.length} ${unreadChats.length == 1 ? 'conversación' : 'conversaciones'} con mensajes nuevos',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onMarkAllRead != null)
                TextButton(
                  onPressed: onMarkAllRead,
                  child: Text(
                    'Marcar todas como leídas',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12.0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}