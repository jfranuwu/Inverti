// Archivo: lib/screens/chat/chats_list_screen.dart
// Pantalla para mostrar lista de todas las conversaciones del usuario - SIN APPBAR DUPLICADO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/custom_card.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final bool showAppBar; // NUEVO: Controlar si mostrar AppBar
  
  const ChatsListScreen({
    super.key,
    this.showAppBar = false, // Por defecto no mostrar (para uso en tabs)
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.uid;
    
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Usuario no autenticado'),
        ),
      );
    }

    final body = Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar conversaciones...',
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

        // Lista de chats
        Expanded(
          child: StreamBuilder<List<ChatModel>>(
            stream: _chatService.getUserChatsStream(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final allChats = snapshot.data ?? [];

              if (allChats.isEmpty) {
                return _buildEmptyState();
              }

              // Filtrar chats por búsqueda
              final filteredChats = _searchQuery.isEmpty
                  ? allChats
                  : allChats.where((chat) {
                      final otherUserName = chat.getOtherParticipantName(currentUserId).toLowerCase();
                      final projectTitle = (chat.projectTitle ?? '').toLowerCase();
                      return otherUserName.contains(_searchQuery) ||
                             projectTitle.contains(_searchQuery);
                    }).toList();

              if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
                return _buildNoResultsState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChatListItem(
                      chat: chat,
                      currentUserId: currentUserId,
                      onTap: () => _navigateToChat(chat),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    // NUEVO: Condicional para mostrar AppBar o no
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conversaciones'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          actions: [
            // Contador de mensajes no leídos
            StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCountStream(currentUserId),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                if (unreadCount == 0) return const SizedBox.shrink();
                
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes conversaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando muestres interés en proyectos o recibas interés, las conversaciones aparecerán aquí',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
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
            'No se encontraron conversaciones',
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
            'Error al cargar conversaciones',
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

  void _navigateToChat(ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          otherUserId: chat.getOtherParticipant(context.read<AuthProvider>().user!.uid),
          otherUserName: chat.getOtherParticipantName(context.read<AuthProvider>().user!.uid),
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.getOtherParticipant(currentUserId);
    final otherUserName = chat.getOtherParticipantName(currentUserId);
    final otherUserType = chat.getOtherParticipantType(currentUserId);
    final unreadCount = chat.getUnreadCountForUser(currentUserId);
    final hasUnread = unreadCount > 0;

    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar del otro usuario
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _getInitials(otherUserName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Indicador de tipo de usuario
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: otherUserType == 'investor' ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      otherUserType == 'investor' 
                          ? Icons.account_balance_wallet
                          : Icons.business,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Información del chat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y timestamp
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageTime != null)
                        Text(
                          _formatTime(chat.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? Theme.of(context).primaryColor : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Proyecto si existe
                  if (chat.projectTitle != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chat.projectTitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Último mensaje
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'No hay mensajes',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Contador de mensajes no leídos
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}