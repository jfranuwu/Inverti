// Archivo: lib/screens/project/interested_investors_screen.dart
// Pantalla para ver inversores interesados en un proyecto - ACTUALIZADA CON CHAT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/custom_card.dart';
import '../../screens/chat/chat_screen.dart';
import 'package:intl/intl.dart';

class InterestedInvestorsScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const InterestedInvestorsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<InterestedInvestorsScreen> createState() => _InterestedInvestorsScreenState();
}

class _InterestedInvestorsScreenState extends State<InterestedInvestorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inversores Interesados',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              widget.projectTitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar inversores...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Lista de inversores
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context
                  .read<ProjectProvider>()
                  .getInterestedInvestorsStream(widget.projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final investors = snapshot.data ?? [];

                if (investors.isEmpty) {
                  return _buildEmptyState();
                }

                // Filtrar inversores por búsqueda
                final filteredInvestors = _searchQuery.isEmpty
                    ? investors
                    : investors.where((investor) {
                        final name = investor['investorName']?.toString().toLowerCase() ?? '';
                        return name.contains(_searchQuery);
                      }).toList();

                if (filteredInvestors.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredInvestors.length,
                  itemBuilder: (context, index) {
                    final investor = filteredInvestors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InvestorCard(
                        investor: investor,
                        projectId: widget.projectId,
                        projectTitle: widget.projectTitle,
                        onStartChat: () => _startChatWithInvestor(investor),
                        onViewProfile: () => _viewInvestorProfile(investor),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay inversores interesados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando los inversores muestren interés en tu proyecto, aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al proyecto'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otro término de búsqueda',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar inversores',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {}); // Trigger rebuild
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // 🚀 NUEVA FUNCIÓN: Iniciar chat con inversor
  Future<void> _startChatWithInvestor(Map<String, dynamic> investor) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    final currentUser = authProvider.user;
    final currentUserModel = authProvider.userModel;
    
    if (currentUser == null || currentUserModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Crear o obtener chat existente
      final chatId = await chatProvider.createOrGetChat(
        userId1: currentUser.uid,
        userName1: currentUserModel.name,
        userType1: currentUserModel.userType,
        userId2: investor['investorId'],
        userName2: investor['investorName'],
        userType2: 'investor',
        projectId: widget.projectId,
        projectTitle: widget.projectTitle,
      );

      // Cerrar loading
      if (mounted) {
        Navigator.pop(context);
      }

      if (chatId != null) {
        // Navegar al chat
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserId: investor['investorId'],
                otherUserName: investor['investorName'],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear la conversación'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewInvestorProfile(Map<String, dynamic> investor) {
    // TODO: Implementar vista de perfil del inversor
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil del Inversor'),
        content: Text(
          'Próximamente podrás ver el perfil completo de ${investor['investorName']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  final Map<String, dynamic> investor;
  final String projectId;
  final String projectTitle;
  final VoidCallback onStartChat;
  final VoidCallback onViewProfile;

  const _InvestorCard({
    required this.investor,
    required this.projectId,
    required this.projectTitle,
    required this.onStartChat,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final investorName = investor['investorName'] ?? 'Inversor Anónimo';
    final interestedAt = investor['interestedAt'] as Timestamp?;
    final investorId = investor['investorId'] ?? '';

    return CustomCard(
      onTap: onViewProfile,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar del inversor
            Hero(
              tag: 'investor_avatar_$investorId',
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _getInitials(investorName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Información del inversor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          investorName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge de verificación (simulado)
                      if (investorId.hashCode % 3 == 0) ...[
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

                  // Fecha de interés
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatInterestDate(interestedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Información adicional simulada
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.account_balance_wallet,
                        label: _getSimulatedInvestmentRange(),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.business,
                        label: _getSimulatedExperience(),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🚀 BOTONES DE ACCIÓN ACTUALIZADOS
            Column(
              children: [
                // Botón de chat (NUEVO)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: onStartChat,
                    icon: const Icon(Icons.chat),
                    color: Colors.white,
                    tooltip: 'Iniciar conversación',
                  ),
                ),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Botón de perfil
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person),
                    color: Colors.grey[700],
                    tooltip: 'Ver perfil',
                  ),
                ),
                Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }

  String _formatInterestDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha desconocida';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _getSimulatedInvestmentRange() {
    final ranges = ['\$5k-25k', '\$10k-50k', '\$25k-100k', '\$50k-250k'];
    return ranges[investor['investorId'].hashCode % ranges.length];
  }

  String _getSimulatedExperience() {
    final experiences = ['Tech', 'FinTech', 'HealthTech', 'EdTech', 'E-commerce'];
    return experiences[investor['investorId'].hashCode % experiences.length];
  }
}