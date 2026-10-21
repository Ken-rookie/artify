import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override State<LoadingScreen> createState() => _LoadingScreenState();
}
class _LoadingScreenState extends State<LoadingScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.brush, size: 58, color: AppColors.orange),
      const SizedBox(height: 18),
      const Text('Artify', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 28),
      const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2.5)),
      const SizedBox(height: 14),
      const Text('Getting your art supplies ready...', style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 20),
      TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
        child: const Text('Continue', style: TextStyle(color: AppColors.orange))),
    ]))),
  );
}
