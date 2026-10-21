import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import 'loading_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _BrushPattern())),
      Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const BrandLogo(light: true, size: 76),
        const SizedBox(height: 18),
        const Text('Create More\nWith the Right Tools', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.45)),
        const SizedBox(height: 46),
        const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.orange)),
        const SizedBox(height: 12),
        const Text('Loading...', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 30),
        TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoadingScreen())),
          child: const Text('Continue', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold))),
      ]))),
    ])),
  );
}
class _BrushPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.orange.withValues(alpha: .11)..strokeWidth = 11..strokeCap = StrokeCap.round;
    for (int i=0; i<12; i++) {
      final x = (i * 83.0) % size.width;
      final y = (i * 127.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 35, y - 56), p);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
