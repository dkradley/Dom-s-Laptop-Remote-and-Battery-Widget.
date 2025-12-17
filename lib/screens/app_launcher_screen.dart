import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class AppLauncherScreen extends ConsumerWidget {
  const AppLauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);

    Future<void> run(Future<Map<String, dynamic>> Function() action) async {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Launch command sent")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }

    final width = MediaQuery.of(context).size.width;

    // Adaptive grid layout for phones, foldables, tablets
    final crossAxisCount = width > 900
        ? 4
        : width > 600
            ? 3
            : 2;

    final items = [
      _LauncherItem(
        label: "Browser",
        icon: Icons.language,
        action: api.openBrowser,
      ),
      _LauncherItem(
        label: "File Explorer",
        icon: Icons.folder,
        action: api.openExplorer,
      ),
      _LauncherItem(
        label: "Task Manager",
        icon: Icons.bar_chart,
        action: api.openTaskManager,
      ),
      _LauncherItem(
        label: "Notepad",
        icon: Icons.note,
        action: api.openNotepad,
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 3.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items
          .map(
            (item) => FilledButton.icon(
              onPressed: () => run(item.action),
              icon: Icon(item.icon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

class _LauncherItem {
  final String label;
  final IconData icon;
  final Future<Map<String, dynamic>> Function() action;

  _LauncherItem({
    required this.label,
    required this.icon,
    required this.action,
  });
}