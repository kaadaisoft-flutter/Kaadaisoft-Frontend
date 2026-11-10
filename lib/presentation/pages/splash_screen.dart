import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final String? redirectMemberId;

  const SplashScreen({super.key, this.redirectMemberId});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Ring rotation controller (2.2s loop)
  late final AnimationController _ringController;

  // Ambient glow & breathe controller (2.8s loop)
  late final AnimationController _breatheController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _logoScale;

  // Progress shimmer bar controller (1.8s loop)
  late final AnimationController _shimmerController;

  // Status text pulse controller (2.0s loop)
  late final AnimationController _statusController;
  late final Animation<double> _statusOpacity;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _glowScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _statusOpacity = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Parallelize token/session check and a minimum splash display duration
    final minDelay = kIsWeb
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 2200);

    final results = await Future.wait([
      _checkAuth(),
      Future.delayed(minDelay),
    ]);

    if (!mounted) return;

    final authData = results[0] as Map<String, dynamic>;
    final bool isLoggedIn = authData['isLoggedIn'] ?? false;

    Widget nextScreen;
    if (isLoggedIn) {
      nextScreen = AdminDashboard(
        userId: authData['userId'],
        userName: authData['userName'] ?? 'User',
        userRole: authData['userRole'] ?? 3,
        initialViewMemberId: widget.redirectMemberId,
      );
    } else {
      nextScreen = LoginPage(redirectMemberId: widget.redirectMemberId);
    }

    // Smooth fade transition to next screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      return {
        'isLoggedIn': isLoggedIn,
        'userId': prefs.getInt('userId'),
        'userName': prefs.getString('userName'),
        'userRole': prefs.getInt('userRole'),
      };
    } catch (e) {
      debugPrint('Error reading session: $e');
      return {'isLoggedIn': false};
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _breatheController.dispose();
    _shimmerController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B0A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Color(0xFF2B231D), // Warm center ambient glow
              Color(0xFF171311), // Deep brown vignette
              Color(0xFF0E0B0A), // Black edge
            ],
            stops: [0.0, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated circular logo unit
                _buildAnimatedLogo(),

                const SizedBox(height: 24),

                // Tamil Title
                const Text(
                  'பூந்துறை காடை குலம்',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF7EEDC),
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // English Subtitle
                const Text(
                  'POONDURAI KAADAI KULAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.2,
                    color: Color(0xFFC5A028),
                    shadows: [
                      Shadow(
                        color: Color(0x55C5A028),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Slim modern gold progress shimmer bar
                _buildProgressBar(),

                const SizedBox(height: 14),

                // Loading status text with soft breathing pulse
                AnimatedBuilder(
                  animation: _statusOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _statusOpacity.value,
                      child: child,
                    );
                  },
                  child: const Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      letterSpacing: 1.6,
                      color: Color(0xA6F5EEDC),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 156,
      height: 156,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient pulsing gold outer glow
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, child) {
              return Transform.scale(
                scale: _glowScale.value,
                child: Opacity(
                  opacity: _glowOpacity.value,
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x66C5A028),
                          Color(0x00C5A028),
                        ],
                        stops: [0.0, 0.75],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Rotating conical gold gradient ring
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _ringController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(144, 144),
                  painter: _GoldRingPainter(),
                ),
              );
            },
          ),

          // 3. Subtle inner dashed ring
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x44C5A028),
                width: 1,
              ),
            ),
          ),

          // 4. Central circular card with temple logo
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoScale.value,
                child: child,
              );
            },
            child: Container(
              width: 124,
              height: 124,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1915),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0x66C5A028),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/poondurai kaadaikulam image.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 180,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final t = _shimmerController.value;
            // Shimmer beam slides smoothly from -0.4 to 1.0 of the track
            final alignX = -1.6 + (t * 3.2);

            return Align(
              alignment: Alignment(alignX, 0),
              child: Container(
                width: 72,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFFC5A028),
                      Color(0xFFFFF3B0),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.75, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3FFE082),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the rotating gold ring
class _GoldRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFF856D1A),
          Color(0xFFC5A028),
          Color(0xFFFFF2A7),
          Colors.transparent,
        ],
        stops: [0.0, 0.25, 0.55, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

