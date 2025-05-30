// Archivo: lib/widgets/audio_player_widget.dart
// Widget para reproducir Quick Pitch existente

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String title;
  final Duration? maxDuration;
  final VoidCallback? onPlayComplete;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.title = 'Quick Pitch',
    this.maxDuration,
    this.onPlayComplete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    // Listener para duración total
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    // Listener para posición actual
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listener para cuando termina la reproducción
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      widget.onPlayComplete?.call();
      _positionTimer?.cancel();
    });

    // Listener para errores
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _audioPlayer.play(UrlSource(widget.audioUrl));
      
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });

      // Timer para actualizar posición cada segundo
      _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPlaying) {
          timer.cancel();
        }
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      _positionTimer?.cancel();
    } catch (e) {
      debugPrint('Error pausando audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      _positionTimer?.cancel();
    } catch (e) {
      debugPrint('Error deteniendo audio: $e');
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error buscando posición: $e');
    }
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y estado
          Row(
            children: [
              Icon(
                Icons.mic,
                color: theme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de estado
              _buildStatusIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Controles de reproducción
          Row(
            children: [
              // Botón play/pause principal
              _isLoading
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(),
                    )
                  : IconButton(
                      onPressed: _isPlaying ? _pauseAudio : _playAudio,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
              
              const SizedBox(width: 16),
              
              // Botón stop
              if (_isPlaying || _currentPosition > Duration.zero)
                IconButton(
                  onPressed: _stopAudio,
                  icon: const Icon(Icons.stop),
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              
              const Spacer(),
              
              // Información de tiempo
              Text(
                '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Barra de progreso
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (_isPlaying) {
      return const Icon(
        Icons.volume_up,
        color: Colors.green,
        size: 20,
      );
    }
    
    return Icon(
      Icons.volume_mute,
      color: Colors.grey[600],
      size: 20,
    );
  }

  String _getStatusText() {
    if (_isLoading) return 'Cargando...';
    if (_isPlaying) return 'Reproduciendo';
    if (_currentPosition > Duration.zero) return 'Pausado';
    return 'Listo para reproducir';
  }

  Widget _buildProgressBar() {
    double progress = 0.0;
    
    if (_totalDuration.inMilliseconds > 0) {
      progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    }
    
    return GestureDetector(
      onTapDown: (details) {
        if (_totalDuration.inMilliseconds > 0) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final relativePosition = localPosition.dx / box.size.width;
            final seekPosition = Duration(
              milliseconds: (_totalDuration.inMilliseconds * relativePosition).round(),
            );
            _seekTo(seekPosition);
          }
        }
      },
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Colors.grey[300],
        ),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}