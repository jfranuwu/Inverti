// Archivo: lib/providers/project_provider.dart
// Provider para gestión de proyectos

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../config/firebase_config.dart';

class ProjectProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ProjectModel> _projects = [];
  List<ProjectModel> _myProjects = [];
  List<ProjectModel> _interestedProjects = [];
  bool _isLoading = false;
  String? _error;
  String _selectedIndustry = 'Todas';
  
  // Getters
  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get myProjects => _myProjects;
  List<ProjectModel> get interestedProjects => _interestedProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedIndustry => _selectedIndustry;
  
  // Obtener proyectos filtrados por industria
  List<ProjectModel> get filteredProjects {
    if (_selectedIndustry == 'Todas') {
      return _projects;
    }
    return _projects
        .where((project) => project.industry == _selectedIndustry)
        .toList();
  }
  
  // Cargar todos los proyectos activos
  Future<void> loadProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final querySnapshot = await _firestore
          .collection(FirebaseConfig.projectsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(50) // Limitar para optimizar uso gratuito
          .get();
      
      _projects = querySnapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar proyectos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Cargar proyectos del emprendedor actual
  Future<void> loadMyProjects(String entrepreneurId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final querySnapshot = await _firestore
          .collection(FirebaseConfig.projectsCollection)
          .where('entrepreneurId', isEqualTo: entrepreneurId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _myProjects = querySnapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar tus proyectos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Crear nuevo proyecto
  Future<bool> createProject({
    required String title,
    required String description,
    required String entrepreneurId,
    required String entrepreneurName,
    required double fundingGoal,
    required String industry,
    String? quickPitchUrl,
    List<String>? images,
    String? location,
    double? roi,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final project = ProjectModel(
        id: '', // Se generará automáticamente
        title: title,
        description: description,
        entrepreneurId: entrepreneurId,
        entrepreneurName: entrepreneurName,
        fundingGoal: fundingGoal,
        industry: industry,
        createdAt: DateTime.now(),
        quickPitchUrl: quickPitchUrl,
        images: images,
        location: location,
        roi: roi,
      );
      
      // Agregar a Firestore
      final docRef = await _firestore
          .collection(FirebaseConfig.projectsCollection)
          .add(project.toFirestore());
      
      // Actualizar lista local
      final newProject = project.copyWith(id: docRef.id);
      _projects.insert(0, newProject);
      _myProjects.insert(0, newProject);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear proyecto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Actualizar proyecto
  Future<bool> updateProject(ProjectModel project) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Actualizar con timestamp
      final updatedProject = project.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(FirebaseConfig.projectsCollection)
          .doc(project.id)
          .update(updatedProject.toFirestore());
      
      // Actualizar listas locales
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = updatedProject;
      }
      
      final myIndex = _myProjects.indexWhere((p) => p.id == project.id);
      if (myIndex != -1) {
        _myProjects[myIndex] = updatedProject;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar proyecto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Expresar interés en un proyecto (para inversores)
  Future<bool> expressInterest(String projectId, String investorId) async {
    try {
      // Crear documento de interés
      await _firestore.collection(FirebaseConfig.interestsCollection).add({
        'projectId': projectId,
        'investorId': investorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Incrementar contador en el proyecto
      await _firestore
          .collection(FirebaseConfig.projectsCollection)
          .doc(projectId)
          .update({
        'interestedInvestors': FieldValue.increment(1),
      });
      
      // Actualizar proyecto local
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = _projects[index].copyWith(
          interestedInvestors: _projects[index].interestedInvestors + 1,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Error al expresar interés: $e';
      return false;
    }
  }
  
  // Cambiar filtro de industria
  void setIndustryFilter(String industry) {
    _selectedIndustry = industry;
    notifyListeners();
  }
  
  // Buscar proyectos
  List<ProjectModel> searchProjects(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _projects.where((project) {
      return project.title.toLowerCase().contains(lowercaseQuery) ||
          project.description.toLowerCase().contains(lowercaseQuery) ||
          project.industry.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}