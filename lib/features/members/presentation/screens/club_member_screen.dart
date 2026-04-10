import 'package:flutter/material.dart';
import 'package:funminton_club_app/features/members/presentation/widgets/member_excel_tools.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/member_item.dart';
import '../../utils/member_storage.dart';
import 'member_row.dart';
import 'member_dialog.dart';
import 'member_filter_widgets.dart';

// ============================================================
// club_member_screen.dart — 회원 목록 메인 화면
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
  String get _title => '${clubName}회원';

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedGender = '전체';
  String _selectedGrade = '전체';
  bool _ascending = true;
  String? _highlightedId;
  bool _isLoading = true;

  final List<MemberItem> _members = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _saveMembers() => MemberStorage.saveMembers(_members);

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

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll('-', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$phone 전화 연결에 실패했습니다.')));
    }
  }

  List<MemberItem> get _filtered {
    List<MemberItem> result = [..._members];
    final kw = _searchCtrl.text.trim();
    if (kw.isNotEmpty)
      result = result.where((m) => m.name.contains(kw)).toList();
    if (_selectedGender != '전체')
      result = result.where((m) => m.gender == _selectedGender).toList();
    if (_selectedGrade != '전체')
      result = result.where((m) => m.grade == _selectedGrade).toList();
    result.sort(
      (a, b) =>
          _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
    );
    return result;
  }

  bool _isDuplicate(MemberItem m) =>
      _members
          .where(
            (e) =>
                e.name == m.name && e.gender == m.gender && e.birth == m.birth,
          )
          .length >
      1;

  bool _isSearchMatch(MemberItem m) {
    final kw = _searchCtrl.text.trim();
    return kw.isNotEmpty && m.name.contains(kw);
  }

  Color _rowBg(int i, MemberItem m) {
    if (_highlightedId == m.id) return const Color(0xFFDCEBFF);
    if (_isDuplicate(m)) return const Color(0xFFFFE3E3);
    if (_isSearchMatch(m)) return const Color(0xFFFFF6CC);
    return i.isEven ? Colors.white : const Color(0xFFF2F4F7);
  }

  Color _rowBorder(MemberItem m) {
    if (_highlightedId == m.id) return const Color(0xFF8CB8F2);
    if (_isDuplicate(m)) return const Color(0xFFE59A9A);
    if (_isSearchMatch(m)) return const Color(0xFFE4CF69);
    return const Color(0xFFD7DCE3);
  }

  void _toggleAll() {
    final visible = _filtered;
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
                if (_highlightedId != null &&
                    _selectedIds.contains(_highlightedId)) {
                  _highlightedId = null;
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
                if (_highlightedId == member.id) _highlightedId = null;
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
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${member.name}(${member.gender})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context, 'edit'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: Color(0xFF222222),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '회원정보 수정',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context, 'delete'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 19, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        '회원 삭제',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F5FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'edit') _showMemberDialog(editTarget: member);
    if (result == 'delete') _deleteOne(member);
  }

  void _showMemberDialog({MemberItem? editTarget}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MemberDialog(
        editTarget: editTarget,
        onSave: (saved) {
          setState(() {
            if (editTarget != null) {
              final idx = _members.indexWhere((e) => e.id == editTarget.id);
              if (idx != -1) _members[idx] = saved;
            } else {
              _members.add(saved);
            }
          });
          _saveMembers();
        },
      ),
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

    final visible = _filtered;
    final allSelected =
        visible.isNotEmpty && visible.every((m) => _selectedIds.contains(m.id));

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
          _title,
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
            color: const Color.fromARGB(255, 16, 42, 98),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: const Text(
              '단체회원 등록은 샘플을 다운받아 양식에 맞게 작성.\n엑셀업로드 버튼으로 여러 명 한꺼번에 등록 가능',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                height: 1.3,
                color: Color.fromARGB(255, 255, 254, 254),
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
                      child: MemberSearchBox(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: MemberFilterBox(
                        label: '성별',
                        value: _selectedGender,
                        items: const ['전체', '남', '여'],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedGender = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: MemberFilterBox(
                        label: '급수',
                        value: _selectedGrade,
                        items: const ['전체', 'A', 'B', 'C', 'D', '초심'],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedGrade = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MemberPillButton(
                      text: allSelected ? '전체해제' : '전체선택',
                      enabled: true,
                      onTap: _toggleAll,
                    ),
                    const SizedBox(width: 6),
                    MemberPillButton(
                      text: '선택삭제',
                      enabled: _selectedIds.isNotEmpty,
                      onTap: _deleteSelected,
                    ),
                    const SizedBox(width: 6),
                    MemberPillButton(
                      text: _ascending ? '이름정렬↑' : '이름정렬↓',
                      enabled: true,
                      onTap: () => setState(() => _ascending = !_ascending),
                    ),
                    const Spacer(),
                    Text(
                      '총 ${visible.length}명',
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
                if (visible.isEmpty)
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
                  ...visible.asMap().entries.map((e) {
                    final i = e.key;
                    final member = e.value;
                    return MemberRow(
                      member: member,
                      checked: _selectedIds.contains(member.id),
                      backgroundColor: _rowBg(i, member),
                      borderColor: _rowBorder(member),
                      onTap: () => setState(() {
                        _highlightedId = _highlightedId == member.id
                            ? null
                            : member.id;
                      }),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedIds.add(member.id);
                        } else {
                          _selectedIds.remove(member.id);
                        }
                      }),
                      onMenuTap: () => _showRowMenu(member),
                      onPhoneTap: () => _call(member.phone),
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
