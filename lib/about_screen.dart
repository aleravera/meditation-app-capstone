import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('aboutScreen'),
      appBar: AppBar(title: const Text('About Mindful Moments')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.spa,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Mindful Moments',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mindful Moments is a meditation app created as a capstone project.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.code),
                    title: Text('Framework'),
                    subtitle: Text('Flutter'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text('Course'),
                    subtitle: Text(
                      'Developed for the Mobile Application Development course.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
