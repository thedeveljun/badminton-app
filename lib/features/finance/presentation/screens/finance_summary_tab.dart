import 'package:flutter/material.dart';
import 'finance_models.dart';

// ============================================================
// finance_summary_tab.dart — 요약 탭
// ============================================================

class SummaryTab extends StatelessWidget {
  final List<Transaction> transactions;
  final String summaryPeriod;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final void Function(String, DateTime?, DateTime?) onPeriodChanged;

  const SummaryTab({
    super.key,
    required this.transactions,
    required this.summaryPeriod,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onPeriodChanged,
  });

  List<Transaction> get _filteredTx {
    if (summaryPeriod == '전체') return transactions;
    return transactions.where((t) {
      try {
        final d = DateTime.parse(t.date);
        return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  int get _income => _filteredTx
      .where((t) => t.type == TransactionType.income)
      .fold(0, (int s, t) => s + t.amount);

  int get _expense => _filteredTx
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (int s, t) => s + t.amount);

  int get _balance => _income - _expense;

  @override
  Widget build(BuildContext context) {
    final income = _income;
    final expense = _expense;
    final balance = _balance;

    final Map<String, int> monthlyIncome = {};
    final Map<String, int> monthlyExpense = {};

    for (final t in _filteredTx) {
      if (t.date.length < 7) continue;
      final ym = t.date.substring(0, 7);
      if (t.type == TransactionType.income) {
        monthlyIncome[ym] = (monthlyIncome[ym] ?? 0) + t.amount;
      } else {
        monthlyExpense[ym] = (monthlyExpense[ym] ?? 0) + t.amount;
      }
    }

    final months = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // 기간 선택
        PeriodSelector(
          current: summaryPeriod,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: 12),

        // 현재 잔액 카드
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 12, 37, 102),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                '현재 잔액',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                fmtAmt(balance),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                fmtKorean(balance),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 총 수입 / 총 지출 카드
        Row(
          children: [
            Expanded(
              child: SummaryAmtCard(
                label: '총 수입',
                amount: income,
                color: const Color.fromARGB(255, 33, 125, 70),
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryAmtCard(
                label: '총 지출',
                amount: expense,
                color: const Color(0xFFB05B5B),
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 월별 수입/지출
        const Text(
          '월별 수입/지출',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),

        if (months.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E4EC)),
            ),
            child: const Text(
              '선택한 기간의 내역이 없습니다.',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
          )
        else
          ...months.map((ym) {
            final inc = monthlyIncome[ym] ?? 0;
            final exp = monthlyExpense[ym] ?? 0;
            final bal = inc - exp;
            final parts = ym.split('-');
            return MonthlyRow(
              label: '${parts[0]}년 ${int.parse(parts[1])}월',
              income: inc,
              expense: exp,
              balance: bal,
            );
          }),
      ],
    );
  }
}

// ── 총수입/지출 카드 ──────────────────────────────────────────
class SummaryAmtCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const SummaryAmtCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          fmtAmt(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ── 월별 행 ───────────────────────────────────────────────────
class MonthlyRow extends StatelessWidget {
  final String label;
  final int income, expense, balance;

  const MonthlyRow({
    super.key,
    required this.label,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE0E4EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: MonthItem(
                label: '수입',
                amount: income,
                color: const Color(0xFF4A9E6B),
              ),
            ),
            Expanded(
              child: MonthItem(
                label: '지출',
                amount: expense,
                color: const Color(0xFFB05B5B),
              ),
            ),
            Expanded(
              child: MonthItem(
                label: '잔액',
                amount: balance,
                color: balance >= 0
                    ? const Color(0xFF1A3A5C)
                    : const Color(0xFFB05B5B),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class MonthItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const MonthItem({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.7),
        ),
      ),
      Text(
        fmtAmt(amount),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

// ── 기간 선택 ─────────────────────────────────────────────────
class PeriodSelector extends StatelessWidget {
  final String current;
  final DateTime rangeStart, rangeEnd;
  final void Function(String, DateTime?, DateTime?) onChanged;

  const PeriodSelector({
    super.key,
    required this.current,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        '${rangeStart.year}.${rangeStart.month.toString().padLeft(2, '0')} ~ '
        '${rangeEnd.year}.${rangeEnd.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기간 선택',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final p in ['전체', '이번달', '직접선택']) ...[
                GestureDetector(
                  onTap: () async {
                    if (p == '직접선택') {
                      final range = await showDateRangePicker(
                        context: context,
                        initialDateRange: DateTimeRange(
                          start: rangeStart,
                          end: rangeEnd,
                        ),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (range != null) onChanged(p, range.start, range.end);
                    } else if (p == '이번달') {
                      final now = DateTime.now();
                      onChanged(
                        p,
                        DateTime(now.year, now.month, 1),
                        DateTime(now.year, now.month + 1, 0),
                      );
                    } else {
                      onChanged(p, null, null);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: current == p
                          ? const Color(0xFF5B8ABB)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: current == p
                            ? const Color(0xFF5B8ABB)
                            : const Color(0xFFD5DAE1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: current == p
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
          if (current == '직접선택') ...[
            const SizedBox(height: 6),
            Text(
              rangeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5B8ABB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (current == '이번달') ...[
            const SizedBox(height: 10),
            Text(
              '${rangeStart.year}년 ${rangeStart.month}월',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5B8ABB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
