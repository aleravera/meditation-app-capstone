import 'package:flutter/material.dart';

import 'meditation.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.meditation});

  /// The selected meditation is provided directly by the tapped Home card.
  final Meditation meditation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditation Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local graphic placeholder: no remote image or service is used.
                Container(
                  key: const Key('detailImage'),
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: meditation.colors),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(meditation.icon, size: 92, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  meditation.title,
                  key: const Key('detailTitle'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.spa_outlined, size: 18),
                      label: Text(meditation.category),
                    ),
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 18),
                      label: Text(meditation.duration),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'About this meditation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  meditation.description,
                  key: const Key('detailDescription'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
