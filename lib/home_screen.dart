import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail_screen.dart';
import 'meditation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'Friend';

  static const _meditations = [
    Meditation(
      title: 'Mindful Breathing',
      category: 'Relaxation',
      shortDescription: 'Slow down and reconnect with your breath.',
      description:
          'A gentle guided breathing practice designed to settle the mind, '
          'release tension, and bring your attention back to the present moment.',
      duration: '10 min',
      icon: Icons.air_rounded,
      colors: [Color(0xFF647DEE), Color(0xFF7F53AC)],
    ),
    Meditation(
      title: 'Body Scan Meditation',
      category: 'Wellness',
      shortDescription: 'Notice each part of your body with care.',
      description:
          'Move your awareness slowly through the body. This calming practice '
          'helps you notice sensations, soften tension, and prepare for deep rest.',
      duration: '15 min',
      icon: Icons.self_improvement_rounded,
      colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
    ),
    Meditation(
      title: 'Deep Focus',
      category: 'Productivity',
      shortDescription: 'Clear distractions before your next task.',
      description:
          'A short focus meditation that uses steady breathing and a simple '
          'visualization to help you clear distractions and work with intention.',
      duration: '8 min',
      icon: Icons.center_focus_strong_rounded,
      colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Reads the account name saved during Signup for the welcome message.
  Future<void> _loadUsername() async {
    final preferences = await SharedPreferences.getInstance();
    final savedUsername = preferences.getString('username')?.trim();
    if (!mounted) return;
    setState(() {
      if (savedUsername != null && savedUsername.isNotEmpty) {
        _username = savedUsername;
      }
    });
  }

  // Opens Detail and passes the exact meditation selected by the user.
  void _openDetail(Meditation meditation) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(meditation: meditation),
      ),
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings are not required for this laboratory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMenuPlaceholder(String label) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not required for this laboratory.')),
    );
  }

  // Sign Out clears the navigation history but keeps the locally saved account.
  void _signOut() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('homeScreen'),
      appBar: AppBar(
        title: const Text(
          'Mindful Moments',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            key: const Key('settingsButton'),
            tooltip: 'Settings',
            onPressed: _showSettings,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // The Drawer supplies the hamburger navigation requested by the lab.
      drawer: Drawer(
        key: const Key('homeDrawer'),
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.spa,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Mindful Moments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => _showMenuPlaceholder('Settings'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                onTap: () => _showMenuPlaceholder('Notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.assessment_outlined),
                title: const Text('Reports'),
                onTap: () => _showMenuPlaceholder('Reports'),
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                key: const Key('signOutButton'),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign Out'),
                onTap: _signOut,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('homeFab'),
        tooltip: 'Add',
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section shown at the top of the Home screen.
                  Text(
                    'Hello, $_username!',
                    key: const Key('welcomeText'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find your perfect meditation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF666B7A),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(
                    title: 'Popular Meditations',
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 14),
                  // Popular content uses horizontally scrollable cards.
                  SizedBox(
                    height: 226,
                    child: ListView.separated(
                      key: const Key('popularMeditations'),
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final meditation = _meditations[index];
                        return _PopularMeditationCard(
                          meditation: meditation,
                          onTap: () => _openDetail(meditation),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(
                    title: 'Daily Meditation',
                    icon: Icons.today_outlined,
                  ),
                  const SizedBox(height: 14),
                  // Daily content uses a full-width card for clear contrast.
                  _DailyMeditationCard(
                    meditation: _meditations[2],
                    onTap: () => _openDetail(_meditations[2]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PopularMeditationCard extends StatelessWidget {
  const _PopularMeditationCard({required this.meditation, required this.onTap});

  final Meditation meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          key: Key('meditation-${meditation.title}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MeditationImage(meditation: meditation, height: 105),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.category.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 5),
                        Text(meditation.duration),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meditation.shortDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF737786),
                              fontSize: 12,
                            ),
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
    );
  }
}

class _DailyMeditationCard extends StatelessWidget {
  const _DailyMeditationCard({required this.meditation, required this.onTap});

  final Meditation meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        key: Key('meditation-${meditation.title}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                child: _MeditationImage(meditation: meditation, height: 112),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.category.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meditation.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meditation.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF737786)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 17),
                        const SizedBox(width: 5),
                        Text(meditation.duration),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeditationImage extends StatelessWidget {
  const _MeditationImage({required this.meditation, required this.height});

  final Meditation meditation;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: meditation.colors),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(meditation.icon, size: 50, color: Colors.white),
    );
  }
}
