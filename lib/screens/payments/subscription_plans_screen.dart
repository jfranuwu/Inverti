// Archivo: lib/screens/payments/subscription_plans_screen.dart
// Pantalla de planes de suscripción (3 planes obligatorios)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import 'payment_form_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String? _selectedPlan;

  // Planes de suscripción
  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Inversor Básico',
      price: 0,
      currency: 'USD',
      period: 'mes',
      color: Colors.grey,
      features: [
        'Ver 10 proyectos por mes',
        'Perfil básico',
        '3 contactos por mes',
        'Soporte por email',
      ],
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Inversor Pro',
      price: 29.99,
      currency: 'USD',
      period: 'mes',
      color: Colors.blue,
      features: [
        'Proyectos ilimitados',
        'Verificación de perfil',
        '20 contactos por mes',
        'Análisis básicos',
        'Soporte prioritario',
        'Acceso a Quick Pitch',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Inversor Premium',
      price: 99.99,
      currency: 'USD',
      period: 'mes',
      color: Colors.purple,
      features: [
        'Todo de Pro +',
        'Contactos ilimitados',
        'Analytics avanzados',
        'Asesoría personalizada',
        'Acceso VIP a eventos',
        'Badge exclusivo',
        'API access',
      ],
      isPopular: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Seleccionar plan actual del usuario
    final currentPlan = context.read<AuthProvider>().userModel?.subscriptionPlan ?? 'basic';
    _selectedPlan = currentPlan;
  }

  // Proceder al pago
  void _proceedToPayment() {
    if (_selectedPlan == null) return;
    
    final selectedPlanData = _plans.firstWhere((plan) => plan.id == _selectedPlan);
    
    if (selectedPlanData.price == 0) {
      // Plan gratuito - no requiere pago
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes el plan básico'),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormScreen(
          plan: selectedPlanData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<AuthProvider>().userModel?.userType ?? 'investor';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes de suscripción'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Elige el plan perfecto para ti',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  userType == 'investor'
                      ? 'Desbloquea todas las funciones para encontrar las mejores inversiones'
                      : 'Potencia tu proyecto y conecta con más inversores',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Lista de planes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PlanCard(
                    plan: plan,
                    isSelected: _selectedPlan == plan.id,
                    onSelect: () {
                      setState(() {
                        _selectedPlan = plan.id;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Botón de continuar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                text: _selectedPlan == 'basic' 
                    ? 'Plan actual' 
                    : 'Continuar al pago',
                onPressed: _selectedPlan == 'basic' ? null : _proceedToPayment,
                icon: Icons.arrow_forward,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para tarjeta de plan
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? plan.color.withOpacity(0.1) 
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plan.color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del plan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.price == 0 ? 'Gratis' : '\$${plan.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: plan.color,
                          ),
                        ),
                        if (plan.price > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '/${plan.period}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                // Badge popular
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Más popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Radio button
                Radio<String>(
                  value: plan.id,
                  groupValue: isSelected ? plan.id : null,
                  onChanged: (_) => onSelect(),
                  activeColor: plan.color,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Lista de características
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: plan.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// Modelo de plan de suscripción
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String period;
  final Color color;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.period,
    required this.color,
    required this.features,
    required this.isPopular,
  });
}