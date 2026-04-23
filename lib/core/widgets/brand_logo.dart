import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool hasShadow;
  final double? opacity;

  const BrandLogo({
    super.key, 
    this.size = 32.0, 
    this.hasShadow = false,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity ?? 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: hasShadow ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.1),
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
