// Archivo: lib/widgets/audio_recorder_widget.dart
// Widget para Quick Pitch: Grabador de audio de 60 segundos

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Duration maxDuration;
  final Function(String path) onRecordingComplete;
  final Function() onRecordingDeleted;

  const AudioRecorderWidget({
    super.key,
    required this.maxDuration,
    required this.onRecordingComplete,
    required this.onRecordingDeleted,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      AudioService.stopRecording();
    }
    if (_isPlaying) {
      AudioService.stopAudio();
    }
    super.dispose();
  }

  // Iniciar grabación
  Future<void> _startRecording() async {
    final success = await AudioService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });
      
      // Iniciar timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
        
        // Detener automáticamente al alcanzar duración máxima
        if (_recordingDuration >= widget.maxDuration) {
          _stopRecording();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la grabación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Detener grabación
  Future<void> _stopRecording() async {
    _timer?.cancel();
    
    final path = await AudioService.stopRecording();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordingPath = path;
      });
      widget.onRecordingComplete(path);
    }
  }

  // Pausar/reanudar grabación
  Future<void> _togglePause() async {
    if (_isPaused) {
      await AudioService.resumeRecording();
      setState(() {
        _isPaused = false;
      });
      
      // Reanudar timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + timer.tick,
          );
        });
        
        if (_recordingDuration >= widget.maxDuration) {
          _stopRecording();
        }
      });
    } else {
      await AudioService.pauseRecording();
      _timer?.cancel();
      setState(() {
        _isPaused = true;
      });
    }
  }

  // Reproducir grabación
  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    
    if (_isPlaying) {
      await AudioService.stopAudio();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await AudioService.playAudio(_recordingPath!);
      setState(() {
        _isPlaying = true;
      });
      
      // Detectar cuando termine la reproducción
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  // Eliminar grabación
  Future<void> _deleteRecording() async {
    if (_recordingPath != null) {
      await AudioService.deleteAudioFile(_recordingPath!);
    }
    
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
    
    widget.onRecordingDeleted();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Visualizador de audio
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: _isRecording
                  ? _buildWaveform()
                  : _hasRecording
                      ? _buildPlaybackControls()
                      : Icon(
                          Icons.mic_none,
                          size: 40,
                          color: Colors.grey[400],
                        ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Duración
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : Colors.grey[700],
            ),
          ),
          Text(
            '/ ${_formatDuration(widget.maxDuration)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Controles
          if (!_isRecording && !_hasRecording)
            // Botón iniciar grabación
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Iniciar grabación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(200, 50),
              ),
            )
          else if (_isRecording)
            // Controles de grabación
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pausar/Reanudar
                IconButton(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Detener
                IconButton(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else
            // Controles de grabación completa
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reproducir
                IconButton(
                  onPressed: _playRecording,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Eliminar
                IconButton(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Regrabar
                IconButton(
                  onPressed: () {
                    _deleteRecording();
                    _startRecording();
                  },
                  icon: const Icon(Icons.refresh, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Construir forma de onda animada
  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: _isPaused ? 20 : (20 + (index % 3) * 10).toDouble(),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // Construir controles de reproducción
  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(30, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 2,
          height: 20 + (index % 4) * 10,
          decoration: BoxDecoration(
            color: _isPlaying 
                ? Theme.of(context).primaryColor 
                : Colors.grey[400],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  // Formatear duración
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}