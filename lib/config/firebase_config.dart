// Archivo: lib/config/firebase_config.dart
// Configuración de Firebase para Android (Plan Spark Gratuito)

import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Configuración para Android - REEMPLAZAR CON TUS CREDENCIALES
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    //apiKey: 'AIzaSyB_8hfohCpVCXTzn7FLNit3QSzu4ORKpSo',
    apiKey: 'AIzaSyC6VXLpuBIyszwnIuQZV2zbTpga8QC3C1k',
    appId: '1:333011509093:android:b8ea63560a0494840c4b8c',
    messagingSenderId: '333011509093',
    projectId: 'inverti-app',
    storageBucket: 'inverti-app.firebasestorage.app',
  );
  
  // Límites del plan gratuito de Firebase
  static const FirebaseLimits freeLimits = FirebaseLimits(
    authVerifications: 10000,
    firestoreReads: 50000,
    firestoreWrites: 20000,
    firestoreDeletes: 20000,
    storageSize: 5,
    storageDownloads: 1,
    fcmMessages: -1,
  );
  
  // Colecciones de Firestore
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String interestsCollection = 'interests';
  static const String notificationsCollection = 'notifications';
  static const String paymentsCollection = 'payments';
  static const String investmentsCollection = 'investments';
  static const String chatsCollection = 'chats';
  static const String analyticsCollection = 'analytics';
  static const String fcmTokensCollection = 'fcm_tokens';
  
  // Rutas de Storage
  static const String userAvatarsPath = 'user_avatars';
  static const String projectImagesPath = 'project_images';
  static const String quickPitchAudioPath = 'quick_pitch_audio';
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';
  
  // Temas de notificaciones FCM
  static const String newProjectsTopic = 'new_projects';
  static const String investorInterestTopic = 'investor_interest';
  static const String platformUpdatesTopic = 'platform_updates';
  static const String generalNotificationsTopic = 'general_notifications';
  static const String maintenanceTopic = 'app_maintenance';
  
  // Configuración de notificaciones Android
  static const String androidNotificationChannelId = 'inverti_channel';
  static const String androidNotificationChannelName = 'Inverti Notifications';
  static const String androidNotificationChannelDescription = 
      'Notificaciones de la aplicación Inverti';

  // Configuración de archivos
  static const int maxProjectImages = 5;
  static const int maxFileSize = 10 * 1024 * 1024;
  static const int notificationRetentionDays = 30;

  // Genera ruta completa para avatares de usuario
  static String getUserAvatarPath(String userId) {
    return '$userAvatarsPath/$userId';
  }

  // Genera ruta completa para imágenes de proyecto
  static String getProjectImagePath(String projectId, String imageName) {
    return '$projectImagesPath/$projectId/$imageName';
  }

  // Genera ruta completa para audio de quick pitch
  static String getQuickPitchAudioPath(String projectId, String audioName) {
    return '$quickPitchAudioPath/$projectId/$audioName';
  }

  // Genera ruta completa para documentos
  static String getDocumentPath(String userId, String documentName) {
    return '$documentsPath/$userId/$documentName';
  }

  // Valida tamaño de archivo
  static bool isFileSizeValid(int fileSize) {
    return fileSize <= maxFileSize;
  }

  // Formatea tamaño de archivo para mostrar
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Obtiene temas de notificación según tipo de usuario - OPTIMIZADO PARA NOTIFICACIONES AUTOMÁTICAS
  static List<String> getTopicsForUserType(String userType) {
    switch (userType) {
      case 'investor':
        return [
          newProjectsTopic,
          generalNotificationsTopic,
          platformUpdatesTopic,
        ];
      case 'entrepreneur':
        return [
          investorInterestTopic,
          generalNotificationsTopic,
          platformUpdatesTopic,
        ];
      default:
        return [generalNotificationsTopic, platformUpdatesTopic];
    }
  }

  // Obtiene el tema principal para notificaciones automáticas por tipo de usuario
  static String getPrimaryNotificationTopic(String userType) {
    switch (userType) {
      case 'investor':
        return newProjectsTopic;
      case 'entrepreneur':
        return investorInterestTopic;
      default:
        return generalNotificationsTopic;
    }
  }

  // Verifica si un tema es válido
  static bool isValidTopic(String topic) {
    const validTopics = [
      newProjectsTopic,
      investorInterestTopic,
      platformUpdatesTopic,
      generalNotificationsTopic,
      maintenanceTopic,
    ];
    return validTopics.contains(topic);
  }

  // Reglas de validación para proyectos
  static const Map<String, dynamic> projectValidation = {
    'titleMinLength': 5,
    'titleMaxLength': 100,
    'descriptionMinLength': 50,
    'descriptionMaxLength': 2000,
    'minFundingGoal': 1000,
    'maxFundingGoal': 10000000,
    'minEquityOffered': 1,
    'maxEquityOffered': 49,
  };

  // Categorías disponibles para proyectos
  static const List<String> projectCategories = [
    'Tecnología',
    'Salud',
    'Educación',
    'Fintech',
    'E-commerce',
    'Sostenibilidad',
    'Entretenimiento',
    'Alimentación',
    'Transporte',
    'Inmobiliario',
    'Turismo',
    'Otro',
  ];

  // Rangos de inversión predefinidos
  static const List<Map<String, dynamic>> investmentRanges = [
    {'label': '\$1K - \$10K', 'min': 1000, 'max': 10000},
    {'label': '\$10K - \$50K', 'min': 10000, 'max': 50000},
    {'label': '\$50K - \$100K', 'min': 50000, 'max': 100000},
    {'label': '\$100K - \$500K', 'min': 100000, 'max': 500000},
    {'label': '\$500K+', 'min': 500000, 'max': 999999999},
  ];

  // Configuración de tipos de notificación - ACTUALIZADA PARA NOTIFICACIONES AUTOMÁTICAS
  static const Map<String, Map<String, dynamic>> notificationTypes = {
    'investor_interest': {
      'icon': '🎯',
      'title': 'Nuevo inversor interesado',
      'priority': 'high',
      'sound': 'default',
      'vibrate': true,
    },
    'project_funded': {
      'icon': '🎉',
      'title': 'Proyecto financiado',
      'priority': 'high',
      'sound': 'default',
      'vibrate': true,
    },
    'new_project': {
      'icon': '💡',
      'title': 'Nuevo proyecto disponible',
      'priority': 'normal',
      'sound': 'default',
      'vibrate': false,
    },
    'quick_pitch_uploaded': {
      'icon': '🎤',
      'title': 'Quick Pitch subido',
      'priority': 'normal',
      'sound': 'default',
      'vibrate': false,
    },
    'message': {
      'icon': '💬',
      'title': 'Nuevo mensaje',
      'priority': 'normal',
      'sound': 'default',
      'vibrate': true,
    },
    'general': {
      'icon': '📢',
      'title': 'Notificación general',
      'priority': 'normal',
      'sound': 'default',
      'vibrate': false,
    },
    'system': {
      'icon': '⚙️',
      'title': 'Actualización del sistema',
      'priority': 'low',
      'sound': 'none',
      'vibrate': false,
    },
  };

  // Obtiene configuración de notificación por tipo
  static Map<String, dynamic>? getNotificationConfig(String type) {
    return notificationTypes[type];
  }

  // Verifica si un tipo de notificación es de alta prioridad
  static bool isHighPriorityNotification(String type) {
    final config = getNotificationConfig(type);
    return config?['priority'] == 'high';
  }

  // Obtiene el icono para un tipo de notificación
  static String getNotificationIcon(String type) {
    final config = getNotificationConfig(type);
    return config?['icon'] ?? '📢';
  }

  // Obtiene el título para un tipo de notificación
  static String getNotificationTitle(String type) {
    final config = getNotificationConfig(type);
    return config?['title'] ?? 'Notificación';
  }

  // Verifica si Firebase está configurado correctamente
  static bool get isConfigured {
    return currentPlatform.apiKey.isNotEmpty && 
           currentPlatform.appId.isNotEmpty && 
           currentPlatform.messagingSenderId.isNotEmpty;
  }

  // Información de configuración para debug
  static Map<String, dynamic> get debugInfo {
    return {
      'projectId': currentPlatform.projectId,
      'storageBucket': currentPlatform.storageBucket,
      'isConfigured': isConfigured,
      'hasApiKey': currentPlatform.apiKey.isNotEmpty,
      'hasAppId': currentPlatform.appId.isNotEmpty,
      'hasSenderId': currentPlatform.messagingSenderId.isNotEmpty,
      'topics': {
        'newProjects': newProjectsTopic,
        'investorInterest': investorInterestTopic,
        'platformUpdates': platformUpdatesTopic,
        'general': generalNotificationsTopic,
      },
      'notificationChannel': {
        'id': androidNotificationChannelId,
        'name': androidNotificationChannelName,
        'description': androidNotificationChannelDescription,
      },
    };
  }

  // Configuración específica para notificaciones automáticas
  static const Map<String, dynamic> automaticNotifications = {
    'enabled': true,
    'retryAttempts': 3,
    'retryDelaySeconds': 5,
    'batchSize': 100,
    'timeoutSeconds': 30,
  };

  // Verifica si las notificaciones automáticas están habilitadas
  static bool get areAutomaticNotificationsEnabled {
    return automaticNotifications['enabled'] as bool;
  }

  // Obtiene configuración de reintentos para notificaciones
  static int get notificationRetryAttempts {
    return automaticNotifications['retryAttempts'] as int;
  }

  // Obtiene delay entre reintentos
  static int get notificationRetryDelay {
    return automaticNotifications['retryDelaySeconds'] as int;
  }
}

