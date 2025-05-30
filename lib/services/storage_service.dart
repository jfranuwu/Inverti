// Archivo: lib/services/storage_service.dart
// Servicio para manejo de Firebase Storage - VERSIÓN CORREGIDA

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();
  
  // Subir imagen de perfil
  static Future<String?> uploadProfileImage(String userId) async {
    try {
      // Seleccionar imagen de galería
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image == null) return null;
      
      // Crear referencia en Storage
      final ref = _storage.ref().child(
        '${FirebaseConfig.userAvatarsPath}/$userId.jpg',
      );
      
      // Subir archivo
      final uploadTask = await ref.putFile(File(image.path));
      
      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error al subir imagen de perfil: $e');
      return null;
    }
  }
  
  // Subir imagen de proyecto
  static Future<String?> uploadProjectImage(
    String projectId,
    String imageName,
  ) async {
    try {
      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      
      // Crear referencia
      final ref = _storage.ref().child(
        '${FirebaseConfig.projectImagesPath}/$projectId/$imageName.jpg',
      );
      
      // Subir archivo
      final uploadTask = await ref.putFile(File(image.path));
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error al subir imagen de proyecto: $e');
      return null;
    }
  }
  
  // Subir múltiples imágenes de proyecto
  static Future<List<String>> uploadProjectImages(
    String projectId,
    int maxImages,
  ) async {
    try {
      final List<String> imageUrls = [];
      
      // Seleccionar múltiples imágenes
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      // Limitar número de imágenes
      final imagesToUpload = images.take(maxImages);
      
      // Subir cada imagen
      int index = 0;
      for (final image in imagesToUpload) {
        final ref = _storage.ref().child(
          '${FirebaseConfig.projectImagesPath}/$projectId/image_$index.jpg',
        );
        
        final uploadTask = await ref.putFile(File(image.path));
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
        index++;
      }
      
      return imageUrls;
    } catch (e) {
      debugPrint('Error al subir imágenes de proyecto: $e');
      return [];
    }
  }
  
  // 🔥 MÉTODO PRINCIPAL - Subir audio de Quick Pitch (RESTAURADO EXACTAMENTE COMO FUNCIONABA)
  static Future<String?> uploadQuickPitchAudio(
    String projectId,
    String audioPath,
  ) async {
    try {
      debugPrint('🎵 StorageService.uploadQuickPitchAudio called:');
      debugPrint('   - projectId: $projectId');
      debugPrint('   - audioPath: $audioPath');
      
      // Validar que el path no esté vacío
      if (audioPath.trim().isEmpty) {
        debugPrint('❌ Audio path is empty');
        return null;
      }

      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('❌ Audio file does not exist at path: $audioPath');
        return null;
      }

      // Crear referencia - USANDO LA ESTRUCTURA ORIGINAL QUE FUNCIONABA
      final ref = _storage.ref().child(
        '${FirebaseConfig.quickPitchAudioPath}/$projectId.m4a',
      );
      
      debugPrint('🎵 Firebase Storage reference: ${ref.fullPath}');
      
      // Subir archivo - MANTENER CONFIGURACIÓN ORIGINAL
      final uploadTask = await ref.putFile(File(audioPath));
      
      // Obtener URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      debugPrint('✅ Quick Pitch uploaded successfully!');
      debugPrint('   - Download URL: $downloadUrl');
      debugPrint('   - File size: ${await file.length()} bytes');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading Quick Pitch: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  // Eliminar archivo
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar archivo: $e');
      return false;
    }
  }
  
  // Obtener metadata de archivo
  static Future<FullMetadata?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('Error al obtener metadata: $e');
      return null;
    }
  }
  
  // Verificar si un archivo existe
  static Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Obtener tamaño total usado (para monitorear límites gratuitos)
  static Future<int> getTotalStorageUsed() async {
    try {
      // Nota: Firebase no proporciona una API directa para esto
      // Esta es una implementación simplificada
      int totalBytes = 0;
      
      // Listar archivos en cada carpeta
      final paths = [
        FirebaseConfig.userAvatarsPath,
        FirebaseConfig.projectImagesPath,
        FirebaseConfig.quickPitchAudioPath,
      ];
      
      for (final path in paths) {
        final result = await _storage.ref().child(path).listAll();
        
        for (final item in result.items) {
          final metadata = await item.getMetadata();
          totalBytes += metadata.size ?? 0;
        }
      }
      
      return totalBytes;
    } catch (e) {
      debugPrint('Error al calcular almacenamiento usado: $e');
      return 0;
    }
  }
  
  // Convertir bytes a formato legible
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}