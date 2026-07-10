import 'package:flutter/material.dart';

/// App-wide theme matching the original uni-app glassmorphism design
class AppTheme {
  // Brand colors
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pinkGradient = LinearGradient(
    colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const blueGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism card style
  static BoxDecoration glassCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0x99FFFFFF), Color(0x88FFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Brand icon gradient
  static BoxDecoration brandIconDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x59667EEA),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Tab active decoration
  static BoxDecoration tabActiveDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: const BorderRadius.all(Radius.circular(11)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x59667EEA),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Tab inactive decoration
  static BoxDecoration tabInactiveDecoration = const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(11)),
  );

  // Glass container for inputs
  static BoxDecoration glassContainerDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0x99FFFFFF), Color(0x88FFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    border: Border.all(color: const Color(0x66FFFFFF), width: 1),
  );

  // Prompt input style
  static BoxDecoration promptInputDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xB2FFFFFF), Color(0xB2FFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    border: Border.all(color: const Color(0x80FFFFFF), width: 1),
  );

  // Focus border color
  static const focusBorderColor = Color(0x80667EEA);

  // Colors
  static const textColorPrimary = Color(0xFF1D1D1F);
  static const textColorSecondary = Color(0xFF666666);
  static const textColorHint = Color(0xFF999999);
  static const textColorSubtle = Color(0xFFCCCCCC);
  static const errorColor = Color(0xFFF56C6C);
  static const successColor = Color(0xFF67C23A);

  // Background colors
  static const bgColor = Color(0xFFFAFBFF);

  // Font sizes
  static const fontSizeBrand = 26.0;
  static const fontSizeTitle = 18.0;
  static const fontSizeBody = 15.0;
  static const fontSizeSmall = 13.0;
  static const fontSizeTiny = 11.0;

  // Spacing
  static const spacingXS = 4.0;
  static const spacingSM = 8.0;
  static const spacingMD = 16.0;
  static const spacingLG = 24.0;
  static const spacingXL = 40.0;

  /// Build the animated background orbs
  static Widget buildBackground(BuildContext context) {
    return Stack(
      children: [
        _AnimatedOrb(
          size: _responsiveOrbSize(context, 400, 250),
          gradient: AppTheme.primaryGradient,
          top: -100,
          left: -100,
        ),
        _AnimatedOrb(
          size: _responsiveOrbSize(context, 350, 200),
          gradient: AppTheme.pinkGradient,
          bottom: -80,
          right: -80,
        ),
        _AnimatedOrb(
          size: _responsiveOrbSize(context, 250, 150),
          gradient: AppTheme.blueGradient,
          center: true,
        ),
      ],
    );
  }

  static double _responsiveOrbSize(BuildContext context, double desktop, double mobile) {
    return MediaQuery.of(context).size.width < 640 ? mobile : desktop;
  }
}

class _AnimatedOrb extends StatefulWidget {
  final double size;
  final Gradient gradient;
  final double? top, left, bottom, right;
  final bool center;

  const _AnimatedOrb({
    required this.size,
    required this.gradient,
    this.top,
    this.left,
    this.bottom,
    this.right,
    this.center = false,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        double dx, dy, scale;

        if (widget.center) {
          dx = (t < 0.5 ? t * 40 : -(t - 0.5) * 30);
          dy = (t < 0.5 ? -t * 40 : (t - 0.5) * 30);
          scale = 0.96 + t * 0.08;
        } else if (widget.top != null && widget.left != null) {
          dx = (t < 0.25 ? 30 : t < 0.5 ? -20 : t < 0.75 ? 0 : 20);
          dy = (t < 0.25 ? -30 : t < 0.5 ? 20 : t < 0.75 ? -20 : 10);
          scale = 0.95 + (t < 0.5 ? t * 0.1 : (1 - t) * 0.1);
        } else {
          dx = (t < 0.25 ? -25 : t < 0.5 ? 15 : t < 0.75 ? -15 : 0);
          dy = (t < 0.25 ? 25 : t < 0.5 ? -15 : t < 0.75 ? -10 : 0);
          scale = 0.97 + (t < 0.5 ? t * 0.06 : (1 - t) * 0.06);
        }

        return Stack(
          children: [
            if (widget.center)
              Positioned(
                left: size.width / 2 - widget.size / 2 + dx,
                top: size.height / 2 - widget.size / 2 + dy,
                width: widget.size,
                height: widget.size,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              )
            else
              Positioned(
                top: widget.top,
                left: widget.left,
                bottom: widget.bottom,
                right: widget.right,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              ),
          ],
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.gradient,
        ),
      ),
    );
  }
}
