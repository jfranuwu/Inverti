// Archivo: lib/screens/maps/office_location_screen.dart
// Pantalla de mapas con Google Maps integrado

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OfficeLocationScreen extends StatefulWidget {
  const OfficeLocationScreen({super.key});

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  late GoogleMapController _mapController;
  
  // Ubicación ficticia de oficinas Inverti en Ciudad de México
  static const LatLng _officeLocation = LatLng(19.4326, -99.1332);
  
  // Marcadores
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('inverti_office'),
      position: _officeLocation,
      infoWindow: const InfoWindow(
        title: 'Oficinas Inverti México',
        snippet: 'Av. Reforma 123, Ciudad de México',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación de oficinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: _openDirections,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa de Google
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: _officeLocation,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          ),
          
          // Tarjeta de información
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arrastre
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Información de la oficina
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Oficinas Inverti México',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sede principal',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Dirección
                        _InfoRow(
                          icon: Icons.location_on,
                          text: 'Av. Reforma 123, Col. Centro\n'
                              'Ciudad de México, CDMX 06000',
                        ),
                        const SizedBox(height: 12),
                        
                        // Horario
                        _InfoRow(
                          icon: Icons.schedule,
                          text: 'Lunes a Viernes: 9:00 - 18:00\n'
                              'Sábados: 9:00 - 14:00',
                        ),
                        const SizedBox(height: 12),
                        
                        // Teléfono
                        _InfoRow(
                          icon: Icons.phone,
                          text: '+52 55 1234 5678',
                        ),
                        const SizedBox(height: 12),
                        
                        // Email
                        _InfoRow(
                          icon: Icons.email,
                          text: 'contacto@inverti.mx',
                        ),
                        const SizedBox(height: 20),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callOffice,
                                icon: const Icon(Icons.phone),
                                label: const Text('Llamar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openDirections,
                                icon: const Icon(Icons.directions),
                                label: const Text('Cómo llegar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Abrir direcciones en Google Maps
  void _openDirections() {
    // Implementar apertura de Google Maps con direcciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abriendo Google Maps...'),
      ),
    );
  }

  // Llamar a la oficina
  void _callOffice() {
    // Implementar llamada telefónica
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando llamada...'),
      ),
    );
  }
}

// Widget auxiliar para filas de información
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}