import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dashboard_page.dart';

// ──────────────────────────────────────────────
// LEAKO — Welcome Page
// Theme: Mint Green (#6EDAA0) · White · Black
// ──────────────────────────────────────────────

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // ── Animations ──
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _btnLoginSlide;
  late Animation<double> _btnLoginFade;
  late Animation<Offset> _btnSignupSlide;
  late Animation<double> _btnSignupFade;
  late Animation<double> _pulse;

  // ── Colors ──
  static const Color _mintGreen = Color(0xFF6EDAA0);
  static const Color _darkGreen = Color(0xFF2E7D52);
  static const Color _bgDark = Color(0xFF0D1B14);
  static const Color _bgCard = Color(0xFF142A1E);
  static const Color _textWhite = Color(0xFFF5F5F5);
  static const Color _textGrey = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();

    // Fade + scale for the logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    // Slide-up for texts and buttons
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    _btnLoginSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _btnLoginFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );

    _btnSignupSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _btnSignupFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    // Pulse for the logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Start animations in sequence
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // ── Background gradient ──
          _buildBackground(size),

          // ── Floating particles ──
          _buildParticles(size),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.08),

                      // ── Logo with glow ──
                      _buildLogo(),

                      const SizedBox(height: 32),

                      // ── App name ──
                      _buildTitle(),

                      const SizedBox(height: 12),

                      // ── Subtitle ──
                      _buildSubtitle(),

                      SizedBox(height: size.height * 0.08),

                      // ── Login button ──
                      _buildLoginButton(),

                      const SizedBox(height: 16),

                      // ── Sign-up button ──
                      _buildSignupButton(),

                      SizedBox(height: size.height * 0.06),

                      // ── Footer ──
                      _buildFooter(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  BACKGROUND                                  ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgDark, const Color(0xFF0A2318), _bgDark],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  FLOATING PARTICLES                           ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _ParticlePainter(
            progress: _particleController.value,
            color: _mintGreen,
          ),
        );
      },
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  LOGO                                        ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _mintGreen.withValues(alpha: _pulse.value * 0.4),
                    blurRadius: 40 + (_pulse.value * 20),
                    spreadRadius: 5 + (_pulse.value * 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgCard,
                  border: Border.all(
                    color: _mintGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if logo not found
                    return Icon(
                      Icons.water_drop_outlined,
                      size: 60,
                      color: _mintGreen,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  TITLE                                       ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_textWhite, _mintGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'LEAKO',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  SUBTITLE                                    ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildSubtitle() {
    return SlideTransition(
      position: _subtitleSlide,
      child: FadeTransition(
        opacity: _subtitleFade,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [_mintGreen, _darkGreen],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Surveillance intelligente des fuites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: _textGrey,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  LOGIN BUTTON                                ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildLoginButton() {
    return SlideTransition(
      position: _btnLoginSlide,
      child: FadeTransition(
        opacity: _btnLoginFade,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardPage(
                    utilisateurId: 1,
                    nom: 'Technicien',
                    email: 'technicien@ocpgroup.ma',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mintGreen,
              foregroundColor: _bgDark,
              elevation: 0,
              shadowColor: _mintGreen.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, size: 22),
                SizedBox(width: 12),
                Text(
                  'Se connecter',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  SIGNUP BUTTON                               ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildSignupButton() {
    return SlideTransition(
      position: _btnSignupSlide,
      child: FadeTransition(
        opacity: _btnSignupFade,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to signup page
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _mintGreen,
              side: BorderSide(
                color: _mintGreen.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 22),
                SizedBox(width: 12),
                Text(
                  "S'inscrire",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  FOOTER                                      ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildFooter() {
    return FadeTransition(
      opacity: _btnSignupFade,
      child: Text(
        '© 2025 LEAKO · OCP Group',
        style: TextStyle(
          fontSize: 12,
          color: _textGrey.withValues(alpha: 0.5),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════╗
// ║  PARTICLE PAINTER — Floating ambient particles       ║
// ╚══════════════════════════════════════════════════════╝
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Generate deterministic particles
    final rng = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 1.5 + rng.nextDouble() * 2.5;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * math.pi;

      final x = baseX + math.sin((progress * 2 * math.pi * speed) + phase) * 30;
      final y =
          baseY + math.cos((progress * 2 * math.pi * speed * 0.7) + phase) * 20;

      final alpha = (0.08 + 0.15 * math.sin((progress * 2 * math.pi) + phase))
          .clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
