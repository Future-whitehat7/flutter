// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';

const Duration _kUnconfirmedRippleDuration = const Duration(seconds: 1);
const Duration _kFadeInDuration = const Duration(milliseconds: 75);
const Duration _kFadeOutDuration = const Duration(milliseconds: 225);

// The fade out begins 75ms after the ripple fadeout animation begins.
const double _kFadeOutIntervalStart = 75.0 / 225.0;

const double _kRippleConfirmedVelocity = 1.0; // logical pixels per millisecond

RectCallback _getClipCallback(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback) {
  if (rectCallback != null) {
    assert(containedInkWell);
    return rectCallback;
  }
  if (containedInkWell)
    return () => Offset.zero & referenceBox.size;
  return null;
}

double _getTargetRadius(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback, Offset position) {
  if (containedInkWell) {
    final Size size = rectCallback != null ? rectCallback().size : referenceBox.size;
    return _getRippleRadiusForPositionInSize(size, position);
  }
  return Material.defaultSplashRadius;
}

double _getRippleRadiusForPositionInSize(Size bounds, Offset position) {
  final double d1 = (position - bounds.topLeft(Offset.zero)).distance;
  final double d2 = (position - bounds.topRight(Offset.zero)).distance;
  final double d3 = (position - bounds.bottomLeft(Offset.zero)).distance;
  final double d4 = (position - bounds.bottomRight(Offset.zero)).distance;
  return math.max(math.max(d1, d2), math.max(d3, d4)).ceilToDouble();
}

/// A visual reaction on a piece of [Material] to user input.
///
///  * [Material], which is the widget on which the ink ripple is painted.
 class InkRipple extends InkFeature {
  /// Begin a ripple, centered at position relative to [referenceBox].
  ///
  /// The [controller] argument is typically obtained via
  /// `Material.of(context)`.
  ///
  /// If `containedInkWell` is true, then the ripple will be sized to fit
  /// the well rectangle, then clipped to it when drawn. The well
  /// rectangle is the box returned by `rectCallback`, if provided, or
  /// otherwise is the bounds of the [referenceBox].
  ///
  /// If `containedInkWell` is false, then `rectCallback` should be null.
  /// The ink ripple is clipped only to the edges of the [Material].
  /// This is the default.
  ///
  /// When the ripple is removed, `onRemoved` will be called.
  InkRipple({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    Offset position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    BorderRadius borderRadius = BorderRadius.zero,
    double radius,
    VoidCallback onRemoved,
  }) : _position = position,
       _color = color,
       _borderRadius = borderRadius,
       _targetRadius = radius ?? _getTargetRadius(referenceBox, containedInkWell, rectCallback, position),
       _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback),
       super(controller: controller, referenceBox: referenceBox, onRemoved: onRemoved)
  {
    assert(_borderRadius != null);

    _radiusController = new AnimationController(duration: _kUnconfirmedRippleDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
     // Initial splash diamater is 60% of the target diameter, final
     // diameter is 10dps larger than the target diameter.
    _radius = new Tween<double>(
      begin: _targetRadius * 0.30,
      end: _targetRadius + 5.0,
    ).animate(
      new CurvedAnimation(
        parent: _radiusController,
        curve: Curves.ease,
      )
    );

    _fadeInController = new AnimationController(duration: _kFadeInDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _fadeIn = new IntTween(
      begin: 0,
      end: color.alpha,
    ).animate(_fadeInController);

    _fadeOutController = new AnimationController(duration: _kFadeOutDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged);
    _fadeOut = new IntTween(
      begin: color.alpha,
      end: 0,
    ).animate(
      new CurvedAnimation(
        parent: _fadeOutController,
        curve: const Interval(_kFadeOutIntervalStart, 1.0)
      ),
    );

    controller.addInkFeature(this);
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback _clipCallback;

  Animation<double> _radius;
  AnimationController _radiusController;

  Animation<int> _fadeIn;
  AnimationController _fadeInController;

  Animation<int> _fadeOut;
  AnimationController _fadeOutController;

  /// The color of the ripple.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color)
      return;
    _color = value;
    controller.markNeedsPaint();
  }

  /// The user input is confirmed.
  ///
  /// Causes the reaction to propagate faster across the material.
  void confirm() {
    final int duration = (_targetRadius / _kRippleConfirmedVelocity).floor();
    _radiusController
      ..duration = new Duration(milliseconds: duration)
      ..forward();
    _fadeInController.value = 1.0;
    _fadeOutController.forward();
  }

  /// The user input was canceled.
  ///
  /// Causes the reaction to gradually disappear.
  void cancel() {
    _fadeOutController.forward();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      dispose();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  RRect _clipRRectFromRect(Rect rect) {
    return new RRect.fromRectAndCorners(
      rect,
      topLeft: _borderRadius.topLeft, topRight: _borderRadius.topRight,
      bottomLeft: _borderRadius.bottomLeft, bottomRight: _borderRadius.bottomRight,
    );
  }

  void _clipCanvasWithRect(Canvas canvas, Rect rect, {Offset offset}) {
    Rect clipRect = rect;
    if (offset != null) {
      clipRect = clipRect.shift(offset);
    }
    if (_borderRadius != BorderRadius.zero) {
      canvas.clipRRect(_clipRRectFromRect(clipRect));
    } else {
      canvas.clipRect(clipRect);
    }
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final int alpha = _fadeOutController.isAnimating ? _fadeOut.value : _fadeIn.value;
    final Paint paint = new Paint()..color = _color.withAlpha(alpha);
    // Splash moves to the center of the reference box.
    final Offset center = Offset.lerp(
      _position,
      referenceBox.size.center(Offset.zero),
      Curves.ease.transform(_radiusController.value),
    );
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      if (_clipCallback != null) {
        _clipCanvasWithRect(canvas, _clipCallback());
      }
      canvas.drawCircle(center, _radius.value, paint);
      canvas.restore();
    } else {
      if (_clipCallback != null) {
        canvas.save();
        _clipCanvasWithRect(canvas, _clipCallback(), offset: originOffset);
      }
      canvas.drawCircle(center + originOffset, _radius.value, paint);
      if (_clipCallback != null)
        canvas.restore();
    }
  }
}
