import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funminton_club_app/features/scoreboard/data/models/scoreboard_result_models.dart';

class ScoreboardBulkPlayerEditPage extends StatefulWidget {
  final String leftPlayer1;
  final String leftPlayer2;
  final String rightPlayer1;
  final String rightPlayer2;

  const ScoreboardBulkPlayerEditPage({
    super.key,
    required this.leftPlayer1,
    required this.leftPlayer2,
    required this.rightPlayer1,
    required this.rightPlayer2,
  });

  @override
  State<ScoreboardBulkPlayerEditPage> createState() =>
      _ScoreboardBulkPlayerEditPageState();
}

class _ScoreboardBulkPlayerEditPageState
    extends State<ScoreboardBulkPlayerEditPage> {
  late final TextEditingController _left1Controller;
  late final TextEditingController _left2Controller;
  late final TextEditingController _right1Controller;
  late final TextEditingController _right2Controller;

  String _displayOrEmpty(String value, String defaultLabel) {
    return value.trim() == defaultLabel ? '' : value.trim();
  }

  @override
  void initState() {
    super.initState();
    _left1Controller = TextEditingController(
      text: _displayOrEmpty(widget.leftPlayer1, '선수1'),
    );
    _left2Controller = TextEditingController(
      text: _displayOrEmpty(widget.leftPlayer2, '선수2'),
    );
    _right1Controller = TextEditingController(
      text: _displayOrEmpty(widget.rightPlayer1, '선수3'),
    );
    _right2Controller = TextEditingController(
      text: _displayOrEmpty(widget.rightPlayer2, '선수4'),
    );

    // 첫 프레임 완료 후 세로모드 전환 → 잘림 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
  }

  @override
  void dispose() {
    // 가로모드 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _left1Controller.dispose();
    _left2Controller.dispose();
    _right1Controller.dispose();
    _right2Controller.dispose();
    super.dispose();
  }

  void _swapTop() {
    final temp = _left1Controller.text;
    _left1Controller.text = _right1Controller.text;
    _right1Controller.text = temp;
    setState(() {});
  }

  void _swapBottom() {
    final temp = _left2Controller.text;
    _left2Controller.text = _right2Controller.text;
    _right2Controller.text = temp;
    setState(() {});
  }

  void _submit() {
    Navigator.pop(
      context,
      ScoreboardBulkPlayerEditResult(
        leftPlayer1: _left1Controller.text,
        leftPlayer2: _left2Controller.text,
        rightPlayer1: _right1Controller.text,
        rightPlayer2: _right2Controller.text,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 2.3),
      ),
    );
  }

  Widget _playerField({
    required TextEditingController controller,
    required String hint,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        maxLength: 12,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(hint),
      ),
    );
  }

  Widget _swapButton(VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1E88E5),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required VoidCallback onTap,
    required bool filled,
  }) {
    if (filled) {
      return SizedBox(
        width: 140,
        height: 46,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7E57C2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: onTap,
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return SizedBox(
      width: 140,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF7E57C2), width: 2.0),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onTap,
        child: const Text(
          '취소',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3EEF7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '선수명 입력',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 22, 18, bottomInset + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '선수명을 입력하세요',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              // 선수1 ↔ 선수3
              Row(
                children: [
                  Expanded(
                    child: _playerField(
                      controller: _left1Controller,
                      hint: '선수1',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _swapButton(_swapTop),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _playerField(
                      controller: _right1Controller,
                      hint: '선수3',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 선수2 ↔ 선수4
              Row(
                children: [
                  Expanded(
                    child: _playerField(
                      controller: _left2Controller,
                      hint: '선수2',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _swapButton(_swapBottom),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _playerField(
                      controller: _right2Controller,
                      hint: '선수4',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 취소 / 확인
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    text: '취소',
                    onTap: () => Navigator.pop(context),
                    filled: false,
                  ),
                  const SizedBox(width: 18),
                  _actionButton(text: '확인', onTap: _submit, filled: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
