import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phishsafe_app/screens/home_screen.dart';

class FeaturePage extends StatefulWidget {
  const FeaturePage({super.key});

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  final double _headerHeight = 280.0;

  // Modern color palette
  final Color _primaryColor = const Color(0xFF4361EE); // Vibrant blue
  final Color _secondaryColor = const Color(0xFF3A0CA3); // Deep purple
  final Color _accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color _darkColor = const Color(0xFF212529); // Dark
  final Color _lightColor = const Color(0xFFF8F9FA); // Light

  // Feature data
  final List<Map<String, dynamic>> _features = [
    {
      'title': "Screen Sharing Detection",
      'description': "Detects when your screen is being shared or recorded",
      'icon': Icons.screen_share,
      'color': const Color(0xFF4361EE),
    },
    {
      'title': "Behavioral Biometrics",
      'description': "Analyzes your unique interaction patterns",
      'icon': Icons.fingerprint,
      'color': const Color(0xFF3A0CA3),
    },
    {
      'title': "Real-time Phishing Alerts",
      'description': "Warns you about suspicious websites and links",
      'icon': Icons.warning_amber,
      'color': const Color(0xFFF72585),
    },
    {
      'title': "Session Integrity Check",
      'description': "Ensures no unauthorized access during banking",
      'icon': Icons.verified_user,
      'color': const Color(0xFF4CC9F0),
    },
    {
      'title': "Device Anomaly Detection",
      'description': "Identifies suspicious device activity",
      'icon': Icons.device_unknown,
      'color': const Color(0xFF7209B7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 200 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
        backgroundColor: _primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.arrow_upward, color: Colors.white),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutQuint,
          );
        },
      ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.5)
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Parallax Header
          SliverAppBar(
            expandedHeight: _headerHeight,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Security Features',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(1, 1),
                      )
                    ],
                  )),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Modern gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor,
                          _secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Animated floating elements
                  Positioned(
                    top: 50,
                    left: 30,
                    child: _buildFloatingCircle(
                      size: 80,
                      color: Colors.white.withOpacity(0.1),
                      delay: 200,
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: _buildFloatingCircle(
                      size: 60,
                      color: Colors.white.withOpacity(0.15),
                      delay: 400,
                    ),
                  ),

                  // Main icon with modern shine effect
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 0.8],
                        ),
                      ),
                      child: Icon(
                        Icons.security,
                        size: 100,
                        color: Colors.white,
                      ).animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                        duration: 2000.ms,
                        delay: 800.ms,
                        angle: -0.5,
                      ).then().shake(duration: 1000.ms),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // CTA Section moved to top
                  _buildTopCTASection(),
                  const SizedBox(height: 24),

                  // Feature Buttons Section
                  _buildFeatureButtonsSection(),
                  const SizedBox(height: 24),

                  // Features Section
                  _buildSectionHeader(
                    title: "Advanced Protection",
                    subtitle: "Comprehensive security features",
                    delay: 500,
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturesList(),
                  const SizedBox(height: 40),

                  // How It Works
                  _buildSectionHeader(
                    title: "How It Protects You",
                    subtitle: "Real-time security monitoring",
                    delay: 600,
                  ),
                  const SizedBox(height: 16),
                  _buildHowItWorks(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircle({required double size, required Color color, int delay = 0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    ).animate(delay: delay.ms)
        .scaleXY(begin: 0, end: 1, curve: Curves.easeOutBack)
        .fadeIn();
  }

  Widget _buildAnimatedSection({required Widget child, int delay = 0}) {
    return Animate(
      effects: [
        FadeEffect(duration: 800.ms, delay: delay.ms),
        SlideEffect(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
          duration: 800.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: child,
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle, int delay = 0}) {
    return _buildAnimatedSection(
      delay: delay,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _darkColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCTASection() {
    return _buildAnimatedSection(
      delay: 100,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withOpacity(0.9),
              _secondaryColor.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Ready to Enable Protection?",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                "Activate All Features",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ).animate(delay: 200.ms)
                .scaleXY(begin: 0.9, curve: Curves.easeOutBack)
                .fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButtonsSection() {
    return _buildAnimatedSection(
      delay: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFeatureButton(
                icon: Icons.screen_share,
                label: "Screen Guard",
                color: _primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              _buildFeatureButton(
                icon: Icons.fingerprint,
                label: "Biometrics",
                color: _secondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              _buildFeatureButton(
                icon: Icons.warning,
                label: "Phishing Alert",
                color: const Color(0xFFF72585),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              _buildFeatureButton(
                icon: Icons.verified_user,
                label: "Session Lock",
                color: _accentColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              _buildFeatureButton(
                icon: Icons.device_unknown,
                label: "Device Check",
                color: const Color(0xFF7209B7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Animate(
      effects: [
        FadeEffect(duration: 600.ms),
        ScaleEffect(
          begin: const Offset(0.9, 0.9),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        ),
      ],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _darkColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: _features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return _buildAnimatedSection(
          delay: 200 + (index * 100),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFeatureCard(
              title: feature['title'],
              description: feature['description'],
              icon: feature['icon'],
              color: feature['color'],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.4),
                  ],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: _darkColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      children: [
        _buildStep(
          number: 1,
          title: "Continuous Monitoring",
          description: "Constantly analyzes your banking session for threats",
          icon: Icons.monitor_heart,
          color: _primaryColor,
          delay: 200,
        ),
        const SizedBox(height: 16),
        _buildStep(
          number: 2,
          title: "Threat Detection",
          description: "Identifies suspicious activity in real-time",
          icon: Icons.warning_amber,
          color: _secondaryColor,
          delay: 300,
        ),
        const SizedBox(height: 16),
        _buildStep(
          number: 3,
          title: "Automatic Protection",
          description: "Takes action to secure your session when needed",
          icon: Icons.security,
          color: _accentColor,
          delay: 400,
        ),
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    int delay = 0,
  }) {
    return _buildAnimatedSection(
      delay: delay,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _darkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: _darkColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
        ),
      ),
    );
  }
}