import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return IconButton(
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
      onPressed: () => Navigator.maybePop(context),
      padding: EdgeInsets.zero,
    );
  }
}

class AuthGradientLogo extends StatelessWidget {
  final double fontSize;
  final String? subtitle;

  const AuthGradientLogo({
    super.key,
    this.fontSize = 32,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'BookSwap',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSizes.s6),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);
    canvas.clipPath(Path()..addOval(rect));

    final colours = [
      (const Color(0xFFEA4335), -1.5708, 1.5708),
      (const Color(0xFFFBBC05), -3.1416, -1.5708),
      (const Color(0xFF34A853), 0.0, 1.5708),
      (const Color(0xFF4285F4), 1.5708, 3.1416),
    ];
    for (final (color, start, sweep) in colours) {
      canvas.drawArc(rect, start, sweep, true, Paint()..color = color);
    }

    canvas.drawCircle(Offset(cx, cy), r * 0.58, Paint()..color = Colors.white);

    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r, r * 0.36),
      Paint()..color = const Color(0xFF4285F4),
    );

    canvas.drawCircle(Offset(cx, cy), r * 0.56, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class AuthAgreementText extends StatelessWidget {
  const AuthAgreementText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class AuthTitle extends StatelessWidget {
  final String text;
  const AuthTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );
  }
}

class AuthSubtitle extends StatelessWidget {
  final String text;
  const AuthSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
    );
  }
}
