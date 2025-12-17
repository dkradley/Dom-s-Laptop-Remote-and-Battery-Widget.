import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class MediaControlsScreen extends ConsumerWidget {
  const MediaControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);

    Future<void> run(Future<Map<String, dynamic>> Function() action) async {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Media command sent")),
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, size: 40),
          const SizedBox(height: 16),

          const Text(
            "Media Controls",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => run(api.volumeMute),
                icon: const Icon(Icons.volume_off),
                label: const Text("Mute"),
              ),
              FilledButton.icon(
                onPressed: () => run(api.volumeDown),
                icon: const Icon(Icons.volume_down),
                label: const Text("Volume -"),
              ),
              FilledButton.icon(
                onPressed: () => run(api.volumeUp),
                icon: const Icon(Icons.volume_up),
                label: const Text("Volume +"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}