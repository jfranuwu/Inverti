// Archivo: lib/providers/project_provider.dart
// Provider actualizado para manejo de proyectos con tiempo real

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../services/fcm_service.dart';

class ProjectProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  // Estado del provider
  List<ProjectModel> _allProjects = [];
  List<ProjectModel> _myProjects = [];
  List<ProjectModel> _featuredProjects = [];
  bool _isLoading = false;
  String? _error;

  // Streams para tiempo real
  StreamSubscription<QuerySnapshot>? _myProjectsSubscription;
  StreamSubscription<QuerySnapshot>? _allProjectsSubscription;

  // Getters
  List<ProjectModel> get allProjects => _allProjects;
  List<ProjectModel> get myProjects => _myProjects;
  List<ProjectModel> get featuredProjects => _featuredProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener proyecto por ID
  ProjectModel? getProjectById(String projectId) {
    try {
      return _allProjects.firstWhere((project) => project.id == projectId);
    } catch (e) {
      return _myProjects.where((project) => project.id == projectId).firstOrNull;
    }
  }

  // Stream para un proyecto específico
  Stream<ProjectModel?> getProjectStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ProjectModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Cargar todos los proyectos con tiempo real
  Future<void> loadAllProjects() async {
    try {
      _setLoading(true);
      _error = null;

      // Cancelar suscripción anterior si existe
      await _allProjectsSubscription?.cancel();

      // Crear stream para todos los proyectos
      _allProjectsSubscription = _firestore
          .collection('projects')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _allProjects = snapshot.docs
              .map((doc) => ProjectModel.fromFirestore(doc))
              .toList();
          
          _updateFeaturedProjects();
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Error cargando proyectos: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Error cargando proyectos: $e');
      _setLoading(false);
    }
  }

  // Cargar mis proyectos con tiempo real
  Future<void> loadMyProjects(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      // Cancelar suscripción anterior si existe
      await _myProjectsSubscription?.cancel();

      // Crear stream para mis proyectos
      _myProjectsSubscription = _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _myProjects = snapshot.docs
              .map((doc) => ProjectModel.fromFirestore(doc))
              .toList();
          
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Error cargando mis proyectos: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Error cargando mis proyectos: $e');
      _setLoading(false);
    }
  }

  // Actualizar proyectos destacados
  void _updateFeaturedProjects() {
    _featuredProjects = _allProjects
        .where((project) => project.isFeatured)
        .take(5)
        .toList();
  }

  // Crear nuevo proyecto
  Future<String?> createProject(ProjectModel project) async {
    try {
      _setLoading(true);
      _error = null;

      final docRef = await _firestore.collection('projects').add({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'interestedInvestors': 0,
        'currentFunding': 0.0,
        'fundingPercentage': 0.0,
      });

      _setLoading(false);
      debugPrint('✅ Proyecto creado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _setError('Error creando proyecto: $e');
      _setLoading(false);
      debugPrint('❌ Error creando proyecto: $e');
      return null;
    }
  }

  // Actualizar proyecto existente
  Future<bool> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _error = null;

      await _firestore.collection('projects').doc(projectId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      debugPrint('✅ Proyecto actualizado: $projectId');
      return true;
    } catch (e) {
      _setError('Error actualizando proyecto: $e');
      _setLoading(false);
      debugPrint('❌ Error actualizando proyecto: $e');
      return false;
    }
  }

  // Eliminar proyecto
  Future<bool> deleteProject(String projectId) async {
    try {
      _setLoading(true);
      _error = null;

      // Marcar como inactivo en lugar de eliminar físicamente
      await _firestore.collection('projects').doc(projectId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      debugPrint('✅ Proyecto eliminado: $projectId');
      return true;
    } catch (e) {
      _setError('Error eliminando proyecto: $e');
      _setLoading(false);
      debugPrint('❌ Error eliminando proyecto: $e');
      return false;
    }
  }

  // Registrar interés de inversor
  Future<bool> registerInvestorInterest({
    required String projectId,
    required String investorId,
    required String investorName,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final batch = _firestore.batch();

      // 1. Crear registro de interés
      final interestRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('interested_investors')
          .doc(investorId);

      batch.set(interestRef, {
        'investorId': investorId,
        'investorName': investorName,
        'interestedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // 2. Incrementar contador en el proyecto
      final projectRef = _firestore.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'interestedInvestors': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 3. Obtener datos del proyecto para notificación
      final projectDoc = await projectRef.get();
      if (projectDoc.exists) {
        final project = ProjectModel.fromFirestore(projectDoc);
        
        // 4. Enviar notificación al emprendedor
        await _fcmService.sendInvestorInterestNotification(
          entrepreneurId: project.createdBy,
          projectId: projectId,
          projectTitle: project.title,
          investorName: investorName,
        );
      }

      _setLoading(false);
      debugPrint('✅ Interés registrado para proyecto: $projectId');
      return true;
    } catch (e) {
      _setError('Error registrando interés: $e');
      _setLoading(false);
      debugPrint('❌ Error registrando interés: $e');
      return false;
    }
  }

  // Remover interés de inversor
  Future<bool> removeInvestorInterest({
    required String projectId,
    required String investorId,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final batch = _firestore.batch();

      // 1. Marcar interés como inactivo
      final interestRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('interested_investors')
          .doc(investorId);

      batch.update(interestRef, {
        'isActive': false,
        'removedAt': FieldValue.serverTimestamp(),
      });

      // 2. Decrementar contador en el proyecto
      final projectRef = _firestore.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'interestedInvestors': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _setLoading(false);
      debugPrint('✅ Interés removido del proyecto: $projectId');
      return true;
    } catch (e) {
      _setError('Error removiendo interés: $e');
      _setLoading(false);
      debugPrint('❌ Error removiendo interés: $e');
      return false;
    }
  }

  // Obtener inversores interesados en un proyecto
  Stream<List<Map<String, dynamic>>> getInterestedInvestorsStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('interested_investors')
        .where('isActive', isEqualTo: true)
        .orderBy('interestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Verificar si un inversor mostró interés
  Future<bool> hasInvestorShownInterest(String projectId, String investorId) async {
    try {
      final doc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('interested_investors')
          .doc(investorId)
          .get();

      return doc.exists && (doc.data()?['isActive'] == true);
    } catch (e) {
      debugPrint('❌ Error verificando interés: $e');
      return false;
    }
  }

  // Buscar proyectos
  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      if (query.isEmpty) return _allProjects;

      // Búsqueda simple por título y descripción
      final results = _allProjects.where((project) {
        final titleMatch = project.title.toLowerCase().contains(query.toLowerCase());
        final descMatch = project.description.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = project.category.toLowerCase().contains(query.toLowerCase());
        
        return titleMatch || descMatch || categoryMatch;
      }).toList();

      return results;
    } catch (e) {
      debugPrint('❌ Error buscando proyectos: $e');
      return [];
    }
  }

  // Filtrar proyectos por categoría
  List<ProjectModel> getProjectsByCategory(String category) {
    if (category == 'Todos') return _allProjects;
    
    return _allProjects
        .where((project) => project.category == category)
        .toList();
  }

  // Obtener estadísticas del emprendedor
  Map<String, dynamic> getEntrepreneurStats(String userId) {
    final userProjects = _myProjects;
    
    return {
      'totalProjects': userProjects.length,
      'activeProjects': userProjects.where((p) => p.status == 'active').length,
      'totalInterested': userProjects.fold<int>(0, (sum, p) => sum + p.interestedInvestors),
      'totalViews': userProjects.fold<int>(0, (sum, p) => sum + (p.views ?? 0)),
      'totalFunding': userProjects.fold<double>(0, (sum, p) => sum + p.currentFunding),
    };
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

  // Limpiar recursos
  @override
  void dispose() {
    _myProjectsSubscription?.cancel();
    _allProjectsSubscription?.cancel();
    super.dispose();
  }
}