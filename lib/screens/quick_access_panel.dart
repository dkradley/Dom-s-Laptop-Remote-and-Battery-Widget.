import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class QuickAccessPanel extends ConsumerWidget {
  const QuickAccessPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);

    Future<void> run(Future<Map<String, dynamic>> Function() action) async {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Command sent")),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => run(api.displayOff),
          icon: const Icon(Icons.monitor),
          label: const Text("Display Off"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.volumeMute),
          icon: const Icon(Icons.volume_off),
          label: const Text("Mute"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.openBrowser),
          icon: const Icon(Icons.language),
          label: const Text("Browser"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.openExplorer),
          icon: const Icon(Icons.folder),
          label: const Text("Explorer"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.openTaskManager),
          icon: const Icon(Icons.bar_chart),
          label: const Text("TaskMgr"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.openNotepad),
          icon: const Icon(Icons.note),
          label: const Text("Notepad"),
        ),
      ],
    );
  }
}