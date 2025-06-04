// Archivo: lib/screens/home/entrepreneur_home_screen.dart
// Pantalla principal para emprendedores - ACTUALIZADA CON SISTEMA DE CHAT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/project_status_chip.dart';
import '../../widgets/quick_action_fab.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/chat_icon_widget.dart';
import '../project/create_project_screen.dart';
import '../project/project_detail_screen.dart';
import '../project/interested_investors_screen.dart';
import '../project/edit_project_screen.dart';
import '../chat/chats_list_screen.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../maps/office_location_screen.dart';
import '../payments/subscription_plans_screen.dart';

class EntrepreneurHomeScreen extends StatefulWidget {
  const EntrepreneurHomeScreen({super.key});

  @override
  State<EntrepreneurHomeScreen> createState() => _EntrepreneurHomeScreenState();
}

class _EntrepreneurHomeScreenState extends State<EntrepreneurHomeScreen> 
    with ChatProviderInitializer {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const _MyProjectsTab(),
      const ChatsListScreen(showAppBar: false),
      const _InvestorsTab(),
      const ProfileScreen(),
    ];
    
    // Cargar proyectos del emprendedor
    Future.microtask(() {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<ProjectProvider>().loadMyProjects(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userModel?.name ?? 'Emprendedor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Hola, $userName' : _getPageTitle(),
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          // ÍCONO DE CHAT CON CONTADOR EN APPBAR
          if (_selectedIndex != 2) // No mostrar en la pantalla de chats
            const ChatAppBarAction(),
          
          NotificationBadge(
            count: 5, // Simulado
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Proyectos',
          ),
          // NUEVA NAVEGACIÓN DE CHAT CON CONTADOR
          NavigationDestination(
            icon: ChatBottomNavItem(isSelected: _selectedIndex == 2),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Inversores',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 1: // Tab de Proyectos
        return QuickActionFab(
          actions: [
            QuickAction(
              icon: Icons.add,
              label: 'Nuevo proyecto',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProjectScreen(),
                  ),
                );
              },
            ),
            QuickAction(
              icon: Icons.location_on,
              label: 'Oficinas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OfficeLocationScreen(),
                  ),
                );
              },
            ),
          ],
        );
      case 2: // Tab de Chats
        return null; // Los chats manejan su propia navegación
      default:
        return null;
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Mis Proyectos';
      case 2:
        return 'Conversaciones';
      case 3:
        return 'Inversores';
      case 4:
        return 'Mi Perfil';
      default:
        return 'Inverti';
    }
  }
}

