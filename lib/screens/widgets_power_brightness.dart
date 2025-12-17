import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

/// ------------------------------------------------------------
/// POWER CONTROLS (Shutdown, Restart, Sleep, Lock)
/// ------------------------------------------------------------
class PowerControlsRow extends ConsumerWidget {
  const PowerControlsRow({super.key});

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
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => run(api.shutdown),
          icon: const Icon(Icons.power_settings_new),
          label: const Text("Shutdown"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.restart),
          icon: const Icon(Icons.restart_alt),
          label: const Text("Restart"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.sleep),
          icon: const Icon(Icons.hotel),
          label: const Text("Sleep"),
        ),
        FilledButton.icon(
          onPressed: () => run(api.lock),
          icon: const Icon(Icons.lock),
          label: const Text("Lock"),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// BRIGHTNESS SLIDER
/// ------------------------------------------------------------
class BrightnessSlider extends ConsumerStatefulWidget {
  const BrightnessSlider({super.key});

  @override
  ConsumerState<BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends ConsumerState<BrightnessSlider> {
  double _brightness = 100;

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);

    Future<void> sendBrightness(double value) async {
      try {
        await api.setBrightness(value.toInt());
      } catch (_) {
        // ignore errors silently
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _brightness,
          min: 0,
          max: 100,
          divisions: 20,
          label: "${_brightness.toInt()}%",
          onChanged: (value) {
            setState(() => _brightness = value);
            sendBrightness(value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.brightness_low),
            Text(
              "${_brightness.toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.brightness_high),
          ],
        ),
      ],
    );
  }
}