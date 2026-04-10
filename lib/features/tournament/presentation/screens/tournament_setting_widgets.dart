import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';
import 'tournament_models.dart';

// ── 탭 버튼 ─────────────────────────────────────────────────
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
        height: 44,
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
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? const Color(0xFF5B8ABB)
                    : const Color(0xFF888888),
              ),
            ),
            if (badge.isNotEmpty)
              Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? const Color(0xFF5B8ABB)
                      : const Color(0xFFAAAAAA),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// ── 설정 섹션 헤더 ───────────────────────────────────────────
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

// ── 코트 수 선택 ─────────────────────────────────────────────
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
        ? (selectedCount / 4).floor().clamp(1, 10)
        : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4D8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(10, (i) {
              final n = i + 1;
              final isSel = value == n;
              final isRec = n == rec;
              return GestureDetector(
                onTap: () => onChanged(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF5B8ABB)
                        : isRec
                        ? const Color(0xFFEEF4FB)
                        : const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF5B8ABB)
                          : isRec
                          ? const Color(0xFF8CB8F2)
                          : const Color(0xFFD4D8DE),
                      width: isSel || isRec ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                      if (isRec)
                        Text(
                          '권장',
                          style: TextStyle(
                            fontSize: 9,
                            color: isSel
                                ? Colors.white70
                                : const Color(0xFF5B8ABB),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            selectedCount > 0
                ? '$selectedCount명 기준 권장: ${rec}코트  (4명당 1코트)'
                : '참가자를 먼저 선택하면 권장 코트 수가 표시됩니다.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ── 1인당 게임 수 ────────────────────────────────────────────
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4D8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(5, (i) {
              final n = i + 1;
              final isSel = value == n;
              return GestureDetector(
                onTap: () => onChanged(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 68,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF5B8ABB)
                        : const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF5B8ABB)
                          : const Color(0xFFD4D8DE),
                      width: isSel ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$n 게임',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '선택: 1인당 $value게임 진행',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ── 라운드 유형 카드 ─────────────────────────────────────────
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
        color: selected ? type.color.withValues(alpha: 0.07) : Colors.white,
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

// ── 라운드 미리보기 행 ───────────────────────────────────────
class RoundPreviewRow extends StatelessWidget {
  final int roundNum;
  final RoundType type;
  const RoundPreviewRow({
    super.key,
    required this.roundNum,
    required this.type,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: type.color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'R$roundNum',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            Text(
              type.desc,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── 코트 권장 배너 ───────────────────────────────────────────
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
    final rec = (selected / 4).floor().clamp(1, 10);
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
                    ? '$selected명 참가 → 현재 ${courtCount}코트 (권장 ${rec}코트)'
                    : '$selected명 참가 → 권장 ${rec}코트  |  현재 ${courtCount}코트',
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

// ── 급수별 요약 바 ───────────────────────────────────────────
class GradeSummaryBar extends StatelessWidget {
  final Map<String, List<MemberItem>> grouped;
  final Set<String> selectedIds;
  const GradeSummaryBar({
    super.key,
    required this.grouped,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    final grades = [
      'A',
      'B',
      'C',
      'D',
      '초심',
    ].where((g) => grouped.containsKey(g)).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8D0EC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: grades.map((grade) {
          final total = grouped[grade]?.length ?? 0;
          final sel =
              grouped[grade]?.where((m) => selectedIds.contains(m.id)).length ??
              0;
          return Column(
            children: [
              Text(
                '$grade급',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B8ABB),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$sel / $total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: sel > 0
                      ? const Color(0xFF111111)
                      : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 급수 섹션 헤더 ───────────────────────────────────────────
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
          '$grade급',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
          color: Color(0xFF888888),
        ),
      ),
    ],
  );
}

// ── 회원 체크 행 ─────────────────────────────────────────────
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFEAF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '  (${member.gender})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  TextSpan(
                    text: '  ${tournamentAge(member)}세',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF999999),
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
                fontSize: 12,
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

// ── 선택 인원 배지 ───────────────────────────────────────────
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

// ── 필 버튼 ─────────────────────────────────────────────────
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
