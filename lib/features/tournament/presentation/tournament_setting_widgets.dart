import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../members/domain/models/member_item.dart';
import 'tournament_models.dart';

class TournamentTabBtn extends StatelessWidget {
  final String label, badge;
  final bool selected;
  final VoidCallback onTap;
  const TournamentTabBtn({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = '',
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF5B8ABB) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? const Color(0xFF2A5A8A)
                    : const Color(0xFF444444),
              ),
            ),
            if (badge.isNotEmpty)
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF2A5A8A)
                      : const Color(0xFF666666),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class SettingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const SettingSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5B8ABB)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

// ── 공통 숫자 입력 위젯 ───────────────────────────────────
class _NumberInputBox extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;
  final String? hintText;

  const _NumberInputBox({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<_NumberInputBox> createState() => _NumberInputBoxState();
}

class _NumberInputBoxState extends State<_NumberInputBox> {
  late TextEditingController _ctrl;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _validate();
    });
  }

  @override
  void didUpdateWidget(_NumberInputBox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_focus.hasFocus) {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _validate() {
    final v = int.tryParse(_ctrl.text) ?? widget.value;
    final clamped = v.clamp(widget.min, widget.max);
    _ctrl.text = '$clamped';
    widget.onChanged(clamped);
  }

  void _dec() {
    final v = (widget.value - 1).clamp(widget.min, widget.max);
    _ctrl.text = '$v';
    widget.onChanged(v);
  }

  void _inc() {
    final v = (widget.value + 1).clamp(widget.min, widget.max);
    _ctrl.text = '$v';
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 감소 버튼
        _CircleBtn(icon: Icons.remove, onTap: _dec),
        const SizedBox(width: 12),
        // 숫자 입력창
        SizedBox(
          width: 80,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A3F6F),
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
              suffix: Text(
                widget.unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B8ABB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF9BB5D0),
                  width: 1.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2A5A8A),
                  width: 2.2,
                ),
              ),
            ),
            onSubmitted: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 12),
        // 증가 버튼
        _CircleBtn(icon: Icons.add, onTap: _inc),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8CB8F2), width: 1.3),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: const Color(0xFF1A5CA8)),
    ),
  );
}

// ── 사용 코트 수 ─────────────────────────────────────────
class CourtSelector extends StatelessWidget {
  final int value, selectedCount;
  final ValueChanged<int> onChanged;
  const CourtSelector({
    super.key,
    required this.value,
    required this.selectedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rec = selectedCount > 0
        ? (selectedCount / 4).floor().clamp(1, 99)
        : 0;
    final isRec = rec > 0 && value == rec;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9BB5D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberInputBox(
                value: value,
                min: 1,
                max: 99,
                unit: '코트',
                onChanged: onChanged,
              ),
              const SizedBox(width: 14),
              if (rec > 0)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isRec
                          ? const Color(0xFFEAF5EA)
                          : const Color(0xFFFFF8E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isRec
                            ? const Color(0xFF8BC98B)
                            : const Color(0xFFE4C96A),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRec ? '✓ 권장 코트' : '권장 코트',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isRec
                                ? const Color(0xFF2A6A2A)
                                : const Color(0xFF8A6500),
                          ),
                        ),
                        Text(
                          '$rec코트',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isRec
                                ? const Color(0xFF2A6A2A)
                                : const Color(0xFF8A6500),
                          ),
                        ),
                        Text(
                          '4명당 1코트',
                          style: TextStyle(
                            fontSize: 10,
                            color: isRec
                                ? const Color(0xFF3A8A3A)
                                : const Color(0xFFB08A00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedCount > 0
                ? '$selectedCount명 기준 권장: $rec코트  (4명당 1코트)'
                : '참가자를 먼저 선택하면 권장 코트 수 표시.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1인당 경기 수 ─────────────────────────────────────────
class GamesPerPlayerSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const GamesPerPlayerSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9BB5D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberInputBox(
                value: value,
                min: 1,
                max: 20,
                unit: '게임',
                onChanged: onChanged,
              ),
              const SizedBox(width: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '선택: 1인당 $value 게임 진행 예정',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundOptionCard extends StatelessWidget {
  final RoundType type;
  final bool selected;
  final VoidCallback onToggle;
  const RoundOptionCard({
    super.key,
    required this.type,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? type.color.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? type.color : const Color(0xFFD4D8DE),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? type.color : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? type.color : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CourtRecommendBanner extends StatelessWidget {
  final int selected, courtCount;
  final VoidCallback onGoSetting;
  const CourtRecommendBanner({
    super.key,
    required this.selected,
    required this.courtCount,
    required this.onGoSetting,
  });

  @override
  Widget build(BuildContext context) {
    final rec = (selected / 4).floor().clamp(1, 99);
    final ok = courtCount == rec;
    return GestureDetector(
      onTap: onGoSetting,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFEAF5EA) : const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ok ? const Color(0xFF8BC98B) : const Color(0xFFE4C96A),
          ),
        ),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.info_outline,
              size: 14,
              color: ok ? const Color(0xFF3A8A3A) : const Color(0xFFB08A00),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ok
                    ? '$selected명 참가\n현재 $courtCount코트 (권장 $rec코트)'
                    : '$selected명 참가 → 권장 $rec코트\n현재 $courtCount코트',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ok ? const Color(0xFF2A6A2A) : const Color(0xFF8A6500),
                ),
              ),
            ),
            Text(
              '설정 →',
              style: TextStyle(
                fontSize: 11,
                color: ok ? const Color(0xFF3A8A3A) : const Color(0xFFB08A00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradeSectionHeader extends StatelessWidget {
  final String grade;
  final int total, selected;
  const GradeSectionHeader({
    super.key,
    required this.grade,
    required this.total,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF5B8ABB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$grade조',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '$selected / $total명 선택',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF444444),
        ),
      ),
    ],
  );
}

class MemberCheckRow extends StatelessWidget {
  final MemberItem member;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  const MemberCheckRow({
    super.key,
    required this.member,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!checked),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFEAF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: checked ? const Color(0xFF8CB8F2) : const Color(0xFFD4D8DE),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            side: const BorderSide(color: Color(0xFF666D76), width: 1.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: member.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '  (${member.gender})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  TextSpan(
                    text: '  ${tournamentAge(member)}세',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFB8D0EC)),
            ),
            child: Text(
              member.grade,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3F6D98),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SelectionCountBadge extends StatelessWidget {
  final int count;
  const SelectionCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final ok = count >= 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFDCEBFF) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok ? const Color(0xFF8CB8F2) : const Color(0xFFD2D7DF),
        ),
      ),
      child: Text(
        '선택 $count명',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ok ? const Color(0xFF1A5CA8) : const Color(0xFF888888),
        ),
      ),
    );
  }
}

class TournamentPill extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;
  const TournamentPill({
    super.key,
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: enabled ? onTap : null,
    child: Container(
      height: 30,
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: enabled ? const Color(0xFF53759B) : const Color(0xFFC2C7D0),
        ),
      ),
    ),
  );
}
