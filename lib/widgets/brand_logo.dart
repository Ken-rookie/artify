import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final bool light;
  final double size;
  const BrandLogo({super.key, this.light = false, this.size = 42});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    CustomPaint(size: Size(size * .78, size), painter: _MarkPainter()),
    SizedBox(width: size * .12),
    Text('Artify', style: TextStyle(fontSize: size * .57, fontWeight: FontWeight.w800,
      letterSpacing: -1.1, color: light ? Colors.white : AppColors.ink)),
  ]);
}
class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orange = Paint()..color = AppColors.orange;
    final white = Paint()..color = Colors.white;
    final path1 = Path()..moveTo(size.width*.06,size.height*.72)..quadraticBezierTo(size.width*.22,size.height*.24,size.width*.84,size.height*.02)..quadraticBezierTo(size.width*.75,size.height*.38,size.width*.06,size.height*.72);
    final path2 = Path()..moveTo(size.width*.12,size.height*.91)..quadraticBezierTo(size.width*.50,size.height*.58,size.width*.94,size.height*.28)..quadraticBezierTo(size.width*.76,size.height*.77,size.width*.12,size.height*.91);
    canvas.drawPath(path1, orange); canvas.drawPath(path2, white);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
