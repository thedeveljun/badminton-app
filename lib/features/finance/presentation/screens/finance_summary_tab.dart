import 'package:flutter/material.dart';
import 'finance_models.dart';

/// 숫자를 한글로 (팔백삼십육만이천원)
String _toKoreanFull(int amount) {
  if (amount == 0) return '영원';
  final units = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];
  final pos = ['', '십', '백', '천'];
  final bigPos = ['', '만', '억', '조'];
  String result = '';
  int bigIdx = 0;
  int n = amount.abs();
  while (n > 0) {
    final chunk = n % 10000;
    if (chunk != 0) {
      String chunkStr = '';
      int c = chunk;
      for (int i = 0; c > 0; i++) {
        final digit = c % 10;
        if (digit != 0) {
          final d = (digit == 1 && i > 0) ? '' : units[digit];
          chunkStr = '$d${pos[i]}$chunkStr';
        }
        c ~/= 10;
      }
      result = '$chunkStr${bigPos[bigIdx]}$result';
    }
    bigIdx++;
    n ~/= 10000;
  }
  if (amount < 0) result = '마이너스$result';
  return '${result}원';
}

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
        PeriodSelector(
          current: summaryPeriod,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: 12),

        // 현재 잔액 박스
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 12, 37, 102),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                '현재 잔액',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fmtAmt(balance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _toKoreanFull(balance),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  letterSpacing: -0.2,
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
                color: const Color(0xFF217D46),
                bgColor: const Color(0xFFEAF5EE),
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryAmtCard(
                label: '총 지출',
                amount: expense,
                color: const Color(0xFFB05B5B),
                bgColor: const Color(0xFFFFF0F0),
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          '월별 수입/지출',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
            letterSpacing: -0.3,
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

class SummaryAmtCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const SummaryAmtCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3), width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            fmtAmt(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

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
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E4EC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
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
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          fmtAmt(amount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ),
    ],
  );
}

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
      padding: const EdgeInsets.all(14),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
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
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: current == p
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          if (current == '직접선택') ...[
            const SizedBox(height: 8),
            Text(
              rangeLabel,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5B8ABB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (current == '이번달') ...[
            const SizedBox(height: 8),
            Text(
              '${rangeStart.year}년 ${rangeStart.month}월',
              style: const TextStyle(
                fontSize: 13,
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
