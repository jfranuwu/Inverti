// Archivo: lib/providers/project_provider.dart
// Provider actualizado para manejo de proyectos - CON LIMPIEZA SEGURA EN LOGOUT

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

  // NUEVO: Flag para prevenir operaciones durante logout
  bool _isClearing = false;

  // Streams para tiempo real
  StreamSubscription<QuerySnapshot>? _myProjectsSubscription;
  StreamSubscription<QuerySnapshot>? _allProjectsSubscription;

  // Getters
  List<ProjectModel> get allProjects => _allProjects;
  List<ProjectModel> get myProjects => _myProjects;
  List<ProjectModel> get featuredProjects => _featuredProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isClearing => _isClearing; // NUEVO

  // Obtener proyecto por ID con protección
  ProjectModel? getProjectById(String projectId) {
    if (_isClearing) return null;
    
    try {
      return _allProjects.firstWhere((project) => project.id == projectId);
    } catch (e) {
      return _myProjects.where((project) => project.id == projectId).firstOrNull;
    }
  }

  // Stream para un proyecto específico con protección
  Stream<ProjectModel?> getProjectStream(String projectId) {
    if (_isClearing) {
      return Stream.value(null);
    }
    
    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (doc.exists && !_isClearing) {
        return ProjectModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // MEJORADO: Cargar todos los proyectos con tiempo real y protección
  Future<void> loadAllProjects() async {
    if (_isClearing) return;
    
    try {
      _setLoading(true);
      _error = null;

      await _allProjectsSubscription?.cancel();

      if (_isClearing) return;

      _allProjectsSubscription = _firestore
          .collection('projects')
          .where('isActive', isEqualTo: true)  
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          // Solo procesar si no estamos limpiando
          if (!_isClearing) {
            _allProjects = snapshot.docs
                .map((doc) => ProjectModel.fromFirestore(doc))
                .toList();
            
            _updateFeaturedProjects();
            _setLoading(false);
            notifyListeners();
          }
        },
        onError: (error) {
          if (!_isClearing) {
            debugPrint('❌ Error en stream de todos los proyectos: $error');
            _setError('Error cargando proyectos: $error');
            _setLoading(false);
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!_isClearing) {
        _setError('Error cargando proyectos: $e');
        _setLoading(false);
      }
    }
  }

  // MEJORADO: Cargar mis proyectos con tiempo real y protección
  Future<void> loadMyProjects(String userId) async {
    if (_isClearing) return;
    
    try {
      _setLoading(true);
      _error = null;

      await _myProjectsSubscription?.cancel();

      if (_isClearing) return;

      _myProjectsSubscription = _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: userId)
          .where('isActive', isEqualTo: true)  
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          // Solo procesar si no estamos limpiando
          if (!_isClearing) {
            _myProjects = snapshot.docs
                .map((doc) => ProjectModel.fromFirestore(doc))
                .toList();
            
            _setLoading(false);
            notifyListeners();
          }
        },
        onError: (error) {
          if (!_isClearing) {
            debugPrint('❌ Error en stream de mis proyectos: $error');
            _setError('Error cargando mis proyectos: $error');
            _setLoading(false);
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!_isClearing) {
        _setError('Error cargando mis proyectos: $e');
        _setLoading(false);
      }
    }
  }

  // Actualizar proyectos destacados con protección
  void _updateFeaturedProjects() {
    if (_isClearing) return;
    
    _featuredProjects = _allProjects
        .where((project) => project.isFeatured)
        .take(5)
        .toList();
  }

  // Crear nuevo proyecto CON NOTIFICACIÓN AUTOMÁTICA y protección
  Future<String?> createProject(ProjectModel project) async {
    if (_isClearing) return null;
    
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

      debugPrint('✅ Proyecto creado con ID: ${docRef.id}');

      // 🚀 ENVIAR NOTIFICACIÓN A INVERSORES AUTOMÁTICAMENTE (solo si no estamos limpiando)
      if (!_isClearing) {
        try {
          final entrepreneurName = project.metadata['entrepreneurName'] as String? ?? 'Emprendedor';
          
          await _fcmService.sendNewProjectNotification(
            projectId: docRef.id,
            projectTitle: project.title,
            entrepreneurName: entrepreneurName,
            category: project.category,
          );
          
          debugPrint('✅ Notificación de nuevo proyecto enviada a inversores');
        } catch (notificationError) {
          // No fallar la creación del proyecto por error de notificación
          debugPrint('⚠️ Error enviando notificación de nuevo proyecto: $notificationError');
        }
      }

      _setLoading(false);
      return docRef.id;
    } catch (e) {
      if (!_isClearing) {
        _setError('Error creando proyecto: $e');
        _setLoading(false);
        debugPrint('❌ Error creando proyecto: $e');
      }
      return null;
    }
  }

  // Actualizar proyecto existente con protección
  Future<bool> updateProject(String projectId, Map<String, dynamic> updates) async {
    if (_isClearing) return false;
    
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
      if (!_isClearing) {
        _setError('Error actualizando proyecto: $e');
        _setLoading(false);
        debugPrint('❌ Error actualizando proyecto: $e');
      }
      return false;
    }
  }

  // Eliminar proyecto con protección
  Future<bool> deleteProject(String projectId) async {
    if (_isClearing) return false;
    
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
      if (!_isClearing) {
        _setError('Error eliminando proyecto: $e');
        _setLoading(false);
        debugPrint('❌ Error eliminando proyecto: $e');
      }
      return false;
    }
  }

  // Registrar interés de inversor CON NOTIFICACIÓN AUTOMÁTICA y protección
  Future<bool> registerInvestorInterest({
    required String projectId,
    required String investorId,
    required String investorName,
  }) async {
    if (_isClearing) return false;
    
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

      // 3. Obtener datos del proyecto para notificación (solo si no estamos limpiando)
      if (!_isClearing) {
        final projectDoc = await projectRef.get();
        if (projectDoc.exists && !_isClearing) {
          final project = ProjectModel.fromFirestore(projectDoc);
          
          // 🚀 ENVIAR NOTIFICACIÓN AL EMPRENDEDOR AUTOMÁTICAMENTE
          try {
            await _fcmService.sendInvestorInterestNotification(
              entrepreneurId: project.createdBy,
              projectId: projectId,
              projectTitle: project.title,
              investorName: investorName,
            );
            
            debugPrint('✅ Notificación de interés enviada al emprendedor');
          } catch (notificationError) {
            // No fallar el registro de interés por error de notificación
            debugPrint('⚠️ Error enviando notificación de interés: $notificationError');
          }
        }
      }

      _setLoading(false);
      debugPrint('✅ Interés registrado para proyecto: $projectId');
      return true;
    } catch (e) {
      if (!_isClearing) {
        _setError('Error registrando interés: $e');
        _setLoading(false);
        debugPrint('❌ Error registrando interés: $e');
      }
      return false;
    }
  }

  // Remover interés de inversor con protección
  Future<bool> removeInvestorInterest({
    required String projectId,
    required String investorId,
  }) async {
    if (_isClearing) return false;
    
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
      if (!_isClearing) {
        _setError('Error removiendo interés: $e');
        _setLoading(false);
        debugPrint('❌ Error removiendo interés: $e');
      }
      return false;
    }
  }

  // Obtener inversores interesados en un proyecto con protección
  Stream<List<Map<String, dynamic>>> getInterestedInvestorsStream(String projectId) {
    if (_isClearing) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('interested_investors')
        .where('isActive', isEqualTo: true)
        .orderBy('interestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (_isClearing) return [];
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Verificar si un inversor mostró interés con protección
  Future<bool> hasInvestorShownInterest(String projectId, String investorId) async {
    if (_isClearing) return false;
    
    try {
      final doc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('interested_investors')
          .doc(investorId)
          .get();

      return doc.exists && (doc.data()?['isActive'] == true);
    } catch (e) {
      if (!_isClearing) {
        debugPrint('❌ Error verificando interés: $e');
      }
      return false;
    }
  }

  // Buscar proyectos con protección
  Future<List<ProjectModel>> searchProjects(String query) async {
    if (_isClearing) return [];
    
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
      if (!_isClearing) {
        debugPrint('❌ Error buscando proyectos: $e');
      }
      return [];
    }
  }

  // Filtrar proyectos por categoría con protección
  List<ProjectModel> getProjectsByCategory(String category) {
    if (_isClearing) return [];
    
    if (category == 'Todos') return _allProjects;
    
    return _allProjects
        .where((project) => project.category == category)
        .toList();
  }

  // Obtener estadísticas del emprendedor con protección
  Map<String, dynamic> getEntrepreneurStats(String userId) {
    if (_isClearing) return {};
    
    final userProjects = _myProjects;
    
    return {
      'totalProjects': userProjects.length,
      'activeProjects': userProjects.where((p) => p.status == 'active').length,
      'totalInterested': userProjects.fold<int>(0, (sum, p) => sum + p.interestedInvestors),
      'totalViews': userProjects.fold<int>(0, (sum, p) => sum + (p.views ?? 0)),
      'totalFunding': userProjects.fold<double>(0, (sum, p) => sum + p.currentFunding),
    };
  }

  // MEJORADO: Limpiar streams en logout de forma más robusta
  Future<void> clearOnLogout() async {
    debugPrint('🧹 ProjectProvider - Limpiando streams en logout...');
    
    // Marcar como limpiando para prevenir nuevas operaciones
    _isClearing = true;
    
    try {
      // Cancelar suscripciones activas con manejo de errores
      if (_myProjectsSubscription != null) {
        await _myProjectsSubscription!.cancel();
        _myProjectsSubscription = null;
      }
      
      if (_allProjectsSubscription != null) {
        await _allProjectsSubscription!.cancel();
        _allProjectsSubscription = null;
      }
      
      // Limpiar datos locales
      _allProjects.clear();
      _myProjects.clear();
      _featuredProjects.clear();
      _error = null;
      _isLoading = false;
      
      debugPrint('✅ ProjectProvider limpiado en logout');
      
      // Notificar cambios antes de resetear el flag
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error limpiando ProjectProvider: $e');
      // No lanzar error para no bloquear el logout
    } finally {
      // Resetear flag de limpieza después de un pequeño delay
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

  // Limpiar recursos
  @override
  void dispose() {
    debugPrint('🧹 ProjectProvider dispose() llamado');
    _isClearing = true;
    _myProjectsSubscription?.cancel();
    _allProjectsSubscription?.cancel();
    super.dispose();
  }
}