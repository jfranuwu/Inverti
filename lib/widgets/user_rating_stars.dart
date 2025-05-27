// Archivo: lib/widgets/user_rating_stars.dart
// Widget personalizado #3: Sistema de estrellas interactivo

import 'package:flutter/material.dart';

class UserRatingStars extends StatelessWidget {
  final double rating;
  final double maxRating;
  final int starCount;
  final double size;
  final Color? filledColor;
  final Color? emptyColor;
  final bool allowHalfRating;
  final Function(double)? onRatingChanged;

  const UserRatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5.0,
    this.starCount = 5,
    this.size = 24,
    this.filledColor,
    this.emptyColor,
    this.allowHalfRating = true,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filled = filledColor ?? Colors.amber;
    final empty = emptyColor ?? Colors.grey[300]!;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = (index + 1).toDouble();
        final starRating = rating / maxRating * starCount;
        
        IconData iconData;
        Color iconColor;
        
        if (starValue <= starRating) {
          // Estrella llena
          iconData = Icons.star;
          iconColor = filled;
        } else if (starValue - 0.5 <= starRating && allowHalfRating) {
          // Media estrella
          iconData = Icons.star_half;
          iconColor = filled;
        } else {
          // Estrella vacía
          iconData = Icons.star_border;
          iconColor = empty;
        }
        
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () {
                  final newRating = starValue / starCount * maxRating;
                  onRatingChanged!(newRating);
                }
              : null,
          child: Icon(
            iconData,
            size: size,
            color: iconColor,
          ),
        );
      }),
    );
  }
}