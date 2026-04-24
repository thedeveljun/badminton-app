import 'dart:io';
import 'package:flutter/material.dart';
import 'finance_models.dart';

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
    // 6) 모든 거래 날짜+id 내림차순 (최신순 = 항상 위에)
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) {
        final dateComp = b.date.compareTo(a.date);
        if (dateComp != 0) return dateComp;
        return b.id.compareTo(a.id);
      });

    final int txIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (int s, t) => s + t.amount);
    final int txExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (int s, t) => s + t.amount);

    return Column(
      children: [
        // 1) 수입/지출 라벨 폰트 그림1과 동일하게, 2) padding 줄여서 높이 20% 축소
        Container(
          color: const Color(0xFF0F2B5F),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Stack(
            children: [
              // + 버튼 오른쪽 상단에 작게 배치
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A5A8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ),
              // 수입/지출 전체 폭 사용
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '수입',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.75),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fmtAmt(txIncome),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '지출',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.75),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fmtAmt(txExpense),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // + 버튼 공간 확보 (Positioned가 겹치지 않게)
                  const SizedBox(width: 40),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Center(child: Text('내역이 없습니다'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
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
    final bool isRefund =
        tx.memo.startsWith('회비반환_') || tx.title.startsWith('[반환]');
    final bool isMemoHidden =
        tx.memo.startsWith('회비_') || tx.memo.startsWith('회비반환_');

    // 색상 정의
    // 수입: 녹색 / 반환: 파랑 / 지출: 빨강
    final Color iconBg = isIncome
        ? const Color(0xFFE8F5EE) // 연녹색
        : isRefund
        ? const Color(0xFFE3EEFF) // 연파랑
        : const Color(0xFFFFF0F0); // 연빨강 (지출 박스 배경 연하게)
    final Color iconColor = isIncome
        ? const Color(0xFF4A9E6B) // 녹색
        : isRefund
        ? const Color(0xFF3A7BD5) // 파랑
        : const Color(0xFFCC4444); // 빨강
    final Color amountColor = isIncome
        ? const Color(0xFF2A7A4A) // 진녹색
        : isRefund
        ? const Color(0xFF2A5FCC) // 진파랑
        : const Color(0xFFCC2222); // 진빨강
    final Color cardBg = isIncome
        ? Colors.white
        : isRefund
        ? Colors.white
        : const Color(0xFFFFF8F8); // 지출 카드 배경 연분홍
    final Color cardBorder = isIncome
        ? const Color(0xFF9BB5D0)
        : isRefund
        ? const Color(0xFF9BB5D0)
        : const Color(0xFFE8A0A0); // 지출 테두리 연빨강

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.undo, color: Color(0xFFB05B5B), size: 22),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '회비 반납할까요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: Text(tx.title, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소', style: TextStyle(fontSize: 14)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '반납',
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // 4) 박스 높이 최대한 줄임
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: tx.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          File(tx.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        isIncome
                            ? Icons.arrow_upward
                            : isRefund
                            ? Icons.undo
                            : Icons.arrow_downward,
                        size: 18,
                        color: iconColor,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            tx.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isIncome ? '+' : '-'}${fmtAmt(tx.amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: amountColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        letterSpacing: -0.2,
                      ),
                    ),
                    // 5) 메모 표시 (회비_ 자동메모는 숨김, 직접 입력 메모만 표시)
                    if (tx.memo.isNotEmpty && !isMemoHidden)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          tx.memo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2A7A4A),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
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
