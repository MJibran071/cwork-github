import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Animated icon button with hover effects for web and desktop webview
/// Scales up, changes color, and adds a subtle background on hover
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? hoverColor;
  final double iconSize;
  final bool enabled;
  final Duration hoverDuration;
  final Curve hoverCurve;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.hoverColor,
    this.iconSize = 24.0,
    this.enabled = true,
    this.hoverDuration = AnimationTheme.quick,
    this.hoverCurve = AnimationTheme.standard,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AnimationTheme.shouldAnimate(context);
    const isWeb = kIsWeb;
    final theme = Theme.of(context);
    final iconColor = widget.iconColor ?? theme.iconTheme.color ?? Colors.grey;
    final hoverColor = widget.hoverColor ?? theme.colorScheme.primary.withOpacity(0.1);

    // Only apply hover effects on web platforms
    if (!isWeb) {
      return IconButton(
        icon: Icon(widget.icon),
        onPressed: widget.enabled ? widget.onPressed : null,
        color: iconColor,
        iconSize: widget.iconSize,
        tooltip: widget.tooltip,
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
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: _isHovering ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Center(
            child: AnimatedScale(
              duration: shouldAnimate ? widget.hoverDuration : Duration.zero,
              curve: widget.hoverCurve,
              scale: _isHovering && !_isPressed ? 1.2 : 1.0,
              child: Icon(
                widget.icon,
                color: _getIconColor(iconColor),
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(Color baseColor) {
    if (!widget.enabled) {
      return baseColor.withOpacity(0.5);
    }

    if (_isPressed) {
      return _darkenColor(baseColor, 0.2);
    }

    if (_isHovering) {
      return _lightenColor(baseColor, 0.2);
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
}
