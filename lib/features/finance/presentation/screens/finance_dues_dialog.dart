import 'package:flutter/material.dart';
import 'finance_models.dart';

// ============================================================
// finance_dues_dialog.dart — 회비납부 다이얼로그
// ============================================================

class DuesDialog extends StatefulWidget {
  final DuesRecord record;
  final int defaultDuesAmount;
  final int ageDiscountAmount;
  final int studentDiscountAmount;
  final int expectedAmount;
  final List<Transaction> transactions;
  final void Function(
    DuesRecord record,
    List<Transaction> transactions,
  ) onSave;

  const DuesDialog({
    super.key,
    required this.record,
    required this.defaultDuesAmount,
    required this.ageDiscountAmount,
    required this.studentDiscountAmount,
    required this.expectedAmount,
    required this.transactions,
    required this.onSave,
  });

  @override
  State<DuesDialog> createState() => _DuesDialogState();
}

class _DuesDialogState extends State<DuesDialog> {
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;
  late String _paidDate;
  late bool _isPaid;
  late String _discountType;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _amountCtrl = TextEditingController(
      text: r.amount > 0
          ? r.amount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
          : '',
    );
    _memoCtrl    = TextEditingController(text: r.memo);
    _paidDate    = r.paidDate.isEmpty ? todayStr() : r.paidDate;
    _isPaid      = r.isPaid;
    _discountType = r.discountType;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  int get _dialogExpectedAmount {
    switch (_discountType) {
      case 'age':     return widget.ageDiscountAmount;
      case 'student': return widget.studentDiscountAmount;
      case 'free':    return 0;
      default:        return widget.defaultDuesAmount;
    }
  }

  void _applyAutoAmount() {
    final amt = _dialogExpectedAmount;
    _amountCtrl.text = amt == 0
        ? '0'
        : amt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    setState(() {});
  }

  DateTime _parseDate(String s) {
    try { return DateTime.parse(s); } catch (_) { return DateTime.now(); }
  }

  void _save() {
    final prevPaid = widget.record.isPaid;
    final record   = widget.record;
    final txList   = List<Transaction>.from(widget.transactions);

    record.isPaid       = _isPaid;
    record.discountType = _discountType;
    record.hasDiscount  = _discountType != 'none';
    record.amount = int.tryParse(
      _amountCtrl.text.replaceAll(',', '').replaceAll('원', '').trim()) ?? 0;
    record.memo = _memoCtrl.text.trim();

    // 납부일 처리
    if (_isPaid) {
      record.paidDate = _paidDate;
    } else {
      record.paidDate = '';
    }

    if (record.discountType == 'free') {
      record.amount = 0;
    } else if (record.isPaid && record.amount == 0) {
      record.amount = _dialogExpectedAmount;
    }

    // ★ 납부 처리 → 수입 항목 자동 추가
    if (_isPaid && !prevPaid && record.amount > 0) {
      txList.removeWhere((t) => t.memo == '회비_${record.memberId}');
      txList.add(Transaction(
        type: TransactionType.income,
        title: '${record.memberName} 회비',
        amount: record.amount,
        date: _paidDate,
        memo: '회비_${record.memberId}',
      ));
    }

    // ★ 미납으로 변경 → [반환] 기록 추가 + 수입 항목 삭제
    if (!_isPaid && prevPaid) {
      final existing = txList.firstWhere(
        (t) => t.memo == '회비_${record.memberId}',
        orElse: () => Transaction(
          type: TransactionType.income, title: '',
          amount: record.amount > 0 ? record.amount : _dialogExpectedAmount,
          date: todayStr(),
        ),
      );
      final returnAmount = existing.amount > 0 ? existing.amount
          : (record.amount > 0 ? record.amount : _dialogExpectedAmount);

      txList.removeWhere((t) => t.memo == '회비_${record.memberId}');

      final alreadyCancelled =
          txList.any((t) => t.memo == '회비반환_${record.memberId}');
      if (!alreadyCancelled) {
        txList.add(Transaction(
          type: TransactionType.expense,
          title: '[반환] ${record.memberName} 회비',
          amount: returnAmount,
          date: todayStr(),
          memo: '회비반환_${record.memberId}',
        ));
      }
    }

    widget.onSave(record, txList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF4F5FA),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이름 + 나이
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.record.memberName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: Color(0xFF111111))),
                if (widget.record.memberBirth.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('${calcAge(widget.record.memberBirth)}세',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF888888))),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 납부 여부 토글
            Row(
              children: [
                const Text('납부 여부',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF444444))),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isPaid = !_isPaid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 76, height: 32,
                    decoration: BoxDecoration(
                      color: _isPaid
                          ? const Color(0xFF4A9E6B) : const Color(0xFFB05B5B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(_isPaid ? '납부 ✓' : '미납',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 할인 구분
            DlgField(
              label: '할인 구분',
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  _chip('일반', 'none'),
                  _chip('연령', 'age'),
                  _chip('학생', 'student'),
                  _chip('무료', 'free'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 납부금액
            DlgField(
              label: '납부금액',
              child: AmountTextField(
                  controller: _amountCtrl,
                  hint: fmtAmt(_dialogExpectedAmount)),
            ),
            const SizedBox(height: 8),

            // 납부일
            DlgField(
              label: '납부일',
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _parseDate(_paidDate),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _paidDate =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                  }
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB8BEC9)),
                  ),
                  child: Row(
                    children: [
                      Text(_paidDate.isEmpty ? '날짜 선택' : _paidDate,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: Color(0xFF111111))),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined,
                          size: 15, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 메모
            DlgField(
              label: '메모',
              child: TextField(
                controller: _memoCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: financeInputDeco('메모 입력'),
              ),
            ),
            const SizedBox(height: 14),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB6BCC8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Color(0xFF555555))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF5B8ABB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('저장',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _discountType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _discountType = value);
        _applyAutoAmount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B8ABB) : const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF5B8ABB) : const Color(0xFFCDD5DF)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF555555),
            )),
      ),
    );
  }
}