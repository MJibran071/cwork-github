import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/animation_theme.dart';

/// Animated button with hover effects for web and desktop webview
/// Scales up, changes background color, and increases shadow on hover
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enabled;
  final Duration hoverDuration;
  final Curve hoverCurve;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.enabled = true,
    this.hoverDuration = AnimationTheme.moderate,
    this.hoverCurve = AnimationTheme.standard,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AnimationTheme.shouldAnimate(context);
    final baseStyle = widget.style ?? ElevatedButton.styleFrom();
    final isWeb = !Theme.of(context).platform.isMobile;

    // Only apply hover effects on web platforms
    if (!isWeb) {
      return ElevatedButton(
        onPressed: widget.enabled ? widget.onPressed : null,
        style: baseStyle,
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
          transform: Matrix4.identity()
            ..scale(_isHovering && !_isPressed ? 1.05 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
            color: _getBackgroundColor(context, baseStyle),
            boxShadow: _getBoxShadows(context, baseStyle),
          ),
          child: Padding(
            padding: baseStyle.padding?.resolve(WidgetState.values.toSet()) ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingS,
                ),
            child: DefaultTextStyle(
              style: _getTextStyle(context, baseStyle),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context, ButtonStyle baseStyle) {
    final baseColor = baseStyle.backgroundColor?.resolve(WidgetState.values.toSet()) ??
        AppTheme.primaryBlue;
    
    if (!widget.enabled) {
      return baseColor.withOpacity(0.5);
    }

    if (_isPressed) {
      return baseColor.darken(0.1);
    }

    if (_isHovering) {
      return baseColor.lighten(0.1);
    }

    return baseColor;
  }

  List<BoxShadow> _getBoxShadows(BuildContext context, ButtonStyle baseStyle) {
    final baseElevation = baseStyle.elevation?.resolve(WidgetState.values.toSet()) ?? 0;
    final shadowColor = baseStyle.shadowColor?.resolve(WidgetState.values.toSet()) ??
        Colors.black.withOpacity(0.25);

    if (!widget.enabled) {
      return [
        BoxShadow(
          color: shadowColor,
          blurRadius: baseElevation * 2,
          offset: const Offset(0, 1),
        ),
      ];
    }

    if (_isHovering) {
      return [
        BoxShadow(
          color: shadowColor,
          blurRadius: (baseElevation + 2) * 2,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: baseElevation * 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  TextStyle _getTextStyle(BuildContext context, ButtonStyle baseStyle) {
    final baseTextStyle = baseStyle.textStyle?.resolve(WidgetState.values.toSet()) ??
        AppTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    if (!widget.enabled) {
      return baseTextStyle?.copyWith(color: Colors.white.withOpacity(0.6)) ??
          const TextStyle();
    }

    return baseTextStyle ?? const TextStyle();
  }
}

/// Extension methods for color manipulation
extension ColorExtensions on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}

/// Pre-configured animated button styles following the design system
class AnimatedButtonStyles {
  static ButtonStyle primary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      textStyle: AppTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle secondary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.primaryBlue,
      side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      textStyle: AppTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      elevation: 0,
    );
  }

  static ButtonStyle success(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.successGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      textStyle: AppTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle warning(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.warningYellow,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      textStyle: AppTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle error(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.errorRed,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      textStyle: AppTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      elevation: 2,
    );
  }
}