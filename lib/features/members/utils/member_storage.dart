import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/member_item.dart';

/// 회원 데이터를 기기에 영구 저장/불러오기하는 클래스
/// shared_preferences를 사용해 앱을 껐다 켜도 데이터가 유지됩니다.
class MemberStorage {
  static const String _key = 'club_members_v1';

  /// 회원 목록 저장
  static Future<bool> saveMembers(List<MemberItem> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = members.map((m) => jsonEncode(m.toMap())).toList();
      return await prefs.setStringList(_key, jsonList);
    } catch (e) {
      return false;
    }
  }

  /// 회원 목록 불러오기
  /// 저장된 데이터가 없으면 null 반환
  static Future<List<MemberItem>?> loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key);
      if (jsonList == null) return null; // 최초 실행 → 기본 데이터 사용

      return jsonList
          .map((s) => MemberItem.fromMap(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null; // 불러오기 실패 시 기본 데이터 사용
    }
  }

  /// 저장된 데이터 전체 삭제 (초기화용)
  static Future<void> clearMembers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
