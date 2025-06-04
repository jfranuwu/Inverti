// Archivo: lib/providers/chat_provider.dart
// Provider para manejo de estado de chats y mensajes - CORREGIDO PARA LOGOUT SEGURO

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
  
  // NUEVO: Flag para prevenir operaciones durante logout
  bool _isClearing = false;
  String? _currentUserId; // Para tracking del usuario actual

  // Getters
  List<ChatModel> get userChats => _userChats;
  Map<String, List<MessageModel>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUnreadCount => _totalUnreadCount;

  // NUEVO: Getter para verificar si está limpiando
  bool get isClearing => _isClearing;

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

  // CORREGIDO: Inicializar chats del usuario con protección
  Future<void> initializeUserChats(String userId) async {
    // No inicializar si estamos limpiando
    if (_isClearing) {
      debugPrint('🚫 ChatProvider en proceso de limpieza, saltando inicialización');
      return;
    }

    try {
      debugPrint('🚀 ChatProvider - Inicializando chats para usuario: $userId');
      _currentUserId = userId;
      _setLoading(true);
      _error = null;

      // Limpiar suscripciones anteriores
      await _clearAllSubscriptions();

      // NUEVO: Verificar otra vez si no estamos limpiando después del delay
      if (_isClearing) {
        debugPrint('🚫 Limpieza iniciada durante inicialización, abortando');
        return;
      }

      // Escuchar chats del usuario con manejo de errores mejorado
      _chatSubscriptions['user_chats'] = _chatService
          .getUserChatsStream(userId)
          .listen(
        (chats) {
          // Solo procesar si no estamos limpiando
          if (!_isClearing && _currentUserId == userId) {
            _userChats = chats;
            _updateTotalUnreadCount(userId);
            _setLoading(false);
            notifyListeners();
          }
        },
        onError: (error) {
          // Solo manejar errores si no estamos limpiando
          if (!_isClearing) {
            debugPrint('❌ Error en stream de chats: $error');
            _setError('Error cargando chats: $error');
            _setLoading(false);
          }
        },
        cancelOnError: false, // No cancelar automáticamente en error
      );

      // Escuchar contador total de no leídos con protección
      _chatSubscriptions['unread_count'] = _chatService
          .getTotalUnreadCountStream(userId)
          .listen(
        (count) {
          // Solo procesar si no estamos limpiando
          if (!_isClearing && _currentUserId == userId) {
            _totalUnreadCount = count;
            notifyListeners();
          }
        },
        onError: (error) {
          // Solo manejar errores si no estamos limpiando
          if (!_isClearing) {
            debugPrint('❌ Error obteniendo contador de no leídos: $error');
            // No setear error para este stream ya que no es crítico
          }
        },
        cancelOnError: false,
      );

      debugPrint('✅ ChatProvider inicializado correctamente');
      
    } catch (e) {
      if (!_isClearing) {
        debugPrint('❌ Error inicializando ChatProvider: $e');
        _setError('Error inicializando chats: $e');
        _setLoading(false);
      }
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
    if (_isClearing) return null;

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
      
      if (chatId != null && !_isClearing) {
        // Inicializar mensajes del chat si es nuevo
        _initializeChatMessages(chatId);
        notifyListeners();
      }

      return chatId;
    } catch (e) {
      if (!_isClearing) {
        _setError('Error creando/obteniendo chat: $e');
        _setLoading(false);
      }
      return null;
    }
  }

  // CORREGIDO: Inicializar mensajes de un chat específico con protección
  void _initializeChatMessages(String chatId) {
    if (_isClearing) return;

    // Cancelar suscripción anterior si existe
    _messageSubscriptions[chatId]?.cancel();

    // Crear nueva suscripción con protección
    _messageSubscriptions[chatId] = _chatService
        .getChatMessagesStream(chatId)
        .listen(
      (messages) {
        // Solo procesar si no estamos limpiando
        if (!_isClearing) {
          _chatMessages[chatId] = messages;
          notifyListeners();
        }
      },
      onError: (error) {
        if (!_isClearing) {
          debugPrint('❌ Error cargando mensajes del chat $chatId: $error');
        }
      },
      cancelOnError: false,
    );
  }

  // Cargar mensajes de un chat
  Future<void> loadChatMessages(String chatId) async {
    if (_isClearing || _chatMessages.containsKey(chatId)) {
      return; // Ya están cargados o estamos limpiando
    }

    _initializeChatMessages(chatId);
  }

  // Enviar mensaje con protección
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (_isClearing) return false;

    try {
      final success = await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        metadata: metadata,
      );

      if (success && !_isClearing) {
        // El mensaje se actualizará automáticamente a través del stream
        notifyListeners();
      }

      return success;
    } catch (e) {
      if (!_isClearing) {
        _setError('Error enviando mensaje: $e');
      }
      return false;
    }
  }

  // Marcar mensajes como leídos con protección
  Future<bool> markMessagesAsRead(String chatId, String userId) async {
    if (_isClearing) return false;

    try {
      final success = await _chatService.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
      );

      if (success && !_isClearing) {
        // Los contadores se actualizarán automáticamente a través de los streams
        notifyListeners();
      }

      return success;
    } catch (e) {
      if (!_isClearing) {
        debugPrint('Error marcando mensajes como leídos: $e');
      }
      return false;
    }
  }

  // Buscar chats
  Future<List<ChatModel>> searchChats(String userId, String query) async {
    if (_isClearing) return [];

    try {
      return await _chatService.searchChats(userId, query);
    } catch (e) {
      if (!_isClearing) {
        _setError('Error buscando chats: $e');
      }
      return [];
    }
  }

  // Obtener estadísticas de chat
  Future<Map<String, int>> getChatStats(String userId) async {
    if (_isClearing) return {};

    try {
      return await _chatService.getChatStats(userId);
    } catch (e) {
      if (!_isClearing) {
        debugPrint('Error obteniendo estadísticas de chat: $e');
      }
      return {};
    }
  }

  // Verificar si existe chat entre usuarios
  Future<String?> getChatBetweenUsers({
    required String userId1,
    required String userId2,
    String? projectId,
  }) async {
    if (_isClearing) return null;

    try {
      return await _chatService.getChatBetweenUsers(
        userId1: userId1,
        userId2: userId2,
        projectId: projectId,
      );
    } catch (e) {
      if (!_isClearing) {
        debugPrint('Error verificando chat existente: $e');
      }
      return null;
    }
  }

  // Actualizar contador total de no leídos
  void _updateTotalUnreadCount(String userId) {
    if (_isClearing) return;

    int total = 0;
    for (final chat in _userChats) {
      total += chat.getUnreadCountForUser(userId);
    }
    _totalUnreadCount = total;
  }

  // Obtener chat más reciente
  ChatModel? getMostRecentChat() {
    if (_userChats.isEmpty || _isClearing) return null;
    
    return _userChats.first; // Ya están ordenados por updatedAt descendente
  }

  // Obtener chats con mensajes no leídos
  List<ChatModel> getUnreadChats(String userId) {
    if (_isClearing) return [];
    return _userChats.where((chat) => chat.hasUnreadMessages(userId)).toList();
  }

  // Obtener chats por tipo de participante
  List<ChatModel> getChatsByParticipantType(String currentUserId, String participantType) {
    if (_isClearing) return [];
    return _userChats.where((chat) {
      final otherUserType = chat.getOtherParticipantType(currentUserId);
      return otherUserType == participantType;
    }).toList();
  }

  // Obtener chats relacionados con proyectos
  List<ChatModel> getProjectChats() {
    if (_isClearing) return [];
    return _userChats.where((chat) => chat.projectId != null).toList();
  }

  // Obtener último mensaje de un chat
  MessageModel? getLastMessage(String chatId) {
    if (_isClearing) return null;
    final messages = _chatMessages[chatId];
    if (messages == null || messages.isEmpty) return null;
    
    return messages.last;
  }

  // Verificar si un chat tiene mensajes
  bool chatHasMessages(String chatId) {
    if (_isClearing) return false;
    final messages = _chatMessages[chatId];
    return messages != null && messages.isNotEmpty;
  }

  // Obtener resumen de actividad reciente
  Map<String, dynamic> getRecentActivity(String userId) {
    if (_isClearing) return {};
    
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

  // CORREGIDO: Limpiar todas las suscripciones de manera más robusta
  Future<void> _clearAllSubscriptions() async {
    debugPrint('🧹 ChatProvider - Iniciando limpieza de suscripciones...');
    
    // Cancelar suscripciones de mensajes
    final messageSubsToCancel = [..._messageSubscriptions.values];
    _messageSubscriptions.clear();
    
    for (final subscription in messageSubsToCancel) {
      try {
        await subscription.cancel();
      } catch (e) {
        debugPrint('⚠️ Error cancelando suscripción de mensaje: $e');
      }
    }
    
    debugPrint('🧹 Canceladas ${messageSubsToCancel.length} suscripciones de mensajes');

    // Cancelar suscripciones de chats
    final chatSubsToCancel = [..._chatSubscriptions.values];
    _chatSubscriptions.clear();
    
    for (final subscription in chatSubsToCancel) {
      try {
        await subscription.cancel();
      } catch (e) {
        debugPrint('⚠️ Error cancelando suscripción de chat: $e');
      }
    }
    
    debugPrint('🧹 Canceladas ${chatSubsToCancel.length} suscripciones de chats');
    debugPrint('✅ Todas las suscripciones de ChatProvider canceladas');
  }

  // CORREGIDO: Limpiar datos del usuario (logout) de manera más robusta
  Future<void> clearUserData() async {
    debugPrint('🧹 ChatProvider - Iniciando limpieza completa...');
    
    // Marcar como limpiando para prevenir nuevas operaciones
    _isClearing = true;
    
    try {
      // Limpiar suscripciones primero
      await _clearAllSubscriptions();
      
      // Limpiar datos
      _userChats.clear();
      _chatMessages.clear();
      _totalUnreadCount = 0;
      _error = null;
      _isLoading = false;
      _currentUserId = null;
      
      debugPrint('✅ ChatProvider completamente limpiado');
      
      // Notificar cambios antes de resetear el flag
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error limpiando ChatProvider: $e');
      // No lanzar error para no bloquear el logout
    } finally {
      // Resetear flag de limpieza después de un pequeño delay
      // para asegurar que no hay operaciones pendientes
      await Future.delayed(const Duration(milliseconds: 100));
      _isClearing = false;
    }
  }

  // Métodos de utilidad con protección
  void _setLoading(bool loading) {
    if (!_isClearing) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (!_isClearing) {
      _error = error;
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    if (!_isClearing) {
      _error = null;
      notifyListeners();
    }
  }

  // Refrescar chats con protección
  Future<void> refreshChats(String userId) async {
    if (_isClearing) return;
    
    await clearUserData();
    // Pequeño delay para asegurar que la limpieza terminó
    await Future.delayed(const Duration(milliseconds: 200));
    await initializeUserChats(userId);
  }

  @override
  void dispose() {
    debugPrint('🧹 ChatProvider dispose() llamado');
    _isClearing = true;
    _clearAllSubscriptions();
    super.dispose();
  }
}