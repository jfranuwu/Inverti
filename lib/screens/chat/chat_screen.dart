// File: lib/screens/chat/chat_screen.dart
// Pantalla de chat completa con notificaciones integradas

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_notification_widget.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? projectTitle;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.projectTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  String? _currentUserId;
  bool _isAppInForeground = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_currentUserId != null) {
      // Cargar mensajes del chat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().loadChatMessages(widget.chatId);
        // Marcar mensajes como leídos al entrar al chat
        _markMessagesAsRead();
      });
    }

    // Listener para detectar cuando el usuario está escribiendo
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // Detectar cambios en el texto para mostrar indicador de escritura
  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  // Detectar cuando la app vuelve al primer plano para marcar mensajes como leídos
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        // Marcar mensajes como leídos cuando la app vuelve al primer plano
        if (_currentUserId != null) {
          _markMessagesAsRead();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }

  // Marcar mensajes como leídos
  void _markMessagesAsRead() {
    if (_currentUserId != null) {
      context.read<ChatProvider>().markMessagesAsRead(widget.chatId, _currentUserId!);
    }
  }

  // Enviar mensaje con notificaciones automáticas
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    final chatProvider = context.read<ChatProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) return;

    try {
      // Limpiar el campo inmediatamente para mejor UX
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });

      final success = await chatProvider.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        senderName: currentUser.displayName ?? 'Usuario',
        content: content,
        type: MessageType.text,
      );

      if (success) {
        // Scroll al final después de enviar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        // Si falla, restaurar el mensaje
        _messageController.text = content;
        _showErrorSnackBar('Error enviando mensaje');
      }
    } catch (e) {
      // Si falla, restaurar el mensaje
      _messageController.text = content;
      _showErrorSnackBar('Error enviando mensaje: $e');
    }
  }

  // Scroll al final de la conversación
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Mostrar error
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  // Mostrar opciones del chat
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información del chat'),
              onTap: () {
                Navigator.pop(context);
                _showChatInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Silenciar notificaciones'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar silenciar notificaciones
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear usuario'),
              onTap: () {
                Navigator.pop(context);
                _showBlockUserDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar información del chat
  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${widget.otherUserName}'),
            if (widget.projectTitle != null)
              Text('Proyecto: ${widget.projectTitle}'),
            const SizedBox(height: 16.0),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getChatMessages(widget.chatId);
                return Text('Mensajes: ${messages.length}');
              },
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
  }

  // Mostrar diálogo de bloquear usuario
  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: Text('¿Estás seguro de que quieres bloquear a ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar bloquear usuario
              _showErrorSnackBar('Función no implementada aún');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Usuario no autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showChatInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 16.0),
              ),
              if (widget.projectTitle != null)
                Text(
                  widget.projectTitle!,
                  style: const TextStyle(
                    fontSize: 12.0, 
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          // Badge de notificaciones de chat
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChatNotificationBadge(
              userId: _currentUserId!,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Navegar a pantalla de notificaciones
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            ),
          ),
          // Opciones del chat
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Lista de mensajes
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages = chatProvider.getChatMessages(widget.chatId);
                    
                    if (chatProvider.isLoading && messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (chatProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.0,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Error cargando mensajes',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.red[600],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              chatProvider.error!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: () {
                                chatProvider.clearError();
                                chatProvider.loadChatMessages(widget.chatId);
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64.0,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Inicia la conversación',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (widget.projectTitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Proyecto: ${widget.projectTitle}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16.0),
                            Text(
                              '¡Envía tu primer mensaje!',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Auto-scroll al final cuando hay mensajes nuevos
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser = message.senderId == _currentUserId;
                        final isSystemMessage = message.senderId == 'system';

                        // Marcar mensajes como leídos al hacerlos visibles
                        if (!isCurrentUser && !message.isRead && _isAppInForeground) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _markMessagesAsRead();
                          });
                        }

                        return _buildMessageBubble(message, isCurrentUser, isSystemMessage);
                      },
                    );
                  },
                ),
              ),

              // Campo de texto para escribir mensajes
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10.0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        decoration: BoxDecoration(
                          color: _isTyping 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isTyping ? Icons.send : Icons.send_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _isTyping ? _sendMessage : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Widget de notificación en tiempo real para esta conversación
          ChatMessageNotificationWidget(
            chatId: widget.chatId,
            currentUserId: _currentUserId!,
          ),
        ],
      ),
    );
  }

  // Construir burbuja de mensaje completa
  Widget _buildMessageBubble(MessageModel message, bool isCurrentUser, bool isSystemMessage) {
    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16.0,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12.0),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18.0),
                  topRight: const Radius.circular(18.0),
                  bottomLeft: Radius.circular(isCurrentUser ? 18.0 : 4.0),
                  bottomRight: Radius.circular(isCurrentUser ? 4.0 : 18.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5.0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeFormat,
                        style: TextStyle(
                          color: isCurrentUser 
                              ? Colors.white.withOpacity(0.7) 
                              : Colors.grey[600],
                          fontSize: 11.0,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4.0),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14.0,
                          color: message.isRead 
                              ? Colors.blue[300] 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              radius: 16.0,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white, size: 16.0),
            ),
          ],
        ],
      ),
    );
  }
}