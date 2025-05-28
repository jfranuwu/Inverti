// Archivo: lib/screens/project/create_project_screen.dart
// Pantalla para crear nuevo proyecto (solo emprendedores) - CORREGIDA

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/audio_recorder_widget.dart';
import '../../services/storage_service.dart';
import '../../services/audio_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fullDescriptionController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _equityController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // Categorías disponibles
  final List<String> _categories = [
    'Tecnología',
    'Salud',
    'Educación',
    'Finanzas',
    'E-commerce',
    'Sostenibilidad',
    'Entretenimiento',
    'Alimentación',
    'Transporte',
    'Inmobiliario',
  ];
  
  String _selectedCategory = 'Tecnología';
  List<String> _projectImages = [];
  String? _quickPitchPath;
  bool _isLoading = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // Prellenar email del usuario actual
    final authProvider = context.read<AuthProvider>();
    _contactEmailController.text = authProvider.userModel?.email ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fullDescriptionController.dispose();
    _fundingGoalController.dispose();
    _equityController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  // Agregar imágenes del proyecto
  Future<void> _addProjectImages() async {
    try {
      final images = await StorageService.uploadProjectImages(
        'temp_${DateTime.now().millisecondsSinceEpoch}',
        3, // Máximo 3 imágenes
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _projectImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Crear proyecto
  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    try {
      // Subir audio si existe
      String? quickPitchUrl;
      if (_quickPitchPath != null) {
        quickPitchUrl = await StorageService.uploadQuickPitchAudio(
          'project_${DateTime.now().millisecondsSinceEpoch}',
          _quickPitchPath!,
        );
      }
      
      // Preparar metadata que incluye información del emprendedor
      Map<String, dynamic> metadata = {};
      if (quickPitchUrl != null) {
        metadata['quickPitchUrl'] = quickPitchUrl;
      }
      // Agregar nombre del emprendedor al metadata si está disponible
      if (authProvider.userModel?.name != null) {
        metadata['entrepreneurName'] = authProvider.userModel!.name;
      }
      
      // Crear el ProjectModel
      final project = ProjectModel(
        id: '', // Se asignará automáticamente
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fullDescription: _fullDescriptionController.text.trim().isEmpty 
            ? _descriptionController.text.trim() 
            : _fullDescriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: _projectImages.isNotEmpty ? _projectImages.first : '',
        images: _projectImages,
        fundingGoal: double.parse(_fundingGoalController.text),
        currentFunding: 0.0,
        fundingPercentage: 0.0,
        equityOffered: _equityController.text.isEmpty 
            ? 0.0 
            : double.parse(_equityController.text),
        status: 'active',
        createdBy: authProvider.user!.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        website: _websiteController.text.trim(),
        linkedin: _linkedinController.text.trim(),
        isFeatured: false,
        isActive: true,
        interestedInvestors: 0,
        views: 0,
        metadata: metadata,
      );
      
      // Crear proyecto usando el ProjectProvider actualizado
      final projectId = await projectProvider.createProject(project);
      
      if (!mounted) return;
      
      if (projectId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Proyecto creado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.error ?? 'Error al crear proyecto'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear proyecto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título del proyecto
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Título del proyecto *',
                hintText: 'Ej: App de delivery sostenible',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                if (value.trim().length < 5) {
                  return 'El título debe tener al menos 5 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción corta
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción corta *',
                hintText: 'Resumen ejecutivo de tu proyecto',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                if (value.trim().length < 20) {
                  return 'La descripción debe tener al menos 20 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción completa
            TextFormField(
              controller: _fullDescriptionController,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción completa (opcional)',
                hintText: 'Describe detalladamente tu proyecto, problema que resuelve, modelo de negocio, etc.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Meta de financiamiento y equity
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fundingGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Meta (USD) *',
                      hintText: '50000',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Monto inválido';
                      }
                      if (amount < 1000) {
                        return 'Mínimo \$1,000';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _equityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Equity (%)',
                      hintText: '10',
                      prefixIcon: Icon(Icons.percent),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final equity = double.tryParse(value);
                        if (equity == null || equity < 0 || equity > 100) {
                          return 'Entre 0-100%';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Información de contacto
            Text(
              'Información de contacto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email de contacto *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email requerido';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono de contacto *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Teléfono requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Sitio web (opcional)',
                hintText: 'https://miempresa.com',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _linkedinController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'LinkedIn (opcional)',
                hintText: 'https://linkedin.com/in/miperfil',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sección de imágenes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Imágenes del proyecto',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: _projectImages.length >= 3 
                              ? null 
                              : _addProjectImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const Text(
                      'Máximo 3 imágenes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_projectImages.isEmpty)
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sin imágenes',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _projectImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _projectImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _projectImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sección de Quick Pitch
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Pitch (60 segundos)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Graba un pitch de 60 segundos para que los inversores '
                      'conozcan tu proyecto de forma más personal',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    AudioRecorderWidget(
                      maxDuration: const Duration(seconds: 60),
                      onRecordingComplete: (path) {
                        setState(() {
                          _quickPitchPath = path;
                        });
                      },
                      onRecordingDeleted: () {
                        setState(() {
                          _quickPitchPath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Botón crear proyecto
            CustomButton(
              text: 'Crear proyecto',
              onPressed: _isLoading ? null : _createProject,
              isLoading: _isLoading,
              icon: Icons.rocket_launch,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}