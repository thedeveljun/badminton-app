import 'package:flutter/material.dart';
import 'finance_models.dart';

class TransactionDialog extends StatefulWidget {
  final Transaction? tx;
  final void Function(Transaction) onSave;
  final void Function(String msg) onSnack;
  final String? initialTitle;
  final int? initialAmount;

  const TransactionDialog({
    super.key,
    this.tx,
    required this.onSave,
    required this.onSnack,
    this.initialTitle,
    this.initialAmount,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  late TransactionType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;
  late String _date;

  bool get _isEdit => widget.tx != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.tx;
    _type =
        tx?.type ??
        (widget.initialAmount != null
            ? TransactionType.expense
            : TransactionType.income);
    _titleCtrl = TextEditingController(
      text: tx?.title ?? widget.initialTitle ?? '',
    );
    _amountCtrl = TextEditingController(
      text: tx != null && tx.amount > 0
          ? tx.amount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
          : (widget.initialAmount != null
                ? widget.initialAmount.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]},',
                  )
                : ''),
    );
    final rawMemo = tx?.memo ?? '';
    _memoCtrl = TextEditingController(
      text: rawMemo.startsWith('회비_') || rawMemo.startsWith('회비반환_')
          ? ''
          : rawMemo,
    );
    _date = tx?.date ?? todayStr();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount =
        int.tryParse(
          _amountCtrl.text.replaceAll(',', '').replaceAll('원', '').trim(),
        ) ??
        0;

    if (title.isEmpty) {
      widget.onSnack('항목명을 입력해주세요.');
      return;
    }
    if (amount <= 0) {
      widget.onSnack('금액을 입력해주세요.');
      return;
    }

    final tx = widget.tx;
    if (_isEdit && tx != null) {
      tx.type = _type;
      tx.title = title;
      tx.amount = amount;
      tx.date = _date;
      final rawMemo = tx.memo;
      tx.memo = (rawMemo.startsWith('회비_') || rawMemo.startsWith('회비반환_'))
          ? rawMemo
          : _memoCtrl.text.trim();
      widget.onSave(tx);
    } else {
      widget.onSave(
        Transaction(
          type: _type,
          title: title,
          amount: amount,
          date: _date,
          memo: _memoCtrl.text.trim(),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? '항목 수정' : '항목 추가',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _typeBtn(
                    '수입',
                    TransactionType.income,
                    const Color(0xFF4A9E6B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _typeBtn(
                    '지출',
                    TransactionType.expense,
                    const Color(0xFFB05B5B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            DlgField(
              label: '항목명',
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: financeInputDeco('예: 대관료'),
              ),
            ),
            const SizedBox(height: 8),

            DlgField(
              label: '금액 (원)',
              child: AmountTextField(controller: _amountCtrl, hint: '입력'),
            ),
            const SizedBox(height: 8),

            DlgField(
              label: '날짜',
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _parseDate(_date),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(
                      () => _date =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                    );
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
                      Text(
                        _date,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Color(0xFF888888),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            DlgField(
              label: '메모',
              child: TextField(
                controller: _memoCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: financeInputDeco('예: 자체대회'),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB6BCC8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Color(0xFF555555)),
                    ),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      _isEdit ? '수정' : '추가',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, TransactionType t, Color activeColor) {
    final selected = _type == t;
    return GestureDetector(
      onTap: () => setState(() => _type = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