class FirebaseLimits {
  final int authVerifications;
  final int firestoreReads;
  final int firestoreWrites;
  final int firestoreDeletes;
  final int storageSize;
  final int storageDownloads;
  final int fcmMessages;
  
  const FirebaseLimits({
    required this.authVerifications,
    required this.firestoreReads,
    required this.firestoreWrites,
    required this.firestoreDeletes,
    required this.storageSize,
    required this.storageDownloads,
    required this.fcmMessages,
  });

  // Verifica si el uso actual está cerca del límite
  bool isNearLimit(String operation, int currentUsage) {
    switch (operation) {
      case 'reads':
        return currentUsage > (firestoreReads * 0.8);
      case 'writes':
        return currentUsage > (firestoreWrites * 0.8);
      case 'deletes':
        return currentUsage > (firestoreDeletes * 0.8);
      default:
        return false;
    }
  }

  // Resumen de límites en formato legible
  Map<String, String> get summary {
    return {
      'Auth': '$authVerifications verificaciones/mes',
      'Lecturas': '$firestoreReads lecturas/día',
      'Escrituras': '$firestoreWrites escrituras/día',
      'Eliminaciones': '$firestoreDeletes eliminaciones/día',
      'Storage': '${storageSize}GB total',
      'Descargas': '${storageDownloads}GB/día',
      'FCM': fcmMessages == -1 ? 'Ilimitado' : '$fcmMessages/día',
    };
  }
}