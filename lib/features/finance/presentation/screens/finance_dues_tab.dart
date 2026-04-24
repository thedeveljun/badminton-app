import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'finance_models.dart';

class DuesTab extends StatefulWidget {
  final List<DuesRecord> dues;
  final List<DuesRecord> filteredDues;
  final int totalDues;
  final int paidCount;
  final int unpaidCount;
  final int unpaidTotal;
  final int defaultDuesAmount;
  final int discountAge;
  final int ageDiscountAmount;
  final int studentDiscountAmount;
  final TextEditingController searchCtrl;
  final String filterStatus;
  final void Function(String) onFilterChanged;
  final void Function(int) onDefaultAmtConfirm;
  final void Function(int age, int amount) onAgeDiscountConfirm;
  final void Function(int amount) onStudentDiscountConfirm;
  final void Function(DuesRecord) onRowTap;
  final VoidCallback onRowChanged;

  const DuesTab({
    super.key,
    required this.dues,
    required this.filteredDues,
    required this.totalDues,
    required this.paidCount,
    required this.unpaidCount,
    required this.unpaidTotal,
    required this.defaultDuesAmount,
    required this.discountAge,
    required this.ageDiscountAmount,
    required this.studentDiscountAmount,
    required this.searchCtrl,
    required this.filterStatus,
    required this.onFilterChanged,
    required this.onDefaultAmtConfirm,
    required this.onAgeDiscountConfirm,
    required this.onStudentDiscountConfirm,
    required this.onRowTap,
    required this.onRowChanged,
  });

  @override
  State<DuesTab> createState() => _DuesTabState();
}

class _DuesTabState extends State<DuesTab> {
  late final TextEditingController _defaultCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _ageAmountCtrl;
  late final TextEditingController _studentAmountCtrl;

  String _selectedDiscountKind = 'none';

