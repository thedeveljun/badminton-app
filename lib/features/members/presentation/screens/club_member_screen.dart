import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funminton_club_app/features/members/presentation/widgets/member_excel_tools.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/member_item.dart';
import '../../utils/member_storage.dart';
import '../../utils/phone_number_formatter.dart';

// ============================================================
// 기본 회원 데이터 (앱 최초 실행 시 1회만 사용)
// ============================================================
List<MemberItem> get _defaultMembers => [
  MemberItem(
    name: '강연정',
    gender: '여',
    birth: '701025',
    grade: 'A',
    phone: '010-1234-0000',
    address: '과천시 중앙동',
  ),
  MemberItem(
    name: '고길동',
    gender: '남',
    birth: '750215',
    grade: 'B',
    phone: '010-5682-1113',
    address: '과천시 막계동',
  ),
  MemberItem(
    name: '김은하',
    gender: '남',
    birth: '751025',
    grade: 'B',
    phone: '010-5678-2580',
    address: '과천시 원문동',
  ),
  MemberItem(
    name: '문귀녀',
    gender: '여',
    birth: '720916',
    grade: 'A',
    phone: '010-5004-3052',
    address: '서울시 서초구 서초동',
  ),
  MemberItem(
    name: '이순신',
    gender: '남',
    birth: '700517',
    grade: 'D',
    phone: '010-5812-7958',
    address: '안양시 동안구 인덕원동',
  ),
  MemberItem(
    name: '이재명',
    gender: '남',
    birth: '651012',
    grade: '초심',
    phone: '010-5008-7333',
    address: '의왕시 내손동',
  ),
  MemberItem(
    name: '임홍준',
    gender: '남',
    birth: '720519',
    grade: 'B',
    phone: '010-8531-9998',
    address: '의왕시 포일동',
  ),
  MemberItem(
    name: '최준호',
    gender: '남',
    birth: '690523',
    grade: 'A',
    phone: '010-5008-7330',
    address: '안양시 동안구 범계동',
  ),
  MemberItem(
    name: '최홍선',
    gender: '남',
    birth: '730512',
    grade: 'A',
    phone: '010-5322-1234',
    address: '서울시 동작구 신림동',
  ),
  MemberItem(
    name: '한명수',
    gender: '여',
    birth: '731010',
    grade: 'C',
    phone: '010-3690-2580',
    address: '과천시 원문동 한양수자인',
  ),
];

class ClubMemberScreen extends StatefulWidget {
  const ClubMemberScreen({super.key});

  @override
  State<ClubMemberScreen> createState() => _ClubMemberScreenState();
}

class _ClubMemberScreenState extends State<ClubMemberScreen> {
  final String clubName = '중앙클럽';
  String get clubMemberTitle => '${clubName}회원';

  final TextEditingController _searchController = TextEditingController();

  String _selectedGender = '전체';
  String _selectedGrade = '전체';
  bool _ascending = true;
  String? _highlightedMemberId;

  bool _isLoading = true;

