// Archivo: lib/screens/auth/email_verification_screen.dart
// Pantalla para verificación de email

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Verificar automáticamente cada 3 segundos si el email fue verificado
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Verificar si el email ya fue verificado
  Future<void> _checkEmailVerified() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    
    // Si el email está verificado, navegar automáticamente
    if (authProvider.user?.emailVerified == true) {
      if (mounted) {
        _timer?.cancel();
        Navigator.of(context).pop(); // Volver al AuthWrapper que manejará la navegación
      }
    }
  }

  // Verificar manualmente
  Future<void> _checkManually() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (authProvider.user?.emailVerified == true) {
      _timer?.cancel();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email aún no verificado. Por favor, revisa tu correo.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Reenviar email de verificación
  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationEmail();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Iniciar countdown para reenvío
      setState(() {
        _canResendEmail = false;
        _resendCountdown = 60;
      });

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown > 0) {
          setState(() {
            _resendCountdown--;
          });
        } else {
          setState(() {
            _canResendEmail = true;
          });
          timer.cancel();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de verificación reenviado'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Error al reenviar email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Cerrar sesión
  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icono
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 50,
                    color: Colors.blue[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Título
              Text(
                'Verifica tu email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Descripción
              Text(
                'Hemos enviado un enlace de verificación a:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Email
              Text(
                userEmail,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para continuar:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Revisa tu bandeja de entrada (y spam)'),
                    const Text('2. Haz clic en el enlace de verificación'),
                    const Text('3. Regresa a la app'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botón verificar manualmente
              CustomButton(
                text: 'Ya verifiqué mi email',
                onPressed: _isLoading ? null : _checkManually,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              
              // Botón reenviar
              OutlinedButton(
                onPressed: _canResendEmail && !_isLoading ? _resendVerificationEmail : null,
                child: Text(
                  _canResendEmail 
                    ? 'Reenviar email de verificación'
                    : 'Reenviar en ${_resendCountdown}s',
                ),
              ),
              const SizedBox(height: 16),
              
              // Ayuda
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '¿No recibiste el email?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Revisa tu carpeta de spam\n'
                      '• Verifica que el email sea correcto\n'
                      '• Contacta soporte si persiste el problema',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Estado de verificación automática
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Verificando automáticamente...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}