import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: FilledButton.icon(
      onPressed: onPressed, icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      style: FilledButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  );
}
