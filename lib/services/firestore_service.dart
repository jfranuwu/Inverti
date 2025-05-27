// Archivo: lib/services/firestore_service.dart
// Servicio para operaciones CRUD con Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Referencia a colecciones
  static CollectionReference get users => 
      _firestore.collection(FirebaseConfig.usersCollection);
  
  static CollectionReference get projects => 
      _firestore.collection(FirebaseConfig.projectsCollection);
  
  static CollectionReference get interests => 
      _firestore.collection(FirebaseConfig.interestsCollection);
  
  static CollectionReference get notifications => 
      _firestore.collection(FirebaseConfig.notificationsCollection);
  
  // Crear documento con ID automático
  static Future<String> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear documento: $e');
    }
  }
  
  // Actualizar documento
  static Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Error al actualizar documento: $e');
    }
  }
  
  // Eliminar documento
  static Future<void> deleteDocument(
    String collection,
    String documentId,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }
  
  // Obtener documento por ID
  static Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      throw Exception('Error al obtener documento: $e');
    }
  }
  
  // Obtener documentos con filtros
  static Future<QuerySnapshot> getDocuments(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      // Aplicar filtros
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            whereIn: filter.whereIn,
          );
        }
      }
      
      // Ordenar
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Limitar resultados
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query.get();
    } catch (e) {
      throw Exception('Error al obtener documentos: $e');
    }
  }
  
  // Stream de documentos en tiempo real
  static Stream<QuerySnapshot> streamDocuments(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    List<QueryFilter>? filters,
  }) {
    Query query = _firestore.collection(collection);
    
    // Aplicar filtros
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          whereIn: filter.whereIn,
        );
      }
    }
    
    // Ordenar
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    // Limitar resultados
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }
  
  // Batch operations para múltiples escrituras
  static Future<void> batchWrite(
    List<BatchOperation> operations,
  ) async {
    final batch = _firestore.batch();
    
    for (final op in operations) {
      final docRef = _firestore.collection(op.collection).doc(op.documentId);
      
      switch (op.type) {
        case OperationType.create:
          batch.set(docRef, op.data!);
          break;
        case OperationType.update:
          batch.update(docRef, op.data!);
          break;
        case OperationType.delete:
          batch.delete(docRef);
          break;
      }
    }
    
    await batch.commit();
  }
}

// Clase auxiliar para filtros
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? whereIn;
  
  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.whereIn,
  });
}

// Tipos de operación para batch
enum OperationType { create, update, delete }

// Clase para operaciones batch
class BatchOperation {
  final String collection;
  final String documentId;
  final OperationType type;
  final Map<String, dynamic>? data;
  
  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });
}