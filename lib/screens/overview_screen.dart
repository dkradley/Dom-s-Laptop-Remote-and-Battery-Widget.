import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  Color _batteryColor(num? level) {
    if (level == null) return Colors.grey;
    if (level <= 20) return Colors.redAccent;
    if (level <= 50) return Colors.orangeAccent;
    if (level <= 80) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(statusProvider);
    final infoAsync = ref.watch(infoProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: Column(
            children: [
              statusAsync.when(
                data: (status) => AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 250),
                  child: _BatteryOverviewCard(
                    level: _parseNum(status['battery']),
                    charging: status['charging'] == true,
                    remaining: status['remaining']?.toString() ?? "--",
                    powerPlan: status['powerPlan']?.toString() ?? "Unknown",
                    colorForLevel: _batteryColor,
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorText("Status error: $e"),
              ),
              const SizedBox(height: 16),
              infoAsync.when(
                data: (info) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isWide
                      ? Row(
                          key: ValueKey(info.hashCode),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SystemOverviewCard(info: info),
                            ),
                          ],
                        )
                      : _SystemOverviewCard(info: info),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorText("Info error: $e"),
              ),
            ],
          ),
        );
      },
    );
  }

  num _parseNum(dynamic v) {
    if (v == null) return 0;
    return num.tryParse(v.toString()) ?? 0;
  }
}

class _BatteryOverviewCard extends StatelessWidget {
  final num? level;
  final bool? charging;
  final String remaining;
  final String? powerPlan;
  final Color Function(num?) colorForLevel;

  const _BatteryOverviewCard({
    required this.level,
    required this.charging,
    required this.remaining,
    required this.powerPlan,
    required this.colorForLevel,
  });

  IconData _planIcon(String? plan) {
    final p = (plan ?? "").toLowerCase();
    if (p.contains("performance")) return Icons.bolt;
    if (p.contains("power saver")) return Icons.energy_savings_leaf;
    return Icons.balance;
  }

  @override
  Widget build(BuildContext context) {
    final batteryLevel = level ?? 0;
    final color = colorForLevel(batteryLevel);
    final isCharging = charging == true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor:
                          (batteryLevel.clamp(0, 100) / 100).toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  child: Container(
                    width: 6,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (isCharging)
                  const Icon(Icons.bolt, color: Colors.yellowAccent, size: 20),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${batteryLevel.toStringAsFixed(0)}% ${isCharging ? "(Charging)" : ""}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_planIcon(powerPlan), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        powerPlan ?? "Power plan: Unknown",
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                          fontSize: 13,
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
    );
  }
}

class _SystemOverviewCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const _SystemOverviewCard({required this.info});

  num _parseNum(dynamic v) {
    if (v == null) return 0;
    return num.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cpu = _parseNum(info['cpu_percent']);
    final ram = _parseNum(info['ram_percent']);
    final host = info['hostname']?.toString() ?? '--';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _StatRow(
              icon: Icons.memory,
              label: "CPU Usage",
              value: "${cpu.toStringAsFixed(0)}%",
            ),
            const SizedBox(height: 8),
            _LinearUsageBar(percent: cpu.toDouble()),
            const SizedBox(height: 16),
            _StatRow(
              icon: Icons.storage,
              label: "RAM Usage",
              value: "${ram.toStringAsFixed(0)}%",
            ),
            const SizedBox(height: 8),
            _LinearUsageBar(percent: ram.toDouble()),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.computer, size: 20),
                const SizedBox(width: 8),
                Text(
                  host,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LinearUsageBar extends StatelessWidget {
  final double percent;

  const _LinearUsageBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0, 100) / 100;
    final color = pct < 0.6
        ? Colors.greenAccent
        : (pct < 0.85 ? Colors.orangeAccent : Colors.redAccent);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: Colors.white10,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: pct,
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: Colors.redAccent),
    );
  }
}