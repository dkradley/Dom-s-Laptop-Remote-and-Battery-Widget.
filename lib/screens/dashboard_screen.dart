import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import 'quick_access_panel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        ref.invalidate(statusProvider);
        ref.invalidate(infoProvider);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _connectionBar(bool connected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.check_circle : Icons.error,
            color: connected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? "Connected to PC" : "Disconnected",
            style: TextStyle(
              color: connected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(statusProvider);
    final infoAsync = ref.watch(infoProvider);
    final connectionAsync = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Remote Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, "/settings"),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(statusProvider);
              ref.invalidate(infoProvider);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            connectionAsync.when(
              data: (ok) => _connectionBar(ok),
              loading: () => _connectionBar(false),
              error: (_, __) => _connectionBar(false),
            ),

            const SizedBox(height: 16),

            statusAsync.when(
              data: (status) => BatteryCard(status: status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorCard(message: 'Status error: $e'),
            ),

            const SizedBox(height: 16),

            infoAsync.when(
              data: (info) => InfoCard(info: info),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorCard(message: 'Info error: $e'),
            ),

            const SizedBox(height: 24),

            const Text(
              "Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const QuickAccessPanel(),

            const SizedBox(height: 24),

            const Text(
              'Power Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PowerControlsRow(),

            const SizedBox(height: 24),

            const Text(
              'Brightness',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const BrightnessSlider(),
          ],
        ),
      ),
    );
  }
}

class BatteryCard extends StatelessWidget {
  final Map<String, dynamic> status;

  const BatteryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final battery = status['battery'] ?? '--';
    final charging = status['charging'] ?? false;
    final remaining = status['remaining'] ?? '--';
    final plan = status['powerPlan'] ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Battery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Level: $battery%'),
            Text('Charging: $charging'),
            Text('Remaining: $remaining'),
            Text('Power plan: $plan'),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const InfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final cpu = info['cpu_percent'] ?? 0;
    final ram = info['ram_percent'] ?? 0;
    final host = info['hostname'] ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('CPU: $cpu%'),
            Text('RAM: $ram%'),
            Text('Host: $host'),
          ],
        ),
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String message;

  const ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class PowerControlsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);

    Future<void> runAction(Future<Map<String, dynamic>> Function() action) async {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Command sent')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => runAction(api.shutdown),
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Shutdown'),
        ),
        ElevatedButton.icon(
          onPressed: () => runAction(api.restart),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Restart'),
        ),
        ElevatedButton.icon(
          onPressed: () => runAction(api.sleep),
          icon: const Icon(Icons.bedtime),
          label: const Text('Sleep'),
        ),
        ElevatedButton.icon(
          onPressed: () => runAction(api.lock),
          icon: const Icon(Icons.lock),
          label: const Text('Lock'),
        ),
      ],
    );
  }
}

class BrightnessSlider extends ConsumerStatefulWidget {
  const BrightnessSlider();

  @override
  ConsumerState<BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends ConsumerState<BrightnessSlider> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);

    return Row(
      children: [
        const Icon(Icons.brightness_low),
        Expanded(
          child: Slider(
            value: _value,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_value.toInt()}%',
            onChanged: (v) {
              setState(() {
                _value = v;
              });
            },
            onChangeEnd: (v) async {
              try {
                await api.setBrightness(v.toInt());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Brightness set to ${v.toInt()}%')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ),
        const Icon(Icons.brightness_high),
      ],
    );
  }
}