// Archivo: lib/screens/project/project_detail_screen.dart
// Pantalla de detalles del proyecto con Quick Pitch - ACTUALIZADA

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/project_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/project_status_chip.dart';
import '../../../widgets/user_rating_stars.dart';
import '../../../services/audio_service.dart';
import '../profile/public_profile_screen.dart';
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
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
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
      final hasInterest = await projectProvider.checkUserInterest(
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
    if (!widget.project.hasQuickPitch) return;

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
        
        await AudioService.playAudio(widget.project.quickPitchUrl!);
        
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
  
  final success = await projectProvider.expressInterest(
    widget.project.id,
    authProvider.user!.uid,
  );
  
  if (!mounted) return;
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Has expresado interés en este proyecto!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Opcionalmente, crear una notificación para el emprendedor
    try {
     await FirebaseFirestore.instance
    .collection('notifications')
    .add({
      'userId': widget.project.entrepreneurId,
      'title': 'Nuevo inversor interesado',
      'body': '${authProvider.userModel?.name ?? 'Un inversor'} está interesado en tu proyecto ${widget.project.title}',
      'type': 'investor_interest',
      'data': {
        'projectId': widget.project.id,
        'projectTitle': widget.project.title,
        'investorId': authProvider.user!.uid,
        'investorName': authProvider.userModel?.name ?? 'Inversor',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    } catch (e) {
      print('Error creating notification: $e');
      // No fallar la operación por esto
    }
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
          userId: widget.project.entrepreneurId,
          userName: widget.project.entrepreneurName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isInvestor = authProvider.userModel?.userType == 'investor';
    final isOwner = widget.project.entrepreneurId == authProvider.user?.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Carousel de imágenes
                  if (widget.project.images != null && 
                      widget.project.images!.isNotEmpty)
                    PageView.builder(
                      controller: _imageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: widget.project.images!.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.project.images![index],
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
                  if (widget.project.images != null && 
                      widget.project.images!.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.project.images!.length,
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
                          widget.project.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ProjectStatusChip(status: widget.project.status),
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
                        widget.project.industry,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.project.location != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.project.location!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Pitch
                  if (widget.project.hasQuickPitch)
                    _buildQuickPitchSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Progreso de financiamiento
                  _buildFundingProgress(),
                  const SizedBox(height: 24),
                  
                  // Descripción
                  Text(
                    'Descripción del proyecto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.project.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Información del emprendedor
                  _buildEntrepreneurInfo(),
                  const SizedBox(height: 24),
                  
                  // Estadísticas
                  _buildStatistics(),
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
                        backgroundColor: _isInterested 
                            ? Colors.grey 
                            : Theme.of(context).primaryColor,
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implementar compartir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de compartir próximamente'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir proyecto'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ] else ...[
                    // Opciones para el dueño
                    CustomButton(
                      text: 'Editar proyecto',
                      onPressed: () {
                        // TODO: Navegar a editar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de edición próximamente'),
                          ),
                        );
                      },
                      icon: Icons.edit,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Ver estadísticas
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Estadísticas próximamente'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('Ver estadísticas'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Quick Pitch
  Widget _buildQuickPitchSection() {
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

  // Progreso de financiamiento
  Widget _buildFundingProgress() {
    final percentage = widget.project.fundingPercentage;
    final current = widget.project.currentFunding;
    final goal = widget.project.fundingGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta de financiamiento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${current.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'recaudados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${goal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'meta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (widget.project.roi != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ROI esperado: ${widget.project.roi}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Información del emprendedor
  Widget _buildEntrepreneurInfo() {
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
                    widget.project.entrepreneurName[0].toUpperCase(),
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
                        widget.project.entrepreneurName,
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

  // Estadísticas del proyecto
  Widget _buildStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas del proyecto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _StatItem(
                  icon: Icons.people,
                  label: 'Inversores interesados',
                  value: widget.project.interestedInvestors.toString(),
                ),
                _StatItem(
                  icon: Icons.visibility,
                  label: 'Vistas del proyecto',
                  value: '234', // Simulado
                ),
                _StatItem(
                  icon: Icons.calendar_today,
                  label: 'Días activo',
                  value: DateTime.now()
                      .difference(widget.project.createdAt)
                      .inDays
                      .toString(),
                ),
                _StatItem(
                  icon: Icons.attach_money,
                  label: 'Inversión promedio',
                  value: '\$5,000', // Simulado
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para estadísticas
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