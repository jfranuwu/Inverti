// Archivo: lib/screens/payments/payment_form_screen.dart
// Pantalla de formulario de pago (simulación) - CORREGIDA

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import '../../widgets/custom_button.dart';
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
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;
  bool _isProcessing = false;
  bool _saveCard = false;
  bool _useGlassMorphism = false;
  bool _useBackgroundImage = false;
  OutlineInputBorder? border;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    border = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.grey.withOpacity(0.7),
        width: 2.0,
      ),
    );
    super.initState();
  }

  // Procesar pago simulado
  Future<void> _processPayment() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Simular procesamiento de pago
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Mostrar éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('¡Pago exitoso!'),
            ],
          ),
          content: Text(
            'Te has suscrito al plan ${widget.plan.name}.\n'
            'Recibirás un correo de confirmación en breve.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      print('invalid!');
    }
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
                  
                  // Tarjeta de crédito visual
                  CreditCardWidget(
                    glassmorphismConfig: _useGlassMorphism
                        ? Glassmorphism.defaultConfig()
                        : null,
                    cardNumber: _cardNumber,
                    expiryDate: _expiryDate,
                    cardHolderName: _cardHolderName,
                    cvvCode: _cvvCode,
                    bankName: 'Inverti Bank',
                    frontCardBorder: Border.all(color: Colors.grey),
                    backCardBorder: Border.all(color: Colors.grey),
                    showBackView: _isCvvFocused,
                    obscureCardNumber: true,
                    obscureCardCvv: true,
                    isHolderNameVisible: true,
                    cardBgColor: widget.plan.color,
                    backgroundImage: _useBackgroundImage ? 'assets/card_bg.png' : null,
                    isSwipeGestureEnabled: true,
                    onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
                    customCardTypeIcons: <CustomCardTypeIcon>[
                      CustomCardTypeIcon(
                        cardType: CardType.mastercard,
                        cardImage: Image.asset(
                          'assets/mastercard.png',
                          height: 48,
                          width: 48,
                        ),
                      ),
                    ],
                  ),
                  
                  // Formulario de tarjeta
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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
                        const SizedBox(height: 16),
                        
                        // Guardar tarjeta
                        CheckboxListTile(
                          title: const Text('Guardar tarjeta para futuros pagos'),
                          value: _saveCard,
                          onChanged: (value) {
                            setState(() {
                              _saveCard = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 16),
                        
                        // Información de seguridad
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.security,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pago seguro',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      'Tu información está protegida con encriptación SSL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de pago - CORREGIDO
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
                text: 'Pagar \$${widget.plan.price.toStringAsFixed(2)}',
                onPressed: _isProcessing ? null : _processPayment,
                isLoading: _isProcessing,
                color: widget.plan.color, // ✅ Cambiado de backgroundColor a color
                icon: Icons.lock,
              ),
            ),
          ),
        ],
      ),
    );
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