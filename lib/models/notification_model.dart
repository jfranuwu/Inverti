// Archivo: lib/models/notification_model.dart
// Modelo de notificación actualizado con campos adicionales

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? actionUrl;
  final NotificationPriority priority;
  final bool isExpired;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data = const {},
    this.imageUrl,
    this.actionUrl,
    this.priority = NotificationPriority.medium,
    this.isExpired = false,
    this.expiresAt,
  });

  // Crear desde Firestore Document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isExpired: data['isExpired'] ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  // Crear desde JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isExpired: json['isExpired'] ?? false,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'priority': priority.toString().split('.').last,
      'isExpired': isExpired,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'priority': priority.toString().split('.').last,
      'isExpired': isExpired,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  // Método copyWith
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority? priority,
    bool? isExpired,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
      isExpired: isExpired ?? this.isExpired,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Métodos de utilidad

  // Marcar como leída
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  // Verificar si la notificación ha expirado
  bool get hasExpired {
    if (expiresAt == null) return isExpired;
    return DateTime.now().isAfter(expiresAt!) || isExpired;
  }

  // Obtener tiempo desde creación
  Duration get timeSinceCreation => DateTime.now().difference(createdAt);

  // Verificar si es una notificación nueva (menos de 1 hora)
  bool get isNew => timeSinceCreation.inHours < 1;

  // Verificar si es una notificación reciente (menos de 24 horas)
  bool get isRecent => timeSinceCreation.inHours < 24;

  // Obtener descripción del tipo de notificación
  String get typeDescription {
    switch (type) {
      case 'investor_interest':
        return 'Interés de Inversor';
      case 'project_funded':
        return 'Proyecto Financiado';
      case 'project_update':
        return 'Actualización de Proyecto';
      case 'message':
        return 'Mensaje';
      case 'system':
        return 'Sistema';
      case 'promotion':
        return 'Promoción';
      case 'reminder':
        return 'Recordatorio';
      default:
        return 'General';
    }
  }

  // Obtener icono basado en el tipo
  String get iconName {
    switch (type) {
      case 'investor_interest':
        return 'people';
      case 'project_funded':
        return 'attach_money';
      case 'project_update':
        return 'update';
      case 'message':
        return 'message';
      case 'system':
        return 'settings';
      case 'promotion':
        return 'campaign';
      case 'reminder':
        return 'schedule';
      default:
        return 'notifications';
    }
  }

  // Obtener color basado en el tipo y prioridad
  String get colorCode {
    if (priority == NotificationPriority.high) return '#FF5722'; // Red
    if (priority == NotificationPriority.low) return '#9E9E9E'; // Grey
    
    switch (type) {
      case 'investor_interest':
        return '#FF9800'; // Orange
      case 'project_funded':
        return '#4CAF50'; // Green
      case 'project_update':
        return '#2196F3'; // Blue
      case 'message':
        return '#9C27B0'; // Purple
      case 'system':
        return '#607D8B'; // Blue Grey
      case 'promotion':
        return '#E91E63'; // Pink
      case 'reminder':
        return '#FF5722'; // Deep Orange
      default:
        return '#757575'; // Grey
    }
  }

  // Obtener datos específicos
  T? getData<T>(String key) {
    return data[key] as T?;
  }

  // Verificar si tiene acción
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;

  // Verificar si tiene imagen
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Obtener resumen para mostrar en notificaciones push
  Map<String, String> get pushNotificationData {
    return {
      'title': title,
      'body': message,
      'type': type,
      'priority': priority.toString().split('.').last,
      'image': imageUrl ?? '',
      'action': actionUrl ?? '',
      'userId': userId,
      'notificationId': id,
    };
  }

  // Verificar si se puede eliminar (notificaciones antigas o leídas)
  bool get canBeDeleted {
    return isRead || timeSinceCreation.inDays > 30 || hasExpired;
  }

  // Obtener formato de tiempo para mostrar en UI
  String get timeFormat {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}

// Enum para prioridad de notificaciones
enum NotificationPriority {
  low,
  medium,
  high,
  urgent;

  // Obtener valor numérico para ordenamiento
  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.medium:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.urgent:
        return 4;
    }
  }

  // Obtener descripción legible
  String get description {
    switch (this) {
      case NotificationPriority.low:
        return 'Baja';
      case NotificationPriority.medium:
        return 'Media';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  // Obtener color asociado
  String get colorCode {
    switch (this) {
      case NotificationPriority.low:
        return '#9E9E9E'; // Grey
      case NotificationPriority.medium:
        return '#2196F3'; // Blue
      case NotificationPriority.high:
        return '#FF9800'; // Orange
      case NotificationPriority.urgent:
        return '#F44336'; // Red
    }
  }
}

// Clase para tipos de notificación predefinidos
class NotificationTypes {
  static const String investorInterest = 'investor_interest';
  static const String projectFunded = 'project_funded';
  static const String projectUpdate = 'project_update';
  static const String message = 'message';
  static const String system = 'system';
  static const String promotion = 'promotion';
  static const String reminder = 'reminder';
  static const String general = 'general';

  static const List<String> all = [
    investorInterest,
    projectFunded,
    projectUpdate,
    message,
    system,
    promotion,
    reminder,
    general,
  ];

  // Verificar si un tipo es válido
  static bool isValidType(String type) {
    return all.contains(type);
  }

  // Obtener descripción del tipo
  static String getDescription(String type) {
    switch (type) {
      case investorInterest:
        return 'Interés de Inversor';
      case projectFunded:
        return 'Proyecto Financiado';
      case projectUpdate:
        return 'Actualización de Proyecto';
      case message:
        return 'Mensaje';
      case system:
        return 'Sistema';
      case promotion:
        return 'Promoción';
      case reminder:
        return 'Recordatorio';
      case general:
        return 'General';
      default:
        return 'Desconocido';
    }
  }
}