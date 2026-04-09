/// 클럽 회원 데이터 모델 (Member + MemberItem 통합)
/// 앱 전체에서 이 클래스 하나만 사용합니다.
class MemberItem {
  final String id;
  final String name;
  final String gender;
  final String birth;
  final String grade; // 'A' | 'B' | 'C' | 'D' | '초심'
  final String phone;
  final String address;

  MemberItem({
    String? id,
    required this.name,
    required this.gender,
    required this.birth,
    required this.grade,
    required this.phone,
    this.address = '',
  }) : id = id ?? _generateId(name, birth, phone);

  /// ID는 이름+생년월일+전화번호 조합으로 생성합니다.
  /// 같은 사람이 중복 등록되는 걸 방지하는 데도 활용됩니다.
  static String _generateId(String name, String birth, String phone) {
    final cleaned = phone.replaceAll('-', '');
    return '${name}_${birth}_$cleaned';
  }

  // -------------------------------------------------------
  // copyWith — 수정 시 기존 id를 유지합니다.
  // -------------------------------------------------------
  MemberItem copyWith({
    String? name,
    String? gender,
    String? birth,
    String? grade,
    String? phone,
    String? address,
  }) {
    return MemberItem(
      id: id, // 수정해도 id는 바뀌지 않습니다.
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birth: birth ?? this.birth,
      grade: grade ?? this.grade,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  // -------------------------------------------------------
  // 직렬화 / 역직렬화 (로컬 저장소용)
  // -------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birth': birth,
      'grade': grade,
      'phone': phone,
      'address': address,
    };
  }

  factory MemberItem.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString();
    final birth = (map['birth'] ?? '').toString();
    final phone = (map['phone'] ?? '').toString();

    return MemberItem(
      // 저장된 id가 있으면 그걸 쓰고, 없으면 새로 생성합니다.
      id: (map['id'] ?? '').toString().isNotEmpty ? map['id'].toString() : null,
      name: name,
      gender: (map['gender'] ?? '').toString(),
      birth: birth,
      // 구버전 호환: 'level' 키로 저장된 데이터도 읽습니다.
      grade: (map['grade'] ?? map['level'] ?? '').toString(),
      phone: phone,
      address: (map['address'] ?? '').toString(),
    );
  }

  // -------------------------------------------------------
  // 동등 비교 — id 기준
  // -------------------------------------------------------
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MemberItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MemberItem(id: $id, name: $name, grade: $grade)';
}
