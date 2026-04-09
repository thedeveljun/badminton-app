import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// finance_models.dart
// 유틸 함수 + 데이터 모델 + 저장소
// ============================================================

// ── 유틸 함수 ─────────────────────────────────────────────────

String fmtAmt(int n) {
  if (n == 0) return '0원';
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf}원' : '${buf}원';
}

String fmtKorean(int n) {
  if (n == 0) return '영원';
  final prefix = n < 0 ? '마이너스 ' : '';
  final abs = n.abs();
  const ones = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];
  const units = ['', '십', '백', '천'];
  const big = ['', '만', '억', '조'];

  String convertGroup(int num) {
    if (num == 0) return '';
    var result = '';
    for (int i = 3; i >= 0; i--) {
      final d = (num ~/ [1, 10, 100, 1000][i]) % 10;
      if (d == 0) continue;
      result += (d == 1 && i > 0) ? units[i] : ones[d] + units[i];
    }
    return result;
  }

  var result = '';
  for (int i = 3; i >= 0; i--) {
    final divisor = [1, 10000, 100000000, 1000000000000][i];
    final group = (abs ~/ divisor) % 10000;
    if (group == 0) continue;
    result += convertGroup(group) + big[i];
  }
  return '$prefix${result}원';
}

String todayStr() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

int calcAge(String birth) {
  if (birth.length < 6) return 0;
  final yy = int.tryParse(birth.substring(0, 2)) ?? 0;
  return DateTime.now().year - (yy >= 30 ? 1900 + yy : 2000 + yy);
}

String discountTypeLabel(String type) {
  switch (type) {
    case 'age':
      return '연령';
    case 'student':
      return '학생';
    case 'free':
      return '무료';
    default:
      return '일반';
  }
}

// ── 데이터 모델 ──────────────────────────────────────────────

class DuesRecord {
  final String memberId;
  final String memberName;
  final String memberBirth;
  bool isPaid;
  int amount;
  bool hasDiscount;
  String paidDate;
  String memo;

  /// none / age / student / free
  String discountType;

  DuesRecord({
    required this.memberId,
    required this.memberName,
    this.memberBirth = '',
    this.isPaid = false,
    this.amount = 0,
    this.hasDiscount = false,
    this.paidDate = '',
    this.memo = '',
    this.discountType = 'none',
  });

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'memberName': memberName,
    'memberBirth': memberBirth,
    'isPaid': isPaid,
    'amount': amount,
    'hasDiscount': hasDiscount,
    'paidDate': paidDate,
    'memo': memo,
    'discountType': discountType,
  };

  factory DuesRecord.fromMap(Map<String, dynamic> map) => DuesRecord(
    memberId: map['memberId'] ?? '',
    memberName: map['memberName'] ?? '',
    memberBirth: map['memberBirth'] ?? '',
    isPaid: map['isPaid'] == true,
    amount: map['amount'] ?? 0,
    hasDiscount: map['hasDiscount'] == true,
    paidDate: map['paidDate'] ?? '',
    memo: map['memo'] ?? '',
    discountType: map['discountType'] ?? 'none',
  );
}

enum TransactionType { income, expense }

class Transaction {
  final String id;
  TransactionType type;
  String title;
  int amount;
  String date;
  String memo;

  Transaction({
    String? id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.memo = '',
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'amount': amount,
    'date': date,
    'memo': memo,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    type: map['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    title: map['title'] ?? '',
    amount: map['amount'] ?? 0,
    date: map['date'] ?? '',
    memo: map['memo'] ?? '',
  );
}

// ── 저장소 ────────────────────────────────────────────────────

class FinanceStorage {
  static const _duesKey = 'club_dues_v2';
  static const _txKey = 'club_transactions_v1';
  static const _defAmtKey = 'club_default_dues_amount';
  static const _ageDiscAmtKey = 'club_age_discount_dues_amount';
  static const _studentDiscAmtKey = 'club_student_discount_dues_amount';
  static const _discAgeKey = 'club_discount_age';

  static Future<void> saveDues(List<DuesRecord> r) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _duesKey,
      r.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  static Future<List<DuesRecord>> loadDues() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_duesKey) ?? [])
          .map((s) => DuesRecord.fromMap(jsonDecode(s)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTx(List<Transaction> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _txKey,
      list.map((t) => jsonEncode(t.toMap())).toList(),
    );
  }

  static Future<List<Transaction>> loadTx() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_txKey) ?? [])
          .map((s) => Transaction.fromMap(jsonDecode(s)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDefaultAmt(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_defAmtKey, v);

  static Future<int> loadDefaultAmt() async =>
      (await SharedPreferences.getInstance()).getInt(_defAmtKey) ?? 10000;

  static Future<void> saveAgeDiscountAmt(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_ageDiscAmtKey, v);

  static Future<int> loadAgeDiscountAmt() async =>
      (await SharedPreferences.getInstance()).getInt(_ageDiscAmtKey) ?? 5000;

  static Future<void> saveStudentDiscountAmt(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_studentDiscAmtKey, v);

  static Future<int> loadStudentDiscountAmt() async =>
      (await SharedPreferences.getInstance()).getInt(_studentDiscAmtKey) ??
      5000;

  static Future<void> saveDiscountAge(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_discAgeKey, v);

  static Future<int> loadDiscountAge() async =>
      (await SharedPreferences.getInstance()).getInt(_discAgeKey) ?? 70;
}

// ── 공통 소형 위젯 ────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const StatusChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: '$count명',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class AmountSummaryBlock extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const AmountSummaryBlock({
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.9),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        fmtAmt(amount),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.4,
          height: 1.1,
        ),
        maxLines: 2,
        softWrap: true,
      ),
    ],
  );
}

class FilterPill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    if (!selected) {
      bg = const Color(0xFFF0F4FA);
      border = const Color(0xFFCDD5DF);
      fg = const Color(0xFF888888);
    } else if (text == '납부') {
      bg = const Color(0xFFE8F5EE);
      border = const Color(0xFF4A9E6B);
      fg = const Color(0xFF2A6A2A);
    } else if (text == '미납') {
      bg = const Color(0xFFFFEEEE);
      border = const Color(0xFFB05B5B);
      fg = const Color(0xFF8A3030);
    } else {
      bg = const Color(0xFFEEF4FB);
      border = const Color(0xFF5B8ABB);
      fg = const Color(0xFF2A4A7C);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border, width: selected ? 1.4 : 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class DlgField extends StatelessWidget {
  final String label;
  final Widget child;

  const DlgField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6A6A6A),
        ),
      ),
      const SizedBox(height: 3),
      child,
    ],
  );
}

class AmountTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const AmountTextField({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  State<AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<AmountTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_format);
  }

  void _format() {
    final raw = widget.controller.text.replaceAll(',', '');
    final n = int.tryParse(raw);
    if (n == null) return;

    final formatted = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    if (widget.controller.text != formatted) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_format);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111111),
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB3B8C1)),
        suffixText: '원',
        suffixStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB8BEC9), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5B8ABB), width: 1.5),
        ),
      ),
    ),
  );
}

InputDecoration financeInputDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB3B8C1)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  filled: true,
  fillColor: Colors.white,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFB8BEC9), width: 1.2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF8F98A8), width: 1.5),
  ),
);
