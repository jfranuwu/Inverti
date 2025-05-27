// Archivo: lib/screens/home/entrepreneur_home_screen.dart
// Pantalla principal para emprendedores

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/project_status_chip.dart';
import '../../../widgets/quick_action_fab.dart';
import '../../../widgets/notification_badge.dart';
import '../project/create_project_screen.dart';
import '../project/project_detail_screen.dart';
import '../investor/interested_investors_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../maps/office_location_screen.dart';
import '../payments/subscription_plans_screen.dart';

class EntrepreneurHomeScreen extends StatefulWidget {
  const EntrepreneurHomeScreen({super.key});

  @override
  State<EntrepreneurHomeScreen> createState() => _EntrepreneurHomeScreenState();
}

class _EntrepreneurHomeScreenState extends State<EntrepreneurHomeScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const _MyProjectsTab(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Proyectos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Inversores',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? QuickActionFab(
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
            )
          : null,
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Mis Proyectos';
      case 2:
        return 'Inversores';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Inverti';
    }
  }
}

// Tab de inicio para emprendedores
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final myProjects = projectProvider.myProjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de proyectos
          _buildProjectsSummary(context, myProjects.length),
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
          
          // Accesos rápidos
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
              _ResourceCard(
                icon: Icons.school,
                title: 'Guía de pitch',
                color: Colors.blue,
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
                icon: Icons.analytics,
                title: 'Estadísticas',
                color: Colors.green,
                onTap: () {
                  // Ver estadísticas
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

  Widget _buildProjectsSummary(BuildContext context, int projectCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de actividad',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.rocket_launch,
                  label: 'Proyectos',
                  value: projectCount.toString(),
                  color: Theme.of(context).primaryColor,
                ),
                _SummaryItem(
                  icon: Icons.people,
                  label: 'Inversores interesados',
                  value: '12', // Simulado
                  color: Colors.orange,
                ),
                _SummaryItem(
                  icon: Icons.visibility,
                  label: 'Vistas totales',
                  value: '234', // Simulado
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tab de mis proyectos
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

// Tab de inversores
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
        
        // Lista de inversores simulados
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

// Widgets auxiliares
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

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
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
        child: Column(
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
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () {
                // Abrir chat
              },
            ),
          ],
        ),
      ),
    );
  }
}