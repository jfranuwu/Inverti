// Archivo: lib/screens/investor/interested_investors_screen.dart
// Pantalla para ver inversores interesados en un proyecto

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../config/firebase_config.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/user_rating_stars.dart';
import '../profile/public_profile_screen.dart';

class InterestedInvestorsScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const InterestedInvestorsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<InterestedInvestorsScreen> createState() => _InterestedInvestorsScreenState();
}

class _InterestedInvestorsScreenState extends State<InterestedInvestorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _investors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterestedInvestors();
  }

  Future<void> _loadInterestedInvestors() async {
    try {
      // Obtener todos los intereses para este proyecto
      final interestsSnapshot = await _firestore
          .collection(FirebaseConfig.interestsCollection)
          .where('projectId', isEqualTo: widget.projectId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${interestsSnapshot.docs.length} interested investors');

      // Cargar información de cada inversor
      for (final interestDoc in interestsSnapshot.docs) {
        final interestData = interestDoc.data();
        final investorId = interestData['investorId'];
        
        // Obtener datos del inversor
        final userDoc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(investorId)
            .get();
        
        if (userDoc.exists) {
          final investor = UserModel.fromFirestore(userDoc);
          _investors.add({
            'investor': investor,
            'interestDate': (interestData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'interestId': interestDoc.id,
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading interested investors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inversores interesados'),
      ),
      body: Column(
        children: [
          // Header del proyecto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_investors.length} inversores interesados',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de inversores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _investors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aún no hay inversores interesados',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los inversores interesados aparecerán aquí',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _investors.length,
                        itemBuilder: (context, index) {
                          final data = _investors[index];
                          final investor = data['investor'] as UserModel;
                          final interestDate = data['interestDate'] as DateTime;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _InvestorCard(
                              investor: investor,
                              interestDate: interestDate,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicProfileScreen(
                                      userId: investor.uid,
                                      userName: investor.name,
                                    ),
                                  ),
                                );
                              },
                              onContact: () {
                                _contactInvestor(investor);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _contactInvestor(UserModel investor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar inversor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${investor.name}'),
            Text('Email: ${investor.email}'),
            if (investor.phone != null)
              Text('Teléfono: ${investor.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar envío de email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de contacto próximamente'),
                ),
              );
            },
            icon: const Icon(Icons.email),
            label: const Text('Enviar email'),
          ),
        ],
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  final UserModel investor;
  final DateTime interestDate;
  final VoidCallback onTap;
  final VoidCallback onContact;

  const _InvestorCard({
    required this.investor,
    required this.interestDate,
    required this.onTap,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: investor.photoURL != null
                      ? CachedNetworkImageProvider(investor.photoURL!)
                      : null,
                  child: investor.photoURL == null
                      ? Text(
                          investor.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            investor.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (investor.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      UserRatingStars(
                        rating: 4.5, // Simulado
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Interesado el ${DateFormat('dd/MM/yyyy').format(interestDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información adicional
            if (investor.location != null || investor.industries != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (investor.location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            investor.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (investor.industries != null && investor.industries!.isNotEmpty) ...[
                      if (investor.location != null) const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              investor.industries!.join(', '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.person),
                    label: const Text('Ver perfil'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.message),
                    label: const Text('Contactar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}