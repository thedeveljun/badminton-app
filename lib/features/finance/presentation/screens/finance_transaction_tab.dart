import 'package:flutter/material.dart';
import 'finance_models.dart';

// ============================================================
// finance_transaction_tab.dart
// 수입/지출 탭 위젯 + 행 위젯
// ============================================================

class TransactionTab extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onAddTap;
  final void Function(Transaction) onEditTap;
  final void Function(Transaction) onDelete;

  const TransactionTab({
    super.key,
    required this.transactions,
    required this.onAddTap,
    required this.onEditTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final int txIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (int s, t) => s + t.amount);
    final int txExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (int s, t) => s + t.amount);

    return Column(
      children: [
        // ── 요약 배너 ──────────────────────────────────────────
        Container(
          color: const Color.fromARGB(255, 15, 43, 95),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: AmountSummaryBlock(
                  label: '수입',
                  amount: txIncome,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AmountSummaryBlock(
                  label: '지출',
                  amount: txExpense,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // ── + 버튼 ──────────────────────────────────────
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A5A8A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B8ABB).withOpacity(0.30),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // ── 리스트 ────────────────────────────────────────────
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 44,
                        color: Color(0xFFCCCCCC),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '수입/지출 내역이 없습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: onAddTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8ABB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '항목 추가',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final tx = sorted[i];
                    return TransactionRow(
                      tx: tx,
                      onTap: () => onEditTap(tx),
                      onDelete: () => onDelete(tx),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class TransactionRow extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionRow({
    super.key,
    required this.tx,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFB05B5B)),
      ),
      confirmDismiss: (_) async {
        // ★ 삭제 확인 다이얼로그
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '삭제할까요?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: Text(
              '"${tx.title}" 항목을 삭제합니다.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Color(0xFFB05B5B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) onDelete();
        return false; // Dismissible 자체 삭제는 항상 막음
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4D8DE), width: 1.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isIncome
                      ? const Color(0xFFE8F5EE)
                      : const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: isIncome
                      ? const Color(0xFF4A9E6B)
                      : const Color(0xFFB05B5B),
                ),
              ),
              const SizedBox(width: 10),

              // 제목 + 날짜 + 메모
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 금액 한 줄
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tx.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${fmtAmt(tx.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isIncome
                                ? const Color(0xFF2A7A4A)
                                : const Color(0xFFB05B5B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 날짜
                    Text(
                      tx.date,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF444444),
                      ),
                    ),
                    // 메모 — 전체 너비 사용, 잘림 없음
                    if (tx.memo.isNotEmpty &&
                        !tx.memo.startsWith('회비_') &&
                        !tx.memo.startsWith('회비반환_'))
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          tx.memo,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
