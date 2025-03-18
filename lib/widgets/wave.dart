import 'package:flutter/material.dart';

// Clipper personalizado para criar o efeito de onda
class WaveClipper extends CustomClipper<Path> {
  final bool flip;
  final double heightFactor;

  WaveClipper({this.flip = false, this.heightFactor = 1.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double height = size.height * heightFactor;

    if (!flip) {
      // Onda superior
      path.lineTo(0, height - 20);
      path.quadraticBezierTo(size.width / 4, height + 10, size.width / 2, height - 20);
      path.quadraticBezierTo(size.width * 3 / 4, height - 50, size.width, height - 20);
      path.lineTo(size.width, 0);
    } else {
      // Onda inferior - ajuste para evitar espaços retos
      path.moveTo(0, size.height);
      path.lineTo(0, size.height - height + 20);
      path.quadraticBezierTo(size.width / 4, size.height - height - 10, size.width / 2, size.height - height + 20);
      path.quadraticBezierTo(size.width * 3 / 4, size.height - height + 50, size.width, size.height - height + 20);
      path.lineTo(size.width, size.height);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
