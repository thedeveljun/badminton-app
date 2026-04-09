import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';
import '../../../members/utils/member_storage.dart';
import 'finance_models.dart';
import 'finance_dues_tab.dart';
import 'finance_transaction_tab.dart';

// ============================================================
// club_finance_screen.dart — 메인 화면 + 요약 탭
// ============================================================

class ClubFinanceScreen extends StatefulWidget {
  const ClubFinanceScreen({super.key});

  @override
  State<ClubFinanceScreen> createState() => _ClubFinanceScreenState();
}

class _ClubFinanceScreenState extends State<ClubFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<DuesRecord> _dues = [];
  List<Transaction> _transactions = [];

  int _defaultDuesAmount = 10000;
  int _ageDiscountAmount = 5000;
  int _studentDiscountAmount = 5000;
  int _discountAge = 70;

  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = '전체';

  String _summaryPeriod = '전체';
  DateTime _rangeStart = DateTime(DateTime.now().year, 1, 1);
  DateTime _rangeEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final members = await MemberStorage.loadMembers();
    final savedDues = await FinanceStorage.loadDues();
    final savedTx = await FinanceStorage.loadTx();
    final defAmt = await FinanceStorage.loadDefaultAmt();
    final ageDiscAmt = await FinanceStorage.loadAgeDiscountAmt();
    final studentDiscAmt = await FinanceStorage.loadStudentDiscountAmt();
    final discAge = await FinanceStorage.loadDiscountAge();

    setState(() {
      _dues = _syncDues(members ?? [], savedDues);
      _transactions = savedTx;
      _defaultDuesAmount = defAmt;
      _ageDiscountAmount = ageDiscAmt;
      _studentDiscountAmount = studentDiscAmt;
      _discountAge = discAge;
      _isLoading = false;
    });
  }

  List<DuesRecord> _syncDues(List<MemberItem> members, List<DuesRecord> saved) {
    final savedMap = {for (final r in saved) r.memberId: r};
    return members.map((m) {
      final existing = savedMap[m.id];
      if (existing != null) return existing;
      return DuesRecord(
        memberId: m.id,
        memberName: m.name,
        memberBirth: m.birth,
      );
    }).toList()..sort((a, b) => a.memberName.compareTo(b.memberName));
  }

  List<DuesRecord> get _filteredDues {
    final kw = _searchCtrl.text.trim();
    return _dues.where((r) {
      final matchName = kw.isEmpty || r.memberName.contains(kw);
      final matchStatus =
          _filterStatus == '전체' ||
          (_filterStatus == '납부' && r.isPaid) ||
          (_filterStatus == '미납' && !r.isPaid);
      return matchName && matchStatus;
    }).toList();
  }

  List<Transaction> get _filteredTx {
    if (_summaryPeriod == '전체') return _transactions;
    return _transactions.where((t) {
      try {
        final d = DateTime.parse(t.date);
        return !d.isBefore(_rangeStart) && !d.isAfter(_rangeEnd);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  int _expectedAmount(DuesRecord r) {
    switch (r.discountType) {
      case 'age':
        return _ageDiscountAmount;
      case 'student':
        return _studentDiscountAmount;
      case 'free':
        return 0;
      default:
        return _defaultDuesAmount;
    }
  }

  int get _totalDues =>
      _dues.where((r) => r.isPaid).fold(0, (int s, r) => s + r.amount);

  int get _paidCount => _dues.where((r) => r.isPaid).length;
  int get _unpaidCount => _dues.where((r) => !r.isPaid).length;

  int get _unpaidTotal => _dues
      .where((r) => !r.isPaid)
      .fold(0, (int s, r) => s + _expectedAmount(r));

  int get _summaryIncome => _filteredTx
      .where((t) => t.type == TransactionType.income)
      .fold(0, (int s, t) => s + t.amount);

  int get _summaryExpense => _filteredTx
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (int s, t) => s + t.amount);

  int get _summaryBalance => _summaryIncome - _summaryExpense;

  Future<void> _saveDues() => FinanceStorage.saveDues(_dues);
  Future<void> _saveTx() => FinanceStorage.saveTx(_transactions);

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _applyDefaultAmt(int defaultAmt) async {
    setState(() {
      _defaultDuesAmount = defaultAmt;
      for (final r in _dues) {
        if (r.isPaid && r.discountType == 'none') r.amount = _expectedAmount(r);
      }
    });
    await FinanceStorage.saveDefaultAmt(defaultAmt);
    await _saveDues();
    _snack('기본회비가 저장되었습니다.');
  }

  Future<void> _applyAgeDiscount(int age, int amount) async {
    setState(() {
      _discountAge = age;
      _ageDiscountAmount = amount;
      for (final r in _dues) {
        if (r.isPaid && r.discountType == 'age') r.amount = _expectedAmount(r);
      }
    });
    await FinanceStorage.saveDiscountAge(age);
    await FinanceStorage.saveAgeDiscountAmt(amount);
    await _saveDues();
    _snack('연령 할인 설정이 저장되었습니다.');
  }

  Future<void> _applyStudentDiscount(int amount) async {
    setState(() {
      _studentDiscountAmount = amount;
      for (final r in _dues) {
        if (r.isPaid && r.discountType == 'student')
          r.amount = _expectedAmount(r);
      }
    });
    await FinanceStorage.saveStudentDiscountAmt(amount);
    await _saveDues();
    _snack('학생 할인 설정이 저장되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        surfaceTintColor: const Color(0xFFF6F7FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 34,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF111111),
          ),
        ),
        title: const Text(
          '클럽 재정관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: Color(0xFF5B8ABB),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelColor: const Color(0xFF5B8ABB),
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: const Color(0xFF5B8ABB),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: '회비납부'),
            Tab(text: '수입/지출'),
            Tab(text: '요약'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DuesTab(
            dues: _dues,
            filteredDues: _filteredDues,
            totalDues: _totalDues,
            paidCount: _paidCount,
            unpaidCount: _unpaidCount,
            unpaidTotal: _unpaidTotal,
            defaultDuesAmount: _defaultDuesAmount,
            discountAge: _discountAge,
            ageDiscountAmount: _ageDiscountAmount,
            studentDiscountAmount: _studentDiscountAmount,
            searchCtrl: _searchCtrl,
            filterStatus: _filterStatus,
            onFilterChanged: (s) => setState(() => _filterStatus = s),
            onDefaultAmtConfirm: _applyDefaultAmt,
            onAgeDiscountConfirm: _applyAgeDiscount,
            onStudentDiscountConfirm: _applyStudentDiscount,
            onRowTap: (r) => _showDuesDialog(r),
            onRowChanged: () {
              setState(() {});
              _saveDues();
            },
          ),

          TransactionTab(
            transactions: _transactions,
            onAddTap: () => _showTransactionDialog(),
            onEditTap: (tx) => _showTransactionDialog(tx: tx),
            onDelete: (tx) {
              // ★ 회비 수입 항목 삭제 시 → [반환] 기록 추가 + 회비납부 탭 자동 미납
              if (tx.memo.startsWith('회비_')) {
                final memberId = tx.memo.replaceFirst('회비_', '');

                setState(() {
                  // 1. 수입 항목 삭제
                  _transactions.removeWhere((t) => t.id == tx.id);

                  // 2. [반환] 기록 추가 (중복 방지)
                  final alreadyCancelled = _transactions.any(
                    (t) => t.memo == '회비반환_$memberId',
                  );
                  if (!alreadyCancelled) {
                    _transactions.add(
                      Transaction(
                        type: TransactionType.expense,
                        title: '[반환] ${tx.title}',
                        amount: tx.amount,
                        date: todayStr(),
                        memo: '회비반환_$memberId',
                      ),
                    );
                  }

                  // 3. 회비납부 탭 자동 미납 처리
                  final due = _dues.firstWhere(
                    (d) => d.memberId == memberId,
                    orElse: () => DuesRecord(memberId: '', memberName: ''),
                  );
                  if (due.memberId.isNotEmpty) {
                    due.isPaid = false;
                    due.paidDate = '';
                  }
                });

                _saveTx();
                _saveDues();
                _snack('반환 처리되었습니다.');
                return;
              }

              // ★ 일반 항목 삭제
              setState(() => _transactions.removeWhere((t) => t.id == tx.id));
              _saveTx();
              _snack('삭제되었습니다.');
            },
          ),

          _buildSummaryTab(),
        ],
      ),
    );
  }

  // ── 회비납부 다이얼로그 ────────────────────────────────────
  void _showDuesDialog(DuesRecord record) {
    final amountCtrl = TextEditingController(
      text: record.amount > 0
          ? record.amount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
          : '',
    );
    final memoCtrl = TextEditingController(text: record.memo);
    String paidDate = record.paidDate.isEmpty ? todayStr() : record.paidDate;
    bool isPaid = record.isPaid;
    String discountType = record.discountType;

    int dialogExpectedAmount() {
      switch (discountType) {
        case 'age':
          return _ageDiscountAmount;
        case 'student':
          return _studentDiscountAmount;
        case 'free':
          return 0;
        default:
          return _defaultDuesAmount;
      }
    }

    void applyAutoAmount(StateSetter setDlg) {
      final amt = dialogExpectedAmount();
      amountCtrl.text = amt == 0
          ? '0'
          : amt.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            );
      setDlg(() {});
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: const Color(0xFFF4F5FA),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.memberName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    if (record.memberBirth.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${calcAge(record.memberBirth)}세',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Text(
                      '납부 여부',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setDlg(() => isPaid = !isPaid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 76,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFF4A9E6B)
                              : const Color(0xFFB05B5B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isPaid ? '납부 ✓' : '미납',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                DlgField(
                  label: '할인 구분',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _discountChip(
                        label: '일반',
                        value: 'none',
                        current: discountType,
                        onTap: () {
                          setDlg(() => discountType = 'none');
                          applyAutoAmount(setDlg);
                        },
                      ),
                      _discountChip(
                        label: '연령',
                        value: 'age',
                        current: discountType,
                        onTap: () {
                          setDlg(() => discountType = 'age');
                          applyAutoAmount(setDlg);
                        },
                      ),
                      _discountChip(
                        label: '학생',
                        value: 'student',
                        current: discountType,
                        onTap: () {
                          setDlg(() => discountType = 'student');
                          applyAutoAmount(setDlg);
                        },
                      ),
                      _discountChip(
                        label: '무료',
                        value: 'free',
                        current: discountType,
                        onTap: () {
                          setDlg(() => discountType = 'free');
                          applyAutoAmount(setDlg);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                DlgField(
                  label: '납부금액',
                  child: AmountTextField(
                    controller: amountCtrl,
                    hint: fmtAmt(dialogExpectedAmount()),
                  ),
                ),
                const SizedBox(height: 8),

                DlgField(
                  label: '납부일',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _parseDate(paidDate),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(
                          () => paidDate =
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
                            paidDate.isEmpty ? '날짜 선택' : paidDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
                    controller: memoCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: financeInputDeco('메모 입력'),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () {
                          final prevPaid = record.isPaid;

                          setState(() {
                            record.isPaid = isPaid;
                            record.discountType = discountType;
                            record.hasDiscount = discountType != 'none';
                            record.amount =
                                int.tryParse(
                                  amountCtrl.text
                                      .replaceAll(',', '')
                                      .replaceAll('원', '')
                                      .trim(),
                                ) ??
                                0;
                            record.paidDate = paidDate;
                            record.memo = memoCtrl.text.trim();

                            if (record.discountType == 'free') {
                              record.amount = 0;
                            } else if (record.isPaid && record.amount == 0) {
                              record.amount = _expectedAmount(record);
                            }

                            // ★ 납부 처리 → 수입 항목 자동 추가
                            if (isPaid && !prevPaid && record.amount > 0) {
                              _transactions.removeWhere(
                                (t) => t.memo == '회비_${record.memberId}',
                              );
                              _transactions.add(
                                Transaction(
                                  type: TransactionType.income,
                                  title: '${record.memberName} 회비',
                                  amount: record.amount,
                                  date: paidDate,
                                  memo: '회비_${record.memberId}',
                                ),
                              );
                            }

                            // ★ 미납으로 변경 → [반환] 기록 추가 + 수입 항목 삭제
                            if (!isPaid && prevPaid) {
                              // 기존 수입 항목 금액 확인 후 삭제
                              final existingTx = _transactions.firstWhere(
                                (t) => t.memo == '회비_${record.memberId}',
                                orElse: () => Transaction(
                                  type: TransactionType.income,
                                  title: '',
                                  amount: record.amount > 0
                                      ? record.amount
                                      : _expectedAmount(record),
                                  date: todayStr(),
                                ),
                              );
                              final returnAmount = existingTx.amount > 0
                                  ? existingTx.amount
                                  : (record.amount > 0
                                        ? record.amount
                                        : _expectedAmount(record));

                              // 수입 항목 삭제
                              _transactions.removeWhere(
                                (t) => t.memo == '회비_${record.memberId}',
                              );

                              // [반환] 기록 추가 (중복 방지)
                              final alreadyCancelled = _transactions.any(
                                (t) => t.memo == '회비반환_${record.memberId}',
                              );
                              if (!alreadyCancelled) {
                                _transactions.add(
                                  Transaction(
                                    type: TransactionType.expense,
                                    title: '[반환] ${record.memberName} 회비',
                                    amount: returnAmount,
                                    date: todayStr(),
                                    memo: '회비반환_${record.memberId}',
                                  ),
                                );
                              }
                            }
                          });

                          _saveDues();
                          _saveTx();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF5B8ABB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
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
        ),
      ),
    );
  }

  Widget _discountChip({
    required String label,
    required String value,
    required String current,
    required VoidCallback onTap,
  }) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B8ABB) : const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF5B8ABB) : const Color(0xFFCDD5DF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  // ── 수입/지출 다이얼로그 ──────────────────────────────────
  void _showTransactionDialog({Transaction? tx}) {
    final isEdit = tx != null;
    TransactionType type = tx?.type ?? TransactionType.income;
    final titleCtrl = TextEditingController(text: tx?.title ?? '');
    final amountCtrl = TextEditingController(
      text: tx != null && tx.amount > 0
          ? tx.amount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
          : '',
    );
    final memoCtrl = TextEditingController(text: tx?.memo ?? '');
    String date = tx?.date ?? todayStr();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: const Color(0xFFF4F5FA),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? '항목 수정' : '항목 추가',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDlg(() => type = TransactionType.income),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 40,
                          decoration: BoxDecoration(
                            color: type == TransactionType.income
                                ? const Color(0xFF4A9E6B)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '수입',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: type == TransactionType.income
                                  ? Colors.white
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDlg(() => type = TransactionType.expense),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 40,
                          decoration: BoxDecoration(
                            color: type == TransactionType.expense
                                ? const Color(0xFFB05B5B)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '지출',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: type == TransactionType.expense
                                  ? Colors.white
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                DlgField(
                  label: '항목명',
                  child: TextField(
                    controller: titleCtrl,
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
                  child: AmountTextField(controller: amountCtrl, hint: '입력'),
                ),
                const SizedBox(height: 8),

                DlgField(
                  label: '날짜',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _parseDate(date),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(
                          () => date =
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
                            date,
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
                    controller: memoCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: financeInputDeco('예: 자체대회'),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          final amount =
                              int.tryParse(
                                amountCtrl.text
                                    .replaceAll(',', '')
                                    .replaceAll('원', '')
                                    .trim(),
                              ) ??
                              0;

                          if (title.isEmpty) {
                            _snack('항목명을 입력해주세요.');
                            return;
                          }
                          if (amount <= 0) {
                            _snack('금액을 입력해주세요.');
                            return;
                          }

                          setState(() {
                            if (isEdit) {
                              tx!.type = type;
                              tx.title = title;
                              tx.amount = amount;
                              tx.date = date;
                              tx.memo = memoCtrl.text.trim();
                            } else {
                              _transactions.add(
                                Transaction(
                                  type: type,
                                  title: title,
                                  amount: amount,
                                  date: date,
                                  memo: memoCtrl.text.trim(),
                                ),
                              );
                            }
                          });
                          _saveTx();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF5B8ABB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          isEdit ? '수정' : '추가',
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
        ),
      ),
    );
  }

  // ── 요약 탭 ───────────────────────────────────────────────
  Widget _buildSummaryTab() {
    final int income = _summaryIncome;
    final int expense = _summaryExpense;
    final int balance = _summaryBalance;

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
        _PeriodSelector(
          current: _summaryPeriod,
          rangeStart: _rangeStart,
          rangeEnd: _rangeEnd,
          onChanged: (period, start, end) => setState(() {
            _summaryPeriod = period;
            if (start != null) _rangeStart = start;
            if (end != null) _rangeEnd = end;
          }),
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

        Row(
          children: [
            Expanded(
              child: _SummaryAmtCard(
                label: '총 수입',
                amount: income,
                color: const Color.fromARGB(255, 33, 125, 70),
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryAmtCard(
                label: '총 지출',
                amount: expense,
                color: const Color(0xFFB05B5B),
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
            final int inc = monthlyIncome[ym] ?? 0;
            final int exp = monthlyExpense[ym] ?? 0;
            final int bal = inc - exp;
            final parts = ym.split('-');
            return _MonthlyRow(
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

// ── 요약 카드 ─────────────────────────────────────────────────
class _SummaryAmtCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryAmtCard({
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
class _MonthlyRow extends StatelessWidget {
  final String label;
  final int income, expense, balance;

  const _MonthlyRow({
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
              child: _MonthItem(
                label: '수입',
                amount: income,
                color: const Color(0xFF4A9E6B),
              ),
            ),
            Expanded(
              child: _MonthItem(
                label: '지출',
                amount: expense,
                color: const Color(0xFFB05B5B),
              ),
            ),
            Expanded(
              child: _MonthItem(
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

class _MonthItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _MonthItem({
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
class _PeriodSelector extends StatelessWidget {
  final String current;
  final DateTime rangeStart, rangeEnd;
  final void Function(String, DateTime?, DateTime?) onChanged;

  const _PeriodSelector({
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
