// Archivo: lib/models/user_model.dart
// Modelo de datos para usuarios con roles (Inversor/Emprendedor)

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String userType; // "investor" o "entrepreneur"
  final String? photoURL;
  final String? bio;
  final List<String>? industries; // Industrias de interés
  final DateTime createdAt;
  final String? phone;
  final String? location;
  final bool isVerified;
  final String subscriptionPlan; // "basic", "pro", "premium"

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    this.photoURL,
    this.bio,
    this.industries,
    required this.createdAt,
    this.phone,
    this.location,
    this.isVerified = false,
    this.subscriptionPlan = 'basic',
  });

  // Convertir de Firestore a UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: data['userType'] ?? 'investor',
      photoURL: data['photoURL'],
      bio: data['bio'],
      industries: data['industries'] != null 
          ? List<String>.from(data['industries']) 
          : null,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      phone: data['phone'],
      location: data['location'],
      isVerified: data['isVerified'] ?? false,
      subscriptionPlan: data['subscriptionPlan'] ?? 'basic',
    );
  }

  // Convertir UserModel a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType,
      'photoURL': photoURL,
      'bio': bio,
      'industries': industries,
      'createdAt': Timestamp.fromDate(createdAt),
      'phone': phone,
      'location': location,
      'isVerified': isVerified,
      'subscriptionPlan': subscriptionPlan,
    };
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? userType,
    String? photoURL,
    String? bio,
    List<String>? industries,
    DateTime? createdAt,
    String? phone,
    String? location,
    bool? isVerified,
    String? subscriptionPlan,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      industries: industries ?? this.industries,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }
}