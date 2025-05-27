// Archivo: lib/screens/profile/public_profile_screen.dart
// Pantalla de perfil público para ver otros usuarios

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user_model.dart';
import '../../../models/project_model.dart';
import '../../../config/firebase_config.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/user_rating_stars.dart';
import '../../../widgets/project_status_chip.dart';
import '../project/project_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _userModel;
  List<ProjectModel> _userProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Cargar datos del usuario
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _userModel = UserModel.fromFirestore(userDoc);
      }

      // Si es emprendedor, cargar sus proyectos
      if (_userModel?.userType == 'entrepreneur') {
        final projectsSnapshot = await _firestore
            .collection(FirebaseConfig.projectsCollection)
            .where('entrepreneurId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .get();

        _userProjects = projectsSnapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName),
        ),
        body: const Center(
          child: Text('Usuario no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userModel!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header del perfil
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: _userModel!.photoURL != null
                        ? CachedNetworkImageProvider(_userModel!.photoURL!)
                        : null,
                    child: _userModel!.photoURL == null
                        ? Text(
                            _userModel!.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre y tipo
                  Text(
                    _userModel!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _userModel!.userType == 'investor'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _userModel!.userType == 'investor'
                          ? 'Inversor'
                          : 'Emprendedor',
                      style: TextStyle(
                        color: _userModel!.userType == 'investor'
                            ? Colors.blue
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  UserRatingStars(
                    rating: 4.5,
                    size: 20,
                  ),
                  
                  if (_userModel!.isVerified) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verificado',
                            style: TextStyle(
                              fontSize: 12,
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
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Biografía
                  if (_userModel!.bio != null && _userModel!.bio!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acerca de',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(_userModel!.bio!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Información adicional
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          
                          if (_userModel!.location != null)
                            _InfoRow(
                              icon: Icons.location_on,
                              label: 'Ubicación',
                              value: _userModel!.location!,
                            ),
                          
                          if (_userModel!.industries != null && 
                              _userModel!.industries!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.category,
                              label: 'Industrias de interés',
                              value: _userModel!.industries!.join(', '),
                            ),
                          
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Miembro desde',
                            value: _formatDate(_userModel!.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Proyectos del emprendedor
                  if (_userModel!.userType == 'entrepreneur' && 
                      _userProjects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Proyectos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    ..._userProjects.map((project) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                project: project,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ProjectStatusChip(status: project.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                project.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Meta: \$${project.fundingGoal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${project.fundingPercentage.toStringAsFixed(0)}% financiado',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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