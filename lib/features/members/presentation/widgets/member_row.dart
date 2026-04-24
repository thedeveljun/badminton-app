import 'package:flutter/material.dart';
import '../../domain/models/member_item.dart';

class MemberRow extends StatelessWidget {
  final MemberItem member;
  final bool checked;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onMenuTap;
  final VoidCallback onPhoneTap;

  const MemberRow({
    super.key,
    required this.member,
    required this.checked,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.onChanged,
    required this.onMenuTap,
    required this.onPhoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onChanged,
                visualDensity: const VisualDensity(
                  horizontal: -3.5,
                  vertical: -3.5,
                ),
                side: const BorderSide(color: Color(0xFF666D76), width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: member.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: ' (${member.gender})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111111),
                              letterSpacing: -0.2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: ' ${member.birth}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A8A8A),
                              letterSpacing: -0.1,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${member.grade}조',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: -0.1,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onPhoneTap,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Color(0xFF3A7BD5),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    member.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3A7BD5),
                                      height: 1.0,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF3A7BD5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  onPressed: onMenuTap,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
