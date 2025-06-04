// Archivo: lib/screens/chat/chat_screen.dart
// Pantalla principal de conversación entre usuarios - CORREGIDA SIN LOOP INFINITO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/custom_card.dart';
import '../project/project_detail_screen.dart';
import '../profile/public_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  bool _hasMarkedAsRead = false; // 🔧 NUEVO: Flag para evitar loop
  ChatModel? _chat;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    final chat = await _chatService.getChatById(widget.chatId);
    if (chat != null && mounted) {
      setState(() {
        _chat = chat;
      });
      
      // 🔧 CORREGIDO: Solo marcar como leído UNA VEZ al cargar
      if (!_hasMarkedAsRead) {
        _markMessagesAsRead();
        _hasMarkedAsRead = true;
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = context.read<AuthProvider>().user?.uid;
    if (currentUserId != null) {
      debugPrint('📖 Marcando mensajes como leídos (solo una vez)');
      await _chatService.markMessagesAsRead(
        chatId: widget.chatId,
        userId: currentUserId,
      );
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = context.read<AuthProvider>().user;
    final userModel = context.read<AuthProvider>().userModel;
    
    if (currentUser == null || userModel == null) return;
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    final success = await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: currentUser.uid,
      senderName: userModel.name,
      content: messageText,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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

    return Scaffold(
      body: StreamBuilder<ChatModel?>(
        stream: _chatService.getChatStream(widget.chatId),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting && _chat == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final chat = chatSnapshot.data ?? _chat;
          if (chat == null) {
            return const Center(
              child: Text('Chat no encontrado'),
            );
          }

          final otherUserId = chat.getOtherParticipant(currentUserId);
          final otherUserName = chat.getOtherParticipantName(currentUserId);
          final otherUserType = chat.getOtherParticipantType(currentUserId);

          return Column(
            children: [
              // App Bar personalizada
              _buildCustomAppBar(chat, otherUserName, otherUserType),
              
              // Información del proyecto si existe
              if (chat.projectId != null && chat.projectTitle != null)
                _buildProjectInfo(chat),
              
              // Lista de mensajes
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getChatMessagesStream(widget.chatId),
                  builder: (context, messagesSnapshot) {
                    if (messagesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = messagesSnapshot.data ?? [];

                    if (messages.isEmpty) {
                      return _buildEmptyState(otherUserName);
                    }

                    // 🔧 CORREGIDO: Auto-scroll solo cuando hay mensajes nuevos
                    // Sin llamar markAsRead repetidamente
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom(); // Solo scroll, no mark as read
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isFromCurrentUser = message.isFromUser(currentUserId);
                        final showDateHeader = _shouldShowDateHeader(messages, index);
                        
                        return Column(
                          children: [
                            if (showDateHeader)
                              _buildDateHeader(message.createdAt),
                            
                            _buildMessageBubble(message, isFromCurrentUser),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Campo de entrada de mensaje
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar(ChatModel chat, String otherUserName, String otherUserType) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            
            // Avatar del otro usuario
            GestureDetector(
              onTap: () => _navigateToProfile(chat),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _getInitials(otherUserName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Información del usuario
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToProfile(chat),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (otherUserType == 'investor') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.account_balance_wallet,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ] else if (otherUserType == 'entrepreneur') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        ],
                      ],
                    ),
                    Text(
                      otherUserType == 'investor' ? 'Inversor' : 'Emprendedor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert),
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'profile',
      child: Row(
        children: [
          const Icon(Icons.person, size: 20),
          const SizedBox(width: 8),
          Expanded( // ← SOLUCIÓN: Envolver el Text en Expanded
            child: Text(
              'Ver perfil de $otherUserName',
              overflow: TextOverflow.ellipsis, // ← Truncar si es muy largo
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
    if (chat.projectId != null)
      const PopupMenuItem(
        value: 'project',
        child: Row(
          children: [
            Icon(Icons.business, size: 20),
            SizedBox(width: 8),
            Expanded( // ← También aplicar aquí para consistencia
              child: Text(
                'Ver proyecto',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
  ],
  onSelected: (value) => _handleMenuAction(value, chat),
),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfo(ChatModel chat) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: CustomCard(
        onTap: () => _navigateToProject(chat.projectId!),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyecto:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      chat.projectTitle!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String otherUserName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '¡Inicia la conversación!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envía tu primer mensaje a $otherUserName',
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

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    String dateText;
    if (difference == 0) {
      dateText = 'Hoy';
    } else if (difference == 1) {
      dateText = 'Ayer';
    } else if (difference < 7) {
      const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      dateText = weekdays[date.weekday - 1];
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isFromCurrentUser) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
              child: Text(
                _getInitials(message.senderName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeFormat,
                        style: TextStyle(
                          color: isFromCurrentUser 
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isFromCurrentUser && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
              child: Text(
                _getInitials(message.senderName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(MessageModel message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Botón de enviar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSendingMessage ? null : _sendMessage,
                icon: _isSendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    return currentMessage.createdAt.day != previousMessage.createdAt.day ||
           currentMessage.createdAt.month != previousMessage.createdAt.month ||
           currentMessage.createdAt.year != previousMessage.createdAt.year;
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  void _navigateToProfile(ChatModel chat) {
    final currentUserId = context.read<AuthProvider>().user?.uid;
    if (currentUserId == null) return;
    
    final otherUserId = chat.getOtherParticipant(currentUserId);
    final otherUserName = chat.getOtherParticipantName(currentUserId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: otherUserId,
          userName: otherUserName,
        ),
      ),
    );
  }

  void _navigateToProject(String projectId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando al proyecto...'),
      ),
    );
  }

  void _handleMenuAction(String action, ChatModel chat) {
    switch (action) {
      case 'profile':
        _navigateToProfile(chat);
        break;
      case 'project':
        if (chat.projectId != null) {
          _navigateToProject(chat.projectId!);
        }
        break;
    }
  }
}