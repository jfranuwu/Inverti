// Archivo: lib/screens/project/project_detail_screen.dart
// Pantalla de detalles del proyecto con Quick Pitch FUNCIONAL y CARRUSEL CORREGIDO

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
import '../profile/public_profile_screen.dart';
import 'edit_project_screen.dart';
import 'interested_investors_screen.dart';

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
    
    // Debug inicial del proyecto
    debugPrint('🔍 === PROJECT DETAIL SCREEN INICIADO ===');
    debugPrint('📋 Proyecto: ${widget.project.title}');
    debugPrint('📋 ID: ${widget.project.id}');
    debugPrint('🖼️ Número de imágenes: ${widget.project.images.length}');
    debugPrint('🖼️ URLs de imágenes: ${widget.project.images}');
    debugPrint('📋 Metadata completo: ${widget.project.metadata}');
    _debugQuickPitchInfo();
  }

  @override
  void dispose() {
    _imageController.dispose();
    if (_isPlayingPitch) {
      AudioService.stopAudio();
    }
    super.dispose();
  }

  // 🔍 Método de debug para Quick Pitch
  void _debugQuickPitchInfo() {
    debugPrint('🔍 === ANALIZANDO QUICK PITCH ===');
    debugPrint('📋 Metadata disponible:');
    widget.project.metadata.forEach((key, value) {
      debugPrint('   - $key: $value (${value.runtimeType})');
    });
    
    final quickPitchUrl = _getQuickPitchUrl();
    debugPrint('🎵 URL del Quick Pitch: $quickPitchUrl');
    debugPrint('🎵 Tiene Quick Pitch: ${quickPitchUrl != null}');
    debugPrint('🔍 === FIN ANÁLISIS ===');
  }

  // 🔥 HELPER GETTER CORREGIDO - Buscar Quick Pitch
  bool get _hasQuickPitch {
    final quickPitchUrl = _getQuickPitchUrl();
    final hasQuickPitch = quickPitchUrl != null && quickPitchUrl.isNotEmpty;
    
    debugPrint('🔍 _hasQuickPitch getter:');
    debugPrint('   - URL encontrada: $quickPitchUrl');
    debugPrint('   - Tiene Quick Pitch: $hasQuickPitch');
    
    return hasQuickPitch;
  }

  // 🔥 MÉTODO CORREGIDO - Obtener URL del Quick Pitch
  String? _getQuickPitchUrl() {
    final metadata = widget.project.metadata;
    
    // Buscar con múltiples posibles claves por compatibilidad
    final possibleKeys = ['quickPitchUrl', 'quick_pitch_url', 'quickPitch', 'audioUrl'];
    
    for (final key in possibleKeys) {
      final url = metadata[key];
      if (url != null && url is String && url.isNotEmpty) {
        debugPrint('✅ Quick Pitch encontrado con clave "$key": $url');
        return url;
      }
    }
    
    debugPrint('❌ No se encontró Quick Pitch URL en metadata');
    debugPrint('📋 Claves buscadas: $possibleKeys');
    debugPrint('📋 Metadata disponible: ${metadata.keys.toList()}');
    
    return null;
  }

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
      debugPrint('Error checking interest: $e');
      setState(() {
        _isCheckingInterest = false;
      });
    }
  }

  // 🔥 MÉTODO CORREGIDO - Reproducir Quick Pitch
  Future<void> _toggleQuickPitch() async {
    final quickPitchUrl = _getQuickPitchUrl();
    
    debugPrint('🎵 === INTENTANDO REPRODUCIR QUICK PITCH ===');
    debugPrint('🎵 URL: $quickPitchUrl');
    debugPrint('🎵 Estado actual: ${_isPlayingPitch ? "reproduciendo" : "detenido"}');
    
    if (quickPitchUrl == null || quickPitchUrl.isEmpty) {
      debugPrint('❌ No hay URL de Quick Pitch válida');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay Quick Pitch disponible para este proyecto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (_isPlayingPitch) {
        debugPrint('⏸️ Deteniendo reproducción de audio');
        await AudioService.stopAudio();
        setState(() {
          _isPlayingPitch = false;
        });
      } else {
        debugPrint('▶️ Iniciando reproducción de audio');
        debugPrint('🎵 URL completa: $quickPitchUrl');
        
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
      debugPrint('❌ Error playing audio: $e');
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

  // Expresar interés (para inversores)
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
              // 🔥 APP BAR CON CARRUSEL DE IMÁGENES CORREGIDO
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
                  background: _buildImageCarousel(project),
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
                      
                      // 🔥 SECCIÓN DE QUICK PITCH RESTAURADA
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

  // 🔥 CARRUSEL DE IMÁGENES CORREGIDO
  Widget _buildImageCarousel(ProjectModel project) {
    debugPrint('🖼️ Construyendo carrusel con ${project.images.length} imágenes');
    
    if (project.images.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Sin imágenes',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 🔥 PAGEVIEW MEJORADO PARA CARRUSEL
        PageView.builder(
          controller: _imageController,
          physics: const BouncingScrollPhysics(), // Mejores físicas de scroll
          onPageChanged: (index) {
            debugPrint('🖼️ Cambiando a imagen $index de ${project.images.length}');
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: project.images.length,
          itemBuilder: (context, index) {
            final imageUrl = project.images[index];
            debugPrint('🖼️ Cargando imagen $index: $imageUrl');
            
            return GestureDetector(
              onTap: () {
                // Mostrar imagen en pantalla completa al tocar
                _showFullScreenImage(project.images, index);
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Cargando imagen...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('❌ Error cargando imagen: $url - Error: $error');
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
              ),
            );
          },
        ),
        
        // Gradiente oscuro para mejor legibilidad
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
        
        // 🔥 INDICADORES DE PÁGINA MEJORADOS
        if (project.images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      project.images.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // 🔥 CONTADOR DE IMÁGENES
        if (project.images.length > 1)
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${project.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        // 🔥 BOTONES DE NAVEGACIÓN PARA DESKTOP/TABLET
        if (project.images.length > 1) ...[
          // Botón anterior
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_currentImageIndex > 0) {
                      _imageController.animateToPage(
                        _currentImageIndex - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          
          // Botón siguiente
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_currentImageIndex < project.images.length - 1) {
                      _imageController.animateToPage(
                        _currentImageIndex + 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 🔥 MÉTODO PARA MOSTRAR IMAGEN EN PANTALLA COMPLETA
  void _showFullScreenImage(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // 🔥 SECCIÓN DE QUICK PITCH RESTAURADA (EXACTAMENTE COMO FUNCIONABA)
  Widget _buildQuickPitchSection(ProjectModel project) {
    final quickPitchUrl = _getQuickPitchUrl();
    
    debugPrint('🎵 Building Quick Pitch section:');
    debugPrint('   - URL: $quickPitchUrl');
    debugPrint('   - Project ID: ${project.id}');
    
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
          
          // Botón de reproducir (TU IMPLEMENTACIÓN ORIGINAL)
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

// 🔥 VISOR DE IMÁGENES EN PANTALLA COMPLETA
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} de ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.1,
            maxScale: 3.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}