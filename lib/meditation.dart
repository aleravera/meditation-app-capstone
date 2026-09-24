import 'package:flutter/material.dart';

/// Data passed from a Home card to the Detail screen.
class Meditation {
  const Meditation({
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.description,
    required this.duration,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String category;
  final String shortDescription;
  final String description;
  final String duration;
  final IconData icon;
  final List<Color> colors;
}
