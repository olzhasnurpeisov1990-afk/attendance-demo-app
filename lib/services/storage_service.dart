import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences prefs;
  StorageService._(this.prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // attendance stored as Map<date, Map<classId, Map<student, status>>>
  Future<Map<String, dynamic>> _loadAll() async {
    final raw = prefs.getString('attendance_all') ?? '{}';
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    await prefs.setString('attendance_all', json.encode(data));
  }

  Future<Map<String, String>> loadAttendanceForDate(String classId, String date) async {
    final all = await _loadAll();
    final dateMap = Map<String, dynamic>.from(all[date] ?? {});
    final classMap = Map<String, dynamic>.from(dateMap[classId] ?? {});
    return classMap.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> saveAttendanceForDate(String classId, String date, Map<String, String> data, {Map<String, String>? reasons}) async {
    final all = await _loadAll();
    final dateMap = Map<String, dynamic>.from(all[date] ?? {});
    dateMap[classId] = data;
    all[date] = dateMap;
    await _saveAll(all);
    if (reasons != null && reasons.isNotEmpty) {
      // optional: store reasons separately
      final key = 'reasons_${date}_$classId';
      await prefs.setString(key, json.encode(reasons));
    }
  }
}
