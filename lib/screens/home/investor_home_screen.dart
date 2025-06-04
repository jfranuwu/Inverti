// Archivo: lib/screens/home/investor_home_screen.dart
// Pantalla principal para inversores - ACTUALIZADA CON SISTEMA DE CHAT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/investment_progress_card.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/chat_icon_widget.dart';
import '../project/project_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../maps/office_location_screen.dart';
import '../payments/subscription_plans_screen.dart';
import '../chat/chats_list_screen.dart';

class InvestorHomeScreen extends StatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  State<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends State<InvestorHomeScreen> 
    with ChatProviderInitializer {
  int _selectedIndex = 0;
  String _selectedCategory = 'Todas';
  
  // Páginas del bottom navigation - ACTUALIZADO CON CHAT
  late final List<Widget> _pages;

  // Categorías disponibles
  final List<String> _categories = [
    'Todas',
    'Tecnología',
    'Salud',
    'Educación',
    'Finanzas',
    'E-commerce',
    'Sostenibilidad',
    'Entretenimiento',
    'Alimentación',
    'Transporte',
    'Inmobiliario',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const _PortfolioTab(),
      const ChatsListScreen(showAppBar: false),
      _ExploreTab(
        categories: _categories,
        selectedCategory: _selectedCategory,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
      const ProfileScreen(),
    ];
    
    // Cargar proyectos
    Future.microtask(() {
      context.read<ProjectProvider>().loadAllProjects();
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
          // ÍCONO DE CHAT CON CONTADOR EN APPBAR
          if (_selectedIndex != 2) // No mostrar en la pantalla de chats
            const ChatAppBarAction(),
          
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
        children: [
          _pages[0], // HomeTab
          _pages[1], // PortfolioTab
          _pages[2], // ChatsListScreen - NUEVA
          _ExploreTab(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ), // ExploreTab
          _pages[4], // ProfileTab
        ],
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
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          // NUEVA NAVEGACIÓN DE CHAT CON CONTADOR
          NavigationDestination(
            icon: ChatBottomNavItem(isSelected: _selectedIndex == 2),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          const NavigationDestination(
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
        return 'Conversaciones';
      case 3:
        return 'Explorar Proyectos';
      case 4:
        return 'Mi Perfil';
      default:
        return 'Inverti';
    }
  }
}

// Tab de inicio - ACTUALIZADO CON SECCIÓN DE CHAT
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final projects = projectProvider.allProjects.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NUEVA SECCIÓN: Resumen de actividad con chats
          _buildActivitySummary(context, chatProvider),
          const SizedBox(height: 24),
          
          // Resumen de inversiones (original)
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
                  // Ir a explorar - cambiar índice a 3 (era 2)
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
          
          // Accesos rápidos - ACTUALIZADO CON CHAT
          Text(
            'Accesos rápidos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Grid 2x2 con accesos rápidos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              // NUEVA TARJETA: Conversaciones
              _QuickAccessCard(
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
              _QuickAccessCard(
                icon: Icons.location_on,
                title: 'Oficinas',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfficeLocationScreen(),
                    ),
                  );
                },
              ),
              _QuickAccessCard(
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
              _QuickAccessCard(
                icon: Icons.analytics,
                title: 'Estadísticas',
                color: Colors.orange,
                onTap: () {
                  // Ver estadísticas
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NUEVA FUNCIÓN: Resumen de actividad con chats
  Widget _buildActivitySummary(BuildContext context, ChatProvider chatProvider) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    
    if (currentUserId == null) return const SizedBox.shrink();

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
                  'Actividad reciente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (chatProvider.totalUnreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chatProvider.totalUnreadCount} nuevos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
                  icon: Icons.favorite,
                  count: 8, // Simulado - proyectos de interés
                  label: 'Proyectos de interés',
                  color: Colors.red,
                ),
                _ActivityItem(
                  icon: Icons.pie_chart,
                  count: 3, // Simulado - inversiones activas
                  label: 'Inversiones activas',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
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

// Tab de portfolio (sin cambios significativos)
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

// Tab de explorar (sin cambios significativos)
class _ExploreTab extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const _ExploreTab({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    
    // Filtrar proyectos por categoría
    final filteredProjects = selectedCategory == 'Todas'
        ? projectProvider.allProjects
        : projectProvider.getProjectsByCategory(selectedCategory);

    return Column(
      children: [
        // Filtros
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    onCategoryChanged(category);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de proyectos
        Expanded(
          child: projectProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProjects.isEmpty
                  ? const Center(
                      child: Text('No hay proyectos en esta categoría'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
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

// Widgets auxiliares (actualizados)
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
  final String? badge; // NUEVO: Para mostrar contador

  const _QuickAccessCard({
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
                  child: project.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: project.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.business, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.business, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.business, color: Colors.grey),
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
                        project.category,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Quick Pitch indicator
                if (project.metadata['quickPitchUrl'] != null && 
                    project.metadata['quickPitchUrl'].toString().isNotEmpty)
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