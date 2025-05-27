// Archivo: lib/screens/project/create_project_screen.dart
// Pantalla para crear nuevo proyecto (solo emprendedores)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/project_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/audio_recorder_widget.dart';
import '../../../services/storage_service.dart';
import '../../../services/audio_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _roiController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedIndustry = Industries.list.first;
  List<String> _projectImages = [];
  String? _quickPitchPath;
  bool _isLoading = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fundingGoalController.dispose();
    _roiController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Agregar imágenes del proyecto
  Future<void> _addProjectImages() async {
    final images = await StorageService.uploadProjectImages(
      'temp_${DateTime.now().millisecondsSinceEpoch}',
      3, // Máximo 3 imágenes
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _projectImages.addAll(images);
      });
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
      
      // Crear proyecto
      final success = await projectProvider.createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        entrepreneurId: authProvider.user!.uid,
        entrepreneurName: authProvider.userModel!.name,
        fundingGoal: double.parse(_fundingGoalController.text),
        industry: _selectedIndustry,
        quickPitchUrl: quickPitchUrl,
        images: _projectImages.isEmpty ? null : _projectImages,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        roi: _roiController.text.isEmpty 
            ? null 
            : double.parse(_roiController.text),
      );
      
      if (!mounted) return;
      
      if (success) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            
            // Industria
            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: const InputDecoration(
                labelText: 'Industria *',
                prefixIcon: Icon(Icons.category),
              ),
              items: Industries.list.map((industry) {
                return DropdownMenuItem(
                  value: industry,
                  child: Text(industry),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIndustry = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción del proyecto *',
                hintText: 'Describe tu proyecto, problema que resuelve, '
                    'modelo de negocio, etc.',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                if (value.trim().length < 50) {
                  return 'La descripción debe tener al menos 50 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Meta de financiamiento
            TextFormField(
              controller: _fundingGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta de financiamiento (USD) *',
                hintText: 'Ej: 50000',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la meta de financiamiento';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                if (amount < 1000) {
                  return 'El monto mínimo es \$1,000 USD';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // ROI esperado
            TextFormField(
              controller: _roiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ROI esperado (%) - Opcional',
                hintText: 'Ej: 15.5',
                prefixIcon: Icon(Icons.trending_up),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final roi = double.tryParse(value);
                  if (roi == null || roi < 0) {
                    return 'Ingresa un porcentaje válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Ubicación
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ubicación - Opcional',
                hintText: 'Ej: Ciudad de México',
                prefixIcon: Icon(Icons.location_on),
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