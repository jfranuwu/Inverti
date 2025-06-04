// File: lib/services/notification_service.dart
// Servicio de notificaciones con soporte para mensajes de chat - CORREGIDO

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Streams para tiempo real
  StreamController<List<NotificationModel>>? _notificationsController;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // Estado
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  Stream<List<NotificationModel>> get notificationsStream => 
      _notificationsController?.stream ?? const Stream.empty();

  // Inicializar servicio
  Future<void> initialize() async {
    try {
      _notificationsController = StreamController<List<NotificationModel>>.broadcast();
      debugPrint('✅ NotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationService: $e');
    }
  }

  // Escuchar notificaciones de un usuario en tiempo real
  void listenToUserNotifications(String userId) {
    try {
      // Cancelar suscripción anterior si existe
      _notificationsSubscription?.cancel();

      // Crear nueva suscripción
      _notificationsSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limitar a las 50 más recientes
          .snapshots()
          .listen(
        (snapshot) {
          _notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          
          _unreadCount = _notifications
              .where((notification) => !notification.isRead)
              .length;

          // Emitir nueva lista
          _notificationsController?.add(_notifications);
          
          debugPrint('📢 Notificaciones actualizadas: ${_notifications.length} total, $_unreadCount sin leer');
        },
        onError: (error) {
          debugPrint('❌ Error escuchando notificaciones: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ Error configurando listener de notificaciones: $e');
    }
  }

  // Detener escucha de notificaciones
  void stopListening() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _notifications.clear();
    _unreadCount = 0;
    debugPrint('🔇 Listener de notificaciones detenido');
  }

  // Limpiar en logout
  Future<void> clearOnLogout() async {
    try {
      debugPrint('🧹 Limpiando NotificationService en logout...');
      
      // Cancelar suscripción activa
      await _notificationsSubscription?.cancel();
      _notificationsSubscription = null;
      
      // Limpiar datos locales
      _notifications.clear();
      _unreadCount = 0;
      
      // Cerrar stream controller si existe
      _notificationsController?.close();
      _notificationsController = null;
      
      debugPrint('✅ NotificationService limpiado en logout');
      
    } catch (e) {
      debugPrint('⚠️ Error limpiando NotificationService: $e');
      // No lanzar error para no bloquear el logout
    }
  }

  // Reinicializar después del logout
  Future<void> reinitializeAfterLogout() async {
    try {
      if (_notificationsController == null) {
        _notificationsController = StreamController<List<NotificationModel>>.broadcast();
        debugPrint('✅ NotificationService reinicializado después del logout');
      }
    } catch (e) {
      debugPrint('⚠️ Error reinicializando NotificationService: $e');
    }
  }

  // Crear nueva notificación
  Future<bool> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toMap());
      debugPrint('✅ Notificación creada: ${notification.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
      return false;
    }
  }

  // Crear notificación específica de mensaje de chat
  Future<bool> createChatNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
    required String chatId,
    String? projectTitle,
  }) async {
    try {
      debugPrint('💬 Creando notificación de mensaje de chat...');
      
      // Truncar mensaje si es muy largo para el historial
      String displayMessage = messageContent;
      if (displayMessage.length > 100) {
        displayMessage = '${displayMessage.substring(0, 97)}...';
      }
      
      // Agregar contexto del proyecto si existe
      String title = '💬 Mensaje de $senderName';
      if (projectTitle != null && projectTitle.isNotEmpty) {
        title = '💬 $senderName - $projectTitle';
      }

      final notification = NotificationModel(
        id: '',
        userId: receiverId,
        title: title,
        message: displayMessage,
        type: 'message',
        isRead: false,
        createdAt: DateTime.now(),
        priority: NotificationPriority.medium,
        data: {
          'type': 'chat_message',
          'chatId': chatId,
          'senderName': senderName,
          'projectTitle': projectTitle ?? '',
          'messageContent': messageContent,
          'clickAction': 'OPEN_CHAT',
        },
      );

      final success = await createNotification(notification);
      
      if (success) {
        debugPrint('✅ Notificación de chat creada exitosamente');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error creando notificación de chat: $e');
      return false;
    }
  }

  // Marcar notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Notificación marcada como leída: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error marcando notificación como leída: $e');
      return false;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Todas las notificaciones marcadas como leídas');
      return true;
    } catch (e) {
      debugPrint('❌ Error marcando todas como leídas: $e');
      return false;
    }
  }

  // Marcar todas las notificaciones de chat como leídas
  Future<bool> markAllChatNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadChatNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'message')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadChatNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Todas las notificaciones de chat marcadas como leídas');
      return true;
    } catch (e) {
      debugPrint('❌ Error marcando notificaciones de chat como leídas: $e');
      return false;
    }
  }

  // Marcar notificaciones de un chat específico como leídas
  Future<bool> markChatNotificationsAsRead(String userId, String chatId) async {
    try {
      final batch = _firestore.batch();
      
      final chatNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'message')
          .where('isRead', isEqualTo: false)
          .get();

      // Filtrar por chatId en los datos
      final notificationsToUpdate = chatNotifications.docs.where((doc) {
        final data = doc.data();
        final notificationData = data['data'] as Map<String, dynamic>?;
        return notificationData?['chatId'] == chatId;
      });

      for (final doc in notificationsToUpdate) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Notificaciones del chat $chatId marcadas como leídas');
      return true;
    } catch (e) {
      debugPrint('❌ Error marcando notificaciones del chat como leídas: $e');
      return false;
    }
  }

  // Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      debugPrint('✅ Notificación eliminada: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando notificación: $e');
      return false;
    }
  }

  // Eliminar notificaciones antiguas
  Future<bool> deleteOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Notificaciones antiguas eliminadas: ${oldNotifications.docs.length}');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando notificaciones antiguas: $e');
      return false;
    }
  }

  // Obtener notificaciones por tipo
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Obtener notificaciones de chat
  List<NotificationModel> getChatNotifications() {
    return getNotificationsByType('message');
  }

  // Obtener notificaciones no leídas
  List<NotificationModel> getUnreadNotifications() {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  // Obtener notificaciones no leídas de chat
  List<NotificationModel> getUnreadChatNotifications() {
    return _notifications
        .where((notification) => notification.type == 'message' && !notification.isRead)
        .toList();
  }

  // Obtener contador de notificaciones no leídas de chat
  int getUnreadChatNotificationsCount() {
    return getUnreadChatNotifications().length;
  }

  // Crear notificación de interés de inversor
  Future<bool> createInvestorInterestNotification({
    required String entrepreneurId,
    required String projectId,
    required String projectTitle,
    required String investorName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: entrepreneurId,
        title: '🎯 Nuevo inversor interesado',
        message: '$investorName mostró interés en tu proyecto "$projectTitle"',
        type: 'investor_interest',
        isRead: false,
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        data: {
          'projectId': projectId,
          'projectTitle': projectTitle,
          'investorName': investorName,
          'type': 'investor_interest',
          ...?additionalData,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      debugPrint('❌ Error creando notificación de interés: $e');
      return false;
    }
  }

  // Crear notificación de proyecto financiado
  Future<bool> createProjectFundedNotification({
    required String entrepreneurId,
    required String projectId,
    required String projectTitle,
    required double fundedAmount,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: entrepreneurId,
        title: '🎉 ¡Proyecto financiado!',
        message: 'Tu proyecto "$projectTitle" recibió \$${fundedAmount.toStringAsFixed(0)} en financiamiento',
        type: 'project_funded',
        isRead: false,
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        data: {
          'projectId': projectId,
          'projectTitle': projectTitle,
          'fundedAmount': fundedAmount,
          'type': 'project_funded',
          ...?additionalData,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      debugPrint('❌ Error creando notificación de financiamiento: $e');
      return false;
    }
  }

  // Crear notificación general
  Future<bool> createGeneralNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        priority: priority,
        data: data ?? {},
      );

      return await createNotification(notification);
    } catch (e) {
      debugPrint('❌ Error creando notificación general: $e');
      return false;
    }
  }

  // Obtener estadísticas de notificaciones
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final notification in _notifications) {
      stats[notification.type] = (stats[notification.type] ?? 0) + 1;
    }

    return {
      'total': _notifications.length,
      'unread': _unreadCount,
      'read': _notifications.length - _unreadCount,
      'chatMessages': getChatNotifications().length,
      'unreadChatMessages': getUnreadChatNotificationsCount(),
      ...stats,
    };
  }

  // 🔧 CORREGIDO: Verificar si hay notificaciones recientes de un chat específico (SIN async)
  bool hasRecentChatNotifications(String chatId, {int minutes = 5}) {
    final cutoffTime = DateTime.now().subtract(Duration(minutes: minutes));
    
    return _notifications.any((notification) {
      if (notification.type != 'message') return false;
      
      final notificationChatId = notification.getData<String>('chatId');
      return notificationChatId == chatId && 
             notification.createdAt.isAfter(cutoffTime);
    });
  }

  // Obtener última notificación de chat
  NotificationModel? getLastChatNotification(String chatId) {
    final chatNotifications = _notifications.where((notification) {
      if (notification.type != 'message') return false;
      final notificationChatId = notification.getData<String>('chatId');
      return notificationChatId == chatId;
    }).toList();

    if (chatNotifications.isEmpty) return null;
    
    // Ordenar por fecha y devolver la más reciente
    chatNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chatNotifications.first;
  }

  // Limpiar recursos
  void dispose() {
    _notificationsSubscription?.cancel();
    _notificationsController?.close();
    _notifications.clear();
    _unreadCount = 0;
    debugPrint('🧹 NotificationService limpiado completamente');
  }
}