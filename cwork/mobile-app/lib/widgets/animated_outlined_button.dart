import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/animation_theme.dart';
import 'animated_button.dart'; // For ColorExtensions

/// Animated outlined button with hover effects for web and desktop webview
/// Scales up, changes border and text color, and adds a subtle background on hover
class AnimatedOutlinedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enabled;
  final Duration hoverDuration;
  final Curve hoverCurve;

  const AnimatedOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.enabled = true,
    this.hoverDuration = AnimationTheme.moderate,
    this.hoverCurve = AnimationTheme.standard,
  });

  @override
  State<AnimatedOutlinedButton> createState() => _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<AnimatedOutlinedButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AnimationTheme.shouldAnimate(context);
    final isWeb = Theme.of(context).platform != TargetPlatform.android &&
                  Theme.of(context).platform != TargetPlatform.iOS;

    // Only apply hover effects on web platforms
    if (!isWeb) {
      return OutlinedButton(
        onPressed: widget.enabled ? widget.onPressed : null,
        style: widget.style,
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
            color: _getBackgroundColor(context),
            border: _getBorder(context),
          ),
          child: Padding(
            padding: _getPadding(),
            child: DefaultTextStyle(
              style: _getTextStyle(context),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final baseStyle = widget.style ?? OutlinedButton.styleFrom();
    final baseColor = baseStyle.backgroundColor?.resolve(WidgetState.values.toSet()) ??
        Colors.transparent;

    if (!widget.enabled) {
      return baseColor;
    }

    if (_isPressed) {
      return AppTheme.primaryBlue.withOpacity(0.2);
    }

    if (_isHovering) {
      return AppTheme.primaryBlue.withOpacity(0.1);
    }

    return baseColor;
  }

  Border _getBorder(BuildContext context) {
    final baseStyle = widget.style ?? OutlinedButton.styleFrom();
    final borderSide = baseStyle.side?.resolve(WidgetState.values.toSet()) ??
        const BorderSide(color: AppTheme.primaryBlue, width: 2);
    final borderColor = _getBorderColor(borderSide.color);

    return Border.all(
      color: borderColor,
      width: borderSide.width,
      style: borderSide.style,
    );
  }

  Color _getBorderColor(Color baseColor) {
    if (!widget.enabled) {
      return baseColor.withOpacity(0.5);
    }

    if (_isPressed) {
      return baseColor.darken(0.2);
    }

    if (_isHovering) {
      return baseColor.lighten(0.2);
    }

    return baseColor;
  }

  EdgeInsets _getPadding() {
    final baseStyle = widget.style ?? OutlinedButton.styleFrom();
    final padding = baseStyle.padding?.resolve(WidgetState.values.toSet());
    if (padding is EdgeInsets) {
      return padding;
    }
    return const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingL,
      vertical: AppTheme.spacingS,
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = widget.style ?? OutlinedButton.styleFrom();
    final baseTextStyle = baseStyle.textStyle?.resolve(WidgetState.values.toSet()) ??
        AppTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        );

    if (!widget.enabled) {
      return baseTextStyle?.copyWith(color: AppTheme.primaryBlue.withOpacity(0.5)) ??
          const TextStyle();
    }

    if (_isPressed) {
      return baseTextStyle?.copyWith(color: AppTheme.primaryBlue.darken(0.2)) ??
          const TextStyle();
    }

    if (_isHovering) {
      return baseTextStyle?.copyWith(color: AppTheme.primaryBlue.lighten(0.2)) ??
          const TextStyle();
    }

    return baseTextStyle ?? const TextStyle();
  }
}

/// Pre-configured animated outlined button styles
class AnimatedOutlinedButtonStyles {
  static ButtonStyle primary(BuildContext context) {
    return OutlinedButton.styleFrom(
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
    );
  }

  static ButtonStyle secondary(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.gray700,
      side: const BorderSide(color: AppTheme.gray700, width: 2),
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
    );
  }
}