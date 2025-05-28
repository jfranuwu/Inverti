// Archivo: lib/widgets/real_time_stats_widget.dart
// Widget para mostrar estadísticas en tiempo real

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';

class RealTimeStatsWidget extends StatelessWidget {
  final ProjectModel project;
  final bool showTitle;
  final EdgeInsets? padding;

  const RealTimeStatsWidget({
    super.key,
    required this.project,
    this.showTitle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectModel?>(
      stream: context.read<ProjectProvider>().getProjectStream(project.id),
      initialData: project,
      builder: (context, snapshot) {
        final currentProject = snapshot.data ?? project;
        
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
              
              // Barra de progreso
              _buildProgressBar(context, currentProject),
              const SizedBox(height: 16),
              
              // Estadísticas principales
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.attach_money,
                      label: 'Recaudado',
                      value: '\$${currentProject.currentFunding.toStringAsFixed(0)}',
                      subtitle: 'de \$${currentProject.fundingGoal.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.people,
                      label: 'Interesados',
                      value: currentProject.interestedInvestors.toString(),
                      subtitle: _getInterestedChange(project, currentProject),
                      color: Colors.orange,
                      isClickable: currentProject.interestedInvestors > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.percent,
                      label: 'Progreso',
                      value: '${currentProject.fundingPercentage.toStringAsFixed(1)}%',
                      subtitle: _getProgressChange(project, currentProject),
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
                    (currentProject.views ?? 0).toString(),
                    Icons.visibility,
                    Colors.blue,
                  ),
                  _buildMiniStat(
                    'Estado',
                    _getStatusText(currentProject.status),
                    _getStatusIcon(currentProject.status),
                    _getStatusColor(currentProject.status),
                  ),
                  _buildMiniStat(
                    'Creado',
                    _formatDate(currentProject.createdAt),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const _PulsingDot(),
          ),
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
                color: Colors.grey[600],
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
          value: project.fundingPercentage / 100,
          backgroundColor: Colors.grey[300],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
              color: Colors.grey[600],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
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

  String _getInterestedChange(ProjectModel oldProject, ProjectModel newProject) {
    final change = newProject.interestedInvestors - oldProject.interestedInvestors;
    if (change > 0) {
      return '+$change nuevo${change > 1 ? 's' : ''}';
    } else if (change < 0) {
      return '$change';
    }
    return 'Sin cambios';
  }

  String _getProgressChange(ProjectModel oldProject, ProjectModel newProject) {
    final change = newProject.fundingPercentage - oldProject.fundingPercentage;
    if (change > 0) {
      return '+${change.toStringAsFixed(1)}%';
    } else if (change < 0) {
      return '${change.toStringAsFixed(1)}%';
    }
    return 'Sin cambios';
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
          child: child,
        );
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Widget compacto para usar en cards pequeñas
class CompactRealTimeStats extends StatelessWidget {
  final ProjectModel project;

  const CompactRealTimeStats({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectModel?>(
      stream: context.read<ProjectProvider>().getProjectStream(project.id),
      initialData: project,
      builder: (context, snapshot) {
        final currentProject = snapshot.data ?? project;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCompactStat(
              '\$${currentProject.currentFunding.toStringAsFixed(0)}',
              'Recaudado',
              Icons.attach_money,
              Colors.green,
            ),
            _buildCompactStat(
              currentProject.interestedInvestors.toString(),
              'Interesados',
              Icons.people,
              Colors.orange,
            ),
            _buildCompactStat(
              '${currentProject.fundingPercentage.toStringAsFixed(0)}%',
              'Progreso',
              Icons.percent,
              Colors.blue,
            ),
          ],
        );
      },
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
}