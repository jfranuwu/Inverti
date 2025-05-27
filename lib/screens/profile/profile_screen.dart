// Archivo: lib/screens/profile/profile_screen.dart
// Pantalla de perfil con avatar y cambio de tema

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/user_rating_stars.dart';
import '../../../services/storage_service.dart';
import '../payments/subscription_plans_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingBio = false;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userModel = context.read<AuthProvider>().userModel;
    _bioController.text = userModel?.bio ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // Actualizar foto de perfil
  Future<void> _updateProfilePhoto() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;
    
    final photoUrl = await StorageService.uploadProfileImage(userId);
    
    if (photoUrl != null) {
      final success = await authProvider.updateProfilePhoto(photoUrl);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Guardar biografía
  Future<void> _saveBio() async {
    // Implementar guardado de biografía
    setState(() {
      _isEditingBio = false;
    });
  }

  // Cerrar sesión
  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final userModel = authProvider.userModel;
    
    if (userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar a configuración
            },
          ),
        ],
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: userModel.photoURL != null
                            ? CachedNetworkImageProvider(userModel.photoURL!)
                            : null,
                        child: userModel.photoURL == null
                            ? Text(
                                userModel.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: _updateProfilePhoto,
                          icon: const Icon(Icons.camera_alt),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre y tipo de usuario
                  Text(
                    userModel.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: userModel.userType == 'investor'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      userModel.userType == 'investor'
                          ? 'Inversor'
                          : 'Emprendedor',
                      style: TextStyle(
                        color: userModel.userType == 'investor'
                            ? Colors.blue
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating (simulado)
                  UserRatingStars(
                    rating: 4.5,
                    size: 20,
                  ),
                  const SizedBox(height: 16),
                  
                  // Estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        value: userModel.userType == 'investor' ? '12' : '3',
                        label: userModel.userType == 'investor'
                            ? 'Inversiones'
                            : 'Proyectos',
                      ),
                      _StatColumn(
                        value: '4.5',
                        label: 'Rating',
                      ),
                      _StatColumn(
                        value: DateTime.now()
                            .difference(userModel.createdAt)
                            .inDays
                            .toString(),
                        label: 'Días activo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenido del perfil
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información personal
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Información personal',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (userModel.isVerified)
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
                          ),
                          const SizedBox(height: 16),
                          
                          _InfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: userModel.email,
                          ),
                          if (userModel.phone != null)
                            _InfoRow(
                              icon: Icons.phone,
                              label: 'Teléfono',
                              value: userModel.phone!,
                            ),
                          if (userModel.location != null)
                            _InfoRow(
                              icon: Icons.location_on,
                              label: 'Ubicación',
                              value: userModel.location!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Biografía
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Biografía',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isEditingBio ? Icons.check : Icons.edit,
                                ),
                                onPressed: () {
                                  if (_isEditingBio) {
                                    _saveBio();
                                  } else {
                                    setState(() {
                                      _isEditingBio = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          if (_isEditingBio)
                            TextField(
                              controller: _bioController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Cuéntanos sobre ti...',
                                border: InputBorder.none,
                              ),
                            )
                          else
                            Text(
                              userModel.bio ?? 'Sin biografía',
                              style: TextStyle(
                                color: userModel.bio != null
                                    ? null
                                    : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Plan de suscripción
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.diamond,
                        color: _getPlanColor(userModel.subscriptionPlan),
                      ),
                      title: const Text('Plan de suscripción'),
                      subtitle: Text(_getPlanName(userModel.subscriptionPlan)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPlansScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Configuración
                  Card(
                    child: Column(
                      children: [
                        // Cambio de tema
                        ListTile(
                          leading: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: const Text('Tema'),
                          subtitle: Text(
                            themeProvider.isDarkMode ? 'Oscuro' : 'Claro',
                          ),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        
                        // Notificaciones
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notificaciones'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Configurar notificaciones
                          },
                        ),
                        const Divider(height: 1),
                        
                        // Privacidad
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('Privacidad'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Ver configuración de privacidad
                          },
                        ),
                        const Divider(height: 1),
                        
                        // Ayuda
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Ayuda y soporte'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Abrir ayuda
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón cerrar sesión
                  CustomButton(
                    text: 'Cerrar sesión',
                    onPressed: _signOut,
                    backgroundColor: Colors.red,
                    icon: Icons.logout,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'premium':
        return Colors.purple;
      case 'pro':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPlanName(String plan) {
    switch (plan) {
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      default:
        return 'Básico';
    }
  }
}

// Widgets auxiliares
class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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