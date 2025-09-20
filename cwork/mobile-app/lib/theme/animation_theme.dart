import 'package:flutter/material.dart';

/// Animation Design System for CWork FluidMotion project
/// Defines timing rules, easing curves, and motion principles
class AnimationTheme {
  // Timing Rules - Standard durations for animations
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration moderate = Duration(milliseconds: 300);
  static const Duration complex = Duration(milliseconds: 500);
  static const Duration long = Duration(milliseconds: 700);

  // Easing Curves - Standardized easing functions
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.decelerate;
  static const Curve exit = Curves.fastOutSlowIn;
  static const Curve playful = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve smooth = Curves.easeOutCubic;

  // Motion Principles
  static const String motionCharacter = "Crisp and purposeful";
  static const String motionGuidance = """
  - Elements should fade in rather than slide when appearing
  - Use scale transforms for emphasis and focus
  - Slide animations should be used for spatial transitions
  - Bounce effects are reserved for playful interactions only
  - All animations must serve a functional purpose
  """;

  // Standard Animation Configurations
  static AnimationConfiguration get quickAnimation => const AnimationConfiguration(
        duration: quick,
        curve: standard,
      );

  static AnimationConfiguration get moderateAnimation => const AnimationConfiguration(
        duration: moderate,
        curve: standard,
      );

  static AnimationConfiguration get complexAnimation => const AnimationConfiguration(
        duration: complex,
        curve: standard,
      );

  // Pre-configured Tween animations
  static Tween<double> scaleTween = Tween<double>(begin: 0.95, end: 1.0);
  static Tween<double> fadeTween = Tween<double>(begin: 0.0, end: 1.0);
  static Tween<Offset> slideUpTween = Tween<Offset>(
    begin: const Offset(0.0, 0.1),
    end: Offset.zero,
  );
  static Tween<Offset> slideDownTween = Tween<Offset>(
    begin: const Offset(0.0, -0.1),
    end: Offset.zero,
  );
  static Tween<Offset> slideLeftTween = Tween<Offset>(
    begin: const Offset(0.1, 0.0),
    end: Offset.zero,
  );
  static Tween<Offset> slideRightTween = Tween<Offset>(
    begin: const Offset(-0.1, 0.0),
    end: Offset.zero,
  );

  // Common animation sequences
  static SequenceAnimation get fadeInScale => SequenceAnimation(
        fade: fadeTween,
        scale: scaleTween,
        duration: moderate,
        curve: enter,
      );

  static SequenceAnimation get slideInFade => SequenceAnimation(
        fade: fadeTween,
        slide: slideUpTween,
        duration: moderate,
        curve: enter,
      );

  // Accessibility-aware animation duration
  static Duration accessibleDuration(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return reducedMotion ? Duration.zero : moderate;
  }

  // Accessibility-aware curve
  static Curve accessibleCurve(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return reducedMotion ? Curves.linear : standard;
  }

  // Helper method to check if animations should be disabled
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }
}

/// Configuration for complex animation sequences
class AnimationConfiguration {
  final Duration duration;
  final Curve curve;

  const AnimationConfiguration({
    required this.duration,
    required this.curve,
  });
}

/// Pre-configured sequence for common animation patterns
class SequenceAnimation {
  final Tween<double>? fade;
  final Tween<double>? scale;
  final Tween<Offset>? slide;
  final Duration duration;
  final Curve curve;

  SequenceAnimation({
    this.fade,
    this.scale,
    this.slide,
    required this.duration,
    required this.curve,
  });

  /// Creates an animation controller with the configured duration and curve
  AnimationController createController(TickerProvider vsync) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Applies the sequence to an animation controller
  Animation<double> applyFade(AnimationController controller) {
    return fade?.animate(
          CurvedAnimation(
            parent: controller,
            curve: curve,
          ),
        ) ??
        const AlwaysStoppedAnimation(1.0);
  }

  Animation<double> applyScale(AnimationController controller) {
    return scale?.animate(
          CurvedAnimation(
            parent: controller,
            curve: curve,
          ),
        ) ??
        const AlwaysStoppedAnimation(1.0);
  }

  Animation<Offset> applySlide(AnimationController controller) {
    return slide?.animate(
          CurvedAnimation(
            parent: controller,
            curve: curve,
          ),
        ) ??
        const AlwaysStoppedAnimation(Offset.zero);
  }
}

/// Extension methods for easier animation usage
extension AnimationThemeExtensions on BuildContext {
  AnimationTheme get animationTheme => AnimationTheme();

  Duration get quickAnimation => AnimationTheme.quick;
  Duration get moderateAnimation => AnimationTheme.moderate;
  Duration get complexAnimation => AnimationTheme.complex;

  Curve get standardCurve => AnimationTheme.standard;
  Curve get enterCurve => AnimationTheme.enter;
  Curve get exitCurve => AnimationTheme.exit;

  bool get shouldAnimate => AnimationTheme.shouldAnimate(this);
  Duration get accessibleDuration => AnimationTheme.accessibleDuration(this);
  Curve get accessibleCurve => AnimationTheme.accessibleCurve(this);
}