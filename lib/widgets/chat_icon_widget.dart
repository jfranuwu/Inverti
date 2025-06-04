// Archivo: lib/widgets/chat_icon_widget.dart
// Widget para mostrar el ícono de chat con contador - CON MANEJO DE ERRORES MEJORADO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chat/chats_list_screen.dart';

class ChatIconWidget extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;
  final bool showLabel;

  const ChatIconWidget({
    super.key,
    this.iconColor,
    this.iconSize = 24,
    this.showLabel = false,
  });

  @override
  State<ChatIconWidget> createState() => _ChatIconWidgetState();
}

class _ChatIconWidgetState extends State<ChatIconWidget> {
  @override
  void initState() {
    super.initState();
    _initializeChatProvider();
  }

  void _initializeChatProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final authProvider = context.read<AuthProvider>();
        final chatProvider = context.read<ChatProvider>();
        
        if (authProvider.isAuthenticated && authProvider.user != null) {
          chatProvider.initializeUserChats(authProvider.user!.uid);
        }
      } catch (e) {
        debugPrint('⚠️ Error inicializando ChatProvider en ChatIconWidget: $e');
        // No es crítico, continuar sin chat
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.totalUnreadCount;
        
        return GestureDetector(
          onTap: () => _navigateToChats(context),
          child: widget.showLabel 
              ? _buildWithLabel(unreadCount)
              : _buildIconOnly(unreadCount),
        );
      },
    );
  }

  Widget _buildIconOnly(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.chat_bubble_outline,
          color: widget.iconColor ?? Theme.of(context).primaryColor,
          size: widget.iconSize,
        ),
        
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWithLabel(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: widget.iconColor ?? Theme.of(context).primaryColor,
                size: widget.iconSize,
              ),
              
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
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
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chats',
                style: TextStyle(
                  color: widget.iconColor ?? Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unreadCount > 0)
                Text(
                  '$unreadCount nuevo${unreadCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatsListScreen(showAppBar: true),
      ),
    );
  }
}

// Widget específico para BottomNavigationBar
class ChatBottomNavItem extends StatelessWidget {
  final bool isSelected;

  const ChatBottomNavItem({
    super.key,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      return const Icon(Icons.chat_bubble_outline);
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.totalUnreadCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[600],
            ),
            
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
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
        );
      },
    );
  }
}

// Widget para usar en AppBar
class ChatAppBarAction extends StatelessWidget {
  const ChatAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatsListScreen(showAppBar: true),
            ),
          );
        },
        icon: const ChatIconWidget(),
        tooltip: 'Conversaciones',
      ),
    );
  }
}

// Widget para FloatingActionButton
class ChatFloatingActionButton extends StatelessWidget {
  const ChatFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final unreadCount = chatProvider.totalUnreadCount;
        
        return Stack(
          children: [
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatsListScreen(showAppBar: true),
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.chat,
                color: Colors.white,
              ),
            ),
            
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Mixin para inicializar ChatProvider automáticamente - CON MANEJO DE ERRORES
mixin ChatProviderInitializer<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _initializeChatProvider();
  }

  void _initializeChatProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final authProvider = context.read<AuthProvider>();
        final chatProvider = context.read<ChatProvider>();
        
        if (authProvider.isAuthenticated && authProvider.user != null) {
          chatProvider.initializeUserChats(authProvider.user!.uid);
          debugPrint('✅ ChatProvider inicializado desde mixin');
        }
      } catch (e) {
        debugPrint('⚠️ Error inicializando ChatProvider desde mixin: $e');
        // No es crítico, continuar sin chat
      }
    });
  }
}