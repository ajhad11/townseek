import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;

/// A completely custom, zero-gravity physics-based pull-to-refresh.
/// The `header` is placed at the top and visually stretched downwards
/// when the user drags down on the `body` (which should be a scrollable).
class ZeroGravityRefresh extends StatefulWidget {
  final Widget header;
  final Widget body;
  final Future<void> Function() onRefresh;

  const ZeroGravityRefresh({
    super.key,
    required this.header,
    required this.body,
    required this.onRefresh,
  });

  @override
  State<ZeroGravityRefresh> createState() => _ZeroGravityRefreshState();
}

class _ZeroGravityRefreshState extends State<ZeroGravityRefresh>
    with TickerProviderStateMixin {
  late AnimationController _springController;
  late AnimationController _spinController;

  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _canDrag = false; // true when scroll position is at the top
  final double _maxDrag = 200.0;
  final double _triggerDrag = 120.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = _springController.value.clamp(0.0, _maxDrag);
        });
      }
    });

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _springController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final delta = notification.scrollDelta ?? 0.0;

      if (metrics.pixels <= 0 && delta < 0) {
        // At the top, dragging further down
        _canDrag = true;
        _springController.stop();
        setState(() {
          final double friction = math.max(0.15, 1.0 - (_dragOffset / _maxDrag));
          _dragOffset = (_dragOffset + (-delta * friction)).clamp(0.0, _maxDrag);
        });
        return true;
      } else if (_dragOffset > 0 && delta > 0) {
        // Releasing / scrolling back up
        _springController.stop();
        setState(() {
          _dragOffset = (_dragOffset - delta).clamp(0.0, _maxDrag);
        });
        return true;
      } else if (metrics.pixels > 0) {
        _canDrag = false;
      }
    } else if (notification is ScrollEndNotification) {
      if (_canDrag) {
        if (_dragOffset >= _triggerDrag && !_isRefreshing) {
          _startRefresh();
        } else if (_dragOffset > 0) {
          _snapBack();
        }
        _canDrag = false;
      }
    } else if (notification is OverscrollNotification) {
      final delta = notification.overscroll;
      if (delta < 0 && !_isRefreshing) {
        _springController.stop();
        setState(() {
          final double friction = math.max(0.15, 1.0 - (_dragOffset / _maxDrag));
          _dragOffset = (_dragOffset + (-delta * friction)).clamp(0.0, _maxDrag);
        });
        return true;
      }
    }

    return false;
  }

  void _snapBack() {
    _runSpringSimulation(target: 0.0, initialVelocity: 0.0);
  }

  void _startRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Bounce to a loading resting state
    _runSpringSimulation(target: 90.0, initialVelocity: 50.0);

    await widget.onRefresh();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });

    // Drop away with liquid wobble
    _runSpringSimulation(target: 0.0, initialVelocity: -800.0);
  }

  void _runSpringSimulation(
      {required double target, required double initialVelocity}) {
    final SpringDescription spring = SpringDescription(
      mass: 0.7,
      stiffness: 160.0,
      damping: 12.0,
    );

    final simulation = SpringSimulation(
      spring,
      _dragOffset,
      target,
      initialVelocity,
    );

    _springController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_dragOffset / _triggerDrag).clamp(0.0, 1.0);
    final double iconOpacity = _dragOffset > 10 ? math.min(1.0, _dragOffset / 60) : 0.0;
    final double iconTop = 148.0 + (_dragOffset * 0.55);

    return Stack(
      children: [
        // Scrollable body with a top padding offset by header + stretch
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Column(
            children: [
              SizedBox(height: 180 + (_dragOffset * 0.25)),
              Expanded(child: widget.body),
            ],
          ),
        ),

        // Stretching liquid app bar header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _LiquidClipper(dragOffset: _dragOffset),
            child: widget.header,
          ),
        ),

        // Refresh icon drop (spinning when refreshing, rotating with drag otherwise)
        if (_dragOffset > 10)
          Positioned(
            left: 0,
            right: 0,
            top: iconTop,
            child: Opacity(
              opacity: iconOpacity,
              child: Center(
                child: _isRefreshing
                    ? RotationTransition(
                        turns: _spinController,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2962FF).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.autorenew,
                            color: Color(0xFF2962FF),
                            size: 20,
                          ),
                        ),
                      )
                    : Transform.rotate(
                        angle: progress * 2 * math.pi,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: progress),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2962FF).withValues(alpha: progress * 0.3),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.autorenew,
                            color: Color.lerp(
                              const Color(0xFF2962FF).withValues(alpha: 0.3),
                              const Color(0xFF2962FF),
                              progress,
                            ),
                            size: 20,
                          ),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bezier curve that drops the center of the header down on drag
class _LiquidClipper extends CustomClipper<Path> {
  final double dragOffset;

  _LiquidClipper({required this.dragOffset});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + (dragOffset * 1.6),
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidClipper oldClipper) {
    return oldClipper.dragOffset != dragOffset;
  }
}
