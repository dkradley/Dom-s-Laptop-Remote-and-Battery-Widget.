import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import 'overview_screen.dart';
import 'system_commands_screen.dart';
import 'media_controls_screen.dart';
import 'app_launcher_screen.dart';
import 'settings_screen.dart';

enum HomeSection {
  overview,
  systemCommands,
  mediaControls,
  appLauncher,
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  HomeSection _current = HomeSection.overview;
  bool _lastConnected = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Auto-refresh status + info every 3 seconds
    Future.microtask(() {
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        ref.invalidate(statusProvider);
        ref.invalidate(infoProvider);
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _selectSection(HomeSection section) {
    setState(() {
      _current = section;
    });
    Navigator.of(context).pop(); // close drawer
  }

  Widget _buildBody() {
    switch (_current) {
      case HomeSection.overview:
        return const OverviewScreen();
      case HomeSection.systemCommands:
        return const SystemCommandsScreen();
      case HomeSection.mediaControls:
        return const MediaControlsScreen();
      case HomeSection.appLauncher:
        return const AppLauncherScreen();
    }
  }

  String _titleForSection() {
    switch (_current) {
      case HomeSection.overview:
        return "System Overview";
      case HomeSection.systemCommands:
        return "System Commands";
      case HomeSection.mediaControls:
        return "Media Controls";
      case HomeSection.appLauncher:
        return "App Launcher";
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Show the IP the app is actually using
    print("🔍 CURRENT IP = '${ref.watch(ipStateProvider)}'");

    final connectionAsync = ref.watch(connectionStatusProvider);

    // Show popup ONLY when connection drops
    connectionAsync.whenData((connected) {
      if (_lastConnected && !connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Device not connected"),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
      _lastConnected = connected;
    });

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForSection()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        width: isWide ? 340 : 280,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Remote Panels",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              _DrawerItem(
                label: "Overview",
                icon: Icons.dashboard,
                selected: _current == HomeSection.overview,
                onTap: () => _selectSection(HomeSection.overview),
              ),

              _DrawerItem(
                label: "System Commands",
                icon: Icons.settings_remote,
                selected: _current == HomeSection.systemCommands,
                onTap: () => _selectSection(HomeSection.systemCommands),
              ),

              _DrawerItem(
                label: "Media Controls",
                icon: Icons.music_note,
                selected: _current == HomeSection.mediaControls,
                onTap: () => _selectSection(HomeSection.mediaControls),
              ),

              _DrawerItem(
                label: "App Launcher",
                icon: Icons.apps,
                selected: _current == HomeSection.appLauncher,
                onTap: () => _selectSection(HomeSection.appLauncher),
              ),
            ],
          ),
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.05, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: Container(
          key: ValueKey(_current),
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? Theme.of(context).colorScheme.primary : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}