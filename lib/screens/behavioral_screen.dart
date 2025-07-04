import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:phishsafe_app/utils/behavior_logger.dart';

class BehavioralScreen extends StatefulWidget {
  const BehavioralScreen({super.key});

  @override
  State<BehavioralScreen> createState() => _BehavioralScreenState();
}

class _BehavioralScreenState extends State<BehavioralScreen> {
  final BehaviorLogger _logger = BehaviorLogger(userId: 'current_user', maxTapCount: 50); // Updated with user ID and tap limit
  late DateTime _screenOpenedTime;
  final List<int> _tapDelays = [];
  Timer? _idleTimer;
  bool _showHesitation = false;
  bool _isLoading = false;
  bool _tapLimitReached = false; // New state for tap limit

  @override
  void initState() {
    super.initState();
    _screenOpenedTime = DateTime.now();
    _logger.logScreenOpen('BehavioralScreen');
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showHesitation = true);
        _logger.logCustom('hesitation', {'seconds': 10});
      }
    });
  }

  void _recordTap() {
    if (_tapLimitReached) return; // Don't process if limit reached

    final now = DateTime.now();
    final delay = now.difference(_screenOpenedTime).inMilliseconds;

    setState(() {
      _tapDelays.add(delay);
      _showHesitation = false;
    });

    _logger.logTap('BehavioralScreen');
    _logger.logCustom('tap_delay', {'value_ms': delay});
    _startIdleTimer();

    // Check if tap limit was reached after this tap
    if (_logger.logs.length >= _logger.maxTapCount && !_tapLimitReached) {
      setState(() => _tapLimitReached = true);
      _showTapLimitReachedSnackbar();
    }
  }

  void _showTapLimitReachedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tap limit reached for this session'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveLogs() async {
    setState(() => _isLoading = true);
    try {
      final path = await _logger.saveToFile(); // Updated to use logger's method
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Behavioral logs saved successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save logs: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _averageTapDelay() {
    if (_tapDelays.isEmpty) return 0;
    return _tapDelays.reduce((a, b) => a + b) / _tapDelays.length;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avgDelay = _averageTapDelay().toStringAsFixed(0);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Biometrics'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade700,
                Colors.indigo.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 28,
                          color: Colors.deepPurple.shade400,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Behavioral Analysis',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Interact with the button below. We analyze your tap patterns and response times to enhance security.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                    ),
                    if (_tapLimitReached) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap limit reached (${_logger.maxTapCount} taps). Data collection continues for other events.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _recordTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _tapLimitReached ? Colors.grey : Colors.deepPurple.shade400,
                        _tapLimitReached ? Colors.grey.shade600 : Colors.indigo.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_tapLimitReached ? Colors.grey : Colors.deepPurple).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tapLimitReached ? 'Limit Reached' : 'Tap Here',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_tapLimitReached) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_logger.maxTapCount} taps logged',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          icon: Icons.timeline,
                          color: Colors.blue,
                          title: 'Total Taps',
                          value: '${_tapDelays.length}/${_logger.maxTapCount}',
                        ),
                        _buildStatItem(
                          icon: Icons.speed,
                          color: Colors.green,
                          title: 'Avg Delay',
                          value: '$avgDelay ms',
                        ),
                      ],
                    ),
                    if (_showHesitation) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hesitation detected in your interaction',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Save Behavioral Data',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This data helps us build a unique behavioral profile to detect anomalies.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}