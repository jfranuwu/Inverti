// Archivo: lib/screens/home/investor_home_screen.dart
// Pantalla principal para inversores

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../models/project_model.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/investment_progress_card.dart';
import '../../../widgets/notification_badge.dart';
import '../project/project_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../maps/office_location_screen.dart';
import '../payments/subscription_plans_screen.dart';

class InvestorHomeScreen extends StatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  State<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends State<InvestorHomeScreen> {
  int _selectedIndex = 0;
  
  // Páginas del bottom navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const _PortfolioTab(),
      const _ExploreTab(),
      const ProfileScreen(),
    ];
    
    // Cargar proyectos
    Future.microtask(() {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userModel?.name ?? 'Inversor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Hola, $userName' : _getPageTitle(),
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          // Botón de notificaciones con badge
          NotificationBadge(
            count: 3, // Simulado
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
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Mi Portfolio';
      case 2:
        return 'Explorar Proyectos';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Inverti';
    }
  }
}

// Tab de inicio
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de inversiones
          _buildInvestmentSummary(context),
          const SizedBox(height: 24),
          
          // Proyectos destacados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proyectos destacados',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  // Ir a explorar
                },
                child: const Text('Ver más'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Lista de proyectos
          if (projectProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (projects.isEmpty)
            const Center(
              child: Text('No hay proyectos disponibles'),
            )
          else
            ...projects.map((project) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ProjectCard(project: project),
            )),
          
          const SizedBox(height: 24),
          
          // Accesos rápidos
          Text(
            'Accesos rápidos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.location_on,
                  title: 'Oficinas',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OfficeLocationScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.diamond,
                  title: 'Premium',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de inversiones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total invertido',
                  value: '\$25,000',
                  color: Theme.of(context).primaryColor,
                ),
                _SummaryItem(
                  label: 'Proyectos activos',
                  value: '3',
                  color: Colors.orange,
                ),
                _SummaryItem(
                  label: 'ROI promedio',
                  value: '15.2%',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tab de portfolio
class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Gráfico de inversiones (simulado)
        Card(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución de inversiones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Expanded(
                  child: Center(
                    child: Icon(
                      Icons.pie_chart,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de inversiones
        Text(
          'Mis inversiones',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // Proyectos en portfolio (simulados)
        InvestmentProgressCard(
          projectName: 'EcoTech Solutions',
          investedAmount: 10000,
          totalGoal: 50000,
          roi: 12.5,
        ),
        const SizedBox(height: 12),
        InvestmentProgressCard(
          projectName: 'FoodDelivery Pro',
          investedAmount: 5000,
          totalGoal: 30000,
          roi: 18.2,
        ),
        const SizedBox(height: 12),
        InvestmentProgressCard(
          projectName: 'HealthApp Plus',
          investedAmount: 10000,
          totalGoal: 100000,
          roi: 15.0,
        ),
      ],
    );
  }
}

// Tab de explorar
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();

    return Column(
      children: [
        // Filtros
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('Todas'),
                selected: projectProvider.selectedIndustry == 'Todas',
                onSelected: (_) {
                  projectProvider.setIndustryFilter('Todas');
                },
              ),
              const SizedBox(width: 8),
              ...Industries.list.map((industry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(industry),
                  selected: projectProvider.selectedIndustry == industry,
                  onSelected: (_) {
                    projectProvider.setIndustryFilter(industry);
                  },
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de proyectos
        Expanded(
          child: projectProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : projectProvider.filteredProjects.isEmpty
                  ? const Center(
                      child: Text('No hay proyectos en esta categoría'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: projectProvider.filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = projectProvider.filteredProjects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ProjectCard(project: project),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Widgets auxiliares
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
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
              children: [
                // Imagen del proyecto
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: project.images?.first ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.business, color: Colors.grey),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.business, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del proyecto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.industry,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Quick Pitch indicator
                if (project.hasQuickPitch)
                  Icon(
                    Icons.mic,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Descripción
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            
            // Progreso de financiamiento
            LinearProgressIndicator(
              value: project.fundingPercentage / 100,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            
            // Estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${project.currentFunding.toStringAsFixed(0)} / \$${project.fundingGoal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${project.fundingPercentage.toStringAsFixed(0)}%',
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
    );
  }
}