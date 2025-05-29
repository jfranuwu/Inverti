// Archivo: lib/widgets/subscription_status_widget.dart
// Widget para mostrar estado de suscripción y botón de upgrade

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/payments/subscription_plans_screen.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  final bool showUpgradeButton;
  final EdgeInsetsGeometry? padding;

  const SubscriptionStatusWidget({
    super.key,
    this.showUpgradeButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SubscriptionProvider>(
      builder: (context, authProvider, subscriptionProvider, child) {
        final user = authProvider.userModel;
        if (user == null) return const SizedBox.shrink();

        final plan = user.subscriptionPlan;
        final benefits = subscriptionProvider.getPlanBenefits(plan);

        return Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con plan actual
                  Row(
                    children: [
                      _buildPlanIcon(plan),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPlanName(plan),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getPlanDescription(plan),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (plan != 'premium' && showUpgradeButton)
                        _buildUpgradeButton(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Beneficios actuales
                  _buildBenefitsList(benefits),
                  
                  // Botón de gestionar suscripción (solo para planes pagados)
                  if (plan != 'basic' && showUpgradeButton) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToSubscriptions(context),
                        icon: const Icon(Icons.settings),
                        label: const Text('Gestionar suscripción'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanIcon(String plan) {
    Color color;
    IconData icon;
    
    switch (plan) {
      case 'basic':
        color = Colors.grey;
        icon = Icons.person;
        break;
      case 'pro':
        color = Colors.blue;
        icon = Icons.star;
        break;
      case 'premium':
        color = Colors.purple;
        icon = Icons.diamond;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateToSubscriptions(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Upgrade'),
    );
  }

  Widget _buildBenefitsList(Map<String, dynamic> benefits) {
    final List<Widget> benefitWidgets = [];

    // Proyectos
    final maxProjects = benefits['maxProjects'];
    benefitWidgets.add(_buildBenefitItem(
      Icons.work,
      maxProjects == -1 
          ? 'Proyectos ilimitados'
          : 'Hasta $maxProjects proyectos',
      true,
    ));

    // Contactos
    final maxContacts = benefits['maxContacts'];
    benefitWidgets.add(_buildBenefitItem(
      Icons.contacts,
      maxContacts == -1 
          ? 'Contactos ilimitados'
          : 'Hasta $maxContacts contactos/mes',
      true,
    ));

    // Analytics
    benefitWidgets.add(_buildBenefitItem(
      Icons.analytics,
      'Analytics avanzados',
      benefits['analytics'] == true,
    ));

    // Soporte prioritario
    benefitWidgets.add(_buildBenefitItem(
      Icons.support_agent,
      'Soporte prioritario',
      benefits['priority'] == true,
    ));

    // Verificación
    if (benefits['verified'] == true) {
      benefitWidgets.add(_buildBenefitItem(
        Icons.verified,
        'Perfil verificado',
        true,
      ));
    }

    return Column(children: benefitWidgets);
  }

  Widget _buildBenefitItem(IconData icon, String text, bool included) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            color: included ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: included ? Colors.black : Colors.grey,
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanName(String plan) {
    switch (plan) {
      case 'basic':
        return 'Plan Básico';
      case 'pro':
        return 'Plan Pro';
      case 'premium':
        return 'Plan Premium';
      default:
        return 'Plan Desconocido';
    }
  }

  String _getPlanDescription(String plan) {
    switch (plan) {
      case 'basic':
        return 'Funcionalidades limitadas';
      case 'pro':
        return '\$29.99/mes • Funcionalidades avanzadas';
      case 'premium':
        return '\$99.99/mes • Acceso completo';
      default:
        return '';
    }
  }

  void _navigateToSubscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPlansScreen(),
      ),
    );
  }
}