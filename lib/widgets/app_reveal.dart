import 'dart:async';

import 'package:flutter/material.dart';

class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOut,
    this.enabled = true,
    this.beginOffset = Offset.zero,
    this.beginScale = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final Offset beginOffset;
  final double beginScale;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(covariant AppReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _scheduleReveal();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleReveal() {
    _timer?.cancel();
    if (!widget.enabled) {
      if (_visible) {
        setState(() {
          _visible = false;
        });
      }
      return;
    }

    if (_visible) {
      setState(() {
        _visible = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) {
        return;
      }
      final Duration effectiveDelay = widget.delay == Duration.zero
          ? Duration.zero
          : Duration(milliseconds: (widget.delay.inMilliseconds / 4).round());
      if (effectiveDelay == Duration.zero) {
        setState(() {
          _visible = true;
        });
        return;
      }
      _timer = Timer(effectiveDelay, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _visible = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.beginOffset,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedScale(
          scale: _visible ? 1 : widget.beginScale,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
