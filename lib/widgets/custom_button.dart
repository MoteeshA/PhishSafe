import 'package:flutter/material.dart';
import '../services/behaviour_tracker.dart';

class HesitationButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const HesitationButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  @override
  State<HesitationButton> createState() => _HesitationButtonState();
}

class _HesitationButtonState extends State<HesitationButton> {
  DateTime? _tapStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapStart = DateTime.now(),
      onTapUp: (_) {
        if (_tapStart != null) {
          final hesitation = DateTime.now().difference(_tapStart!);
          BehaviorTracker.logHesitation(hesitation);
        }
      },
      onTap: widget.onPressed,
      child: widget.child,
    );
  }
}
