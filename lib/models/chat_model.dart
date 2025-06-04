// Archivo: lib/models/chat_model.dart
// Modelos para chat y mensajes

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantTypes; // 'investor' or 'entrepreneur'
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? projectId;
  final String? projectTitle;
  final Map<String, dynamic> metadata;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantTypes,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.projectId,
    this.projectTitle,
    this.metadata = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantTypes: Map<String, String>.from(data['participantTypes'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      projectId: data['projectId'],
      projectTitle: data['projectTitle'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantTypes': participantTypes,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'metadata': metadata,
    };
  }

  // Obtener el otro participante (no el usuario actual)
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // Obtener nombre del otro participante
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    return participantNames[otherId] ?? 'Usuario';
  }

  // Obtener tipo del otro participante
  String getOtherParticipantType(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    return participantTypes[otherId] ?? 'user';
  }

  // Obtener mensajes no leídos para un usuario
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Verificar si tiene mensajes no leídos
  bool hasUnreadMessages(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantTypes,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? projectId,
    String? projectTitle,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantTypes: participantTypes ?? this.participantTypes,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatModel(id: $id, participants: $participants, projectTitle: $projectTitle)';
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.metadata = const {},
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'metadata': metadata,
    };
  }

  // Verificar si el mensaje es del usuario actual
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  // Obtener formato de tiempo para mostrar
  String get timeFormat {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  // Obtener formato completo de fecha y hora
  String get fullTimeFormat {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}

enum MessageType {
  text,
  image,
  file,
  system,
}

// Tipos de mensajes del sistema
class SystemMessages {
  static const String chatStarted = 'chat_started';
  static const String investorInterested = 'investor_interested';
  static const String projectShared = 'project_shared';
  
  static String getChatStartedMessage(String projectTitle) {
    return 'Conversación iniciada sobre el proyecto "$projectTitle"';
  }
  
  static String getInvestorInterestedMessage(String investorName, String projectTitle) {
    return '$investorName mostró interés en tu proyecto "$projectTitle"';
  }
}