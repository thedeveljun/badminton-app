import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fmtAmt(int amount) {
  if (amount == 0) return '0원';
  final abs = amount.abs();
  final s = abs.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return amount < 0 ? '-${buf.toString()}원' : '${buf.toString()}원';
}

String fmtKorean(int amount) {
  if (amount == 0) return '0원';
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 100000000) {
    final eok = abs ~/ 100000000;
    final man = (abs % 100000000) ~/ 10000;
    if (man == 0) return '$sign$eok억';
    return '$sign$eok억 $man만';
  } else if (abs >= 10000) {
    final man = abs ~/ 10000;
    final rest = abs % 10000;
    if (rest == 0) return '$sign$man만원';
    return '$sign$man만 ${rest}원';
  }
  return fmtAmt(amount);
}

String todayStr() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

int calcAge(String birthYYMMDD) {
  if (birthYYMMDD.length != 6) return 0;
  try {
    final yy = int.parse(birthYYMMDD.substring(0, 2));
    final mm = int.parse(birthYYMMDD.substring(2, 4));
    final dd = int.parse(birthYYMMDD.substring(4, 6));
    final currentYY = DateTime.now().year % 100;
    final fullYear = yy > currentYY ? 1900 + yy : 2000 + yy;
    final now = DateTime.now();
    int age = now.year - fullYear;
    if (now.month < mm || (now.month == mm && now.day < dd)) age--;
    return age;
  } catch (_) {
    return 0;
  }
}

String discountTypeLabel(String type) {
  switch (type) {
    case 'age':
      return '경로할인';
    case 'student':
      return '학생할인';
    case 'free':
      return '면제';
    default:
      return '일반';
  }
}

InputDecoration financeInputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD8DEE8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF5F81A7), width: 1.5),
    ),
  );
}

class DuesRecord {
  String memberId;
  String memberName;
  String memberBirth;
  int amount;
  bool isPaid;
  String paidDate;
  String discountType;
  String memo;

  DuesRecord({
    required this.memberId,
    required this.memberName,
    this.memberBirth = '',
    this.amount = 0,
    this.isPaid = false,
    this.paidDate = '',
    this.discountType = 'none',
    this.memo = '',
  });

  bool get hasDiscount => discountType != 'none';
  set hasDiscount(bool v) {
    if (!v) {
      discountType = 'none';
    } else if (discountType == 'none') {
      discountType = 'age';
    }
  }

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'memberName': memberName,
    'memberBirth': memberBirth,
    'amount': amount,
    'isPaid': isPaid,
    'paidDate': paidDate,
    'discountType': discountType,
    'memo': memo,
  };

  factory DuesRecord.fromMap(Map<String, dynamic> map) => DuesRecord(
    memberId: map['memberId']?.toString() ?? '',
    memberName: map['memberName']?.toString() ?? '',
    memberBirth: map['memberBirth']?.toString() ?? '',
    amount: (map['amount'] as num?)?.toInt() ?? 0,
    isPaid: map['isPaid'] as bool? ?? false,
    paidDate: map['paidDate']?.toString() ?? '',
    discountType: map['discountType']?.toString() ?? 'none',
    memo: map['memo']?.toString() ?? '',
  );
}

enum TransactionType { income, expense }

class Transaction {
  String id;
  TransactionType type;
  String title;
  int amount;
  String date;
  String memo;
  String? imagePath;

  Transaction({
    String? id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.memo = '',
    this.imagePath,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type == TransactionType.income ? 'income' : 'expense',
    'title': title,
    'amount': amount,
    'date': date,
    'memo': memo,
    'imagePath': imagePath,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id']?.toString(),
    type: map['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    title: map['title']?.toString() ?? '',
    amount: (map['amount'] as num?)?.toInt() ?? 0,
    date: map['date']?.toString() ?? '',
    memo: map['memo']?.toString() ?? '',
    imagePath: map['imagePath']?.toString(),
  );
}

class FinanceStorage {
  static const _duesKey = 'club_dues';
  static const _txKey = 'club_transactions';
  static const _defAmtKey = 'club_default_dues_amount';
  static const _ageDiscAmtKey = 'club_age_discount_dues_amount';
  static const _studentDiscAmtKey = 'club_student_discount_dues_amount';
  static const _discAgeKey = 'club_discount_age';

  static Future<void> saveDues(List<DuesRecord> dues) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _duesKey,
      dues.map((d) => jsonEncode(d.toMap())).toList(),
    );
  }

  static Future<List<DuesRecord>> loadDues() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_duesKey) ?? [])
          .map((s) => DuesRecord.fromMap(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTx(List<Transaction> txs) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _txKey,
      txs.map((t) => jsonEncode(t.toMap())).toList(),
    );
  }

  static Future<List<Transaction>> loadTx() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_txKey) ?? [])
          .map(
            (s) => Transaction.fromMap(jsonDecode(s) as Map<String, dynamic>),
          )
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
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
        _ThousandsFormatter(),
      ],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: financeInputDeco(widget.hint),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final n = int.tryParse(digits);
    if (n == null) return oldValue;
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AmountSummaryBlock extends StatelessWidget {
  final String label;
  final int amount;
  final Color? color;
  final bool transparent; // 네이비 배경 위에서 투명 모드

  const AmountSummaryBlock({
    super.key,
    required this.label,
    required this.amount,
    this.color,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xFF1A1A1A);
    final labelColor = transparent
        ? Colors.white.withOpacity(0.75)
        : const Color(0xFF737C8B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: transparent ? null : Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fmtAmt(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final int? count;
  final Color color;
  final Color? bgColor;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.count,
    required this.color,
    this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finalBg = bgColor ?? color.withOpacity(0.18);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: finalBg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  final String? label;
  final String? text;
  final bool? isSelected;
  final bool? selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    this.label,
    this.text,
    this.isSelected,
    this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = label ?? text ?? '';
    final active = isSelected ?? selected ?? false;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5F81A7) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF5F81A7) : const Color(0xFFD4D8DE),
            width: 1.1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF5F6B7A),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5F6B7A),
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}
