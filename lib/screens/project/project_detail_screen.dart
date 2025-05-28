// Archivo: lib/screens/project/project_detail_screen.dart
// Pantalla de detalles del proyecto con Quick Pitch - ACTUALIZADA CON TIEMPO REAL

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/project_status_chip.dart';
import '../../widgets/user_rating_stars.dart';
import '../../widgets/real_time_stats_widget.dart';
import '../../services/audio_service.dart';
import '../../services/fcm_service.dart';
import '../profile/public_profile_screen.dart';
import 'edit_project_screen.dart';
import 'interested_investors_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isPlayingPitch = false;
  bool _isInterested = false;
  bool _isCheckingInterest = true;
  bool _isDeleting = false;
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  late String projectId;

  @override
  void initState() {
    super.initState();
    projectId = widget.project.id;
    _checkUserInterest();
  }

  @override
  void dispose() {
    _imageController.dispose();
    if (_isPlayingPitch) {
      AudioService.stopAudio();
    }
    super.dispose();
  }

  // Helper getters for missing properties
  bool get _hasQuickPitch => _getQuickPitchUrl() != null;
  String? _getQuickPitchUrl() => widget.project.metadata['quickPitchUrl'] as String?;
  String get _entrepreneurId => widget.project.createdBy;
  String get _entrepreneurName => widget.project.metadata['entrepreneurName'] as String? ?? 'Emprendedor';

  // Verificar si el usuario ya expresó interés
  Future<void> _checkUserInterest() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      setState(() {
        _isCheckingInterest = false;
      });
      return;
    }

    try {
      final projectProvider = context.read<ProjectProvider>();
      final hasInterest = await projectProvider.hasInvestorShownInterest(
        widget.project.id,
        authProvider.user!.uid,
      );

      setState(() {
        _isInterested = hasInterest;
        _isCheckingInterest = false;
      });
    } catch (e) {
      print('Error checking interest: $e');
      setState(() {
        _isCheckingInterest = false;
      });
    }
  }

  // Reproducir Quick Pitch
  Future<void> _toggleQuickPitch() async {
    final quickPitchUrl = _getQuickPitchUrl();
    if (quickPitchUrl == null) return;

    try {
      if (_isPlayingPitch) {
        await AudioService.stopAudio();
        setState(() {
          _isPlayingPitch = false;
        });
      } else {
        setState(() {
          _isPlayingPitch = true;
        });
        
        await AudioService.playAudio(quickPitchUrl);
        
        // Escuchar cuando termine (máximo 60 segundos)
        Future.delayed(const Duration(seconds: 60), () {
          if (mounted && _isPlayingPitch) {
            setState(() {
              _isPlayingPitch = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isPlayingPitch = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al reproducir el audio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Expresar interés (para inversores) - ACTUALIZADO CON NUEVO PROVIDER
  Future<void> _expressInterest() async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para expresar interés'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Verificar que sea un inversor
    if (authProvider.userModel?.userType != 'investor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo los inversores pueden expresar interés en proyectos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isInterested = true; // Optimistic update
    });
    
    // Usar el nuevo método del ProjectProvider
    final success = await projectProvider.registerInvestorInterest(
      projectId: widget.project.id,
      investorId: authProvider.user!.uid,
      investorName: authProvider.userModel?.name ?? 'Inversor',
    );
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Has expresado interés en este proyecto!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isInterested = false; // Revert on error
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projectProvider.error ?? 'Error al expresar interés'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navegar al perfil del emprendedor
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: _entrepreneurId,
          userName: _entrepreneurName,
        ),
      ),
    );
  }

  // Editar proyecto
  Future<void> _editProject(ProjectModel project) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProjectScreen(project: project),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyecto actualizado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Mostrar diálogo de confirmación para eliminar
  Future<bool?> _showDeleteConfirmationDialog(String projectTitle) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Eliminar proyecto?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Esta acción no se puede deshacer.'),
              const SizedBox(height: 8),
              Text(
                'Proyecto: $projectTitle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Eliminar proyecto
  Future<void> _deleteProject(ProjectModel project) async {
    final confirmed = await _showDeleteConfirmationDialog(project.title);

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      final success = await context
          .read<ProjectProvider>()
          .deleteProject(project.id);

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proyecto eliminado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el proyecto'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    final isInvestor = authProvider.userModel?.userType == 'investor';
    final isOwner = _entrepreneurId == currentUserId;

    return Scaffold(
      body: StreamBuilder<ProjectModel?>(
        stream: context.read<ProjectProvider>().getProjectStream(projectId),
        initialData: widget.project,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && 
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = snapshot.data ?? widget.project;

          return CustomScrollView(
            slivers: [
              // App bar con imagen y menú de opciones
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                actions: [
                  if (isOwner) ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Editar proyecto'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar proyecto'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editProject(project);
                        } else if (value == 'delete') {
                          _deleteProject(project);
                        }
                      },
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Carousel de imágenes
                      if (project.images.isNotEmpty)
                        PageView.builder(
                          controller: _imageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: project.images.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: project.images[index],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Error al cargar imagen',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.business,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      
                      // Gradiente oscuro
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      
                      // Indicadores de página
                      if (project.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              project.images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ProjectStatusChip(status: project.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Industria y ubicación
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.category,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (project.contactPhone.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'México', // Simulado
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Quick Pitch
                      if (_hasQuickPitch)
                        _buildQuickPitchSection(project),
                      
                      const SizedBox(height: 24),
                      
                      // Estadísticas en tiempo real
                      RealTimeStatsWidget(
                        project: project,
                        showTitle: true,
                      ),
                      const SizedBox(height: 24),
                      
                      // Descripción
                      Text(
                        'Descripción del proyecto',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      // Descripción completa si existe
                      if (project.fullDescription.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Detalles del proyecto',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.fullDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.justify,
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Información del emprendedor
                      _buildEntrepreneurInfo(project),
                      const SizedBox(height: 24),
                      
                      // Información financiera
                      _buildFinancialInfo(project),
                      const SizedBox(height: 24),
                      
                      // Información de contacto
                      _buildContactInfo(project),
                      const SizedBox(height: 32),
                      
                      // Botones de acción
                      if (!isOwner) ...[
                        if (isInvestor)
                          CustomButton(
                            text: _isCheckingInterest
                                ? 'Verificando...'
                                : _isInterested 
                                    ? 'Ya expresaste interés' 
                                    : 'Expresar interés',
                            onPressed: _isCheckingInterest || _isInterested 
                                ? null 
                                : _expressInterest,
                            icon: _isInterested ? Icons.check : Icons.star,
                            color: _isInterested 
                                ? Colors.grey 
                                : Theme.of(context).primaryColor,
                          ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Compartir proyecto',
                          onPressed: () {
                            // TODO: Implementar compartir
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función de compartir próximamente'),
                              ),
                            );
                          },
                          icon: Icons.share,
                          isOutlined: true,
                        ),
                      ] else ...[
                        // Opciones para el propietario
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Editar proyecto',
                                onPressed: () => _editProject(project),
                                icon: Icons.edit,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomButton(
                                text: 'Eliminar',
                                onPressed: _isDeleting ? null : () => _deleteProject(project),
                                icon: _isDeleting ? null : Icons.delete,
                                color: Colors.red,
                                isLoading: _isDeleting,
                              ),
                            ),
                          ],
                        ),
                        if (project.interestedInvestors > 0) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Ver inversores interesados (${project.interestedInvestors})',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InterestedInvestorsScreen(
                                      projectId: project.id,
                                      projectTitle: project.title,
                                    ),
                                  ),
                                );
                              },
                              icon: Icons.people,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sección de Quick Pitch
  Widget _buildQuickPitchSection(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Pitch de 60 segundos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Escucha al emprendedor presentar su proyecto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botón de reproducir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleQuickPitch,
              icon: Icon(_isPlayingPitch ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlayingPitch ? 'Pausar' : 'Reproducir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Información del emprendedor
  Widget _buildEntrepreneurInfo(ProjectModel project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sobre el emprendedor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _entrepreneurName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _entrepreneurName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      UserRatingStars(
                        rating: 4.5, // Simulado
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                OutlinedButton(
                  onPressed: _navigateToProfile,
                  child: const Text('Ver perfil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Información financiera
  Widget _buildFinancialInfo(ProjectModel project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información financiera',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Meta de financiamiento',
                    '\$${project.fundingGoal.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Equity ofrecido',
                    '${project.equityOffered}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Información de contacto
  Widget _buildContactInfo(ProjectModel project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de contacto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (project.contactEmail.isNotEmpty)
              _buildContactItem(
                Icons.email,
                'Email',
                project.contactEmail,
              ),
            if (project.contactPhone.isNotEmpty)
              _buildContactItem(
                Icons.phone,
                'Teléfono',
                project.contactPhone,
              ),
            if (project.website.isNotEmpty)
              _buildContactItem(
                Icons.language,
                'Sitio web',
                project.website,
              ),
            if (project.linkedin.isNotEmpty)
              _buildContactItem(
                Icons.business,
                'LinkedIn',
                project.linkedin,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para estadísticas - MANTENER PARA COMPATIBILIDAD
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}