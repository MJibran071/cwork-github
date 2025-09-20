import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Animated floating action button with hover effects for web and desktop webview
/// Scales up, changes background color, and increases shadow on hover
class AnimatedFloatingActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enabled;
  final Duration hoverDuration;
  final Curve hoverCurve;
  final double? elevation;

  const AnimatedFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.enabled = true,
    this.hoverDuration = AnimationTheme.moderate,
    this.hoverCurve = AnimationTheme.standard,
    this.elevation,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AnimationTheme.shouldAnimate(context);
    const isWeb = kIsWeb;
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final elevation = widget.elevation ?? 6.0;

    // Only apply hover effects on web platforms
    if (!isWeb) {
      return FloatingActionButton(
        onPressed: widget.enabled ? widget.onPressed : null,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        child: widget.child,
      );
    }

    return MouseRegion(
      onEnter: (_) {
        if (shouldAnimate && widget.enabled) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) {
        if (shouldAnimate) {
          setState(() => _isHovering = false);
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (shouldAnimate && widget.enabled) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (shouldAnimate) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (shouldAnimate) {
            setState(() => _isPressed = false);
          }
        },
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: shouldAnimate ? widget.hoverDuration : Duration.zero,
          curve: widget.hoverCurve,
          width: 56.0,
          height: 56.0,
          transform: Matrix4.identity()
            ..scale(_isHovering && !_isPressed ? 1.1 : 1.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(backgroundColor),
            shape: BoxShape.circle,
            boxShadow: _getBoxShadows(elevation),
          ),
          child: IconTheme(
            data: IconThemeData(color: foregroundColor),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(Color baseColor) {
    if (!widget.enabled) {
      return baseColor.withOpacity(0.5);
    }

    if (_isPressed) {
      return _darkenColor(baseColor, 0.15);
    }

    if (_isHovering) {
      return _lightenColor(baseColor, 0.1);
    }

    return baseColor;
  }

  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  List<BoxShadow> _getBoxShadows(double baseElevation) {
    final shadowColor = Colors.black.withOpacity(0.25);

    if (!widget.enabled) {
      return [
        BoxShadow(
          color: shadowColor,
          blurRadius: baseElevation,
          offset: const Offset(0, 1),
        ),
      ];
    }

    if (_isHovering) {
      return [
        BoxShadow(
          color: shadowColor,
          blurRadius: baseElevation + 2,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: baseElevation,
        offset: const Offset(0, 1),
      ),
    ];
  }
}