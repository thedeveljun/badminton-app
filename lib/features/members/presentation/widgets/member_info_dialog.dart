import 'package:flutter/material.dart';

import '../../domain/models/member_item.dart';

class MemberInfoDialog extends StatelessWidget {
  final MemberItem member;

  const MemberInfoDialog({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('회원 정보'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이름: ${member.name}'),
          Text('성별: ${member.gender}'),
          Text('생년월일: ${member.birth}'),
          Text('급수: ${member.grade}'),
          Text('전화번호: ${member.phone}'),
          if (member.address.trim().isNotEmpty) Text('주소: ${member.address}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
