import 'package:flutter/material.dart';

import '../../domain/models/member_item.dart';
import 'member_form_dialog.dart';

class MemberRegisterDialog extends StatelessWidget {
  final ValueChanged<MemberItem> onSubmit;

  const MemberRegisterDialog({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return MemberFormDialog(title: '회원등록', initialMember: null, key: key);
  }

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<MemberItem> onSubmit,
  }) async {
    final result = await showDialog<MemberItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MemberFormDialog(title: '회원등록'),
    );

    if (result != null) {
      onSubmit(result);
    }
  }
}
