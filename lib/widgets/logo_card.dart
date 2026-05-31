import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoCard extends StatelessWidget {
  final double size;
  const LogoCard({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stylized premium Serif P
              Text(
                "P",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  color: AppColors.tosca,
                  height: 1.0,
                ),
              ),
              // Subtle abstract lines to match the Figma vector styling
              Positioned(
                left: size * 0.2,
                top: size * 0.32,
                child: Container(
                  width: size * 0.3,
                  height: 2,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Positioned(
                left: size * 0.2,
                top: size * 0.44,
                child: Container(
                  width: size * 0.25,
                  height: 2,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
