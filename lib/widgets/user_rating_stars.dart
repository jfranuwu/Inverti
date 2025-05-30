// Archivo: lib/widgets/user_rating_stars.dart
// Widget para mostrar calificaciones con estrellas

import 'package:flutter/material.dart';

class UserRatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool showRating;
  final MainAxisAlignment alignment;
  final int maxRating;

  const UserRatingStars({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.color,
    this.unratedColor,
    this.showRating = false,
    this.alignment = MainAxisAlignment.start,
    this.maxRating = 5,
  });

  @override
  Widget build(BuildContext context) {
    final ratedColor = color ?? Colors.amber;
    final unrated = unratedColor ?? Colors.grey[300]!;
    
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          return Icon(
            _getStarIcon(index),
            size: size,
            color: _getStarColor(index, ratedColor, unrated),
          );
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStarIcon(int index) {
    final starValue = index + 1;
    if (rating >= starValue) {
      return Icons.star;
    } else if (rating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index, Color ratedColor, Color unratedColor) {
    final starValue = index + 1;
    if (rating >= starValue) {
      return ratedColor;
    } else if (rating >= starValue - 0.5) {
      return ratedColor;
    } else {
      return unratedColor;
    }
  }
}

// Widget interactivo para seleccionar calificación
class InteractiveRatingStars extends StatefulWidget {
  final double initialRating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final Function(double)? onRatingChanged;
  final int maxRating;
  final bool allowHalfRating;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0.0,
    this.size = 24.0,
    this.color,
    this.unratedColor,
    this.onRatingChanged,
    this.maxRating = 5,
    this.allowHalfRating = false,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final ratedColor = widget.color ?? Colors.amber;
    final unrated = widget.unratedColor ?? Colors.grey[300]!;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: () => _onStarTapped(index),
          onPanUpdate: (details) => _onStarPanned(details, index),
          child: Icon(
            _getStarIcon(index),
            size: widget.size,
            color: _getStarColor(index, ratedColor, unrated),
          ),
        );
      }),
    );
  }

  void _onStarTapped(int index) {
    setState(() {
      if (widget.allowHalfRating) {
        _currentRating = index + 1.0;
      } else {
        _currentRating = index + 1.0;
      }
    });
    widget.onRatingChanged?.call(_currentRating);
  }

  void _onStarPanned(DragUpdateDetails details, int index) {
    if (!widget.allowHalfRating) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final double starWidth = widget.size;
    final double relativePosition = (localPosition.dx - (index * starWidth)) / starWidth;
    
    setState(() {
      if (relativePosition < 0.5) {
        _currentRating = index + 0.5;
      } else {
        _currentRating = index + 1.0;
      }
    });
    widget.onRatingChanged?.call(_currentRating);
  }

  IconData _getStarIcon(int index) {
    final starValue = index + 1;
    if (_currentRating >= starValue) {
      return Icons.star;
    } else if (_currentRating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index, Color ratedColor, Color unratedColor) {
    final starValue = index + 1;
    if (_currentRating >= starValue) {
      return ratedColor;
    } else if (_currentRating >= starValue - 0.5) {
      return ratedColor;
    } else {
      return unratedColor;
    }
  }
}

// Widget compacto para mostrar rating y número de reviews
class CompactRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final Color? color;

  const CompactRating({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: color ?? Colors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Text(
          ' ($reviewCount)',
          style: TextStyle(
            fontSize: size * 0.7,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar distribución de ratings
class RatingDistribution extends StatelessWidget {
  final Map<int, int> distribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}
  final double height;

  const RatingDistribution({
    super.key,
    required this.distribution,
    this.height = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox();

    return Column(
      children: [
        for (int star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildRatingBar(star, distribution[star] ?? 0, total),
          ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.star,
          size: 12,
          color: Colors.amber,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Colors.amber),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}