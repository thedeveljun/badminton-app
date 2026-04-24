import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';
import '../../../members/utils/member_storage.dart';
import 'finance_models.dart';
import 'finance_dues_tab.dart';
import 'finance_transaction_tab.dart';
import 'finance_summary_tab.dart';
import 'finance_dues_dialog.dart';
import 'finance_transaction_dialog.dart';

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
    final stuDiscAmt = await FinanceStorage.loadStudentDiscountAmt();
    final discAge = await FinanceStorage.loadDiscountAge();

    if (!mounted) return;
    setState(() {
      _dues = _syncDues(members ?? [], savedDues);
      _transactions = savedTx;
      _defaultDuesAmount = defAmt;
      _ageDiscountAmount = ageDiscAmt;
      _studentDiscountAmount = stuDiscAmt;
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
      _dues.where((r) => r.isPaid).fold(0, (s, r) => s + r.amount);
  int get _paidCount => _dues.where((r) => r.isPaid).length;
  int get _unpaidCount => _dues.where((r) => !r.isPaid).length;
  int get _unpaidTotal => _dues
      .where((r) => !r.isPaid)
      .fold(0, (int s, r) => s + _expectedAmount(r));

  Future<void> _saveDues() => FinanceStorage.saveDues(_dues);
  Future<void> _saveTx() => FinanceStorage.saveTx(_transactions);

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _applyDefaultAmt(int v) async {
    setState(() {
      _defaultDuesAmount = v;
      for (final r in _dues) {
        if (r.isPaid && r.discountType == 'none') r.amount = _expectedAmount(r);
      }
    });
    await FinanceStorage.saveDefaultAmt(v);
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
        if (r.isPaid && r.discountType == 'student') {
          r.amount = _expectedAmount(r);
        }
      }
    });
    await FinanceStorage.saveStudentDiscountAmt(amount);
    await _saveDues();
    _snack('학생 할인 설정이 저장되었습니다.');
  }

  void _showDuesDialog(DuesRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DuesDialog(
        record: record,
        defaultDuesAmount: _defaultDuesAmount,
        ageDiscountAmount: _ageDiscountAmount,
        studentDiscountAmount: _studentDiscountAmount,
        expectedAmount: _expectedAmount(record),
        transactions: _transactions,
        onSave: (updatedRecord, updatedTx) {
          setState(() {
            _transactions = updatedTx;
          });
          _saveDues();
          _saveTx();
        },
      ),
    );
  }

  void _showTransactionDialog({Transaction? tx}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TransactionDialog(
        tx: tx,
        onSnack: _snack,
        onSave: (saved) {
          setState(() {
            if (tx != null) {
              final idx = _transactions.indexWhere((t) => t.id == saved.id);
              if (idx != -1) _transactions[idx] = saved;
            } else {
              _transactions.add(saved);
            }
          });
          _saveTx();
        },
      ),
    );
  }

  void _onDeleteTransaction(Transaction tx) {
    if (tx.memo.startsWith('회비_')) {
      final memberId = tx.memo.replaceFirst('회비_', '');
      setState(() {
        _transactions.removeWhere((t) => t.id == tx.id);
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
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    _saveTx();
    _snack('삭제되었습니다.');
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
        centerTitle: false,
        titleSpacing: -4,
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
            fontSize: 19,
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
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
            onRowTap: _showDuesDialog,
            onRowChanged: () {
              setState(() {});
              _saveDues();
            },
          ),
          TransactionTab(
            transactions: _transactions,
            onAddTap: () => _showTransactionDialog(),
            onEditTap: (tx) => _showTransactionDialog(tx: tx),
            onDelete: _onDeleteTransaction,
          ),
          SummaryTab(
            transactions: _transactions,
            summaryPeriod: _summaryPeriod,
            rangeStart: _rangeStart,
            rangeEnd: _rangeEnd,
            onPeriodChanged: (period, start, end) => setState(() {
              _summaryPeriod = period;
              if (start != null) _rangeStart = start;
              if (end != null) _rangeEnd = end;
            }),
          ),
        ],
      ),
    );
  }
}
