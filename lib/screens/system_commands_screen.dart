import 'package:flutter/material.dart';

import 'widgets_power_brightness.dart';
import 'quick_access_panel.dart';

class SystemCommandsScreen extends StatelessWidget {
  const SystemCommandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 8),

        _SectionTitle("Power Controls"),
        SizedBox(height: 8),
        PowerControlsRow(),

        SizedBox(height: 24),

        _SectionTitle("Display & Brightness"),
        SizedBox(height: 8),
        BrightnessSlider(),

        SizedBox(height: 24),

        _SectionTitle("Quick System Commands"),
        SizedBox(height: 8),
        QuickAccessPanel(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}