  final List<MemberItem> _members = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final saved = await MemberStorage.loadMembers();
    setState(() {
      if (saved != null) {
        _members.addAll(saved);
      } else {
        _members.addAll(_defaultMembers);
        MemberStorage.saveMembers(_members);
      }
      _isLoading = false;
    });
  }

  Future<void> _saveMembers() async {
    await MemberStorage.saveMembers(_members);
  }

  Future<void> _handleImportRows(List<ImportedMemberRow> rows) async {
    setState(() {
      for (final row in rows) {
        _members.add(
          MemberItem(
            name: row.name,
            gender: row.gender,
            birth: row.birthDate,
            grade: row.grade.trim().toUpperCase(),
            phone: row.phone,
            address: row.address,
          ),
        );
      }
    });
    await _saveMembers();
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleaned = phone.replaceAll('-', '');
    final uri = Uri(scheme: 'tel', path: cleaned);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$phone 전화 연결에 실패했습니다.')));
    }
  }

  List<MemberItem> get _filteredMembers {
    List<MemberItem> result = [..._members];
    final keyword = _searchController.text.trim();

    if (keyword.isNotEmpty) {
      result = result.where((m) => m.name.contains(keyword)).toList();
    }
    if (_selectedGender != '전체') {
      result = result.where((m) => m.gender == _selectedGender).toList();
    }
    if (_selectedGrade != '전체') {
      result = result.where((m) => m.grade == _selectedGrade).toList();
    }

    result.sort(
      (a, b) =>
          _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
    );
    return result;
  }

  bool _isValidBirthDate(String value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return false;

    final yy = int.parse(value.substring(0, 2));
    final mm = int.parse(value.substring(2, 4));
    final dd = int.parse(value.substring(4, 6));

    if (mm < 1 || mm > 12) return false;
    if (dd < 1) return false;

    final year = yy >= 30 ? 1900 + yy : 2000 + yy;

    try {
      final date = DateTime(year, mm, dd);
      return date.year == year && date.month == mm && date.day == dd;
    } catch (_) {
      return false;
    }
  }

  bool _isSearchMatched(MemberItem member) {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return false;
    return member.name.contains(keyword);
  }

  bool _isDuplicateMember(MemberItem member) {
    return _members
            .where(
              (m) =>
                  m.name == member.name &&
                  m.gender == member.gender &&
                  m.birth == member.birth,
            )
            .length >
        1;
  }

  Color _getRowBackgroundColor({
    required int index,
    required MemberItem member,
  }) {
    if (_highlightedMemberId == member.id) return const Color(0xFFDCEBFF);
    if (_isDuplicateMember(member)) return const Color(0xFFFFE3E3);
    if (_isSearchMatched(member)) return const Color(0xFFFFF6CC);
    return index.isEven ? Colors.white : const Color(0xFFF2F4F7);
  }

  Color _getRowBorderColor({required MemberItem member}) {
    if (_highlightedMemberId == member.id) return const Color(0xFF8CB8F2);
    if (_isDuplicateMember(member)) return const Color(0xFFE59A9A);
    if (_isSearchMatched(member)) return const Color(0xFFE4CF69);
    return const Color(0xFFD7DCE3);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleAll() {
    final visible = _filteredMembers;
    setState(() {
      final allSelected =
          visible.isNotEmpty &&
          visible.every((e) => _selectedIds.contains(e.id));

      if (allSelected) {
        _selectedIds.removeAll(visible.map((e) => e.id));
      } else {
        _selectedIds.addAll(visible.map((e) => e.id));
      }
    });
  }

  void _deleteSelected() {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '선택삭제',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '선택한 회원 ${_selectedIds.length}명을 삭제하시겠습니까?',
          style: const TextStyle(fontSize: 16, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _members.removeWhere((m) => _selectedIds.contains(m.id));
                if (_highlightedMemberId != null &&
                    _selectedIds.contains(_highlightedMemberId)) {
                  _highlightedMemberId = null;
                }
                _selectedIds.clear();
              });
              await _saveMembers();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRowMenu(MemberItem member) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C3C6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${member.name}(${member.gender})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                _BottomMenuTile(
                  icon: Icons.edit_outlined,
                  title: '회원정보 수정',
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
                _BottomMenuTile(
                  icon: Icons.delete_outline,
                  title: '회원 삭제',
                  textColor: Colors.red,
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'edit') {
      _showMemberDialog(editTarget: member);
    } else if (result == 'delete') {
      _deleteOne(member);
    }
  }

  void _deleteOne(MemberItem member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '회원 삭제',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        content: Text(
          '${member.name} 회원을 \n삭제하시겠습니까?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _members.removeWhere((m) => m.id == member.id);
                _selectedIds.remove(member.id);
                if (_highlightedMemberId == member.id) {
                  _highlightedMemberId = null;
                }
              });
              await _saveMembers();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog({MemberItem? editTarget}) {
    final isEdit = editTarget != null;

    final nameController = TextEditingController(text: editTarget?.name ?? '');
    final birthController = TextEditingController(
      text: editTarget?.birth ?? '',
    );
    final phoneController = TextEditingController(
      text: editTarget?.phone ?? '',
    );
    final addressController = TextEditingController(
      text: editTarget?.address ?? '',
    );

    String gender = editTarget?.gender ?? '남';
    String grade = editTarget?.grade ?? 'A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFFF4F5FA),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? '정보수정' : '회원등록',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _DialogSectionLabel('이름'),
                                const SizedBox(height: 6),
                                _DialogTextField(
                                  controller: nameController,
                                  hintText: '입력',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _DialogSectionLabel('성별'),
                                const SizedBox(height: 6),
                                _DialogDropdownBox(
                                  value: gender,
                                  items: const ['남', '여'],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setDialogState(() => gender = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _DialogSectionLabel('생년월일 6자리'),
                                const SizedBox(height: 6),
                                _DialogTextField(
                                  controller: birthController,
                                  hintText: '예: 980101',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _DialogSectionLabel('급수'),
                                const SizedBox(height: 6),
                                _DialogDropdownBox(
                                  value: grade,
                                  items: const ['A', 'B', 'C', 'D', '초심'],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setDialogState(() => grade = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      const _DialogSectionLabel('전화번호'),
                      const SizedBox(height: 6),
                      _DialogTextField(
                        controller: phoneController,
                        hintText: '예: 010-0000-0000',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          PhoneNumberFormatter(),
                        ],
                      ),
                      const SizedBox(height: 10),

                      const _DialogSectionLabel('주소'),
                      const SizedBox(height: 6),
                      _DialogTextField(
                        controller: addressController,
                        hintText: '입력',
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4F5FA),
                                  side: const BorderSide(
                                    color: Color(0xFFB6BCC8),
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final birth = birthController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final address = addressController.text.trim();

                                  if (name.isEmpty ||
                                      birth.isEmpty ||
                                      phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '이름, 생년월일, 전화번호를 입력해주세요.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (!_isValidBirthDate(birth)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '생년월일 6자리를 올바르게 입력해주세요. 예: 700523',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (phone.length < 13) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '전화번호를 정확히 입력해주세요. 예: 010-1234-5678',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    if (isEdit) {
                                      final index = _members.indexWhere(
                                        (e) => e.id == editTarget.id,
                                      );
                                      if (index != -1) {
                                        _members[index] = editTarget.copyWith(
                                          name: name,
                                          gender: gender,
                                          grade: grade,
                                          birth: birth,
                                          phone: phone,
                                          address: address,
                                        );
                                      }
                                    } else {
                                      _members.add(
                                        MemberItem(
                                          name: name,
                                          gender: gender,
                                          grade: grade,
                                          birth: birth,
                                          phone: phone,
                                          address: address,
                                        ),
                                      );
                                    }
                                  });

                                  await _saveMembers();

                                  if (mounted) Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF5B8ABB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isEdit ? '저장' : '등록',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleMembers = _filteredMembers;
    final allSelected =
        visibleMembers.isNotEmpty &&
        visibleMembers.every((m) => _selectedIds.contains(m.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        surfaceTintColor: const Color(0xFFF6F7FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 34,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF111111),
          ),
        ),
        title: Text(
          clubMemberTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MemberExcelTools(onImportRows: _handleImportRows),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        width: 112,
        height: 44,
        child: FloatingActionButton(
          heroTag: 'member_fab',
          elevation: 2,
          backgroundColor: const Color(0xFFCFE1F8),
          foregroundColor: const Color(0xFF3F6D98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: () => _showMemberDialog(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 4),
              Text(
                '회원등록',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFD7E9F8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: const Text(
              '단체회원 등록은 샘플을 다운받아 양식에 맞게 작성.\n엑셀업로드 버튼으로 여러 명 한꺼번에 등록 가능',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: Color(0xFF222222),
                letterSpacing: -0.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _SearchBox(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _FilterBox(
                        label: '성별',
                        value: _selectedGender,
                        items: const ['전체', '남', '여'],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedGender = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _FilterBox(
                        label: '급수',
                        value: _selectedGrade,
                        items: const ['전체', 'A', 'B', 'C', 'D', '초심'],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedGrade = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _TopPillButton(
                      text: allSelected ? '전체해제' : '전체선택',
                      enabled: true,
                      onTap: _toggleAll,
                    ),
                    const SizedBox(width: 6),
                    _TopPillButton(
                      text: '선택삭제',
                      enabled: _selectedIds.isNotEmpty,
                      onTap: _deleteSelected,
                    ),
                    const SizedBox(width: 6),
                    _TopPillButton(
                      text: _ascending ? '이름정렬↑' : '이름정렬↓',
                      enabled: true,
                      onTap: () => setState(() => _ascending = !_ascending),
                    ),
                    const Spacer(),
                    Text(
                      '총 ${visibleMembers.length}명',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (visibleMembers.isEmpty)
                  Container(
                    height: 140,
                    alignment: Alignment.center,
                    child: const Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                  )
                else
                  ...visibleMembers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;

                    return _MemberRow(
                      member: member,
                      checked: _selectedIds.contains(member.id),
                      backgroundColor: _getRowBackgroundColor(
                        index: index,
                        member: member,
                      ),
                      borderColor: _getRowBorderColor(member: member),
                      onTap: () {
                        setState(() {
                          _highlightedMemberId =
                              _highlightedMemberId == member.id
                              ? null
                              : member.id;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(member.id);
                          } else {
                            _selectedIds.remove(member.id);
                          }
                        });
                      },
                      onMenuTap: () => _showRowMenu(member),
                      onPhoneTap: () => _makePhoneCall(member.phone),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 하위 위젯들
// ============================================================

class _MemberRow extends StatelessWidget {
  final MemberItem member;
  final bool checked;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onMenuTap;
  final VoidCallback onPhoneTap;

  const _MemberRow({
    required this.member,
    required this.checked,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.onChanged,
    required this.onMenuTap,
    required this.onPhoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onChanged,
                visualDensity: const VisualDensity(
                  horizontal: -3.5,
                  vertical: -3.5,
                ),
                side: const BorderSide(color: Color(0xFF666D76), width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: member.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: ' (${member.gender})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111111),
                              letterSpacing: -0.2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: ' ${member.birth}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A8A8A),
                              letterSpacing: -0.1,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),

                    Row(
                      children: [
                        Text(
                          '급수: ${member.grade}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: -0.1,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onPhoneTap,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 13,
                                  color: Color(0xFF3A7BD5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    member.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3A7BD5),
                                      height: 1.0,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF3A7BD5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  onPressed: onMenuTap,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _BottomMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? const Color(0xFF222222);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  final String text;
  const _DialogSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF6A6A6A),
        letterSpacing: -0.2,
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _DialogTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF222222),
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB3B8C1),
            letterSpacing: -0.2,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB8BEC9), width: 1.35),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8F98A8), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DialogDropdownBox extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DialogDropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8BEC9), width: 1.35),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: Color(0xFF666666),
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF111111),
            letterSpacing: -0.2,
          ),
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: '이름',
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A7A7A),
            letterSpacing: -0.2,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF7A7A7A),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF9AA1AB), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7F8794), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterBox({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9AA1AB), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: Color(0xFF666666),
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((e) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -4,
                    left: 0,
                    child: Container(
                      color: const Color(0xFFF9FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7B7F86),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

class _TopPillButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const _TopPillButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled
        ? const Color(0xFF95A0AD)
        : const Color(0xFFD2D7DF);
    final textColor = enabled
        ? const Color(0xFF53759B)
        : const Color(0xFFC2C7D0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
