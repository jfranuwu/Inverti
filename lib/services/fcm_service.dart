// File: lib/services/fcm_service.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

// Configuración centralizada de FCM
class FCMConfig {
  static const String projectId = 'inverti-app';
  
  // Credenciales del service account desde variables de entorno
  static Map<String, dynamic> get serviceAccountJson => {
    "type": "service_account",
    "project_id": projectId,
    "private_key_id": const String.fromEnvironment('f77754051c7522a288501db3e607cac1345ead42', 
        defaultValue: 'f77754051c7522a288501db3e607cac1345ead42'),
    "private_key": const String.fromEnvironment('-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCrJy1Rm6rBJEin\nEpzRCrwoYsfIY9FMMCz2BMU8vyaQaPHsor7EoKExDgYNdnk+iGUvuLsSM/DtyWI2\neIzO4NJaZA7Lt0WUjhNwz+twEYen4lQkG4zDeIJLzUnOp0/fsaZsHkAsj6t9LjwP\nD1i22volRSuAvcpGusOHJOYnF1xl1nnVGanXzmCQHxkf0WKHIRUv7v0gNNMaAITK\nULcZ56+q+mr/DUx5THpmSRbAKQz4kM44vqMvZ7EPq6PLBKxuvbJmfYm91uBxWSjy\nMGl4/yDfV7gXMsNzHO+EaWZKFf/Xe2hsz3RQg8O8A901dMCj6CVeDLrJOvZC255v\nPEM4uAVnAgMBAAECggEAAVj5nl7fZU3n1Ijs+yheeuLsN8Oxbiwi7nzzIJtQrmpl\nHTvazKmHG1/E5G4+XiOsyEdoEaifCQBA6bThRu+2OEf5Zdk3jwffV1ALxoIc01GQ\n4Afnf9J/FCG1pw7iLhyz9r32O2OWMhIfHu87/5SRy6FTylu0MAJgb7v2o/AnJhYa\n6ja/iyaRpLhSEIuOe+zBP8yBCvWifXRCJsUbVgHdhfylhs74Xttb4lGdmMPw28vR\nw48AOmVZfsbjNV5OvOkAHrDfHP1KOeWMnow4ArKkqrcv+5FVKfKSNvxrMaE+wr0C\n9e2MSAJ77vjKRDkGgawqkDc/+320BhMY/VEm06rswQKBgQDd2F5GndyeFFiOs/pC\n7AM05fxK8ElNvnClLt3oPuy+SgTwC9bTYZhvt5AGInEUVLymfrPqwYpm3oGYF6Gg\nv6pIW94oEasvzMYJgH1Hlw/6dOH2ZQZXz3NonjNoL4ND9A/jrQ83xbhhubpUv0pb\n9DWuxOfzOacwIVlVOyS9hvpVqQKBgQDFgN48lC7ilpWIAduS9sf11/Y/WkAilbu6\nYkQerL2oBpR7OGx2M57WQNTjxqFWCq+pBw7LlMWHpg9DI8BDo0x0HfnF9WWhK6HA\nI+N5vOWK83ZnBtqxdCpwTBkgzvHLxcP6XEYWEF5DhOetqh0h3AO16ZvAP1xy5Gzr\nufmu9lRMjwKBgQCn/vrdpRv1hdjOMBLbbNi8zVDx+ua3/fhVzpjzD/u92lXE5mJH\nbse+ChcB3kEdsVGvD5H1u5ywa91drL+T+LDd3NvuIfst1nc9qNS2SvopoyueqEBW\nbN2roumxAxH3erIxqtM0XAFV2Az3smiAG/4vHCO+d7FY7Fg3B/O5pqaaCQKBgQCp\nMk0w+IFx/C795RmGPYPwSKLcgySOfFfmxGg3HyUa3Qg2x4+jc3WPdtrqhy+P1nfG\nBhXWsgzGuKw6iFYdm7fTghqITEJUYFyhjh1CHWFIOGomuOiBPVNeANNGGANs3m+V\n+5bPMBaRITqYvDNY3nMPVKHpgF5izu3AxAHysXRmYQKBgDPO9p8+z610ZdUqtFEH\nW3PcE2Sgb13wRTBhGq7jXE0U0mQEqKGuU2xSsNy5QwpPD13PXVnkW8ZipB07AEJF\n4Ifgig+Ep8KkIvoTp9A3+zmU0EKJHz/kXcrnOXkXvrQa1CP0PlXJc4fep1rlION5\nBfP3EW5U+fzzeo1sf9uX7vEG\n-----END PRIVATE KEY-----\n', 
        defaultValue: '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCrJy1Rm6rBJEin\nEpzRCrwoYsfIY9FMMCz2BMU8vyaQaPHsor7EoKExDgYNdnk+iGUvuLsSM/DtyWI2\neIzO4NJaZA7Lt0WUjhNwz+twEYen4lQkG4zDeIJLzUnOp0/fsaZsHkAsj6t9LjwP\nD1i22volRSuAvcpGusOHJOYnF1xl1nnVGanXzmCQHxkf0WKHIRUv7v0gNNMaAITK\nULcZ56+q+mr/DUx5THpmSRbAKQz4kM44vqMvZ7EPq6PLBKxuvbJmfYm91uBxWSjy\nMGl4/yDfV7gXMsNzHO+EaWZKFf/Xe2hsz3RQg8O8A901dMCj6CVeDLrJOvZC255v\nPEM4uAVnAgMBAAECggEAAVj5nl7fZU3n1Ijs+yheeuLsN8Oxbiwi7nzzIJtQrmpl\nHTvazKmHG1/E5G4+XiOsyEdoEaifCQBA6bThRu+2OEf5Zdk3jwffV1ALxoIc01GQ\n4Afnf9J/FCG1pw7iLhyz9r32O2OWMhIfHu87/5SRy6FTylu0MAJgb7v2o/AnJhYa\n6ja/iyaRpLhSEIuOe+zBP8yBCvWifXRCJsUbVgHdhfylhs74Xttb4lGdmMPw28vR\nw48AOmVZfsbjNV5OvOkAHrDfHP1KOeWMnow4ArKkqrcv+5FVKfKSNvxrMaE+wr0C\n9e2MSAJ77vjKRDkGgawqkDc/+320BhMY/VEm06rswQKBgQDd2F5GndyeFFiOs/pC\n7AM05fxK8ElNvnClLt3oPuy+SgTwC9bTYZhvt5AGInEUVLymfrPqwYpm3oGYF6Gg\nv6pIW94oEasvzMYJgH1Hlw/6dOH2ZQZXz3NonjNoL4ND9A/jrQ83xbhhubpUv0pb\n9DWuxOfzOacwIVlVOyS9hvpVqQKBgQDFgN48lC7ilpWIAduS9sf11/Y/WkAilbu6\nYkQerL2oBpR7OGx2M57WQNTjxqFWCq+pBw7LlMWHpg9DI8BDo0x0HfnF9WWhK6HA\nI+N5vOWK83ZnBtqxdCpwTBkgzvHLxcP6XEYWEF5DhOetqh0h3AO16ZvAP1xy5Gzr\nufmu9lRMjwKBgQCn/vrdpRv1hdjOMBLbbNi8zVDx+ua3/fhVzpjzD/u92lXE5mJH\nbse+ChcB3kEdsVGvD5H1u5ywa91drL+T+LDd3NvuIfst1nc9qNS2SvopoyueqEBW\nbN2roumxAxH3erIxqtM0XAFV2Az3smiAG/4vHCO+d7FY7Fg3B/O5pqaaCQKBgQCp\nMk0w+IFx/C795RmGPYPwSKLcgySOfFfmxGg3HyUa3Qg2x4+jc3WPdtrqhy+P1nfG\nBhXWsgzGuKw6iFYdm7fTghqITEJUYFyhjh1CHWFIOGomuOiBPVNeANNGGANs3m+V\n+5bPMBaRITqYvDNY3nMPVKHpgF5izu3AxAHysXRmYQKBgDPO9p8+z610ZdUqtFEH\nW3PcE2Sgb13wRTBhGq7jXE0U0mQEqKGuU2xSsNy5QwpPD13PXVnkW8ZipB07AEJF\n4Ifgig+Ep8KkIvoTp9A3+zmU0EKJHz/kXcrnOXkXvrQa1CP0PlXJc4fep1rlION5\nBfP3EW5U+fzzeo1sf9uX7vEG\n-----END PRIVATE KEY-----\n'),
    "client_email": const String.fromEnvironment('firebase-adminsdk-fbsvc@inverti-app.iam.gserviceaccount.com', 
        defaultValue: 'firebase-adminsdk-fbsvc@inverti-app.iam.gserviceaccount.com'),
    "client_id": const String.fromEnvironment('117883425330659088506', 
        defaultValue: '117883425330659088506'),
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40inverti-app.iam.gserviceaccount.com"
  };
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;

