import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'threat_detected_screen.dart';

const MethodChannel _channel = MethodChannel('phishsafe/screen_sharing');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isServiceRunning = true;
  bool hasNavigatedToThreatScreen = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _gradientController;
  Map<String, dynamic> _securityStatus = {};

  final List<String> _securityTips = [
    "Never share OTPs or passwords with anyone, even if they claim to be from support.",
    "Check URLs carefully before entering sensitive information.",
    "Enable two-factor authentication on all important accounts.",
    "Look for HTTPS and the padlock icon in your browser.",
    "Be wary of urgent or threatening messages asking for personal info.",
    "Regularly update your apps and operating system for security patches.",
    "Use a password manager to generate and store strong, unique passwords.",
    "Avoid using public Wi-Fi for sensitive transactions without a VPN.",
  ];

  int _currentTipIndex = 0;
  late final Future<void> _tipsRotation;

  @override
  void initState() {
    super.initState();

    // Initialize all animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Start rotating security tips
    _tipsRotation = _rotateSecurityTips();

    // Set up threat detection
    _setupThreatDetection();

    // Get initial security status
    _getSecurityStatus();
  }

  Future<void> _rotateSecurityTips() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _securityTips.length;
      });
    }
  }

  Future<void> _getSecurityStatus() async {
    try {
      final status = await _channel.invokeMethod('getSecurityStatus');
      if (mounted) {
        setState(() {
          _securityStatus = Map<String, dynamic>.from(status ?? {});
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Error getting security status: $e");
    }
  }

  void _setupThreatDetection() {
    FlutterBackgroundService().on('threatDetected').listen((event) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _navigateToThreatScreen();
      }
    });

    if (isServiceRunning) {
      _startScreenSharingWatcher();
    }
  }

  void _navigateToThreatScreen() {
    if (!hasNavigatedToThreatScreen && mounted) {
      hasNavigatedToThreatScreen = true;
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const ThreatDetectedScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                )),
                child: child,
              ),
            );
          },
        ),
      ).then((_) {
        if (mounted) {
          hasNavigatedToThreatScreen = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void stopService() {
    FlutterBackgroundService().invoke('stopService');
    if (mounted) {
      setState(() => isServiceRunning = false);
    }
  }

  Future<void> startService() async {
    await FlutterBackgroundService().startService();
    if (mounted) {
      setState(() {
        isServiceRunning = true;
        hasNavigatedToThreatScreen = false;
      });
      _startScreenSharingWatcher();
    }
  }

  Future<bool> checkScreenSharing() async {
    try {
      return await _channel.invokeMethod('isScreenSharing') ?? false;
    } on PlatformException catch (e) {
      debugPrint("Error checking screen sharing: $e");
      return false;
    }
  }

  Future<void> checkAndNavigateIfSharing() async {
    try {
      final isSharing = await checkScreenSharing();
      debugPrint("Screen sharing detected: $isSharing");

      if (isSharing && mounted && ModalRoute.of(context)?.isCurrent == true) {
        _navigateToThreatScreen();
      } else if (!isSharing && hasNavigatedToThreatScreen && mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          setState(() => hasNavigatedToThreatScreen = false);
          _showSnackBar(
            "✅ Screen sharing stopped",
            Colors.green.shade600,
            Icons.check_circle,
          );
        }
      }

      // Refresh security status whenever we check for screen sharing
      await _getSecurityStatus();
    } on PlatformException catch (e) {
      debugPrint("Error checking screen sharing: $e");
    }
  }

  void _showSnackBar(String text, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _startScreenSharingWatcher() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (isServiceRunning && mounted) {
        await checkAndNavigateIfSharing();
      }
      return isServiceRunning && mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.topRight,
                    startAngle: 0,
                    endAngle: _gradientController.value * 2 * 3.1416,
                    colors: [
                      Colors.deepPurple.shade50,
                      Colors.indigo.shade50,
                      Colors.blue.shade50,
                      Colors.deepPurple.shade50,
                    ],
                  ),
                ),
              );
            },
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: size.height * 0.28,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'PhishSafe',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade800,
                          Colors.indigo.shade700,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated floating particles
                        ...List.generate(15, (index) {
                          return Positioned(
                            left: (size.width * 0.2) + (index * 30),
                            top: (size.height * 0.1) + (index * 20),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ).animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                                .move(
                              duration: (3000 + index * 200).ms,
                              curve: Curves.easeInOut,
                              begin: Offset(0, -20),
                              end: Offset(0, 20),
                            )
                                .fade(
                              begin: 0.3,
                              end: 0.8,
                              duration: (2000 + index * 200).ms,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.security, color: Colors.white.withOpacity(0.9)),
                    onPressed: () => _showSecurityStatusDialog(context),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildStatusCard(theme),
                      const SizedBox(height: 32),
                      _buildControlButton(),
                      const SizedBox(height: 40),
                      _buildStatsSection(theme),
                      const SizedBox(height: 40),
                      _buildSecurityTip(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSecurityStatusDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isSecure = _securityStatus['isSecure'] ?? false;
    final isExternalDisplay = _securityStatus['isExternalDisplayConnected'] ?? false;
    final isRecordingPossible = _securityStatus['isScreenRecordingPossible'] ?? false;
    final isRecordingActive = _securityStatus['isScreenRecordingActive'] ?? false;
    final androidVersion = _securityStatus['androidVersion'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityStatusItem(
              'Secure Window',
              isSecure ? 'Enabled' : 'Disabled',
              isSecure ? Icons.check_circle : Icons.warning,
              isSecure ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSecurityStatusItem(
              'External Display',
              isExternalDisplay ? 'Connected' : 'Not connected',
              isExternalDisplay ? Icons.tv : Icons.tv_off,
              isExternalDisplay ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildSecurityStatusItem(
              'Screen Recording',
              isRecordingActive ? 'Active' : isRecordingPossible ? 'Possible' : 'Not possible',
              isRecordingActive ? Icons.videocam : Icons.videocam_off,
              isRecordingActive ? Colors.red : isRecordingPossible ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildSecurityStatusItem(
              'Android Version',
              'SDK $androidVersion',
              Icons.android,
              Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Animate(
      effects: [
        ScaleEffect(
          duration: 500.ms,
          curve: Curves.easeOutBack,
        ),
        ShimmerEffect(
          delay: 300.ms,
          duration: 1000.ms,
          color: Colors.white.withOpacity(0.2),
        ),
      ],
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: 600.ms,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isServiceRunning
                    ? _buildActiveProtectionIndicator()
                    : _buildPausedProtectionIndicator(),
              ),
              const SizedBox(height: 24),
              Text(
                isServiceRunning ? 'Protection Active' : 'Protection Paused',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isServiceRunning
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isServiceRunning
                    ? 'Your device is being monitored for phishing attempts'
                    : 'Background service is stopped',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveProtectionIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.green.shade100,
                Colors.green.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Animate(
          onPlay: (controller) => controller.repeat(),
          effects: [
            ScaleEffect(
              duration: 2000.ms,
              curve: Curves.easeInOut,
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
            ),
            ShimmerEffect(
              delay: 1000.ms,
              duration: 2000.ms,
              color: Colors.green.shade100,
            ),
          ],
          child: Icon(
            Icons.security_rounded,
            size: 80,
            color: Colors.green.shade600,
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedProtectionIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.red.shade100,
                Colors.red.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade200,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Animate(
          onPlay: (controller) => controller.repeat(),
          effects: [
            ShakeEffect(
              delay: 1000.ms,
              duration: 2000.ms,
              hz: 4,
              rotation: 0.05,
            ),
          ],
          child: Icon(
            Icons.warning_amber_rounded,
            size: 80,
            color: Colors.red.shade600,
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isServiceRunning ? stopService : startService,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isServiceRunning
                    ? [Colors.red.shade500, Colors.red.shade700]
                    : [Colors.green.shade500, Colors.green.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isServiceRunning
                      ? Colors.red.shade300
                      : Colors.green.shade300)
                      .withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isServiceRunning)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        child: Animate(
                          onPlay: (controller) => controller.repeat(),
                          effects: [
                            ScaleEffect(
                              duration: 2000.ms,
                              begin: const Offset(1, 1),
                              end: const Offset(1.5, 1.5),
                              curve: Curves.easeOut,
                            ),
                            FadeEffect(
                              begin: 0.5,
                              end: 0,
                              duration: 2000.ms,
                            ),
                          ],
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.shade100.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isServiceRunning
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isServiceRunning ? 'Stop Protection' : 'Start Protection',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'SECURITY OVERVIEW',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8),
              _buildStatCard(
                icon: Icons.shield,
                value: '24/7',
                label: 'Monitoring',
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.lock_clock,
                value: '0',
                label: 'Threats Today',
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.history,
                value: _securityStatus['isSecure'] == true ? '100%' : '80%',
                label: 'Reliability',
                color: _securityStatus['isSecure'] == true
                    ? Colors.purple.shade600
                    : Colors.orange.shade600,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.phonelink_lock,
                value: _securityStatus['isScreenRecordingPossible'] == true ? '∞' : 'Basic',
                label: 'Coverage',
                color: _securityStatus['isScreenRecordingPossible'] == true
                    ? Colors.deepPurple.shade600
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Animate(
      effects: [
        FadeEffect(duration: 500.ms),
        ScaleEffect(duration: 500.ms, curve: Curves.easeOutBack),
      ],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(ThemeData theme) {
    return Animate(
      effects: [
        FadeEffect(duration: 600.ms),
        SlideEffect(
          begin: const Offset(0, 0.2),
          duration: 600.ms,
          curve: Curves.easeOutQuart,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade100,
              Colors.indigo.shade100,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.deepPurple.shade800),
                const SizedBox(width: 10),
                Text(
                  'SECURITY TIP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: 600.ms,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _securityTips[_currentTipIndex],
                key: ValueKey<int>(_currentTipIndex),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.deepPurple.shade900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_currentTipIndex + 1}/${_securityTips.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.deepPurple.shade700.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}