// Archivo: lib/models/project_model.dart
// Modelo de proyecto actualizado con campos adicionales para tiempo real

import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String fullDescription;
  final String category;
  final String imageUrl;
  final List<String> images;
  final double fundingGoal;
  final double currentFunding;
  final double fundingPercentage;
  final double equityOffered;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contactEmail;
  final String contactPhone;
  final String website;
  final String linkedin;
  final bool isFeatured;
  final bool isActive;
  final int interestedInvestors;
  final int views;
  final DateTime? deletedAt;
  final Map<String, dynamic> metadata;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.category,
    required this.imageUrl,
    required this.images,
    required this.fundingGoal,
    required this.currentFunding,
    required this.fundingPercentage,
    required this.equityOffered,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.contactEmail,
    required this.contactPhone,
    required this.website,
    required this.linkedin,
    required this.isFeatured,
    required this.isActive,
    required this.interestedInvestors,
    required this.views,
    this.deletedAt,
    this.metadata = const {},
  });

  // Crear desde Firestore Document
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      fundingGoal: (data['fundingGoal'] ?? 0).toDouble(),
      currentFunding: (data['currentFunding'] ?? 0).toDouble(),
      fundingPercentage: (data['fundingPercentage'] ?? 0).toDouble(),
      equityOffered: (data['equityOffered'] ?? 0).toDouble(),
      status: data['status'] ?? 'draft',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      website: data['website'] ?? '',
      linkedin: data['linkedin'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      interestedInvestors: data['interestedInvestors'] ?? 0,
      views: data['views'] ?? 0,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Crear desde JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fullDescription: json['fullDescription'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      fundingGoal: (json['fundingGoal'] ?? 0).toDouble(),
      currentFunding: (json['currentFunding'] ?? 0).toDouble(),
      fundingPercentage: (json['fundingPercentage'] ?? 0).toDouble(),
      equityOffered: (json['equityOffered'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      website: json['website'] ?? '',
      linkedin: json['linkedin'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      interestedInvestors: json['interestedInvestors'] ?? 0,
      views: json['views'] ?? 0,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fullDescription': fullDescription,
      'category': category,
      'imageUrl': imageUrl,
      'images': images,
      'fundingGoal': fundingGoal,
      'currentFunding': currentFunding,
      'fundingPercentage': fundingPercentage,
      'equityOffered': equityOffered,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'linkedin': linkedin,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'interestedInvestors': interestedInvestors,
      'views': views,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'metadata': metadata,
    };
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fullDescription': fullDescription,
      'category': category,
      'imageUrl': imageUrl,
      'images': images,
      'fundingGoal': fundingGoal,
      'currentFunding': currentFunding,
      'fundingPercentage': fundingPercentage,
      'equityOffered': equityOffered,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'linkedin': linkedin,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'interestedInvestors': interestedInvestors,
      'views': views,
      'deletedAt': deletedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Método copyWith para crear copias con modificaciones
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? fullDescription,
    String? category,
    String? imageUrl,
    List<String>? images,
    double? fundingGoal,
    double? currentFunding,
    double? fundingPercentage,
    double? equityOffered,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactEmail,
    String? contactPhone,
    String? website,
    String? linkedin,
    bool? isFeatured,
    bool? isActive,
    int? interestedInvestors,
    int? views,
    DateTime? deletedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fullDescription: fullDescription ?? this.fullDescription,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      fundingGoal: fundingGoal ?? this.fundingGoal,
      currentFunding: currentFunding ?? this.currentFunding,
      fundingPercentage: fundingPercentage ?? this.fundingPercentage,
      equityOffered: equityOffered ?? this.equityOffered,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      interestedInvestors: interestedInvestors ?? this.interestedInvestors,
      views: views ?? this.views,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Métodos de utilidad

  // Verificar si el proyecto está activo
  bool get isActiveProject => isActive && status != 'deleted';

  // Verificar si el proyecto está financiado
  bool get isFullyFunded => fundingPercentage >= 100.0;

  // Obtener progreso del financiamiento
  double get progressPercentage => fundingPercentage.clamp(0.0, 100.0);

  // Verificar si el proyecto necesita atención (pocos interesados)
  bool get needsAttention => interestedInvestors < 5 && status == 'active';

  // Obtener estado del proyecto en texto
  String get statusText {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'draft':
        return 'Borrador';
      case 'paused':
        return 'Pausado';
      case 'funded':
        return 'Financiado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  // Obtener color del estado
  String get statusColor {
    switch (status) {
      case 'active':
        return 'green';
      case 'draft':
        return 'orange';
      case 'paused':
        return 'red';
      case 'funded':
        return 'blue';
      case 'completed':
        return 'purple';
      case 'cancelled':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Verificar si tiene información de contacto completa
  bool get hasCompleteContactInfo {
    return contactEmail.isNotEmpty && contactPhone.isNotEmpty;
  }

  // Verificar si tiene imágenes
  bool get hasImages => images.isNotEmpty;

  // Obtener tiempo desde creación
  Duration get timeSinceCreation => DateTime.now().difference(createdAt);

  // Verificar si es un proyecto nuevo (menos de 7 días)
  bool get isNewProject => timeSinceCreation.inDays < 7;

  // Calcular popularidad basada en vistas e interesados
  double get popularityScore {
    return (views * 0.1) + (interestedInvestors * 10);
  }

  // Verificar si el proyecto está en tendencia
  bool get isTrending {
    return popularityScore > 50 && timeSinceCreation.inDays < 30;
  }

  // Obtener información de progreso para mostrar en UI
  Map<String, dynamic> get progressInfo {
    return {
      'percentage': fundingPercentage,
      'current': currentFunding,
      'goal': fundingGoal,
      'remaining': fundingGoal - currentFunding,
      'isCompleted': isFullyFunded,
    };
  }

  // Obtener metadata específico
  T? getMetadata<T>(String key) {
    return metadata[key] as T?;
  }

  // Establecer metadata específico
  ProjectModel setMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProjectModel(id: $id, title: $title, status: $status, interestedInvestors: $interestedInvestors)';
  }
}