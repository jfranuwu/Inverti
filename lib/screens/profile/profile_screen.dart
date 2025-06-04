// Archivo: lib/screens/profile/profile_screen.dart
// Pantalla de perfil - SIN APPBAR DUPLICADO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/user_rating_stars.dart';
import '../../../services/storage_service.dart';
import '../payments/subscription_plans_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar; // NUEVO: Controlar si mostrar AppBar
  
  const ProfileScreen({
    super.key,
    this.showAppBar = false, // Por defecto no mostrar (para uso en tabs)
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingBio = false;
  final _bioController = TextEditingController();
  bool _isSigningOut = false; // Para prevenir múltiples llamadas

  @override
  void initState() {
    super.initState();
    final userModel = context.read<AuthProvider>().userModel;
    _bioController.text = userModel?.bio ?? '';
    
    // Cargar datos de suscripción después del build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionProvider>().loadUserSubscriptionManually();
      }
    });
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
    
    if (userId == null || _isSigningOut) return;
    
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
    setState(() {
      _isEditingBio = false;
    });
  }

  // LOGOUT SIMPLIFICADO - Solo llama al AuthProvider, NO maneja navegación
  Future<void> _signOut() async {
    if (_isSigningOut) return; // Prevenir múltiples llamadas
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevenir cerrar accidentalmente
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      // Solo llamar al AuthProvider - NO manejar navegación aquí
      // El AuthWrapper se encargará automáticamente de la navegación
      await context.read<AuthProvider>().signOut();
      
      debugPrint('✅ Logout iniciado desde ProfileScreen');
      
    } catch (e) {
      debugPrint('❌ Error en logout desde ProfileScreen: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  // Navegar a planes de suscripción
  void _navigateToSubscriptionPlans() {
    if (_isSigningOut) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPlansScreen(),
      ),
    );
  }

  // Obtener beneficios del plan actual
  List<String> _getCurrentPlanBenefits(String plan, String userType) {
    if (userType == 'investor') {
      switch (plan) {
        case 'premium':
          return [
            'Contactos ilimitados',
            'Analytics avanzados de ROI',
            'Asesoría personalizada',
            'Acceso VIP a eventos',
          ];
        case 'pro':
          return [
            'Proyectos ilimitados',
            'Verificación de perfil',
            '20 contactos por mes',
            'Análisis de inversiones',
          ];
        default:
          return [
            'Ver 10 proyectos por mes',
            'Perfil básico',
            '3 contactos por mes',
          ];
      }
    } else {
      switch (plan) {
        case 'premium':
          return [
            'Mentoring personalizado',
            'Pitch deck profesional',
            'Conexiones directas VIP',
            'Eventos exclusivos',
          ];
        case 'pro':
          return [
            'Proyectos ilimitados',
            'Verificación de perfil',
            'Solicitudes ilimitadas',
            'Analytics de proyecto',
          ];
        default:
          return [
            'Publicar 3 proyectos por mes',
            'Perfil básico',
            '5 solicitudes de fondos',
          ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final userModel = authProvider.userModel;
    
    if (userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Usar el plan del SubscriptionProvider si está disponible, sino usar el del UserModel
    final currentPlan = subscriptionProvider.currentPlan != 'basic' 
        ? subscriptionProvider.currentPlan 
        : userModel.subscriptionPlan;

    final body = SingleChildScrollView(
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
                              userModel.name.isNotEmpty 
                                  ? userModel.name[0].toUpperCase()
                                  : 'U',
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
                        onPressed: _isSigningOut ? null : _updateProfilePhoto,
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
                
                // Rating
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
                // Plan de suscripción
                Card(
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          _getPlanColor(currentPlan).withOpacity(0.1),
                          _getPlanColor(currentPlan).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    color: _getPlanColor(currentPlan),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Plan de suscripción',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _getPlanName(currentPlan, userModel.userType),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getPlanColor(currentPlan),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (currentPlan != 'premium')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Actualizar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Beneficios del plan actual
                          Text(
                            'Beneficios incluidos:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Lista de beneficios
                          ..._getCurrentPlanBenefits(currentPlan, userModel.userType)
                              .take(3)
                              .map((benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: _getPlanColor(currentPlan),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          
                          const SizedBox(height: 16),
                          
                          // Botón para ver/cambiar plan
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSigningOut ? null : _navigateToSubscriptionPlans,
                              icon: const Icon(Icons.upgrade),
                              label: Text(
                                currentPlan == 'basic'
                                    ? 'Mejorar plan'
                                    : 'Gestionar suscripción',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _getPlanColor(currentPlan),
                                side: BorderSide(
                                  color: _getPlanColor(currentPlan),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                              onPressed: _isSigningOut ? null : () {
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
                
                // Historial de pagos
                if (currentPlan != 'basic')
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      title: const Text('Historial de pagos'),
                      subtitle: const Text('Ver transacciones y facturas'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _isSigningOut ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Historial de pagos'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.check_circle, color: Colors.green),
                                  title: Text('Plan ${_getPlanName(currentPlan, userModel.userType)}'),
                                  subtitle: const Text('28 May 2025 - Exitoso'),
                                  trailing: Text(
                                    currentPlan == 'pro' 
                                        ? (userModel.userType == 'investor' ? '\$29.99' : '\$39.99')
                                        : (userModel.userType == 'investor' ? '\$99.99' : '\$149.99'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (currentPlan != 'basic')
                  const SizedBox(height: 16),
                
                // Configuración
                Card(
                  child: Column(
                    children: [
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
                          onChanged: _isSigningOut ? null : (value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notificaciones'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _isSigningOut ? null : () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacidad'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _isSigningOut ? null : () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Ayuda y soporte'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _isSigningOut ? null : () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón cerrar sesión SIMPLIFICADO
                CustomButton(
                  text: _isSigningOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                  onPressed: _isSigningOut ? null : _signOut,
                  color: Colors.red,
                  icon: _isSigningOut ? null : Icons.logout,
                  isLoading: _isSigningOut,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );

    // NUEVO: Condicional para mostrar AppBar o no
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _isSigningOut ? null : () {
                // Navegar a configuración
              },
            ),
          ],
        ),
        body: body,
      );
    } else {
      // Sin AppBar para uso en tabs
      return body;
    }
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

  String _getPlanName(String plan, String userType) {
    if (userType == 'investor') {
      switch (plan) {
        case 'premium':
          return 'Inversor Premium';
        case 'pro':
          return 'Inversor Pro';
        default:
          return 'Inversor Básico';
      }
    } else {
      switch (plan) {
        case 'premium':
          return 'Emprendedor Premium';
        case 'pro':
          return 'Emprendedor Pro';
        default:
          return 'Emprendedor Básico';
      }
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