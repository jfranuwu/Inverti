// Archivo: lib/models/project_model.dart
// Modelo de datos para proyectos creados por emprendedores

import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String entrepreneurId;
  final String entrepreneurName;
  final String? quickPitchUrl; // URL del audio de 60 segundos
  final double fundingGoal;
  final double currentFunding;
  final String industry;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // "active", "funded", "closed"
  final List<String>? images;
  final int interestedInvestors;
  final Map<String, dynamic>? businessPlan;
  final String? location;
  final double? roi; // Return on Investment esperado

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.entrepreneurId,
    required this.entrepreneurName,
    this.quickPitchUrl,
    required this.fundingGoal,
    this.currentFunding = 0,
    required this.industry,
    required this.createdAt,
    this.updatedAt,
    this.status = 'active',
    this.images,
    this.interestedInvestors = 0,
    this.businessPlan,
    this.location,
    this.roi,
  });

  // Calcular porcentaje de financiamiento
  double get fundingPercentage => 
      fundingGoal > 0 ? (currentFunding / fundingGoal) * 100 : 0;

  // Verificar si tiene Quick Pitch
  bool get hasQuickPitch => quickPitchUrl != null && quickPitchUrl!.isNotEmpty;

  // Convertir de Firestore a ProjectModel
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      entrepreneurId: data['entrepreneurId'] ?? '',
      entrepreneurName: data['entrepreneurName'] ?? '',
      quickPitchUrl: data['quickPitchUrl'],
      fundingGoal: (data['fundingGoal'] ?? 0).toDouble(),
      currentFunding: (data['currentFunding'] ?? 0).toDouble(),
      industry: data['industry'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'active',
      images: data['images'] != null 
          ? List<String>.from(data['images']) 
          : null,
      interestedInvestors: data['interestedInvestors'] ?? 0,
      businessPlan: data['businessPlan'],
      location: data['location'],
      roi: data['roi']?.toDouble(),
    );
  }

  // Convertir ProjectModel a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'entrepreneurId': entrepreneurId,
      'entrepreneurName': entrepreneurName,
      'quickPitchUrl': quickPitchUrl,
      'fundingGoal': fundingGoal,
      'currentFunding': currentFunding,
      'industry': industry,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      'images': images,
      'interestedInvestors': interestedInvestors,
      'businessPlan': businessPlan,
      'location': location,
      'roi': roi,
    };
  }

  // Copiar con modificaciones
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? entrepreneurId,
    String? entrepreneurName,
    String? quickPitchUrl,
    double? fundingGoal,
    double? currentFunding,
    String? industry,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    List<String>? images,
    int? interestedInvestors,
    Map<String, dynamic>? businessPlan,
    String? location,
    double? roi,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      entrepreneurId: entrepreneurId ?? this.entrepreneurId,
      entrepreneurName: entrepreneurName ?? this.entrepreneurName,
      quickPitchUrl: quickPitchUrl ?? this.quickPitchUrl,
      fundingGoal: fundingGoal ?? this.fundingGoal,
      currentFunding: currentFunding ?? this.currentFunding,
      industry: industry ?? this.industry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      images: images ?? this.images,
      interestedInvestors: interestedInvestors ?? this.interestedInvestors,
      businessPlan: businessPlan ?? this.businessPlan,
      location: location ?? this.location,
      roi: roi ?? this.roi,
    );
  }
}

// Lista de industrias disponibles
class Industries {
  static const List<String> list = [
    'Tecnología',
    'Salud',
    'Educación',
    'Finanzas',
    'E-commerce',
    'Alimentos',
    'Energía',
    'Transporte',
    'Inmobiliario',
    'Entretenimiento',
    'Agricultura',
    'Manufactura',
    'Servicios',
    'Otro',
  ];
}