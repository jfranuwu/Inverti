// Archivo: lib/providers/chat_provider.dart
// Provider para manejo de estado de chats y mensajes - CON LIMPIEZA MEJORADA

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Estado del provider
  List<ChatModel> _userChats = [];
  Map<String, List<MessageModel>> _chatMessages = {};
  Map<String, StreamSubscription> _messageSubscriptions = {};
  Map<String, StreamSubscription> _chatSubscriptions = {};
  bool _isLoading = false;
  String? _error;
  int _totalUnreadCount = 0;

  // Getters
  List<ChatModel> get userChats => _userChats;
  Map<String, List<MessageModel>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUnreadCount => _totalUnreadCount;

  // Obtener mensajes de un chat específico
  List<MessageModel> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  // Obtener chat por ID
  ChatModel? getChatById(String chatId) {
    try {
      return _userChats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Inicializar chats del usuario
  Future<void> initializeUserChats(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      // Limpiar suscripciones anteriores
      await _clearAllSubscriptions();

      // Escuchar chats del usuario
      _chatSubscriptions['user_chats'] = _chatService
          .getUserChatsStream(userId)
          .listen(
        (chats) {
          _userChats = chats;
          _updateTotalUnreadCount(userId);
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Error cargando chats: $error');
          _setLoading(false);
        },
      );

      // Escuchar contador total de no leídos
      _chatSubscriptions['unread_count'] = _chatService
          .getTotalUnreadCountStream(userId)
          .listen(
        (count) {
          _totalUnreadCount = count;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error obteniendo contador de no leídos: $error');
        },
      );
    } catch (e) {
      _setError('Error inicializando chats: $e');
      _setLoading(false);
    }
  }

  // Crear o obtener chat existente
  Future<String?> createOrGetChat({
    required String userId1,
    required String userName1,
    required String userType1,
    required String userId2,
    required String userName2,
    required String userType2,
    String? projectId,
    String? projectTitle,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final chatId = await _chatService.createOrGetChat(
        userId1: userId1,
        userName1: userName1,
        userType1: userType1,
        userId2: userId2,
        userName2: userName2,
        userType2: userType2,
        projectId: projectId,
        projectTitle: projectTitle,
      );

      _setLoading(false);
      
      if (chatId != null) {
        // Inicializar mensajes del chat si es nuevo
        _initializeChatMessages(chatId);
        notifyListeners();
      }

      return chatId;
    } catch (e) {
      _setError('Error creando/obteniendo chat: $e');
      _setLoading(false);
      return null;
    }
  }

  // Inicializar mensajes de un chat específico
  void _initializeChatMessages(String chatId) {
    // Cancelar suscripción anterior si existe
    _messageSubscriptions[chatId]?.cancel();

    // Crear nueva suscripción
    _messageSubscriptions[chatId] = _chatService
        .getChatMessagesStream(chatId)
        .listen(
      (messages) {
        _chatMessages[chatId] = messages;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error cargando mensajes del chat $chatId: $error');
      },
    );
  }

  // Cargar mensajes de un chat
  Future<void> loadChatMessages(String chatId) async {
    if (_chatMessages.containsKey(chatId)) {
      return; // Ya están cargados
    }

    _initializeChatMessages(chatId);
  }

  // Enviar mensaje
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        metadata: metadata,
      );

      if (success) {
        // El mensaje se actualizará automáticamente a través del stream
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Error enviando mensaje: $e');
      return false;
    }
  }

  // Marcar mensajes como leídos
  Future<bool> markMessagesAsRead(String chatId, String userId) async {
    try {
      final success = await _chatService.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
      );

      if (success) {
        // Los contadores se actualizarán automáticamente a través de los streams
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error marcando mensajes como leídos: $e');
      return false;
    }
  }

  // Buscar chats
  Future<List<ChatModel>> searchChats(String userId, String query) async {
    try {
      return await _chatService.searchChats(userId, query);
    } catch (e) {
      _setError('Error buscando chats: $e');
      return [];
    }
  }

  // Obtener estadísticas de chat
  Future<Map<String, int>> getChatStats(String userId) async {
    try {
      return await _chatService.getChatStats(userId);
    } catch (e) {
      debugPrint('Error obteniendo estadísticas de chat: $e');
      return {};
    }
  }

  // Verificar si existe chat entre usuarios
  Future<String?> getChatBetweenUsers({
    required String userId1,
    required String userId2,
    String? projectId,
  }) async {
    try {
      return await _chatService.getChatBetweenUsers(
        userId1: userId1,
        userId2: userId2,
        projectId: projectId,
      );
    } catch (e) {
      debugPrint('Error verificando chat existente: $e');
      return null;
    }
  }

  // Actualizar contador total de no leídos
  void _updateTotalUnreadCount(String userId) {
    int total = 0;
    for (final chat in _userChats) {
      total += chat.getUnreadCountForUser(userId);
    }
    _totalUnreadCount = total;
  }

  // Obtener chat más reciente
  ChatModel? getMostRecentChat() {
    if (_userChats.isEmpty) return null;
    
    return _userChats.first; // Ya están ordenados por updatedAt descendente
  }

  // Obtener chats con mensajes no leídos
  List<ChatModel> getUnreadChats(String userId) {
    return _userChats.where((chat) => chat.hasUnreadMessages(userId)).toList();
  }

  // Obtener chats por tipo de participante
  List<ChatModel> getChatsByParticipantType(String currentUserId, String participantType) {
    return _userChats.where((chat) {
      final otherUserType = chat.getOtherParticipantType(currentUserId);
      return otherUserType == participantType;
    }).toList();
  }

  // Obtener chats relacionados con proyectos
  List<ChatModel> getProjectChats() {
    return _userChats.where((chat) => chat.projectId != null).toList();
  }

  // Obtener último mensaje de un chat
  MessageModel? getLastMessage(String chatId) {
    final messages = _chatMessages[chatId];
    if (messages == null || messages.isEmpty) return null;
    
    return messages.last;
  }

  // Verificar si un chat tiene mensajes
  bool chatHasMessages(String chatId) {
    final messages = _chatMessages[chatId];
    return messages != null && messages.isNotEmpty;
  }

  // Obtener resumen de actividad reciente
  Map<String, dynamic> getRecentActivity(String userId) {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    int recentChats = 0;
    int newMessages = 0;
    
    for (final chat in _userChats) {
      if (chat.lastMessageTime != null && chat.lastMessageTime!.isAfter(last24Hours)) {
        recentChats++;
      }
      
      newMessages += chat.getUnreadCountForUser(userId);
    }

    return {
      'recentChats': recentChats,
      'newMessages': newMessages,
      'totalChats': _userChats.length,
      'activeChats': _userChats.where((chat) => 
        chat.lastMessageTime != null && 
        now.difference(chat.lastMessageTime!).inDays < 7
      ).length,
    };
  }

  // Limpiar todas las suscripciones - MEJORADO CON DEBUG
  Future<void> _clearAllSubscriptions() async {
    debugPrint('🧹 Limpiando ${_messageSubscriptions.length} suscripciones de mensajes...');
    for (final subscription in _messageSubscriptions.values) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();

    debugPrint('🧹 Limpiando ${_chatSubscriptions.length} suscripciones de chats...');
    for (final subscription in _chatSubscriptions.values) {
      await subscription.cancel();
    }
    _chatSubscriptions.clear();
    
    debugPrint('✅ Todas las suscripciones de ChatProvider canceladas');
  }

  // Limpiar datos del usuario (logout) - MEJORADO CON DEBUG
  Future<void> clearUserData() async {
    try {
      debugPrint('🧹 Limpiando datos de ChatProvider...');
      
      await _clearAllSubscriptions();
      
      _userChats.clear();
      _chatMessages.clear();
      _totalUnreadCount = 0;
      _error = null;
      _isLoading = false;
      
      debugPrint('✅ ChatProvider completamente limpiado');
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error limpiando ChatProvider: $e');
      // No lanzar error para no bloquear el logout
    }
  }

  // Métodos de utilidad
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refrescar chats
  Future<void> refreshChats(String userId) async {
    await clearUserData();
    await initializeUserChats(userId);
  }

  @override
  void dispose() {
    debugPrint('🧹 ChatProvider dispose() llamado');
    _clearAllSubscriptions();
    super.dispose();
  }
}