import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../storage/ip_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    final ip = ref.read(ipStateProvider);
    _ipController = TextEditingController(text: ip);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _saveIp() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty) return;

    // Update provider
    ref.read(ipStateProvider.notifier).state = newIp;

    // Save to storage
    await IpStorage.saveIp(newIp);

    // Refresh dependent providers
    ref.invalidate(statusProvider);
    ref.invalidate(infoProvider);
    ref.invalidate(connectionStatusProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("IP address updated")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Connection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _ipController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: "PC IP (e.g. http://192.168.0.10:5000)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saveIp,
                  child: const Text("Save IP"),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Theme",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text("System default"),
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).state = value;
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("Light"),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).state = value;
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("Dark"),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).state = value;
                      }
                    },
                  ),
                ],
              ),

              const Spacer(),

              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.0, top: 8),
                  child: Text(
                    "Developed for free, and made open source by Dominic Radley.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: content,
                    ),
                  )
                : content,
          );
        },
      ),
    );
  }
}