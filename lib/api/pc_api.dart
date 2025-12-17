import 'dart:convert';
import 'package:http/http.dart' as http;

class PcApi {
  final String baseUrl;

  PcApi(this.baseUrl);

  Future<Map<String, dynamic>> _get(String path) async {
    if (baseUrl.isEmpty) {
      throw Exception("PC IP not set");
    }

    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -------------------------
  // Status (patched to match backend exactly)
  // -------------------------
  Future<Map<String, dynamic>> getStatus() async {
    final raw = await _get('/status');

    return {
      "battery": raw["battery"],
      "charging": raw["charging"],
      "remaining": raw["remaining"],
      "powerPlan": raw["powerPlan"],
      "cpu": raw["cpu"],
      "ram": raw["ram"],
      "disk": raw["disk"],
      "temperature": raw["temperature"],
      "uptime": raw["uptime"],
    };
  }

  // -------------------------
  // Info (patched to match backend exactly)
  // -------------------------
  Future<Map<String, dynamic>> getInfo() async {
    final raw = await _get('/info');

    return {
      "os": raw["os"],
      "hostname": raw["hostname"],
      "cpu_model": raw["cpu_model"],
      "ram_total": raw["ram_total"],
      "cpu_percent": raw["cpu_percent"],
      "ram_percent": raw["ram_percent"],
    };
  }

  // -------------------------
  // Power Controls
  // -------------------------
  Future<Map<String, dynamic>> shutdown() => _get('/shutdown');
  Future<Map<String, dynamic>> restart() => _get('/restart');
  Future<Map<String, dynamic>> sleep() => _get('/sleep');
  Future<Map<String, dynamic>> lock() => _get('/lock');

  // -------------------------
  // Brightness
  // -------------------------
  Future<Map<String, dynamic>> setBrightness(int level) =>
      _get('/brightness/$level');

  // -------------------------
  // Quick Access Commands
  // -------------------------
  Future<Map<String, dynamic>> displayOff() => _get('/display_off');

  // -------------------------
  // Volume Controls
  // -------------------------
  Future<Map<String, dynamic>> volumeMute() => _get('/volume/mute');
  Future<Map<String, dynamic>> volumeUp() => _get('/volume/up');
  Future<Map<String, dynamic>> volumeDown() => _get('/volume/down');

  // -------------------------
  // App Launchers
  // -------------------------
  Future<Map<String, dynamic>> openBrowser() => _get('/open/browser');
  Future<Map<String, dynamic>> openExplorer() => _get('/open/explorer');
  Future<Map<String, dynamic>> openTaskManager() => _get('/open/taskmgr');
  Future<Map<String, dynamic>> openNotepad() => _get('/open/notepad');

  // -------------------------
  // Ping
  // -------------------------
  Future<bool> ping() async {
    if (baseUrl.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/ping');
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}