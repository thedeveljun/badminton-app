import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/member_item.dart';

class MemberStorage {
  static const String _key = 'club_members_v1';

  static Future<bool> saveMembers(List<MemberItem> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = members.map((m) => jsonEncode(m.toMap())).toList();
      return await prefs.setStringList(_key, jsonList);
    } catch (_) {
      return false;
    }
  }

  static Future<List<MemberItem>?> loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key);
      if (jsonList == null) return null;

      return jsonList
          .map((s) => MemberItem.fromMap(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearMembers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
