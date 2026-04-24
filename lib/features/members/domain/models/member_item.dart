/// 클럽 회원 데이터 모델
class MemberItem {
  final String id;
  final String name;
  final String gender;
  final String birth;
  final String grade; // 'A' | 'B' | 'C' | 'D' | '초심'
  final String phone;
  final String address;
  final String joinDate;

  MemberItem({
    String? id,
    required this.name,
    required this.gender,
    required this.birth,
    required this.grade,
    required this.phone,
    this.address = '',
    String? joinDate,
  }) : id = id ?? _generateId(name, birth, phone),
        joinDate = joinDate ?? _thisMonth();

  static String _thisMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  static String _generateId(String name, String birth, String phone) {
    final cleaned = phone.replaceAll('-', '');
    return '${name}_${birth}_$cleaned';
  }

  MemberItem copyWith({
    String? name,
    String? gender,
    String? birth,
    String? grade,
    String? phone,
    String? address,
    String? joinDate,
  }) {
    return MemberItem(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birth: birth ?? this.birth,
      grade: grade ?? this.grade,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birth': birth,
      'grade': grade,
      'phone': phone,
      'address': address,
      'joinDate': joinDate,
    };
  }

  factory MemberItem.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString();
    final birth = (map['birth'] ?? '').toString();
    final phone = (map['phone'] ?? '').toString();

    return MemberItem(
      id: (map['id'] ?? '').toString().isNotEmpty ? map['id'].toString() : null,
      name: name,
      gender: (map['gender'] ?? '').toString(),
      birth: birth,
      grade: (map['grade'] ?? map['level'] ?? '').toString(),
      phone: phone,
      address: (map['address'] ?? '').toString(),
      joinDate: (map['joinDate'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MemberItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MemberItem(id: $id, name: $name, grade: $grade)';
}
