// Archivo: lib/services/fcm_service.dart
// Servicio para manejo de Firebase Cloud Messaging (notificaciones push)

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Inicializar FCM
  Future<void> initialize() async {
    try {
      // Solicitar permisos de notificaciones
      await _requestPermission();
      
      // Configurar notificaciones locales
      await _configureLocalNotifications();
      
      // Obtener token FCM
      await _getFCMToken();
      
      // Configurar handlers de mensajes
      _configureMessageHandlers();
      
      debugPrint('✅ FCM Service inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando FCM Service: $e');
    }
  }

  // Solicitar permisos de notificaciones
  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );
    }

    final settings = await _firebaseMessaging.getNotificationSettings();
    debugPrint('📱 Estado de permisos FCM: ${settings.authorizationStatus}');
  }

  // Configurar notificaciones locales
  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'inverti_channel',
        'Inverti Notifications',
        description: 'Notificaciones de la app Inverti',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Obtener token FCM
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');
      
      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _updateTokenInFirestore(newToken);
        debugPrint('🔄 FCM Token actualizado: $newToken');
      });
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM token: $e');
    }
  }

  // Actualizar token en Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      // Aquí actualizarías el token en el perfil del usuario
      // Ejemplo:
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(currentUserId)
      //     .update({'fcmToken': token});
    } catch (e) {
      debugPrint('❌ Error actualizando token en Firestore: $e');
    }
  }

  // Configurar handlers de mensajes
  void _configureMessageHandlers() {
    // Mensaje recibido cuando app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensaje tocado cuando app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Verificar si la app se abrió desde una notificación
    _checkInitialMessage();
  }

  // Manejar mensajes en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Mensaje recibido en primer plano: ${message.messageId}');
    
    // Mostrar notificación local
    await _showLocalNotification(message);
    
    // Guardar en Firestore si es necesario
    await _saveNotificationToFirestore(message);
  }

  // Manejar toque de notificación en segundo plano
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('👆 Notificación tocada desde segundo plano: ${message.messageId}');
    await _handleNotificationTap(message);
  }

  // Verificar mensaje inicial (app cerrada)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App abierta desde notificación: ${initialMessage.messageId}');
      await _handleNotificationTap(initialMessage);
    }
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'inverti_channel',
      'Inverti Notifications',
      channelDescription: 'Notificaciones de la app Inverti',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.messageId,
    );
  }

  // Guardar notificación en Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final data = message.data;
      
      // Solo guardar si tiene userId (para que aparezca en la bandeja)
      if (data.containsKey('userId')) {
        final notification = NotificationModel(
          id: message.messageId ?? '',
          userId: data['userId'],
          title: message.notification?.title ?? 'Nueva notificación',
          message: message.notification?.body ?? '',
          type: data['type'] ?? 'general',
          isRead: false,
          createdAt: DateTime.now(),
          data: data,
        );

        await NotificationService().createNotification(notification);
      }
    } catch (e) {
      debugPrint('❌ Error guardando notificación: $e');
    }
  }

  // Manejar toque de notificación
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];

    // Navegar según el tipo de notificación
    switch (type) {
      case 'investor_interest':
        // Navegar a la lista de inversores interesados
        // NavigationService.navigateTo('/interested-investors', {
        //   'projectId': data['projectId'],
        // });
        break;
      case 'project_funded':
        // Navegar al detalle del proyecto
        // NavigationService.navigateTo('/project-detail', {
        //   'projectId': data['projectId'],
        // });
        break;
      default:
        // Navegar a notificaciones
        // NavigationService.navigateTo('/notifications');
        break;
    }
  }

  // Callback para notificaciones locales tocadas
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('👆 Notificación local tocada: $payload');
      // Manejar navegación basada en payload
    }
  }

  // Enviar notificación de interés de inversor
  Future<void> sendInvestorInterestNotification({
    required String entrepreneurId,
    required String projectId,
    required String projectTitle,
    required String investorName,
  }) async {
    try {
      // Crear notificación en Firestore
      final notification = NotificationModel(
        id: '',
        userId: entrepreneurId,
        title: '🎯 Nuevo inversor interesado',
        message: '$investorName mostró interés en tu proyecto "$projectTitle"',
        type: 'investor_interest',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'projectId': projectId,
          'projectTitle': projectTitle,
          'investorName': investorName,
          'type': 'investor_interest',
        },
      );

      await NotificationService().createNotification(notification);
      debugPrint('✅ Notificación de interés enviada');
      
    } catch (e) {
      debugPrint('❌ Error enviando notificación de interés: $e');
    }
  }

  // Suscribirse a tópico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error suscribiéndose al tópico $topic: $e');
    }
  }

  // Desuscribirse de tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error desuscribiéndose del tópico $topic: $e');
    }
  }

  // Limpiar recursos
  void dispose() {
    // Limpiar listeners si es necesario
  }
}

// Handler para mensajes en segundo plano (debe estar en top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Mensaje recibido en segundo plano: ${message.messageId}');
  
  // Inicializar Firebase si es necesario
  // await Firebase.initializeApp();
  
  // Procesar el mensaje en segundo plano
}