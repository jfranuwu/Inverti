// Archivo: lib/services/notification_service.dart
// Servicio para manejo de notificaciones con FCM

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Inicializar servicio de notificaciones
  static Future<void> initialize() async {
    // Solicitar permisos
    await _requestPermissions();
    
    // Obtener token FCM
    await _getToken();
    
    // Configurar handlers para diferentes estados
    _configureMessageHandlers();
    
    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen(_saveToken);
  }
  
  // Solicitar permisos de notificaciones
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('Permisos de notificación: ${settings.authorizationStatus}');
  }
  
  // Obtener y guardar token FCM
  static Future<void> _getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      print('Error al obtener token FCM: $e');
    }
  }
  
  // Guardar token en Firestore
  static Future<void> _saveToken(String token) async {
    try {
      // Guardar token asociado al usuario si está autenticado
      // Esto se haría en conjunto con el AuthProvider
      print('Token FCM: $token');
    } catch (e) {
      print('Error al guardar token: $e');
    }
  }
  
  // Configurar handlers para mensajes
  static void _configureMessageHandlers() {
    // Mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje en primer plano: ${message.notification?.title}');
      _handleMessage(message);
    });
    
    // Mensajes al abrir la app desde notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación: ${message.notification?.title}');
      _handleMessageNavigation(message);
    });
    
    // Mensaje inicial si la app se abrió desde notificación cerrada
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Mensaje inicial: ${message.notification?.title}');
        _handleMessageNavigation(message);
      }
    });
  }
  
  // Manejar mensaje recibido
  static void _handleMessage(RemoteMessage message) {
    // Guardar notificación en Firestore
    _saveNotification(message);
    
    // Mostrar notificación local si es necesario
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Inverti',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }
  }
  
  // Manejar navegación desde notificación
  static void _handleMessageNavigation(RemoteMessage message) {
    // Navegar según el tipo de notificación
    final data = message.data;
    
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'new_project':
          // Navegar a detalle del proyecto
          final projectId = data['projectId'];
          if (projectId != null) {
            _navigateToProject(projectId);
          }
          break;
        case 'investor_interest':
          // Navegar a lista de inversores interesados
          _navigateToInterests();
          break;
        default:
          // Navegar a lista de notificaciones
          _navigateToNotifications();
      }
    }
  }
  
  // Guardar notificación en Firestore
  static Future<void> _saveNotification(RemoteMessage message) async {
    try {
      await _firestore.collection(FirebaseConfig.notificationsCollection).add({
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'userId': message.data['userId'], // ID del usuario destinatario
      });
    } catch (e) {
      print('Error al guardar notificación: $e');
    }
  }
  
  // Mostrar notificación local (en primer plano)
  static void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    // Aquí se implementaría la lógica para mostrar
    // una notificación local usando flutter_local_notifications
    // Por simplicidad, solo imprimimos
    print('Notificación local: $title - $body');
  }
  
  // Suscribir a tema
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Suscrito al tema: $topic');
    } catch (e) {
      print('Error al suscribir a tema: $e');
    }
  }
  
  // Desuscribir de tema
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Desuscrito del tema: $topic');
    } catch (e) {
      print('Error al desuscribir de tema: $e');
    }
  }
  
  // Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConfig.notificationsCollection)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error al marcar como leída: $e');
    }
  }
  
  // Obtener notificaciones del usuario
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection(FirebaseConfig.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
  
  // Contar notificaciones no leídas
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(FirebaseConfig.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  // Métodos de navegación (se implementarían con Navigator)
  static void _navigateToProject(String projectId) {
    // Implementar navegación a proyecto
    print('Navegar a proyecto: $projectId');
  }
  
  static void _navigateToInterests() {
    // Implementar navegación a intereses
    print('Navegar a intereses');
  }
  
  static void _navigateToNotifications() {
    // Implementar navegación a notificaciones
    print('Navegar a notificaciones');
  }
}