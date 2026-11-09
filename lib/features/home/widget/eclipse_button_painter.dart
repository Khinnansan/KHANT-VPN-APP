
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum EclipseLook {
  idle,
  starting,
  waiting,
  connected,
  stopping,
  error,
}

class EclipseFrame {
  const EclipseFrame({
    required this.look,
    required this.previous,
    required this.since,
    required this.time,
    required this.color,
    required this.previousColor,
  });

  final EclipseLook look;
  final EclipseLook previous;
  final double since;
  final double time;
  final Color color;
  final Color previousColor;

  Color get logoColor =>
      Color.lerp(previousColor, color, _ease(since / .45))!;

  EclipseFrame get _before => EclipseFrame(
        look: previous,
        previous: previous,
        since: 3 + since,
        time: time,
        color: previousColor,
        previousColor: previousColor,
      );
}

class EclipseTraffic {
  const EclipseTraffic({this.down = 0, this.up = 0});

  final double down;
  final double up;

  double get total => math.max(down, up);

  @override
  bool operator ==(Object other) =>
      other is EclipseTraffic &&
      other.down == down &&
      other.up == up;

  @override
  int get hashCode => Object.hash(down, up);

  static const _steps = [
    (200.0, .2),
    (500.0, .5),
    (1024.0, .65),
    (10240.0, .8),
    (102400.0, 1.0),
  ];

  static double level(num bytesPerSecond) {
    final b = bytesPerSecond.toDouble();
    if (b <= 0) return 0;

    var (from, fromLevel) = _steps.first;

    if (b <= from) return fromLevel * b / from;

    for (final (to, toLevel) in _steps.skip(1)) {
      if (b <= to) {
        return fromLevel +
            (toLevel - fromLevel) *
                math.log(b / from) /
                math.log(to / from);
      }
      (from, fromLevel) = (to, toLevel);
    }

    return 1;
  }
}

class EclipseButtonPainter extends CustomPainter {
  EclipseButtonPainter({
    required this.frame,
    required this.radius,
    required this.traffic,
    required this.dark,
    this.drawLogo = true,
    this.logoOpacity = 1,
    super.repaint,
  });

  final EclipseFrame frame;
  final double radius;
  final EclipseTraffic traffic;
  final bool dark;
  final bool drawLogo;
  final double logoOpacity;

  static const _gold = Color(0xFFFFC857);
  static const _goldLight = Color(0xFFFFE6A6);
  static const _goldDark = Color(0xFF9C6418);
  static const _black = Color(0xFF101010);

  static const _fade = .35;

  static Rect errorBadgeRect(Offset center, double radius) =>
      Rect.fromCircle(
        center: center +
            Offset.fromDirection(math.pi / 4, radius * .74),
        radius: radius * .22,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    final center = size.center(Offset.zero);

    final ctx = _Ctx(
      this,
      canvas,
      center,
      f,
    );

    if (f.since >= _fade || f.previous == f.look) {
      _paintLook(ctx);
      return;
    }

    final a = _ease(f.since / _fade);
    final bounds = Offset.zero & size;

    ctx.disc();

    canvas.saveLayer(
      bounds,
      Paint()..color = Color.fromRGBO(0, 0, 0, 1 - a),
    );
    _paintLook(_Ctx(this, canvas, center, f._before));
    canvas.restore();

    canvas.saveLayer(
      bounds,
      Paint()..color = Color.fromRGBO(0, 0, 0, a),
    );
    _paintLook(ctx);
    canvas.restore();
  }

  @override
  bool shouldRepaint(EclipseButtonPainter old) =>
      old.frame.look != frame.look ||
      old.frame.previous != frame.previous ||
      old.frame.since != frame.since ||
      old.frame.time != frame.time ||
      old.frame.color != frame.color ||
      old.frame.previousColor != frame.previousColor ||
      old.traffic != traffic ||
      old.dark != dark ||
      old.radius != radius ||
      old.drawLogo != drawLogo ||
      old.logoOpacity != logoOpacity;
}

