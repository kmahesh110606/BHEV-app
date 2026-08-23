import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_model.dart';

/// Offline Cache Service for storing and retrieving 10,000+ national EV stations locally
class OfflineCacheService {
  static const String _stationsKey = 'urjaa_offline_stations_v1';
  static const String _lastSyncKey = 'urjaa_offline_last_sync_timestamp';

  /// Save stations list to device local storage
  static Future<void> saveStations(List<StationModel> stations) async {
    if (stations.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = stations.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_stationsKey, jsonString);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Get cached stations from device local storage
  static Future<List<StationModel>> getCachedStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_stationsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        return decoded
            .map((item) => StationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get last sync timestamp formatted string
  static Future<String?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastSyncKey);
      if (raw != null) {
        final dt = DateTime.tryParse(raw)?.toLocal();
        if (dt != null) {
          final now = DateTime.now();
          final diff = now.difference(dt);
          if (diff.inMinutes < 1) return 'Synced just now';
          if (diff.inHours < 1) return 'Synced ${diff.inMinutes}m ago';
          if (diff.inDays < 1) return 'Synced today ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          return 'Cached ${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        }
      }
    } catch (_) {}
    return null;
  }
}
