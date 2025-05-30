// Archivo: lib/widgets/audio_recorder_widget.dart
// Widget para grabar audio del Quick Pitch

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Duration maxDuration;
  final Function(String) onRecordingComplete;
  final VoidCallback? onRecordingDeleted;
  final String? initialAudioPath;

  const AudioRecorderWidget({
    super.key,
    required this.maxDuration,
    required this.onRecordingComplete,
    this.onRecordingDeleted,
    this.initialAudioPath,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  Timer? _recordingTimer;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _audioPath = widget.initialAudioPath;
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _playbackDuration = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _playbackDuration = Duration.zero;
      });
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermissions();
      if (!_hasPermission) {
        _showSnackBar('Permisos de micrófono requeridos', Colors.red);
        return;
      }
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'quick_pitch_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _startRecordingTimer();
      
    } catch (e) {
      _showSnackBar('Error al iniciar grabación: $e', Colors.red);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });
      
      _recordingTimer?.cancel();

      if (path != null) {
        setState(() {
          _audioPath = path;
        });
        widget.onRecordingComplete(path);
        _showSnackBar('Grabación completada', Colors.green);
      }
      
    } catch (e) {
      _showSnackBar('Error al detener grabación: $e', Colors.red);
    }
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });

      // Detener automáticamente al llegar al máximo
      if (_recordingDuration >= widget.maxDuration) {
        _stopRecording();
      }
    });
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;

    try {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      _showSnackBar('Error al reproducir audio: $e', Colors.red);
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _playbackDuration = Duration.zero;
    });
  }

  void _deleteRecording() {
    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }

    setState(() {
      _audioPath = null;
      _recordingDuration = Duration.zero;
      _playbackDuration = Duration.zero;
      _totalDuration = Duration.zero;
    });

    widget.onRecordingDeleted?.call();
    _showSnackBar('Grabación eliminada', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // Estado actual
          _buildStatusIndicator(),
          const SizedBox(height: 16),
          
          // Controles principales
          if (_audioPath == null)
            _buildRecordingControls()
          else
            _buildPlaybackControls(),
          
          const SizedBox(height: 16),
          
          // Barra de progreso
          _buildProgressBar(),
          
          const SizedBox(height: 8),
          
          // Información de duración
          _buildDurationInfo(),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mic_off,
            size: 32,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          const Text(
            'Permisos de micrófono requeridos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _checkPermissions,
            child: const Text('Solicitar permisos'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String status;
    Color color;
    IconData icon;
    
    if (_isRecording) {
      status = 'Grabando...';
      color = Colors.red;
      icon = Icons.fiber_manual_record;
    } else if (_audioPath != null) {
      if (_isPlaying) {
        status = 'Reproduciendo';
        color = Colors.blue;
        icon = Icons.play_arrow;
      } else {
        status = 'Grabación lista';
        color = Colors.green;
        icon = Icons.check_circle;
      }
    } else {
      status = 'Listo para grabar';
      color = Colors.grey;
      icon = Icons.mic;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Detener' : 'Grabar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reproducir/Pausar
        ElevatedButton.icon(
          onPressed: _isPlaying ? _pauseAudio : _playAudio,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(_isPlaying ? 'Pausar' : 'Reproducir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        
        // Detener
        if (_isPlaying)
          IconButton(
            onPressed: _stopAudio,
            icon: const Icon(Icons.stop),
            color: Colors.grey[600],
          ),
        
        // Grabar de nuevo
        TextButton.icon(
          onPressed: () {
            _deleteRecording();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Grabar de nuevo'),
        ),
        
        // Eliminar
        IconButton(
          onPressed: _deleteRecording,
          icon: const Icon(Icons.delete),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    double progress = 0.0;
    
    if (_isRecording) {
      progress = _recordingDuration.inMilliseconds / widget.maxDuration.inMilliseconds;
    } else if (_audioPath != null && _totalDuration.inMilliseconds > 0) {
      progress = _playbackDuration.inMilliseconds / _totalDuration.inMilliseconds;
    }
    
    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        _isRecording ? Colors.red : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDurationInfo() {
    String currentTime;
    String totalTime;
    
    if (_isRecording) {
      currentTime = _formatDuration(_recordingDuration);
      totalTime = _formatDuration(widget.maxDuration);
    } else if (_audioPath != null) {
      currentTime = _formatDuration(_playbackDuration);
      totalTime = _formatDuration(_totalDuration);
    } else {
      currentTime = '00:00';
      totalTime = _formatDuration(widget.maxDuration);
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          currentTime,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          totalTime,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}