// Tab de inicio para emprendedores - ACTUALIZADO CON BOTONES DE CHAT
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final myProjects = projectProvider.myProjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NUEVA SECCIÓN: Resumen de actividad con chats
          _buildActivitySummary(context, myProjects, chatProvider),
          const SizedBox(height: 24),
          
          // Resumen de proyectos (original)
          _buildProjectsSummary(context, myProjects),
          const SizedBox(height: 24),
          
          // Proyectos recientes
          if (myProjects.isNotEmpty) ...[
            Text(
              'Proyectos recientes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            ...myProjects.take(2).map((project) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ProjectSummaryCard(
                title: project.title,
                status: project.status,
                fundingPercentage: project.fundingPercentage,
                interestedInvestors: project.interestedInvestors,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(project: project),
                    ),
                  );
                },
              ),
            )),
          ] else ...[
            // Mensaje para crear primer proyecto
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.rocket_launch_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes proyectos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer proyecto y conecta con inversores',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crear proyecto'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
          
          // Accesos rápidos actualizados
          Text(
            'Recursos útiles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              // NUEVA TARJETA: Conversaciones
              _ResourceCard(
                icon: Icons.chat_bubble,
                title: 'Conversaciones',
                color: Colors.blue,
                badge: chatProvider.totalUnreadCount > 0 
                    ? chatProvider.totalUnreadCount.toString() 
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatsListScreen(),
                    ),
                  );
                },
              ),
              _ResourceCard(
                icon: Icons.school,
                title: 'Guía de pitch',
                color: Colors.green,
                onTap: () {
                  // Abrir guía
                },
              ),
              _ResourceCard(
                icon: Icons.diamond,
                title: 'Planes Premium',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
              ),
              _ResourceCard(
                icon: Icons.location_on,
                title: 'Oficinas',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfficeLocationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NUEVA FUNCIÓN: Resumen de actividad con chats
  Widget _buildActivitySummary(BuildContext context, List<dynamic> myProjects, ChatProvider chatProvider) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    
    if (currentUserId == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad reciente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActivityItem(
                  icon: Icons.chat_bubble,
                  count: chatProvider.userChats.length,
                  label: 'Conversaciones',
                  color: Colors.blue,
                  badge: chatProvider.totalUnreadCount,
                ),
                _ActivityItem(
                  icon: Icons.people,
                  count: myProjects.fold<int>(0, (sum, project) => 
                      sum + (project.interestedInvestors as int? ?? 0)),
                  label: 'Inversores',
                  color: Colors.orange,
                ),
                _ActivityItem(
                  icon: Icons.rocket_launch,
                  count: myProjects.where((p) => p.status == 'active').length,
                  label: 'Activos',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsSummary(BuildContext context, List<dynamic> myProjects) {
    // Calcular estadísticas en tiempo real con conversiones seguras
    final totalProjects = myProjects.length;
    
    int totalInterested = 0;
    double totalFunding = 0.0;
    int totalViews = 0;
    int activeProjects = 0;
    
    // Iterar sobre proyectos y sumar valores de forma segura
    for (final project in myProjects) {
      // Sumar inversores interesados (con casting seguro)
      totalInterested += (project.interestedInvestors as int? ?? 0);
      
      // Sumar financiamiento (con casting seguro)
      totalFunding += (project.currentFunding as double? ?? 0.0);
      
      // Sumar vistas (con casting seguro)
      totalViews += (project.views as int? ?? 0);
      
      // Contar proyectos activos
      if (project.status == 'active') {
        activeProjects++;
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de proyectos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        size: 8,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'En tiempo real',
                        style: TextStyle(
                          fontSize: 10,
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.rocket_launch,
                  label: 'Proyectos',
                  value: totalProjects.toString(),
                  color: Theme.of(context).primaryColor,
                ),
                _SummaryItem(
                  icon: Icons.people,
                  label: 'Inversores interesados',
                  value: totalInterested.toString(),
                  color: Colors.orange,
                ),
                _SummaryItem(
                  icon: Icons.attach_money,
                  label: 'Financiamiento',
                  value: '\$${totalFunding.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              ],
            ),
            
            // Estadísticas adicionales
            if (totalProjects > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      'Activos',
                      activeProjects.toString(),
                      Colors.blue,
                    ),
                    _buildMiniStat(
                      'Vistas',
                      totalViews.toString(),
                      Colors.purple,
                    ),
                    _buildMiniStat(
                      'Promedio',
                      totalProjects > 0 
                          ? '${(totalInterested.toDouble() / totalProjects.toDouble()).toStringAsFixed(1)} int/proyecto'
                          : '0 int/proyecto',
                      Colors.indigo,
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
      ],
    );
  }
}

// Tab de mis proyectos (sin cambios significativos)
class _MyProjectsTab extends StatelessWidget {
  const _MyProjectsTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final myProjects = projectProvider.myProjects;

    if (projectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes proyectos aún',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProjectScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear mi primer proyecto'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myProjects.length,
      itemBuilder: (context, index) {
        final project = myProjects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(project: project),
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
                          style: Theme.of(context).textTheme.titleMedium,
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
                  const SizedBox(height: 16),
                  
                  // Estadísticas del proyecto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProjectStat(
                        icon: Icons.attach_money,
                        label: 'Recaudado',
                        value: '\$${project.currentFunding.toStringAsFixed(0)}',
                      ),
                      _ProjectStat(
                        icon: Icons.people,
                        label: 'Interesados',
                        value: project.interestedInvestors.toString(),
                        onTap: project.interestedInvestors > 0 ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InterestedInvestorsScreen(
                                projectId: project.id,
                                projectTitle: project.title,
                              ),
                            ),
                          );
                        } : null,
                      ),
                      _ProjectStat(
                        icon: Icons.percent,
                        label: 'Progreso',
                        value: '${project.fundingPercentage.toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Tab de inversores - ACTUALIZADO CON BOTONES DE CHAT
class _InvestorsTab extends StatelessWidget {
  const _InvestorsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filtros de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar inversores...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de inversores simulados con botón de chat
        ...[1, 2, 3, 4, 5].map((index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _InvestorCard(
            name: 'Inversor $index',
            bio: 'Interesado en proyectos de tecnología y salud',
            investmentRange: '\$10k - \$50k',
            verified: index % 2 == 0,
          ),
        )),
      ],
    );
  }
}

// NUEVOS WIDGETS

// Widget para mostrar actividad reciente
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final int? badge;

  const _ActivityItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 24),
            
            if (badge != null && badge! > 0)
              Positioned(
                top: -2,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
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
      ],
    );
  }
}

// Widgets auxiliares (resto de widgets sin cambios significativos)
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  final String title;
  final String status;
  final double fundingPercentage;
  final int interestedInvestors;
  final VoidCallback onTap;

  const _ProjectSummaryCard({
    required this.title,
    required this.status,
    required this.fundingPercentage,
    required this.interestedInvestors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$interestedInvestors interesados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProjectStatusChip(status: status),
                const SizedBox(height: 8),
                Text(
                  '${fundingPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? badge; // NUEVO: Para mostrar contador

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            // Badge para mostrar contador
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProjectStat({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 20, 
              color: onTap != null ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: onTap != null ? Colors.blue : null,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  final String name;
  final String bio;
  final String investmentRange;
  final bool verified;

  const _InvestorCard({
    required this.name,
    required this.bio,
    required this.investmentRange,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                name[0],
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
                  Row(
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      investmentRange,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // BOTÓN DE CHAT ACTUALIZADO
            IconButton(
              icon: const ChatIconWidget(
                iconSize: 20,
                iconColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatsListScreen(),
                  ),
                );
              },
              tooltip: 'Iniciar conversación',
            ),
          ],
        ),
      ),
    );
  }
}