  // Inicializa todo el servicio FCM
  Future<void> initialize() async {
    try {
      await _requestPermission();
      await _configureLocalNotifications();
      await _getFCMToken();
      _configureMessageHandlers();
      _isInitialized = true;
      debugPrint('✅ FCM Service inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando FCM Service: $e');
    }
  }

  // Solicita permisos para notificaciones push
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );
    debugPrint('📱 Estado de permisos FCM: ${settings.authorizationStatus}');
  }

  // FCMService prueba de notificacion
// Método para probar notificación FCM
  Future<void> testNotification() async {
    try {
      debugPrint('🧪 Iniciando prueba de notificación...');
      
      if (_fcmToken == null) {
        debugPrint('❌ No hay token FCM disponible');
        throw Exception('Token FCM no disponible');
      }
      
      debugPrint('🔑 Token para prueba: $_fcmToken');
      
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ No se pudo obtener access token - revisar credenciales');
        throw Exception('No se pudo obtener access token');
      }
      
      debugPrint('✅ Access token obtenido para prueba');
      
      await _sendPushNotificationV1(
        token: _fcmToken!,
        title: '🧪 Prueba FCM',
        body: 'Si ves esto, FCM funciona perfectamente!',
        data: {'type': 'test'},
      );
      
      debugPrint('✅ Notificación de prueba enviada exitosamente');
      
    } catch (e) {
      debugPrint('❌ Error en prueba de notificación: $e');
      rethrow;
    }
  }

  // Método para verificar estado del servicio
  void debugFCMStatus() {
    debugPrint('=== ESTADO FCM ===');
    debugPrint('Inicializado: $_isInitialized');
    debugPrint('Token: $_fcmToken');
    debugPrint('Usuario autenticado: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('==================');
  }

  // Configura notificaciones locales para mostrar en primer plano
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

    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'inverti_channel',
        'Inverti Notifications',
        description: 'Notificaciones de la app Inverti',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Obtiene y gestiona el token FCM del dispositivo
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token obtenido: $_fcmToken');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      } else {
        debugPrint('⚠️ Token FCM obtenido pero usuario no autenticado. Se guardará después del login.');
      }
      
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token actualizado: $newToken');
        
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _saveTokenToFirestore(newToken);
          updateUserToken(currentUser.uid);
        }
      });
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM token: $e');
    }
  }

  // Guarda el token FCM en Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No se puede guardar token: usuario no autenticado');
        return;
      }

      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'userId': user.uid,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Token FCM guardado exitosamente');
    } catch (e) {
      debugPrint('❌ Error guardando token: $e');
    }
  }

  // Configura el token después del login del usuario
  Future<void> saveTokenAfterLogin(String userId) async {
    if (_fcmToken != null) {
      try {
        await _saveTokenToFirestore(_fcmToken!);
        await updateUserToken(userId);
        await _cleanupOldTokens(userId);
        debugPrint('✅ Token FCM configurado completamente para usuario: $userId');
      } catch (e) {
        debugPrint('❌ Error configurando token después del login: $e');
      }
    }
  }

  // Actualiza el token en el perfil del usuario
  Future<void> updateUserToken(String userId) async {
    if (_fcmToken != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': _fcmToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Token actualizado en perfil de usuario: $userId');
      } catch (e) {
        debugPrint('❌ Error actualizando token de usuario: $e');
      }
    }
  }

  // Elimina tokens antiguos del mismo usuario
  Future<void> _cleanupOldTokens(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .where('userId', isEqualTo: userId)
          .where('token', isNotEqualTo: _fcmToken)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('🧹 Limpiados ${querySnapshot.docs.length} tokens antiguos');
      }
    } catch (e) {
      debugPrint('❌ Error limpiando tokens antiguos: $e');
    }
  }

  // Configura los manejadores de mensajes FCM
  void _configureMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
    _checkInitialMessage();
  }

  // Maneja mensajes recibidos cuando la app está activa
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Mensaje recibido en primer plano: ${message.messageId}');
    await _showLocalNotification(message);
    await _saveNotificationToFirestore(message);
  }

  // Maneja cuando el usuario toca una notificación en segundo plano
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('👆 Notificación tocada desde segundo plano: ${message.messageId}');
    await _handleNotificationTap(message);
  }

  // Verifica si la app se abrió desde una notificación
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App abierta desde notificación: ${initialMessage.messageId}');
      await _handleNotificationTap(initialMessage);
    }
  }

  // Muestra notificación local en primer plano
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

  // Guarda la notificación en Firestore para el historial
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final data = message.data;
      
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

  // Navega según el tipo de notificación tocada
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'investor_interest':
        debugPrint('Navegar a inversores interesados: ${data['projectId']}');
        break;
      case 'project_funded':
        debugPrint('Navegar a proyecto: ${data['projectId']}');
        break;
      default:
        debugPrint('Navegar a notificaciones');
        break;
    }
  }

  // Maneja cuando se toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('👆 Notificación local tocada: $payload');
    }
  }

  // Obtiene token de acceso para API v1 de FCM
  Future<String?> _getAccessToken() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(FCMConfig.serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      
      return accessToken;
    } catch (e) {
      debugPrint('❌ Error obteniendo access token: $e');
      return null;
    }
  }

  // Envía notificación push a un token específico
  Future<void> _sendPushNotificationV1({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ No se pudo obtener access token');
        return;
      }

      final url = 'https://fcm.googleapis.com/v1/projects/${FCMConfig.projectId}/messages:send';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data.map((key, value) => MapEntry(key, value.toString())),
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'inverti_channel',
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'alert': {
                    'title': title,
                    'body': body,
                  },
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Push notification enviada exitosamente');
        final responseData = json.decode(response.body);
        debugPrint('📊 Respuesta FCM V1: $responseData');
      } else {
        debugPrint('❌ Error enviando push V1: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      debugPrint('❌ Error en _sendPushNotificationV1: $e');
    }
  }

  // Envía notificación a todos los suscriptores de un tópico
  Future<void> sendToTopicV1({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ No se pudo obtener access token');
        return;
      }

      final url = 'https://fcm.googleapis.com/v1/projects/${FCMConfig.projectId}/messages:send';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data.map((key, value) => MapEntry(key, value.toString())),
            'android': {
              'priority': 'high',
            },
            'apns': {
              'payload': {
                'aps': {
                  'alert': {
                    'title': title,
                    'body': body,
                  },
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notificación enviada al tópico V1: $topic');
      } else {
        debugPrint('❌ Error enviando a tópico V1: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      debugPrint('❌ Error enviando a tópico V1: $e');
    }
  }

  // Notifica al emprendedor sobre interés de inversor
  Future<void> sendInvestorInterestNotification({
    required String entrepreneurId,
    required String projectId,
    required String projectTitle,
    required String investorName,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: entrepreneurId,
        title: 'Nuevo inversor interesado',
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

      await _sendPushNotificationToUserV1(
        userId: entrepreneurId,
        title: '🎯 Nuevo inversor interesado',
        body: '$investorName mostró interés en tu proyecto "$projectTitle"',
        data: {
          'userId': entrepreneurId,
          'projectId': projectId,
          'projectTitle': projectTitle,
          'investorName': investorName,
          'type': 'investor_interest',
        },
      );
      
      debugPrint('✅ Notificación de interés enviada completa V1');
      
    } catch (e) {
      debugPrint('❌ Error enviando notificación de interés V1: $e');
    }
  }

  // Notifica sobre nuevo proyecto disponible
  Future<void> sendNewProjectNotification({
    required String projectId,
    required String projectTitle,
    required String entrepreneurName,
    required String category,
  }) async {
    try {
      await sendToTopicV1(
        topic: 'new_projects',
        title: '💡 Nuevo proyecto disponible',
        body: '"$projectTitle" por $entrepreneurName - Categoría: $category',
        data: {
          'projectId': projectId,
          'projectTitle': projectTitle,
          'entrepreneurName': entrepreneurName,
          'category': category,
          'type': 'new_project',
        },
      );
      
      debugPrint('✅ Notificación de nuevo proyecto enviada V1');
      
    } catch (e) {
      debugPrint('❌ Error enviando notificación de nuevo proyecto V1: $e');
    }
  }

  // Envía notificación push a un usuario específico
  Future<void> _sendPushNotificationToUserV1({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ Usuario no encontrado: $userId');
        return;
      }

      final userData = userDoc.data()!;
      final userToken = userData['fcmToken'] as String?;

      if (userToken == null) {
        debugPrint('❌ Token FCM no encontrado para usuario: $userId');
        return;
      }

      await _sendPushNotificationV1(
        token: userToken,
        title: title,
        body: body,
        data: data ?? {},
      );

    } catch (e) {
      debugPrint('❌ Error enviando push a usuario V1: $e');
    }
  }

  // Suscribe el dispositivo a un tópico de notificaciones
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error suscribiéndose al tópico $topic: $e');
    }
  }

  // Desuscribe el dispositivo de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error desuscribiéndose del tópico $topic: $e');
    }
  }

  // Limpia tokens al cerrar sesión
  Future<void> clearTokenOnLogout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(_fcmToken!)
            .delete();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': FieldValue.delete(),
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ Token FCM limpiado al cerrar sesión');
      }
    } catch (e) {
      debugPrint('❌ Error limpiando token: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  // Libera recursos del servicio
  void dispose() {
    debugPrint('🧹 FCM Service disposed');
  }
}