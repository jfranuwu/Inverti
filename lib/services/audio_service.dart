// Archivo: lib/services/audio_service.dart
// Servicio para manejo de audio Quick Pitch

import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();
  
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentRecordingPath;
  
  // Estados
  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;
  static String? get currentRecordingPath => _currentRecordingPath;
  
  // Iniciar grabación de Quick Pitch
  static Future<bool> startRecording() async {
    try {
      // Verificar permisos
      if (!await _recorder.hasPermission()) {
        print('Sin permisos de micrófono');
        return false;
      }
      
      // Crear directorio temporal
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/quick_pitch_$timestamp.m4a';
      
      // Configurar grabación
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      
      // Iniciar grabación
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      
      // Detener automáticamente después de 60 segundos
      Future.delayed(const Duration(seconds: 60), () {
        if (_isRecording) {
          stopRecording();
        }
      });
      
      return true;
    } catch (e) {
      print('Error al iniciar grabación: $e');
      return false;
    }
  }
  
  // Detener grabación
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      final path = await _recorder.stop();
      _isRecording = false;
      
      return path;
    } catch (e) {
      print('Error al detener grabación: $e');
      return null;
    }
  }
  
  // Pausar grabación
  static Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _recorder.pause();
      }
    } catch (e) {
      print('Error al pausar grabación: $e');
    }
  }
  
  // Reanudar grabación
  static Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _recorder.resume();
      }
    } catch (e) {
      print('Error al reanudar grabación: $e');
    }
  }
  
  // Reproducir audio
  static Future<void> playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }
      
      // Verificar si es URL o archivo local
      if (audioPath.startsWith('http')) {
        await _player.play(UrlSource(audioPath));
      } else {
        await _player.play(DeviceFileSource(audioPath));
      }
      
      _isPlaying = true;
      
      // Escuchar cuando termine
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      print('Error al reproducir audio: $e');
    }
  }
  
  // Pausar audio
  static Future<void> pauseAudio() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error al pausar audio: $e');
    }
  }
  
  // Detener audio
  static Future<void> stopAudio() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error al detener audio: $e');
    }
  }
  
  // Obtener duración del audio
  static Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      if (audioPath.startsWith('http')) {
        await _player.setSource(UrlSource(audioPath));
      } else {
        await _player.setSource(DeviceFileSource(audioPath));
      }
      
      return await _player.getDuration();
    } catch (e) {
      print('Error al obtener duración: $e');
      return null;
    }
  }
  
  // Verificar si el archivo existe
  static Future<bool> audioFileExists(String path) async {
    try {
      if (path.startsWith('http')) {
        return true; // Asumimos que las URLs son válidas
      }
      
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  // Eliminar archivo de audio temporal
  static Future<bool> deleteAudioFile(String path) async {
    try {
      if (path.startsWith('http')) {
        return false; // No podemos eliminar archivos remotos
      }
      
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }
  
  // Obtener tamaño del archivo
  static Future<int> getFileSize(String path) async {
    try {
      if (path.startsWith('http')) {
        return 0; // No podemos obtener tamaño de archivos remotos fácilmente
      }
      
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error al obtener tamaño: $e');
      return 0;
    }
  }
  
  // Limpiar recursos
  static void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}