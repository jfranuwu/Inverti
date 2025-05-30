// Archivo: lib/widgets/real_time_stats_widget.dart
// Widget para mostrar estadísticas en tiempo real del proyecto

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';
import 'package:intl/intl.dart';

class RealTimeStatsWidget extends StatelessWidget {
  final ProjectModel project;
  final bool showTitle;
  final bool isCompact;
  final EdgeInsets? padding;

  const RealTimeStatsWidget({
    super.key,
    required this.project,
    this.showTitle = false,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectModel?>(
      stream: context.read<ProjectProvider>().getProjectStream(project.id),
      initialData: project,
      builder: (context, snapshot) {
        ProjectModel currentProject = project;
        
        // Si hay datos del stream, actualizar el proyecto
        if (snapshot.hasData && snapshot.data != null) {
          try {
            currentProject = snapshot.data!;
          } catch (e) {
            // Si hay error parseando, usar el proyecto original
            debugPrint('Error parsing project from stream: $e');
          }
        }

        if (isCompact) {
          return _buildCompactStats(context, currentProject);
        }

        return Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                Row(
                  children: [
                    Text(
                      'Estadísticas en tiempo real',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildLiveIndicator(),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              _buildFullStats(context, currentProject),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullStats(BuildContext context, ProjectModel project) {
    return Column(
      children: [
        // Barra de progreso
        _buildProgressBar(context, project),
        const SizedBox(height: 16),
        
        // Grid de estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.attach_money,
                label: 'Recaudado',
                value: '\$${_formatNumber(project.currentFunding)}',
                subtitle: 'de \$${_formatNumber(project.fundingGoal)}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.people,
                label: 'Interesados',
                value: project.interestedInvestors.toString(),
                subtitle: _getInterestedLabel(project.interestedInvestors),
                color: Colors.orange,
                isClickable: project.interestedInvestors > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.percent,
                label: 'Progreso',
                value: '${project.fundingPercentage.toStringAsFixed(1)}%',
                subtitle: _getProgressStatus(project.fundingPercentage),
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Estadísticas secundarias
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat(
              'Vistas',
              (project.views ?? 0).toString(),
              Icons.visibility,
              Colors.blue,
            ),
            _buildMiniStat(
              'Estado',
              _getStatusText(project.status),
              _getStatusIcon(project.status),
              _getStatusColor(project.status),
            ),
            _buildMiniStat(
              'Creado',
              _formatDate(project.createdAt),
              Icons.calendar_today,
              Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, ProjectModel project) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de financiamiento',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '${project.fundingPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: (project.fundingPercentage / 100).clamp(0.0, 1.0),
          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
    bool isClickable = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? color.withOpacity(0.15) 
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isClickable) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.touch_app,
              size: 12,
              color: color.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStats(BuildContext context, ProjectModel project) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCompactStat(
          '\$${_formatNumber(project.currentFunding)}',
          'Recaudado',
          Icons.attach_money,
          Colors.green,
        ),
        _buildCompactStat(
          project.interestedInvestors.toString(),
          'Interesados',
          Icons.people,
          Colors.orange,
        ),
        _buildCompactStat(
          '${project.fundingPercentage.toStringAsFixed(0)}%',
          'Progreso',
          Icons.percent,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCompactStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Métodos de utilidad
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _getInterestedLabel(int count) {
    if (count == 0) return 'Ninguno aún';
    if (count == 1) return 'inversor';
    return 'inversores';
  }

  String _getProgressStatus(double percentage) {
    if (percentage >= 100) return 'Completado';
    if (percentage >= 75) return 'Casi listo';
    if (percentage >= 50) return 'Avanzando';
    if (percentage >= 25) return 'En progreso';
    return 'Iniciando';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'funded':
        return 'Financiado';
      case 'draft':
        return 'Borrador';
      case 'paused':
        return 'Pausado';
      case 'completed':
        return 'Completado';
      default:
        return 'Desconocido';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.play_arrow;
      case 'funded':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit;
      case 'paused':
        return Icons.pause;
      case 'completed':
        return Icons.celebration;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'funded':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'paused':
        return Colors.red;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 365) {
      return 'Hace ${(difference.inDays / 30).floor()}m';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Widget para el punto pulsante del indicador LIVE
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}