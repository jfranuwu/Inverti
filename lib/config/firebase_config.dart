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
  
  // Límites del plan gratuito de Firebase para referencia
  static const FirebaseLimits freeLimits = FirebaseLimits(
    authVerifications: 10000, // por mes
    firestoreReads: 50000, // por día
    firestoreWrites: 20000, // por día
    firestoreDeletes: 20000, // por día
    storageSize: 5, // GB
    storageDownloads: 1, // GB por día
    fcmMessages: -1, // ilimitado
  );
  
  // Colecciones de Firestore
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String interestsCollection = 'interests';
  static const String notificationsCollection = 'notifications';
  
  // Rutas de Storage
  static const String userAvatarsPath = 'user_avatars';
  static const String projectImagesPath = 'project_images';
  static const String quickPitchAudioPath = 'quick_pitch_audio';
  
  // Temas de notificaciones FCM
  static const String newProjectsTopic = 'new_projects';
  static const String investorInterestTopic = 'investor_interest';
  static const String platformUpdatesTopic = 'platform_updates';
}

// Clase auxiliar para límites del plan gratuito
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
}