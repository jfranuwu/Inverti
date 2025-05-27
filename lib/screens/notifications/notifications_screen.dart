// Archivo: lib/screens/notifications/notifications_screen.dart
// Pantalla de notificaciones FCM

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/custom_card.dart';
import '../investor/interested_investors_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para ver notificaciones'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Marcar todas como leídas'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Te notificaremos cuando haya novedades',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NotificationCard(
                  id: notification.id,
                  title: data['title'] ?? '',
                  body: data['body'] ?? '',
                  timestamp: data['createdAt'] as Timestamp?,
                  isRead: data['read'] ?? false,
                  type: data['data']?['type'] ?? 'general',
                  onTap: () {
                    _handleNotificationTap(notification.id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Marcar todas las notificaciones como leídas
  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await NotificationService
          .getUserNotifications(userId)
          .first;

      for (final doc in notifications.docs) {
        if (!(doc.data() as Map<String, dynamic>)['read']) {
          batch.update(doc.reference, {'read': true});
        }
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Manejar tap en notificación
  void _handleNotificationTap(String notificationId, Map<String, dynamic> data) {
    // Marcar como leída
    NotificationService.markAsRead(notificationId);
    
    // Navegar según el tipo de notificación
    final type = data['data']?['type'];
    switch (type) {
      case 'new_project':
        // Navegar a proyecto
        break;
      case 'investor_interest':
        // Navegar a inversores interesados
        break;
        // En el método _handleNotificationTap, actualiza el case 'investor_interest':

      case 'investor_interest':
        final projectId = data['data']?['projectId'];
        if (projectId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterestedInvestorsScreen(
                projectId: projectId,
                projectTitle: data['data']?['projectTitle'] ?? 'Proyecto',
              ),
            ),
          );
        }
        break;
      default:
        // No hacer nada
        break;
    }
  }
}

// Widget para notificación individual
class _NotificationCard extends StatelessWidget {
  final String id;
  final String title;
  final String body;
  final Timestamp? timestamp;
  final bool isRead;
  final String type;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      color: isRead ? null : Theme.of(context).primaryColor.withOpacity(0.05),
      border: !isRead
          ? Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono según tipo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(type),
                color: _getIconColor(type),
              ),
            ),
            const SizedBox(width: 16),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_project':
        return Icons.rocket_launch;
      case 'investor_interest':
        return Icons.star;
      case 'payment':
        return Icons.payment;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'new_project':
        return Colors.blue;
      case 'investor_interest':
        return Colors.amber;
      case 'payment':
        return Colors.green;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}