  @override
  void initState() {
    super.initState();
    _defaultCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _ageAmountCtrl = TextEditingController();
    _studentAmountCtrl = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant DuesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultDuesAmount != widget.defaultDuesAmount ||
        oldWidget.discountAge != widget.discountAge ||
        oldWidget.ageDiscountAmount != widget.ageDiscountAmount ||
        oldWidget.studentDiscountAmount != widget.studentDiscountAmount) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    _defaultCtrl.text = fmtAmt(widget.defaultDuesAmount).replaceAll('원', '');
    _ageCtrl.text = widget.discountAge.toString();
    _ageAmountCtrl.text = fmtAmt(widget.ageDiscountAmount).replaceAll('원', '');
    _studentAmountCtrl.text = fmtAmt(
      widget.studentDiscountAmount,
    ).replaceAll('원', '');
  }

  @override
  void dispose() {
    _defaultCtrl.dispose();
    _ageCtrl.dispose();
    _ageAmountCtrl.dispose();
    _studentAmountCtrl.dispose();
    super.dispose();
  }

  bool _isDiscountTarget(DuesRecord r) => r.discountType != 'none';

  int _expectedAmount(DuesRecord r) {
    switch (r.discountType) {
      case 'age':
        return widget.ageDiscountAmount;
      case 'student':
        return widget.studentDiscountAmount;
      case 'free':
        return 0;
      default:
        return widget.defaultDuesAmount;
    }
  }

  Color _discountChipBg(String kind, bool selected) {
    if (!selected) return const Color(0xFFF0F4FA);
    switch (kind) {
      case 'age':
        return const Color(0xFF5B8ABB);
      case 'student':
        return const Color(0xFF4A9E6B);
      case 'free':
        return const Color(0xFFC58A00);
      default:
        return const Color(0xFF687385);
    }
  }

  Color _discountChipBorder(String kind, bool selected) {
    if (!selected) return const Color(0xFFCDD5DF);
    switch (kind) {
      case 'age':
        return const Color(0xFF5B8ABB);
      case 'student':
        return const Color(0xFF4A9E6B);
      case 'free':
        return const Color(0xFFC58A00);
      default:
        return const Color(0xFF687385);
    }
  }

  void _confirmDefault() {
    final defaultAmt =
        int.tryParse(_defaultCtrl.text.replaceAll(',', '').trim()) ??
        widget.defaultDuesAmount;
    widget.onDefaultAmtConfirm(defaultAmt);
  }

  void _confirmAgeDiscount() {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? widget.discountAge;
    final amount =
        int.tryParse(_ageAmountCtrl.text.replaceAll(',', '').trim()) ??
        widget.ageDiscountAmount;
    widget.onAgeDiscountConfirm(age, amount);
  }

  void _confirmStudentDiscount() {
    final amount =
        int.tryParse(_studentAmountCtrl.text.replaceAll(',', '').trim()) ??
        widget.studentDiscountAmount;
    widget.onStudentDiscountConfirm(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color.fromARGB(255, 10, 36, 92),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusChip(
                    label: '납부',
                    count: widget.paidCount,
                    color: const Color(0xFF4A9E6B),
                  ),
                  const SizedBox(width: 6),
                  StatusChip(
                    label: '미납',
                    count: widget.unpaidCount,
                    color: const Color(0xFFAAAAAA),
                    bgColor: const Color(0x33AAAAAA),
                  ),
                  const SizedBox(width: 6),
                  StatusChip(
                    label: '전체',
                    count: widget.dues.length,
                    color: const Color(0xFF9DC3E6),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountSummaryBlock(
                      label: '납부총액',
                      amount: widget.totalDues,
                      color: const Color(0xFFFFC300),
                      transparent: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AmountSummaryBlock(
                      label: '미납총액',
                      amount: widget.unpaidTotal,
                      color: const Color.fromARGB(255, 247, 248, 248),
                      transparent: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '기본회비',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SettingAmountField(
                      controller: _defaultCtrl,
                      suffix: '원',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _confirmDefault,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B8ABB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '할인구분',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DiscountKindChip(
                    label: '일반',
                    selected: _selectedDiscountKind == 'none',
                    bg: _discountChipBg(
                      'none',
                      _selectedDiscountKind == 'none',
                    ),
                    border: _discountChipBorder(
                      'none',
                      _selectedDiscountKind == 'none',
                    ),
                    onTap: () => setState(() => _selectedDiscountKind = 'none'),
                  ),
                  const SizedBox(width: 4),
                  _DiscountKindChip(
                    label: '연령',
                    selected: _selectedDiscountKind == 'age',
                    bg: _discountChipBg('age', _selectedDiscountKind == 'age'),
                    border: _discountChipBorder(
                      'age',
                      _selectedDiscountKind == 'age',
                    ),
                    onTap: () => setState(() => _selectedDiscountKind = 'age'),
                  ),
                  const SizedBox(width: 4),
                  _DiscountKindChip(
                    label: '학생',
                    selected: _selectedDiscountKind == 'student',
                    bg: _discountChipBg(
                      'student',
                      _selectedDiscountKind == 'student',
                    ),
                    border: _discountChipBorder(
                      'student',
                      _selectedDiscountKind == 'student',
                    ),
                    onTap: () =>
                        setState(() => _selectedDiscountKind = 'student'),
                  ),
                  const SizedBox(width: 4),
                  _DiscountKindChip(
                    label: '무료',
                    selected: _selectedDiscountKind == 'free',
                    bg: _discountChipBg(
                      'free',
                      _selectedDiscountKind == 'free',
                    ),
                    border: _discountChipBorder(
                      'free',
                      _selectedDiscountKind == 'free',
                    ),
                    onTap: () => setState(() => _selectedDiscountKind = 'free'),
                  ),
                ],
              ),
              if (_selectedDiscountKind == 'age') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 54,
                      child: _SettingNumberField(
                        controller: _ageCtrl,
                        hint: '나이',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '세 이상',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SettingAmountField(
                        controller: _ageAmountCtrl,
                        suffix: '원',
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _confirmAgeDiscount,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B8ABB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedDiscountKind == 'student') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SettingAmountField(
                        controller: _studentAmountCtrl,
                        suffix: '원',
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _confirmStudentDiscount,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9E6B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedDiscountKind == 'free') ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6DA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4C96A)),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '무료 회원은 0원으로 처리됩니다.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A5500),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        Container(
          color: const Color(0xFFF6F7FA),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: widget.searchCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF222222),
                    ),
                    decoration: InputDecoration(
                      hintText: '이름 검색',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9AA1AB),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF9AA1AB),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4D8DE),
                          width: 1.1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B8ABB),
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (_) => widget.onRowChanged(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              for (final s in ['전체', '납부', '미납']) ...[
                FilterPill(
                  text: s,
                  selected: widget.filterStatus == s,
                  onTap: () => widget.onFilterChanged(s),
                ),
                if (s != '미납') const SizedBox(width: 4),
              ],
            ],
          ),
        ),

        Expanded(
          child: widget.dues.isEmpty
              ? const Center(
                  child: Text(
                    '회원관리에서 회원을 먼저 등록해주세요.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                )
              : widget.filteredDues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 36,
                        color: Color(0xFFCCCCCC),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${widget.searchCtrl.text}" 검색 결과가 없습니다.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                  itemCount: widget.filteredDues.length,
                  itemBuilder: (_, i) {
                    final r = widget.filteredDues[i];
                    return DuesRow(
                      record: r,
                      expectedAmount: _expectedAmount(r),
                      isDiscountTarget: _isDiscountTarget(r),
                      onChanged: widget.onRowChanged,
                      onTap: () => widget.onRowTap(r),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class DuesRow extends StatelessWidget {
  final DuesRecord record;
  final int expectedAmount;
  final bool isDiscountTarget;
  final VoidCallback onChanged;
  final VoidCallback onTap;

  const DuesRow({
    super.key,
    required this.record,
    required this.expectedAmount,
    required this.isDiscountTarget,
    required this.onChanged,
    required this.onTap,
  });

  Color _badgeColor() {
    switch (record.discountType) {
      case 'age':
        return const Color(0xFFE9F3FF);
      case 'student':
        return const Color(0xFFEAF5EA);
      case 'free':
        return const Color(0xFFFFF0C0);
      default:
        return const Color(0xFFE9F3FF);
    }
  }

  Color _badgeBorder() {
    switch (record.discountType) {
      case 'age':
        return const Color(0xFF8BB3E8);
      case 'student':
        return const Color(0xFF8BC98B);
      case 'free':
        return const Color(0xFFE4C96A);
      default:
        return const Color(0xFF8BB3E8);
    }
  }

  Color _badgeText() {
    switch (record.discountType) {
      case 'age':
        return const Color(0xFF2A4A7C);
      case 'student':
        return const Color(0xFF2A6A2A);
      case 'free':
        return const Color(0xFF7A5500);
      default:
        return const Color(0xFF2A4A7C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isPaid
        ? const Color(0xFF4A9E6B)
        : const Color.fromARGB(255, 112, 112, 112);
    final statusText = record.isPaid ? '납부' : '미납';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: record.isPaid
              ? const Color(0xFFEAF5EA)
              : const Color.fromARGB(255, 227, 227, 227),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: record.isPaid
                ? const Color(0xFF8BC98B)
                : const Color(0xFFD4D8DE),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 22,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      record.memberName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDiscountTarget)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeColor(),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _badgeBorder()),
                        ),
                        child: Text(
                          discountTypeLabel(record.discountType),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _badgeText(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.amount > 0 || record.discountType == 'free'
                        ? fmtAmt(record.amount)
                        : '-',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: record.isPaid
                          ? const Color(0xFF1A5C30)
                          : const Color.fromARGB(255, 80, 80, 80),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.paidDate.isNotEmpty)
                    Text(
                      record.paidDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 49, 49, 49),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

class _DiscountKindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _DiscountKindChip({
    required this.label,
    required this.selected,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: selected ? 1.4 : 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF555555),
        ),
      ),
    ),
  );
}

class _SettingAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  const _SettingAmountField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F4FA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB8D0EC), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5B8ABB), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SettingNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SettingNumberField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F4FA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB8D0EC), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5B8ABB), width: 1.5),
          ),
        ),
      ),
    );
  }
}
