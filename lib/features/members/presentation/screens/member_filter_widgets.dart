import 'package:flutter/material.dart';

// ============================================================
// member_filter_widgets.dart — 검색·필터·버튼 소형 위젯
// ============================================================

// ── 검색 박스 ─────────────────────────────────────────────────
class MemberSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MemberSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF222222),
        ),
        decoration: InputDecoration(
          hintText: '이름 검색',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA1AB)),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF9AA1AB),
          ),
          filled: true,
          fillColor: const Color(0xFFF6F7FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD4D8DE), width: 1.1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5B8ABB), width: 1.4),
          ),
        ),
      ),
    );
  }
}

// ── 필터 드롭다운 ─────────────────────────────────────────────
class MemberFilterBox extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const MemberFilterBox({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4D8DE), width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: Color(0xFF9AA1AB),
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
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B8ABB),
                        height: 1.0,
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

// ── 필 버튼 ──────────────────────────────────────────────────
class MemberPillButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const MemberPillButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFF95A0AD) : const Color(0xFFD2D7DF),
            width: 1.1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF53759B) : const Color(0xFFC2C7D0),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
