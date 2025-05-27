// Archivo: lib/widgets/quick_action_fab.dart
// Widget personalizado #4: FloatingActionButton expandible

import 'package:flutter/material.dart';

class QuickActionFab extends StatefulWidget {
  final List<QuickAction> actions;
  final IconData mainIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const QuickActionFab({
    super.key,
    required this.actions,
    this.mainIcon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<QuickActionFab> createState() => _QuickActionFabState();
}

class _QuickActionFabState extends State<QuickActionFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Acciones expandibles
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.actions.map((action) {
                final index = widget.actions.indexOf(action);
                final delay = index / widget.actions.length;
                final animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: _expandAnimation,
                    curve: Interval(
                      delay * 0.5,
                      delay * 0.5 + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuickActionItem(
                        action: action,
                        onTap: () {
                          _toggle();
                          action.onTap();
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        
        // FAB principal
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * 0.75 * 3.14159,
                child: Icon(
                  _isExpanded ? Icons.close : widget.mainIcon,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Mini FAB
        SizedBox(
          width: 48,
          height: 48,
          child: FloatingActionButton(
            onPressed: onTap,
            backgroundColor: action.backgroundColor ?? Colors.grey[700],
            foregroundColor: action.foregroundColor ?? Colors.white,
            heroTag: null,
            child: Icon(
              action.icon,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });
}