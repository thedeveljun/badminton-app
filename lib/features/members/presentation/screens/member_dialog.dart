import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/member_item.dart';
import '../../utils/phone_number_formatter.dart';

// ============================================================
// member_dialog.dart — 회원 등록 / 수정 다이얼로그
// ============================================================

class MemberDialog extends StatefulWidget {
  final MemberItem? editTarget; // null이면 등록, 있으면 수정
  final void Function(MemberItem) onSave;

  const MemberDialog({super.key, this.editTarget, required this.onSave});

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _birthCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late String _gender;
  late String _grade;

  bool get _isEdit => widget.editTarget != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editTarget;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _birthCtrl = TextEditingController(text: e?.birth ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _gender = e?.gender ?? '남';
    _grade = e?.grade ?? 'A';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _isValidBirthDate(String value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return false;
    final yy = int.parse(value.substring(0, 2));
    final mm = int.parse(value.substring(2, 4));
    final dd = int.parse(value.substring(4, 6));
    if (mm < 1 || mm > 12 || dd < 1) return false;
    final year = yy >= 30 ? 1900 + yy : 2000 + yy;
    try {
      final date = DateTime(year, mm, dd);
      return date.year == year && date.month == mm && date.day == dd;
    } catch (_) {
      return false;
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final birth = _birthCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isEmpty || birth.isEmpty || phone.isEmpty) {
      _snack('이름, 생년월일, 전화번호를 입력해주세요.');
      return;
    }
    if (!_isValidBirthDate(birth)) {
      _snack('생년월일 6자리를 올바르게 입력해주세요. 예: 700523');
      return;
    }
    if (phone.length < 13) {
      _snack('전화번호를 정확히 입력해주세요. 예: 010-1234-5678');
      return;
    }

    final saved = _isEdit
        ? widget.editTarget!.copyWith(
            name: name,
            gender: _gender,
            grade: _grade,
            birth: birth,
            phone: phone,
            address: address,
          )
        : MemberItem(
            name: name,
            gender: _gender,
            grade: _grade,
            birth: birth,
            phone: phone,
            address: address,
          );

    widget.onSave(saved);
    Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF4F5FA),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: StatefulBuilder(
            builder: (context, setDlg) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  _isEdit ? '정보수정' : '회원등록',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 16),

                // 이름 + 성별
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        '이름',
                        _MemberTextField(controller: _nameCtrl, hintText: '입력'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        '성별',
                        _MemberDropdown(
                          value: _gender,
                          items: const ['남', '여'],
                          onChanged: (v) {
                            if (v == null) return;
                            setDlg(() => _gender = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 생년월일 + 급수
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        '생년월일 6자리',
                        _MemberTextField(
                          controller: _birthCtrl,
                          hintText: '예: 980101',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        '급수',
                        _MemberDropdown(
                          value: _grade,
                          items: const ['A', 'B', 'C', 'D', '초심'],
                          onChanged: (v) {
                            if (v == null) return;
                            setDlg(() => _grade = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 전화번호
                _field(
                  '전화번호',
                  _MemberTextField(
                    controller: _phoneCtrl,
                    hintText: '예: 010-0000-0000',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      PhoneNumberFormatter(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 주소
                _field(
                  '주소',
                  _MemberTextField(controller: _addressCtrl, hintText: '입력'),
                ),
                const SizedBox(height: 16),

                // 취소 / 저장 버튼
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
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF5B8ABB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isEdit ? '저장' : '등록',
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
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6A6A6A),
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

// ── 텍스트 필드 ───────────────────────────────────────────────
class _MemberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _MemberTextField({
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

// ── 드롭다운 ──────────────────────────────────────────────────
class _MemberDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MemberDropdown({
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
