// Archivo: lib/screens/project/edit_project_screen.dart
// Pantalla para editar proyectos existentes - CON QUICK PITCH COMPLETO

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/audio_recorder_widget.dart';
import '../../widgets/audio_player_widget.dart';
import '../../services/storage_service.dart';

class EditProjectScreen extends StatefulWidget {
  final ProjectModel project;

  const EditProjectScreen({
    super.key,
    required this.project,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _fullDescriptionController;
  late final TextEditingController _fundingGoalController;
  late final TextEditingController _equityController;
  late final TextEditingController _websiteController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;

  // Estado
  String _selectedCategory = '';
  String? _selectedImageUrl;
  List<String> _selectedImages = [];
  String? _currentQuickPitchUrl;
  String? _newQuickPitchPath;
  bool _isLoading = false;
  bool _showRecorder = false;

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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final project = widget.project;
    
    _titleController = TextEditingController(text: project.title);
    _descriptionController = TextEditingController(text: project.description);
    _fullDescriptionController = TextEditingController(text: project.fullDescription);
    _fundingGoalController = TextEditingController(text: project.fundingGoal.toString());
    _equityController = TextEditingController(text: project.equityOffered.toString());
    _websiteController = TextEditingController(text: project.website);
    _linkedinController = TextEditingController(text: project.linkedin);
    _contactEmailController = TextEditingController(text: project.contactEmail);
    _contactPhoneController = TextEditingController(text: project.contactPhone);
    
    _selectedCategory = project.category;
    _selectedImageUrl = project.imageUrl;
    _selectedImages = List.from(project.images);
    
    // Inicializar Quick Pitch
    _currentQuickPitchUrl = project.metadata['quickPitchUrl'] as String?;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fullDescriptionController.dispose();
    _fundingGoalController.dispose();
    _equityController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Proyecto'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveProject,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 16),
              
              // Título del proyecto
              CustomTextField(
                controller: _titleController,
                label: 'Título del proyecto',
                hintText: 'Ingresa el título de tu proyecto',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
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
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción corta
              CustomTextField(
                controller: _descriptionController,
                label: 'Descripción corta',
                hintText: 'Describe tu proyecto en pocas palabras',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  if (value.trim().length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción completa
              TextAreaField(
                controller: _fullDescriptionController,
                label: 'Descripción completa',
                hintText: 'Describe detalladamente tu proyecto, problema que resuelve, solución, mercado objetivo, etc.',
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción completa es obligatoria';
                  }
                  if (value.trim().length < 100) {
                    return 'La descripción debe tener al menos 100 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Información financiera
              _buildSectionTitle('Información Financiera'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: NumberTextField(
                      controller: _fundingGoalController,
                      label: 'Meta de financiamiento',
                      hintText: '50000',
                      prefixText: '\$ ',
                      min: 1000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La meta es obligatoria';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Ingresa un monto válido';
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
                    child: NumberTextField(
                      controller: _equityController,
                      label: 'Equity ofrecido',
                      hintText: '10',
                      suffixText: '%',
                      min: 0,
                      max: 100,
                      decimals: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El equity es obligatorio';
                        }
                        final equity = double.tryParse(value);
                        if (equity == null || equity <= 0 || equity > 100) {
                          return 'Ingresa un porcentaje válido (1-100)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Imágenes
              _buildSectionTitle('Imágenes del Proyecto'),
              const SizedBox(height: 16),
              
              ImagePickerWidget(
                initialImageUrl: _selectedImageUrl,
                initialImages: _selectedImages,
                onMainImageSelected: (imageUrl) {
                  setState(() {
                    _selectedImageUrl = imageUrl;
                  });
                },
                onImagesSelected: (images) {
                  setState(() {
                    _selectedImages = images;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // SECCIÓN DE QUICK PITCH CON REPRODUCTOR Y GRABADOR
              _buildSectionTitle('Quick Pitch (60 segundos)'),
              const SizedBox(height: 8),
              Text(
                'Graba un pitch de 60 segundos para que los inversores conozcan tu proyecto de forma más personal',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Pitch actual o grabador
              _buildQuickPitchSection(),
              const SizedBox(height: 24),
              
              // Enlaces y contacto
              _buildSectionTitle('Enlaces y Contacto'),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _websiteController,
                label: 'Sitio web (opcional)',
                hintText: 'https://tuempresa.com',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.language),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _linkedinController,
                label: 'LinkedIn (opcional)',
                hintText: 'https://linkedin.com/in/tuperfil',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.business),
              ),
              const SizedBox(height: 16),
              
              EmailTextField(
                controller: _contactEmailController,
                label: 'Email de contacto',
                hintText: 'contacto@tuempresa.com',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El email es obligatorio';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              PhoneTextField(
                controller: _contactPhoneController,
                label: 'Teléfono de contacto',
                hintText: '+52 123 456 7890',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Guardando cambios...' : 'Guardar cambios',
                  onPressed: _isLoading ? null : _saveProject,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildQuickPitchSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      color: isDarkMode ? Colors.grey[800] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Si hay Quick Pitch actual y no estamos grabando nuevo
            if (_currentQuickPitchUrl != null && !_showRecorder) ...[
              AudioPlayerWidget(
                audioUrl: _currentQuickPitchUrl!,
                title: 'Quick Pitch actual',
              ),
              const SizedBox(height: 16),
              
              // Botones para reemplazar o eliminar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showRecorder = true;
                        });
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('Grabar nuevo'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteCurrentQuickPitch,
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Si no hay Quick Pitch o estamos grabando nuevo
            if (_currentQuickPitchUrl == null || _showRecorder) ...[
              // Mostrar botón cancelar si estamos reemplazando
              if (_showRecorder && _currentQuickPitchUrl != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grabando nuevo Quick Pitch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showRecorder = false;
                          _newQuickPitchPath = null;
                        });
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Widget de grabación
              AudioRecorderWidget(
                maxDuration: const Duration(seconds: 60),
                onRecordingComplete: (path) {
                  setState(() {
                    _newQuickPitchPath = path;
                  });
                },
                onRecordingDeleted: () {
                  setState(() {
                    _newQuickPitchPath = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deleteCurrentQuickPitch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Quick Pitch?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentQuickPitchUrl = null;
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Quick Pitch eliminado');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImageUrl == null) {
      _showErrorSnackBar('Por favor selecciona una imagen principal');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar metadata
      Map<String, dynamic> metadata = Map.from(widget.project.metadata);
      
      // Manejar Quick Pitch
      if (_newQuickPitchPath != null) {
        // Subir nuevo Quick Pitch
        final quickPitchUrl = await StorageService.uploadQuickPitchAudio(
          'project_${widget.project.id}_${DateTime.now().millisecondsSinceEpoch}',
          _newQuickPitchPath!,
        );
        
        if (quickPitchUrl != null) {
          metadata['quickPitchUrl'] = quickPitchUrl;
        }
      } else if (_currentQuickPitchUrl == null) {
        // Eliminar Quick Pitch si se eliminó
        metadata.remove('quickPitchUrl');
      } else {
        // Mantener Quick Pitch actual
        metadata['quickPitchUrl'] = _currentQuickPitchUrl;
      }

      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fullDescription': _fullDescriptionController.text.trim(),
        'category': _selectedCategory,
        'fundingGoal': double.parse(_fundingGoalController.text),
        'equityOffered': double.parse(_equityController.text),
        'imageUrl': _selectedImageUrl,
        'images': _selectedImages,
        'website': _websiteController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'metadata': metadata,
      };

      final success = await context
          .read<ProjectProvider>()
          .updateProject(widget.project.id, updates);

      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackBar('Proyecto actualizado exitosamente');
        }
      } else {
        _showErrorSnackBar('Error al actualizar el proyecto');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}