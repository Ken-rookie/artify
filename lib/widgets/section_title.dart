import 'package:flutter/material.dart';
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
    if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
  ]);
}
