import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/member_item.dart';
import '../../utils/phone_number_formatter.dart';

class MemberFormDialog extends StatefulWidget {
  final String title;
  final MemberItem? initialMember;

  const MemberFormDialog({super.key, required this.title, this.initialMember});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _birthController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  late String _gender;
  late String _grade;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialMember?.name ?? '',
    );
    _birthController = TextEditingController(
      text: widget.initialMember?.birth ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialMember?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialMember?.address ?? '',
    );

    _gender = widget.initialMember?.gender ?? '남';
    _grade = widget.initialMember?.grade ?? 'A';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isValidBirth(String value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return false;

    final yy = int.tryParse(value.substring(0, 2));
    final mm = int.tryParse(value.substring(2, 4));
    final dd = int.tryParse(value.substring(4, 6));

    if (yy == null || mm == null || dd == null) return false;
    if (mm < 1 || mm > 12) return false;
    if (dd < 1) return false;

    final fullYear = yy >= 30 ? 1900 + yy : 2000 + yy;

    try {
      final date = DateTime(fullYear, mm, dd);
      return date.year == fullYear && date.month == mm && date.day == dd;
    } catch (_) {
      return false;
    }
  }

  bool _isValidPhone(String value) {
    return RegExp(r'^010-\d{4}-\d{4}$').hasMatch(value);
  }

  void _save() {
    final name = _nameController.text.trim();
    final birth = _birthController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showError('이름을 입력해주세요.');
      return;
    }

    if (!_isValidBirth(birth)) {
      _showError('생년월일 6자리를 정확히 입력해주세요. 예: 901225');
      return;
    }

    if (!_isValidPhone(phone)) {
      _showError('전화번호를 정확히 입력해주세요. 예: 010-1004-0000');
      return;
    }

    final member =
        (widget.initialMember ??
                MemberItem(
                  name: '',
                  gender: '남',
                  birth: '',
                  grade: 'A',
                  phone: '',
                ))
            .copyWith(
              name: name,
              gender: _gender,
              birth: birth,
              grade: _grade,
              phone: phone,
              address: address,
            );

    Navigator.pop(context, member);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 74,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9AA0A6), width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4E79A7), width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9AA0A6), width: 1.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 22),
              _buildTextField(
                controller: _nameController,
                hintText: '이름',
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[가-힣a-zA-Z\s]')),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _birthController,
                hintText: '생년월일',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _phoneController,
                hintText: '전화번호',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  PhoneNumberFormatter(),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _addressController,
                hintText: '주소',
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 14),
              _buildDropdown(
                label: '성별',
                value: _gender,
                items: const ['남', '여'],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _gender = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildDropdown(
                label: '급수',
                value: _grade,
                items: const ['A', 'B', 'C', 'D', '초심'],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _grade = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4E79A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _save,
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4E79A7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
