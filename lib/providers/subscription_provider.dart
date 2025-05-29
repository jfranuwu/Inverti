// Archivo: lib/providers/subscription_provider.dart
// Provider para gestión de suscripciones y pagos - VERSIÓN FINAL ESTABLE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Estado del provider
  bool _isLoading = false;
  String? _error;
  
  // Datos de suscripción
  String _currentPlan = 'basic';
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  bool _isSubscriptionActive = true;
  List<PaymentHistory> _paymentHistory = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentPlan => _currentPlan;
  DateTime? get subscriptionStartDate => _subscriptionStartDate;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  bool get isSubscriptionActive => _isSubscriptionActive;
  List<PaymentHistory> get paymentHistory => _paymentHistory;
  
  // Constructor SEGURO
  SubscriptionProvider() {
    print('🚀 SubscriptionProvider inicializado');
    // NO hacer nada automático para evitar errores de setState
  }
  
  // Método para cargar datos manualmente (sin efectos secundarios)
  Future<void> loadUserSubscriptionManually() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ No hay usuario autenticado');
      return;
    }
    
    try {
      print('🔄 Cargando suscripción para: ${user.uid}');
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _currentPlan = data['subscriptionPlan'] ?? 'basic';
        
        if (data['subscriptionStartDate'] != null) {
          _subscriptionStartDate = (data['subscriptionStartDate'] as Timestamp).toDate();
        }
        if (data['subscriptionEndDate'] != null) {
          _subscriptionEndDate = (data['subscriptionEndDate'] as Timestamp).toDate();
        }
        
        _isSubscriptionActive = _checkSubscriptionStatus();
        print('📊 Plan cargado: $_currentPlan');
        
        // Cargar historial de pagos
        await _loadPaymentHistory(user.uid);
      }
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando suscripción: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Verificar estado de suscripción
  bool _checkSubscriptionStatus() {
    if (_currentPlan == 'basic') return true;
    if (_subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(_subscriptionEndDate!);
  }
  
  // Cargar historial de pagos
  Future<void> _loadPaymentHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      _paymentHistory = querySnapshot.docs
          .map((doc) => PaymentHistory.fromFirestore(doc))
          .toList();
          
      print('✅ Historial de pagos cargado: ${_paymentHistory.length} registros');
    } catch (e) {
      print('⚠️ Error cargando historial: $e');
    }
  }
  
  // Simular procesamiento de pago
  Future<bool> processPayment({
    required String plan,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      print('🔄 Procesando pago: $plan, \$${amount.toStringAsFixed(2)}, $paymentMethod');
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Simular procesamiento (3 segundos)
      await Future.delayed(const Duration(seconds: 3));
      
      // Simular éxito (100% para pruebas)
      print('✅ Pago simulado exitoso');
      
      // Actualizar suscripción
      final success = await _updateUserSubscription(
        userId: user.uid,
        newPlan: plan,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
      );
      
      _isLoading = false;
      notifyListeners();
      return success;
      
    } catch (e) {
      print('❌ Error en pago: $e');
      _error = 'Error al procesar el pago: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Actualizar suscripción del usuario
  Future<bool> _updateUserSubscription({
    required String userId,
    required String newPlan,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      print('📝 Actualizando suscripción a: $newPlan');
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, now.day);
      
      // Actualizar usuario en Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscriptionPlan': newPlan,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': Timestamp.fromDate(now),
      });
      
      print('✅ Usuario actualizado en Firestore');
      
      // Crear registro de pago
      final paymentData = {
        'userId': userId,
        'amount': amount,
        'currency': 'USD',
        'plan': newPlan,
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'transactionId': 'tx_${now.millisecondsSinceEpoch}',
        'createdAt': Timestamp.fromDate(now),
        'paymentDetails': paymentDetails,
      };
      
      await _firestore.collection('payments').add(paymentData);
      print('✅ Registro de pago creado');
      
      // Actualizar estado local
      _currentPlan = newPlan;
      _subscriptionStartDate = now;
      _subscriptionEndDate = endDate;
      _isSubscriptionActive = true;
      
      // Recargar historial
      await _loadPaymentHistory(userId);
      
      return true;
      
    } catch (e) {
      print('❌ Error actualizando suscripción: $e');
      return false;
    }
  }
  
  // Obtener información del plan por rol
  Map<String, dynamic> getPlanInfo(String planId, [String? userType]) {
    userType = userType ?? 'investor';
    
    if (userType == 'investor') {
      switch (planId) {
        case 'pro':
          return {
            'name': 'Inversor Pro',
            'price': 29.99,
            'features': [
              'Proyectos ilimitados',
              'Verificación de perfil',
              '20 contactos por mes',
              'Análisis de inversiones',
              'Soporte prioritario',
            ],
            'color': Colors.blue,
          };
        case 'premium':
          return {
            'name': 'Inversor Premium',
            'price': 99.99,
            'features': [
              'Todo de Pro +',
              'Contactos ilimitados',
              'Analytics avanzados de ROI',
              'Asesoría personalizada',
              'Acceso VIP a eventos',
            ],
            'color': Colors.purple,
          };
        default:
          return {
            'name': 'Inversor Básico',
            'price': 0.0,
            'features': [
              'Ver 10 proyectos por mes',
              'Perfil básico',
              '3 contactos por mes',
            ],
            'color': Colors.grey,
          };
      }
    } else {
      switch (planId) {
        case 'pro':
          return {
            'name': 'Emprendedor Pro',
            'price': 39.99,
            'features': [
              'Proyectos ilimitados',
              'Verificación de perfil',
              'Solicitudes ilimitadas',
              'Analytics de proyecto',
              'Soporte prioritario',
            ],
            'color': Colors.blue,
          };
        case 'premium':
          return {
            'name': 'Emprendedor Premium',
            'price': 149.99,
            'features': [
              'Todo de Pro +',
              'Mentoring personalizado',
              'Pitch deck profesional',
              'Conexiones directas VIP',
              'Eventos exclusivos',
            ],
            'color': Colors.purple,
          };
        default:
          return {
            'name': 'Emprendedor Básico',
            'price': 0.0,
            'features': [
              'Publicar 3 proyectos por mes',
              'Perfil básico',
              '5 solicitudes de fondos',
            ],
            'color': Colors.grey,
          };
      }
    }
  }
  
  // Obtener beneficios del plan
  Map<String, dynamic> getPlanBenefits(String planId) {
    switch (planId) {
      case 'basic':
        return {
          'maxProjects': 10,
          'maxContacts': 3,
          'analytics': false,
          'priority': false,
          'verified': false,
          'unlimited': false,
        };
      case 'pro':
        return {
          'maxProjects': -1,
          'maxContacts': 20,
          'analytics': true,
          'priority': true,
          'verified': true,
          'unlimited': false,
        };
      case 'premium':
        return {
          'maxProjects': -1,
          'maxContacts': -1,
          'analytics': true,
          'priority': true,
          'verified': true,
          'unlimited': true,
        };
      default:
        return {
          'maxProjects': 10,
          'maxContacts': 3,
          'analytics': false,
          'priority': false,
          'verified': false,
          'unlimited': false,
        };
    }
  }
  
  // Verificar acceso a funciones
  bool canAccessFeature(String feature) {
    switch (feature) {
      case 'unlimited_projects':
        return _currentPlan == 'pro' || _currentPlan == 'premium';
      case 'unlimited_contacts':
        return _currentPlan == 'premium';
      case 'advanced_analytics':
        return _currentPlan == 'premium';
      case 'priority_support':
        return _currentPlan == 'pro' || _currentPlan == 'premium';
      default:
        return true;
    }
  }
  
  // Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Modelo para historial de pagos
class PaymentHistory {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String plan;
  final String paymentMethod;
  final String status;
  final String transactionId;
  final DateTime createdAt;
  final Map<String, dynamic>? paymentDetails;
  
  PaymentHistory({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.plan,
    required this.paymentMethod,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    this.paymentDetails,
  });
  
  factory PaymentHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentHistory(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      plan: data['plan'] ?? 'basic',
      paymentMethod: data['paymentMethod'] ?? 'card',
      status: data['status'] ?? 'pending',
      transactionId: data['transactionId'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      paymentDetails: data['paymentDetails'],
    );
  }
}