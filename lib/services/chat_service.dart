// Archivo: lib/services/chat_service.dart
// Servicio para manejo de chats y mensajes

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear o obtener chat existente entre dos usuarios
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
      debugPrint('🗨️ Creando/obteniendo chat entre $userName1 y $userName2');
      
      // Buscar chat existente entre estos usuarios
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .where('isActive', isEqualTo: true)
          .get();

      // Verificar si ya existe un chat entre estos usuarios para este proyecto
      for (final doc in existingChatQuery.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.contains(userId2) && 
            (projectId == null || chat.projectId == projectId)) {
          debugPrint('✅ Chat existente encontrado: ${doc.id}');
          return doc.id;
        }
      }

      // Crear nuevo chat
      final chatData = {
        'participants': [userId1, userId2],
        'participantNames': {
          userId1: userName1,
          userId2: userName2,
        },
        'participantTypes': {
          userId1: userType1,
          userId2: userType2,
        },
        'unreadCount': {
          userId1: 0,
          userId2: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'projectId': projectId,
        'projectTitle': projectTitle,
        'metadata': {},
      };

      final chatRef = await _firestore.collection('chats').add(chatData);
      
      // Crear mensaje inicial del sistema si hay proyecto
      if (projectId != null && projectTitle != null) {
        await sendSystemMessage(
          chatId: chatRef.id,
          content: SystemMessages.getChatStartedMessage(projectTitle),
          type: SystemMessages.chatStarted,
        );
      }

      debugPrint('✅ Nuevo chat creado: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      debugPrint('❌ Error creando/obteniendo chat: $e');
      return null;
    }
  }

  // Obtener stream de chats del usuario
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();
    });
  }

  // Obtener stream de mensajes de un chat
  Stream<List<MessageModel>> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Enviar mensaje de texto
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📤 Enviando mensaje en chat $chatId');
      
      final batch = _firestore.batch();

      // 1. Crear el mensaje
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': metadata ?? {},
      };

      batch.set(messageRef, messageData);

      // 2. Actualizar el chat con el último mensaje
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Obtener información actual del chat para actualizar unreadCount
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        debugPrint('❌ Chat no encontrado: $chatId');
        return false;
      }

      final chat = ChatModel.fromFirestore(chatDoc);
      final otherUserId = chat.getOtherParticipant(senderId);

      // Actualizar unreadCount para el otro usuario
      final newUnreadCount = Map<String, int>.from(chat.unreadCount);
      newUnreadCount[otherUserId] = (newUnreadCount[otherUserId] ?? 0) + 1;
      newUnreadCount[senderId] = 0; // Reset para el remitente

      final chatUpdateData = {
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'unreadCount': newUnreadCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(chatRef, chatUpdateData);

      await batch.commit();

      debugPrint('✅ Mensaje enviado exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');
      return false;
    }
  }

  // Enviar mensaje del sistema
  Future<bool> sendSystemMessage({
    required String chatId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🤖 Enviando mensaje del sistema en chat $chatId');
      
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageData = {
        'chatId': chatId,
        'senderId': 'system',
        'senderName': 'Sistema',
        'content': content,
        'type': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': true, // Los mensajes del sistema se marcan como leídos
        'metadata': {
          'systemType': type,
          ...?metadata,
        },
      };

      await messageRef.set(messageData);

      debugPrint('✅ Mensaje del sistema enviado');
      return true;
    } catch (e) {
      debugPrint('❌ Error enviando mensaje del sistema: $e');
      return false;
    }
  }

  // Marcar mensajes como leídos
  Future<bool> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      debugPrint('👁️ Marcando mensajes como leídos en chat $chatId para usuario $userId');
      
      final batch = _firestore.batch();

      // 1. Obtener mensajes no leídos del usuario
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // 2. Marcar cada mensaje como leído
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Actualizar contador en el chat
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (chatDoc.exists) {
        final chat = ChatModel.fromFirestore(chatDoc);
        final newUnreadCount = Map<String, int>.from(chat.unreadCount);
        newUnreadCount[userId] = 0;

        batch.update(chatRef, {
          'unreadCount': newUnreadCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint('✅ Mensajes marcados como leídos');
      return true;
    } catch (e) {
      debugPrint('❌ Error marcando mensajes como leídos: $e');
      return false;
    }
  }

  // Obtener información de un chat específico
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo chat: $e');
      return null;
    }
  }

  // Obtener stream de un chat específico
  Stream<ChatModel?> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Desactivar chat (no eliminar físicamente)
  Future<bool> deactivateChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Chat desactivado: $chatId');
      return true;
    } catch (e) {
      debugPrint('❌ Error desactivando chat: $e');
      return false;
    }
  }

  // Obtener contador total de mensajes no leídos para un usuario
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);
        totalUnread += chat.getUnreadCountForUser(userId);
      }
      return totalUnread;
    });
  }

  // Búsqueda de chats
  Future<List<ChatModel>> searchChats(String userId, String query) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final chats = chatsSnapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();

      // Filtrar por nombre de participante o título de proyecto
      final filteredChats = chats.where((chat) {
        final otherParticipantName = chat.getOtherParticipantName(userId).toLowerCase();
        final projectTitle = (chat.projectTitle ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return otherParticipantName.contains(searchQuery) ||
               projectTitle.contains(searchQuery);
      }).toList();

      return filteredChats;
    } catch (e) {
      debugPrint('❌ Error buscando chats: $e');
      return [];
    }
  }

  // Obtener estadísticas de chat para un usuario
  Future<Map<String, int>> getChatStats(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final chats = chatsSnapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();

      int totalUnread = 0;
      int activeChats = 0;
      int chatsWithInvestors = 0;
      int chatsWithEntrepreneurs = 0;

      for (final chat in chats) {
        totalUnread += chat.getUnreadCountForUser(userId);
        
        if (chat.lastMessageTime != null) {
          final daysSinceLastMessage = DateTime.now().difference(chat.lastMessageTime!).inDays;
          if (daysSinceLastMessage < 7) {
            activeChats++;
          }
        }

        final otherUserType = chat.getOtherParticipantType(userId);
        if (otherUserType == 'investor') {
          chatsWithInvestors++;
        } else if (otherUserType == 'entrepreneur') {
          chatsWithEntrepreneurs++;
        }
      }

      return {
        'totalChats': chats.length,
        'totalUnread': totalUnread,
        'activeChats': activeChats,
        'chatsWithInvestors': chatsWithInvestors,
        'chatsWithEntrepreneurs': chatsWithEntrepreneurs,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas de chat: $e');
      return {};
    }
  }

  // Verificar si existe un chat entre dos usuarios para un proyecto específico
  Future<String?> getChatBetweenUsers({
    required String userId1,
    required String userId2,
    String? projectId,
  }) async {
    try {
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in chatsQuery.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.contains(userId2)) {
          // Si se especifica projectId, verificar que coincida
          if (projectId == null || chat.projectId == projectId) {
            return doc.id;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error verificando chat existente: $e');
      return null;
    }
  }

  // Actualizar información del chat (nombres de usuarios, etc.)
  Future<bool> updateChatInfo({
    required String chatId,
    Map<String, String>? participantNames,
    Map<String, String>? participantTypes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (participantNames != null) {
        updateData['participantNames'] = participantNames;
      }
      
      if (participantTypes != null) {
        updateData['participantTypes'] = participantTypes;
      }
      
      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);
      
      debugPrint('✅ Información del chat actualizada');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando información del chat: $e');
      return false;
    }
  }
}