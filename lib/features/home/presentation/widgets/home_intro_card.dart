import 'package:flutter/material.dart';
import '../../../members/utils/member_storage.dart';
import '../../../finance/presentation/screens/finance_models.dart';

class HomeIntroCard extends StatefulWidget {
  const HomeIntroCard({super.key});

  // 전역 RouteObserver — 앱 전체에서 공유
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  @override
  State<HomeIntroCard> createState() => _HomeIntroCardState();
}

class _HomeIntroCardState extends State<HomeIntroCard>
    with WidgetsBindingObserver, RouteAware {
  int _memberCount = 0;
  int _newMemberCount = 0;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      HomeIntroCard.routeObserver.subscribe(this, route);
    }
    _loadStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HomeIntroCard.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStats();
    }
  }

  // 다른 화면에서 돌아올 때 호출됨 (RouteAware)
  @override
  void didPopNext() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final members = await MemberStorage.loadMembers();
      final total = members?.length ?? 0;

      int balance = 0;
      try {
        final txs = await FinanceStorage.loadTx();
        int income = 0;
        int expense = 0;
        for (final tx in txs) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
        balance = income - expense;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _memberCount = total;
        _newMemberCount = total;
        _balance = balance;
      });
    } catch (_) {}
  }

  String _formatNumber(int n) {
    final abs = n.abs();
    final s = abs.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-${buf.toString()}' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      size: 24,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '편민턴',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '클럽 플랫폼',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  '운동은 즐겁게',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCFFF5E),
                    height: 1.2,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  '클럽운영은 스마트하게',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCFFF5E),
                    height: 1.2,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '회원관리 · 재정관리 · 대진표 한 번에',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          color: const Color(0xFF0B1F44),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _StatItem(value: '$_memberCount명', label: '회원수'),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withOpacity(0.14),
              ),
              Expanded(
                flex: 3,
                child: _StatItem(value: '$_newMemberCount명', label: '신규회원'),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withOpacity(0.14),
              ),
              Expanded(
                flex: 5,
                child: _StatItem(value: _formatNumber(_balance), label: '현재잔액'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.68),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
