import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../storage/ip_storage.dart';

class IpSetupScreen extends ConsumerStatefulWidget {
  const IpSetupScreen({super.key});

  @override
  ConsumerState<IpSetupScreen> createState() => _IpSetupScreenState();
}

class _IpSetupScreenState extends ConsumerState<IpSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  Future<void> _saveIp() async {
    final ip = _controller.text.trim();
    if (ip.isEmpty) return;

    setState(() => _saving = true);

    // Save to SharedPreferences
    await IpStorage.saveIp(ip);

    // Update provider
    ref.read(ipStateProvider.notifier).state = ip;

    // Refresh dependent providers
    ref.invalidate(statusProvider);
    ref.invalidate(infoProvider);
    ref.invalidate(connectionStatusProvider);

    if (!mounted) return;

    setState(() => _saving = false);

    // Navigate to home
    Navigator.of(context).pushReplacementNamed("/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect to PC"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.computer, size: 64),
                const SizedBox(height: 16),

                const Text(
                  "Enter your PC's IP address",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: "http://192.168.x.x:5000",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                FilledButton(
                  onPressed: _saving ? null : _saveIp,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Continue"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}