// Archivo: lib/screens/notifications/notifications_screen.dart
// Pantalla de notificaciones mejorada con tiempo real

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/custom_card.dart';
import '../project/project_detail_screen.dart';
import '../project/interested_investors_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Iniciar escucha de notificaciones
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      _notificationService.listenToUserNotifications(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.notificationsStream,
              builder: (context, snapshot) {
                final unreadCount = _notificationService.unreadCount;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Todas'),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'No leídas'),
            const Tab(text: 'Inversores'),
          ],
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.notificationsStream,
            builder: (context, snapshot) {
              final hasUnread = _notificationService.unreadCount > 0;
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                enabled: !_isMarkingAllAsRead,
                itemBuilder: (context) => [
                  if (hasUnread)
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_read, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(_isMarkingAllAsRead ? 'Marcando...' : 'Marcar todas como leídas'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Configurar notificaciones'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    await _markAllAsRead();
                  } else if (value == 'settings') {
                    _showNotificationSettings();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allNotifications = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // Todas las notificaciones
              _buildNotificationsList(allNotifications),
              
              // No leídas
              _buildNotificationsList(
                allNotifications.where((n) => !n.isRead).toList(),
                emptyMessage: 'No tienes notificaciones sin leer',
                emptyIcon: Icons.mark_email_read,
              ),
              
              // Inversores
              _buildNotificationsList(
                allNotifications.where((n) => n.type == 'investor_interest').toList(),
                emptyMessage: 'No tienes notificaciones de inversores',
                emptyIcon: Icons.people_outline,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(
    List<NotificationModel> notifications, {
    String? emptyMessage,
    IconData? emptyIcon,
  }) {
    if (notifications.isEmpty) {
      return _buildEmptyState(
        message: emptyMessage ?? 'No tienes notificaciones',
        icon: emptyIcon ?? Icons.notifications_none,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Las notificaciones se actualizan automáticamente con streams
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onMarkAsRead: () => _markAsRead(notification),
              onDelete: () => _deleteNotification(notification),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando tengas actividad',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar notificaciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final userId = context.read<AuthProvider>().user?.uid;
              if (userId != null) {
                _notificationService.listenToUserNotifications(userId);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Marcar como leída si no lo está
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // Navegar según el tipo de notificación
    switch (notification.type) {
      case 'investor_interest':
        final projectId = notification.data['projectId'];
        final projectTitle = notification.data['projectTitle'];
        
        if (projectId != null && projectTitle != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterestedInvestorsScreen(
                projectId: projectId,
                projectTitle: projectTitle,
              ),
            ),
          );
        }
        break;
        
      case 'project_funded':
        final projectId = notification.data['projectId'];
        
        if (projectId != null) {
          // TODO: Navegar al detalle del proyecto
          // Necesitarías obtener el proyecto completo primero
        }
        break;
        
      default:
        // Mostrar detalles de la notificación
        _showNotificationDetails(notification);
        break;
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isMarkingAllAsRead = true;
    });

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      final success = await _notificationService.markAllAsRead(userId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al marcar notificaciones'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() {
      _isMarkingAllAsRead = false;
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _notificationService.deleteNotification(notification.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación eliminada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar notificación'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Notificaciones'),
        content: const Text(
          'Próximamente podrás configurar qué notificaciones quieres recibir y cómo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de tipo de notificación
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      size: 20,
                      color: _getNotificationColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
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
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            
                            // Acciones
                            Row(
                              children: [
                                if (!notification.isRead)
                                  InkWell(
                                    onTap: onMarkAsRead,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.mark_email_read,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: onDelete,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'investor_interest':
        return Icons.people;
      case 'project_funded':
        return Icons.attach_money;
      case 'project_update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case 'investor_interest':
        return Colors.orange;
      case 'project_funded':
        return Colors.green;
      case 'project_update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}