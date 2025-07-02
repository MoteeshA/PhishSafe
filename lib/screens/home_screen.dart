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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool isServiceRunning = true;
  bool hasNavigatedToThreatScreen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);

    // Threat detection listeners
    _setupThreatDetection();
  }

  void _setupThreatDetection() {
    // Background service threat detection
    FlutterBackgroundService().on('threatDetected').listen((event) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _navigateToThreatScreen();
      }
    });

    // Start screen sharing watcher if service is running
    if (isServiceRunning) {
      _startScreenSharingWatcher();
    }
  }

  void _navigateToThreatScreen() {
    if (!hasNavigatedToThreatScreen && mounted) {
      hasNavigatedToThreatScreen = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ThreatDetectedScreen()),
      ).then((_) => hasNavigatedToThreatScreen = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      } else if (!isSharing && hasNavigatedToThreatScreen) {
        // Auto-return to HomeScreen when sharing stops
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          hasNavigatedToThreatScreen = false;
          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Screen sharing stopped", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error checking screen sharing: $e");
    }
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
      backgroundColor: Colors.grey.withOpacity(0.05),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.25,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PhishSafe',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
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
                      Colors.deepPurple.shade700,
                      Colors.indigo.shade600,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {},
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
                  const SizedBox(height: 32),
                  _buildStatsSection(theme),
                  const SizedBox(height: 40),
                  _buildSecurityTip(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return AnimatedScale(
      scale: isServiceRunning ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
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
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.shade50,
          ),
        ),
        Animate(
          onPlay: (controller) => controller.repeat(),
          effects: [
            ShimmerEffect(
              delay: 1000.ms,
              duration: 2000.ms,
              color: Colors.green.shade100,
            ),
          ],
          child: Icon(
            Icons.verified,
            size: 80,
            color: Colors.green.shade600,
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
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade50,
          ),
        ),
        Animate(
          onPlay: (controller) => controller.repeat(),
          effects: [
            ShakeEffect(
              delay: 1000.ms,
              duration: 2000.ms,
            ),
          ],
          child: Icon(
            Icons.warning_rounded,
            size: 80,
            color: Colors.red.shade600,
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
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: isServiceRunning
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.green.shade400, Colors.green.shade600],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isServiceRunning
                      ? Colors.red.shade200
                      : Colors.green.shade200)
                      .withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isServiceRunning
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isServiceRunning ? 'Stop Protection' : 'Start Protection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
          'Security Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
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
                value: '100%',
                label: 'Reliability',
                color: Colors.purple.shade600,
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.deepPurple.shade600),
              const SizedBox(width: 8),
              Text(
                'Security Tip',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Never share your personal information in response to unexpected requests, '
                'even if they appear to come from trusted sources.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}