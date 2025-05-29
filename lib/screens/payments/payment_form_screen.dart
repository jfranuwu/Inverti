// Archivo: lib/screens/payments/payment_form_screen.dart
// Pantalla de formulario de pago con iconos SVG personalizados

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 🆕 PARA ICONOS SVG
import '../../widgets/custom_button.dart';
import '../../providers/subscription_provider.dart';
import 'subscription_plans_screen.dart';

class PaymentFormScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentFormScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  // 🆕 MÉTODO DE PAGO SELECCIONADO
  String _selectedPaymentMethod = 'stripe';
  
  // Datos de tarjeta (solo para Stripe)
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;
  bool _isProcessing = false;
  bool _saveCard = false;
  
  // Datos de PayPal
  String _paypalEmail = '';
  String _paypalPassword = '';
  
  // Datos de MercadoPago
  String _mercadopagoEmail = '';
  String _mercadopagoPassword = '';
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // 🆕 LISTA DE MÉTODOS DE PAGO CON ICONOS SVG PERSONALIZADOS
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'stripe',
      name: 'Tarjeta de Crédito/Débito',
      subtitle: 'Visa, Mastercard, American Express',
      icon: Icons.credit_card,
      color: Colors.blue,
      logo: '💳', // Mantener emoji para Stripe
      isCustomIcon: false,
    ),
    PaymentMethod(
      id: 'paypal',
      name: 'PayPal',
      subtitle: 'Paga con tu cuenta PayPal',
      icon: Icons.account_balance_wallet,
      color: Colors.indigo,
      logo: 'assets/images/logo/pp.svg', // 🆕 SVG PERSONALIZADO
      isCustomIcon: true,
    ),
    PaymentMethod(
      id: 'mercadopago',
      name: 'MercadoPago',
      subtitle: 'Paga con MercadoPago',
      icon: Icons.payments,
      color: Colors.cyan,
      logo: 'assets/images/logo/mp.svg', // 🆕 SVG PERSONALIZADO
      isCustomIcon: true,
    ),
  ];

  // Procesar pago simulado con método específico
  Future<void> _processPayment() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Preparar datos según el método de pago
      Map<String, dynamic> paymentDetails = {};
      
      switch (_selectedPaymentMethod) {
        case 'stripe':
          paymentDetails = {
            'cardNumber': _cardNumber,
            'expiryDate': _expiryDate,
            'cardHolder': _cardHolderName,
            'method': 'Stripe',
          };
          break;
        case 'paypal':
          paymentDetails = {
            'email': _paypalEmail,
            'method': 'PayPal',
          };
          break;
        case 'mercadopago':
          paymentDetails = {
            'email': _mercadopagoEmail,
            'method': 'MercadoPago',
          };
          break;
      }

      // Usar SubscriptionProvider para procesar pago
      final subscriptionProvider = context.read<SubscriptionProvider>();
      final success = await subscriptionProvider.processPayment(
        plan: widget.plan.id,
        amount: widget.plan.price,
        paymentMethod: _selectedPaymentMethod,
        paymentDetails: paymentDetails,
      );

      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      if (success) {
        // Mostrar éxito con método específico
        _showSuccessDialog();
      } else {
        // Mostrar error
        _showErrorDialog(subscriptionProvider.error ?? 'Error desconocido');
      }
    }
  }

  // Mostrar diálogo de éxito
  void _showSuccessDialog() {
    final methodName = _paymentMethods
        .firstWhere((method) => method.id == _selectedPaymentMethod)
        .name;
        
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('¡Pago exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Plan: ${widget.plan.name}'),
            Text('💰 Monto: \$${widget.plan.price.toStringAsFixed(2)}'),
            Text('💳 Método: $methodName'),
            const SizedBox(height: 12),
            const Text('Recibirás un correo de confirmación en breve.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a planes
              Navigator.of(context).pop(); // Volver a perfil
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de error
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error en el pago'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de suscripción'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Resumen del plan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: widget.plan.color.withOpacity(0.1),
                    child: Column(
                      children: [
                        Text(
                          widget.plan.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${widget.plan.price.toStringAsFixed(2)} ${widget.plan.currency}/${widget.plan.period}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.plan.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 🆕 SELECCIÓN DE MÉTODO DE PAGO
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona método de pago',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de métodos de pago
                        ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
                        
                        const SizedBox(height: 24),
                        
                        // Formulario específico según método seleccionado
                        _buildPaymentForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de pago
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
                text: 'Pagar con ${_getSelectedMethodName()} - \$${widget.plan.price.toStringAsFixed(2)}',
                onPressed: _isProcessing ? null : _processPayment,
                isLoading: _isProcessing,
                color: widget.plan.color,
                icon: Icons.lock,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 WIDGET PARA CADA MÉTODO DE PAGO CON SOPORTE SVG
  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.id;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? method.color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? method.color.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: method.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: method.isCustomIcon 
                    ? SvgPicture.asset(
                        method.logo,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        method.logo,
                        style: const TextStyle(fontSize: 20),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? method.color : null,
                      ),
                    ),
                    Text(
                      method.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method.id,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: method.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 FORMULARIO ESPECÍFICO SEGÚN MÉTODO SELECCIONADO
  Widget _buildPaymentForm() {
    switch (_selectedPaymentMethod) {
      case 'stripe':
        return _buildStripeForm();
      case 'paypal':
        return _buildPayPalForm();
      case 'mercadopago':
        return _buildMercadoPagoForm();
      default:
        return Container();
    }
  }

  // Formulario para Stripe (tarjeta)
  Widget _buildStripeForm() {
    return Column(
      children: [
        // Tarjeta de crédito visual
        CreditCardWidget(
          cardNumber: _cardNumber,
          expiryDate: _expiryDate,
          cardHolderName: _cardHolderName,
          cvvCode: _cvvCode,
          bankName: 'Stripe',
          showBackView: _isCvvFocused,
          obscureCardNumber: true,
          obscureCardCvv: true,
          isHolderNameVisible: true,
          cardBgColor: Colors.blue,
          onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
        ),
        
        // Formulario de tarjeta
        CreditCardForm(
          formKey: formKey,
          obscureCvv: true,
          obscureNumber: true,
          cardNumber: _cardNumber,
          cvvCode: _cvvCode,
          isHolderNameVisible: true,
          isCardNumberVisible: true,
          isExpiryDateVisible: true,
          cardHolderName: _cardHolderName,
          expiryDate: _expiryDate,
          inputConfiguration: const InputConfiguration(
            cardNumberDecoration: InputDecoration(
              labelText: 'Número de tarjeta',
              hintText: 'XXXX XXXX XXXX XXXX',
              prefixIcon: Icon(Icons.credit_card),
            ),
            expiryDateDecoration: InputDecoration(
              labelText: 'Fecha de expiración',
              hintText: 'MM/YY',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            cvvCodeDecoration: InputDecoration(
              labelText: 'CVV',
              hintText: 'XXX',
              prefixIcon: Icon(Icons.lock),
            ),
            cardHolderDecoration: InputDecoration(
              labelText: 'Titular de la tarjeta',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          onCreditCardModelChange: onCreditCardModelChange,
        ),
      ],
    );
  }

  // Formulario para PayPal
  Widget _buildPayPalForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/images/logo/pp.svg',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa tus credenciales de PayPal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email de PayPal',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa tu email';
                    return null;
                  },
                  onChanged: (value) => _paypalEmail = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa tu contraseña';
                    return null;
                  },
                  onChanged: (value) => _paypalPassword = value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formulario para MercadoPago
  Widget _buildMercadoPagoForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/images/logo/mp.svg',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa tus credenciales de MercadoPago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email de MercadoPago',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa tu email';
                    return null;
                  },
                  onChanged: (value) => _mercadopagoEmail = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa tu contraseña';
                    return null;
                  },
                  onChanged: (value) => _mercadopagoPassword = value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtener nombre del método seleccionado
  String _getSelectedMethodName() {
    return _paymentMethods
        .firstWhere((method) => method.id == _selectedPaymentMethod)
        .name;
  }

  void onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      _cardNumber = creditCardModel!.cardNumber;
      _expiryDate = creditCardModel.expiryDate;
      _cardHolderName = creditCardModel.cardHolderName;
      _cvvCode = creditCardModel.cvvCode;
      _isCvvFocused = creditCardModel.isCvvFocused;
    });
  }
}

// 🆕 MODELO PARA MÉTODOS DE PAGO CON SOPORTE PARA SVG
class PaymentMethod {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String logo;
  final bool isCustomIcon; // 🆕 INDICA SI ES SVG PERSONALIZADO

  PaymentMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.logo,
    this.isCustomIcon = false, // Por defecto es emoji/texto
  });
}