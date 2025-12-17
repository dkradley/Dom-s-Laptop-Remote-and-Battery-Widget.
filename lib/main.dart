import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/ip_storage.dart';
import 'api/pc_api.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/ip_setup_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: PcRemoteApp()));
}

final initialIpProvider = FutureProvider<String?>((ref) async {
  return await IpStorage.loadIp();
});

final ipStateProvider = StateProvider<String>((ref) {
  return "";
});

final apiProvider = Provider<PcApi>((ref) {
  final ip = ref.watch(ipStateProvider);
  return PcApi(ip.isNotEmpty ? ip : "");
});

final statusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getStatus();
});

final infoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getInfo();
});

final connectionStatusProvider = StreamProvider<bool>((ref) async* {
  final api = ref.watch(apiProvider);

  while (true) {
    final ok = await api.ping();
    yield ok;
    await Future.delayed(const Duration(seconds: 2));
  }
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

class PcRemoteApp extends ConsumerWidget {
  const PcRemoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialIpAsync = ref.watch(initialIpProvider);
    final themeMode = ref.watch(themeModeProvider);

    return initialIpAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const IpSetupScreen(),
      ),
      data: (initialIp) {
        if (initialIp != null && initialIp.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notifier = ref.read(ipStateProvider.notifier);

            if (notifier.state.isEmpty) {
              notifier.state = initialIp;

              // 🔥 CRITICAL FIX:
              // Now that the IP is loaded, force all providers to refresh.
              ref.invalidate(statusProvider);
              ref.invalidate(infoProvider);
              ref.invalidate(connectionStatusProvider);
            }
          });
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routes: {
            "/setup": (_) => const IpSetupScreen(),
            "/home": (_) => const HomeShell(),
            "/settings": (_) => const SettingsScreen(),
          },
          home: (initialIp == null || initialIp.isEmpty)
              ? const IpSetupScreen()
              : const HomeShell(),
        );
      },
    );
  }
}