void _paintLook(_Ctx x) {
  switch (x.f.look) {
    case EclipseLook.idle:
      x.disc();
      x.goldRing();
      x.logo();
      break;

    case EclipseLook.starting:
      x.disc();
      x.goldRing();
      x.logo(pulse: true);
      x.searching();
      break;

    case EclipseLook.waiting:
      x.disc();
      x.goldRing();
      x.radar();
      x.logo(pulse: true);
      break;

    case EclipseLook.connected:
      _connected(x);
      break;

    case EclipseLook.stopping:
      x.disc();
      x.goldRing();
      x.logo(pulse: true, reverse: true);
      break;

    case EclipseLook.error:
      _error(x);
      break;
  }
}

void _connected(_Ctx x) {
  final s = x.f.since;
  final traffic = x.p.traffic;

  final appear = _ease((s - .4) / 1.2);
  final down = traffic.down * appear;
  final up = traffic.up * appear;

  const connectedGreen = Color(0xFF20E66B);

  x.glow(
    color: connectedGreen,
    level: math.max(.28, down),
    reach: .95,
  );

  x.glow(
    color: const Color(0xFFFFD45C),
    level: up,
    reach: 1.1,
  );

  x.ripple(s);
  x.disc();
  x.goldRing(strength: .5 + .5 * math.max(down, up));

  // Green outer ring communicates the connected state while preserving
  // KHANT VPN's gold premium identity.
  x.c.drawCircle(
    x.center,
    x.r * .94,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = connectedGreen.withValues(
        alpha: (.35 + .35 * math.max(down, up)).clamp(0.0, .8),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );

  x.logo(
    pulse: true,
    connected: true,
  );

  final sparkle = 5 * _bump((s % 2) / 2);

  if (sparkle > 0) {
    x.star(
      Offset(
        x.center.dx + x.r * .72,
        x.center.dy - x.r * .65,
      ),
      sparkle,
    );
  }
}

void _error(_Ctx x) {
  x.disc();
  x.goldRing(strength: .3);
  x.logo(error: true);

  final rect = EclipseButtonPainter.errorBadgeRect(
    x.center,
    x.r,
  );

  final pulse = .5 + .5 * math.sin(x.f.time * 3);

  x.c.drawCircle(
    rect.center,
    rect.width / 2 + 5 + pulse * 4,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.red.withValues(alpha: .45),
  );

  x.badge();
}

class _Ctx {
  _Ctx(this.p, this.c, this.center, this.f)
      : r = p.radius;

  final EclipseButtonPainter p;
  final Canvas c;
  final Offset center;
  final EclipseFrame f;
  final double r;

  static const gold = Color(0xFFFFC857);
  static const goldLight = Color(0xFFFFE6A6);
  static const goldDark = Color(0xFF9C6418);

  void disc() {
    final rect = Rect.fromCircle(
      center: center,
      radius: r,
    );

    c.drawCircle(
      center.translate(0, 5),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          12,
        ),
    );

    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          radius: 1.2,
          colors: [
            Color(0xFF303030),
            Color(0xFF171717),
            Color(0xFF080808),
          ],
        ).createShader(rect),
    );

    c.drawCircle(
      center,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFFE6A6),
            Color(0xFF9C6418),
            Color(0xFFFFC857),
            Color(0xFF9C6418),
            Color(0xFFFFE6A6),
          ],
        ).createShader(rect),
    );

    c.drawCircle(
      center,
      r - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: .13),
    );
  }

  void goldRing({double strength = 1}) {
    c.drawCircle(
      center,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = gold.withValues(alpha: strength.clamp(0.0, 1.0)),
    );

    c.drawCircle(
      center,
      r - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = goldLight.withValues(alpha: .3),
    );
  }

  // KHANT VPN Premium Gold K Logo
  void logo({
    bool pulse = false,
    bool reverse = false,
    bool connected = false,
    bool error = false,
  }) {
    if (!p.drawLogo) return;

    final t = f.time;
    final beat = pulse
        ? .9 + .1 * math.sin(t * 3)
        : 1.0;

    final color = error
        ? const Color(0xFFFF5555)
        : Color.lerp(
            goldDark,
            goldLight,
            .5 + .5 * math.sin(t * 1.5),
          )!;

    final opacity = p.logoOpacity.clamp(0.0, 1.0);

    c.save();
    c.translate(center.dx, center.dy);
    c.scale(beat);
    c.translate(-center.dx, -center.dy);

    final k = r * .012;

    final path = Path()
      ..moveTo(center.dx - 20 * k, center.dy - 32 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 32 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 6 * k)
      ..lineTo(center.dx + 17 * k, center.dy - 32 * k)
      ..lineTo(center.dx + 32 * k, center.dy - 32 * k)
      ..lineTo(center.dx + 4 * k, center.dy - 2 * k)
      ..lineTo(center.dx + 32 * k, center.dy + 32 * k)
      ..lineTo(center.dx + 17 * k, center.dy + 32 * k)
      ..lineTo(center.dx - 8 * k, center.dy + 5 * k)
      ..lineTo(center.dx - 8 * k, center.dy + 32 * k)
      ..lineTo(center.dx - 20 * k, center.dy + 32 * k)
      ..close();

    c.drawPath(
      path,
      Paint()
        ..color = gold.withValues(alpha: .22 * opacity)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          10,
        ),
    );

    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldLight.withValues(alpha: opacity),
            color.withValues(alpha: opacity),
            goldDark.withValues(alpha: opacity),
          ],
        ).createShader(
          Rect.fromCenter(
            center: center,
            width: r * .9,
            height: r * .9,
          ),
        ),
    );

    c.restore();
  }

  void searching() {
    final angle = f.time * 2;
    final rect = Rect.fromCircle(
      center: center,
      radius: r * .72,
    );

    c.drawArc(
      rect,
      angle,
      math.pi * .65,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = gold.withValues(alpha: .7),
    );
  }

  void radar() {
    final angle = f.time * 1.5;

    c.drawArc(
      Rect.fromCircle(
        center: center,
        radius: r * .8,
      ),
      angle,
      math.pi * .45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = gold.withValues(alpha: .7),
    );
  }

  void glow({
    required Color color,
    required double level,
    required double reach,
  }) {
    if (level <= .01) return;

    final outer = r * (1 + reach * level);

    c.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .35 * level),
            color.withValues(alpha: .16 * level),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: outer,
          ),
        ),
    );

    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi * 2 / 24 +
          f.time * .08;

      final length = r * reach * level *
          (.4 + .6 * math.sin(i * 2.4).abs());

      final start = center +
          Offset.fromDirection(angle, r - 1);

      final end = center +
          Offset.fromDirection(angle, r + length);

      c.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            start,
            end,
            [
              color.withValues(alpha: .8 * level),
              color.withValues(alpha: 0),
            ],
          ),
      );
    }
  }

  void ripple(double since) {
    final p = (since % 1.4) / 1.4;

    c.drawCircle(
      center,
      r * (1 + .35 * _ease(p)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = gold.withValues(alpha: .45 * (1 - p)),
    );
  }

  void badge() {
    final rect = EclipseButtonPainter.errorBadgeRect(
      center,
      r,
    );

    c.drawCircle(
      rect.center,
      rect.width / 2 + 3,
      Paint()..color = Colors.white,
    );

    c.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()..color = Colors.red,
    );

    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    c.drawLine(
      rect.center.translate(0, -5),
      rect.center.translate(0, 2),
      p,
    );

    c.drawCircle(
      rect.center.translate(0, 6),
      1.2,
      p,
    );
  }

  void star(Offset at, double size) {
    if (size <= 0) return;

    final path = Path()
      ..moveTo(at.dx, at.dy - size)
      ..lineTo(at.dx + size * .3, at.dy - size * .3)
      ..lineTo(at.dx + size, at.dy)
      ..lineTo(at.dx + size * .3, at.dy + size * .3)
      ..lineTo(at.dx, at.dy + size)
      ..lineTo(at.dx - size * .3, at.dy + size * .3)
      ..lineTo(at.dx - size, at.dy)
      ..lineTo(at.dx - size * .3, at.dy - size * .3)
      ..close();

    c.drawPath(
      path,
      Paint()..color = goldLight,
    );
  }
}

double _clamp(double x) => x.clamp(0.0, 1.0);

double _ease(double x) =>
    Curves.easeInOutCubic.transform(_clamp(x));

double _bump(double x) =>
    x <= 0 || x >= 1 ? 0 : math.sin(math.pi * x);
