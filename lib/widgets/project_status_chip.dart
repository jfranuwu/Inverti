// Archivo: lib/widgets/project_status_chip.dart
// Widget personalizado #2: Chip con estados coloridos

import 'package:flutter/material.dart';

class ProjectStatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;

  const ProjectStatusChip({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _StatusConfig(
          label: 'Activo',
          backgroundColor: Colors.green.withOpacity(0.1),
          borderColor: Colors.green.withOpacity(0.3),
          textColor: Colors.green[700]!,
          dotColor: Colors.green,
        );
      case 'funded':
        return _StatusConfig(
          label: 'Financiado',
          backgroundColor: Colors.blue.withOpacity(0.1),
          borderColor: Colors.blue.withOpacity(0.3),
          textColor: Colors.blue[700]!,
          dotColor: Colors.blue,
        );
      case 'closed':
        return _StatusConfig(
          label: 'Cerrado',
          backgroundColor: Colors.grey.withOpacity(0.1),
          borderColor: Colors.grey.withOpacity(0.3),
          textColor: Colors.grey[700]!,
          dotColor: Colors.grey,
        );
      case 'pending':
        return _StatusConfig(
          label: 'Pendiente',
          backgroundColor: Colors.orange.withOpacity(0.1),
          borderColor: Colors.orange.withOpacity(0.3),
          textColor: Colors.orange[700]!,
          dotColor: Colors.orange,
        );
      default:
        return _StatusConfig(
          label: status,
          backgroundColor: Colors.purple.withOpacity(0.1),
          borderColor: Colors.purple.withOpacity(0.3),
          textColor: Colors.purple[700]!,
          dotColor: Colors.purple,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });
}