
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
      x.globe(connected: false);
      x.orbit(x.f.time, connected: false);
      x.disc();
      x.goldRing();
      x.logo();
      break;

    case EclipseLook.starting:
      x.globe(connected: false);
      x.disc();
      x.goldRing();
      x.logo(pulse: true);
      x.searching();
      break;

    case EclipseLook.waiting:
      x.globe(connected: false);
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
  // Keep the connected state visibly alive even when traffic is momentarily zero.
  final pulse = .72 + .28 * (.5 + .5 * math.sin(s * 2.2));
  final activity = math.max(traffic.down, traffic.up);

  x.globe(connected: true);
  x.glow(
    color: const Color(0xFF20F45A),
    level: pulse,
    reach: 1.18,
  );
  x.glow(
    color: const Color(0xFF9BFFB5),
    level: math.max(.24, activity) * pulse,
    reach: 1.35,
  );

  x.orbit(s, connected: true);
  x.ripple(s);
  x.disc();
  x.connectedRing(strength: .88 + .12 * pulse, time: s);

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

  // Decorative dotted world map and orbital paths behind the connection core.
  void globe({required bool connected}) {
    final pulse = .82 + .18 * math.sin(f.time * 1.25);
    // Match the reference: idle globe stays gold; the entire connected
    // world map shifts to vivid green, not just the orbit around the K.
    final color = connected
        ? const Color(0xFF39FF35)
        : const Color(0xFFFFC857);
    final globeRadius = r * 1.58;
    final centerY = center.dy - r * .16;
    final mapCenter = Offset(center.dx, centerY);

    c.drawOval(
      Rect.fromCenter(
        center: mapCenter,
        width: globeRadius * 2.05,
        height: globeRadius * 1.18,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = connected ? 1.6 : 1.1
        ..color = color.withValues(alpha: (connected ? .48 : .23) * pulse),
    );

    // Stylized continent clusters made from glowing dots.
    const continents = <List<Offset>>[
      [Offset(-.78,-.05),Offset(-.70,-.25),Offset(-.58,-.32),Offset(-.48,-.22),Offset(-.43,-.02),Offset(-.52,.12),Offset(-.60,.30),Offset(-.73,.20)],
      [Offset(-.35,-.42),Offset(-.20,-.50),Offset(-.05,-.42),Offset(-.10,-.25),Offset(-.22,-.18),Offset(-.32,-.25)],
      [Offset(-.20,.02),Offset(-.08,.12),Offset(-.02,.32),Offset(-.12,.55),Offset(-.24,.42),Offset(-.30,.18)],
      [Offset(.02,-.42),Offset(.22,-.48),Offset(.40,-.36),Offset(.52,-.18),Offset(.40,-.04),Offset(.22,-.12),Offset(.12,.02),Offset(-.02,-.12)],
      [Offset(.28,.08),Offset(.45,.12),Offset(.52,.30),Offset(.42,.48),Offset(.28,.40),Offset(.20,.22)],
      [Offset(.60,-.20),Offset(.75,-.12),Offset(.82,.02),Offset(.72,.12),Offset(.60,.02)],
    ];

    const landShapes = <List<Offset>>[
      [Offset(-.94,-.16),Offset(-.82,-.34),Offset(-.64,-.40),Offset(-.48,-.30),Offset(-.40,-.12),Offset(-.47,.04),Offset(-.56,.12),Offset(-.58,.35),Offset(-.72,.42),Offset(-.82,.20)],
      [Offset(-.42,-.48),Offset(-.25,-.57),Offset(-.08,-.49),Offset(-.02,-.36),Offset(-.15,-.24),Offset(-.32,-.25)],
      [Offset(-.31,.02),Offset(-.15,.10),Offset(-.08,.30),Offset(-.18,.58),Offset(-.29,.48),Offset(-.39,.20)],
      [Offset(-.03,-.43),Offset(.12,-.56),Offset(.34,-.52),Offset(.54,-.35),Offset(.61,-.14),Offset(.47,-.03),Offset(.29,-.12),Offset(.17,.02),Offset(.03,-.12)],
      [Offset(.25,.08),Offset(.43,.08),Offset(.58,.23),Offset(.54,.42),Offset(.39,.52),Offset(.25,.37),Offset(.16,.20)],
      [Offset(.62,-.23),Offset(.80,-.17),Offset(.93,-.03),Offset(.86,.12),Offset(.72,.16),Offset(.62,.02)],
    ];
    bool inside(Offset point, List<Offset> polygon) {
      var hit = false;
      for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
        final a = polygon[i];
        final b = polygon[j];
        final crosses = ((a.dy > point.dy) != (b.dy > point.dy)) &&
            (point.dx < (b.dx - a.dx) * (point.dy - a.dy) / ((b.dy - a.dy) == 0 ? .00001 : (b.dy - a.dy)) + a.dx);
        if (crosses) hit = !hit;
      }
      return hit;
    }

    // Fill each continent with a fine dotted grid to resemble the reference map.
    for (final shape in landShapes) {
      for (var y = -.58; y <= .62; y += .045) {
        for (var xx = -.98; xx <= .98; xx += .045) {
          final point = Offset(xx, y);
          if (!inside(point, shape)) continue;
          final at = Offset(mapCenter.dx + xx * globeRadius, mapCenter.dy + y * globeRadius);
          final dotRadius = r * (connected ? .012 : .010);
          if (connected) {
            c.drawCircle(
              at,
              dotRadius * 3.5,
              Paint()
                ..color = color.withValues(alpha: .12 * pulse)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
            );
          }
          c.drawCircle(
            at,
            dotRadius,
            Paint()..color = color.withValues(alpha: (connected ? .86 : .72) * pulse),
          );
        }
      }
    }

    for (final continent in continents) {
      for (final point in continent) {
        final at = Offset(
          mapCenter.dx + point.dx * globeRadius,
          mapCenter.dy + point.dy * globeRadius,
        );
        if (connected) {
          // Soft green bloom beneath each continent light makes the map
          // visibly green across its full surface while preserving the dots.
          c.drawCircle(
            at,
            r * .052,
            Paint()
              ..color = color.withValues(alpha: .24 * pulse)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        c.drawCircle(
          at,
          math.max(1.0, r * (connected ? .022 : .018)),
          Paint()..color = color.withValues(alpha: (connected ? .95 : .68) * pulse),
        );
      }
    }
  }

  void orbit(double time, {required bool connected}) {
    final color = connected
        ? const Color(0xFF35FF45)
        : gold;
    final rect = Rect.fromCenter(
      center: center,
      width: r * 3.05,
      height: r * .78,
    );
    c.save();
    c.rotate(-.06);
    c.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = connected ? 2.2 : 1.2
        ..color = color.withValues(alpha: connected ? .85 : .34),
    );
    final angle = time * (connected ? 1.1 : .25);
    final dot = center + Offset.fromDirection(angle, r * 1.5);
    c.drawCircle(
      dot,
      connected ? 3.5 : 2.2,
      Paint()
        ..color = color
        ..maskFilter = connected
            ? const MaskFilter.blur(BlurStyle.normal, 5)
            : null,
    );
    c.restore();
  }

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

  void connectedRing({required double strength, required double time}) {
    final ringColor = const Color(0xFF42FF35);
    final radius = r - 2;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor.withValues(alpha: .34 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    c.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..color = ringColor.withValues(alpha: .18 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    c.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = ringColor.withValues(alpha: strength),
    );
    c.drawCircle(
      center,
      radius - 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFB7FF8C).withValues(alpha: .8 * strength),
    );
    // Moving segmented energy around the outer edge.
    for (var i = 0; i < 32; i++) {
      final angle = i * math.pi * 2 / 32 + time * .85;
      final inner = center + Offset.fromDirection(angle, radius + 4);
      final outer = center + Offset.fromDirection(angle, radius + 8 + 3 * math.sin(time * 3 + i));
      c.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = ringColor.withValues(alpha: (.35 + .55 * math.sin(time * 2 + i).abs()) * strength),
      );
    }
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
      ..moveTo(center.dx - 20 * k, center.dy - 24 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 24 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 5 * k)
      ..lineTo(center.dx + 17 * k, center.dy - 25 * k)
      ..lineTo(center.dx + 33 * k, center.dy - 25 * k)
      ..lineTo(center.dx + 4 * k, center.dy + 1 * k)
      ..lineTo(center.dx + 32 * k, center.dy + 28 * k)
      ..lineTo(center.dx + 17 * k, center.dy + 28 * k)
      ..lineTo(center.dx - 8 * k, center.dy + 7 * k)
      ..lineTo(center.dx - 8 * k, center.dy + 28 * k)
      ..lineTo(center.dx - 20 * k, center.dy + 28 * k)
      ..close();

    // Small crown above the K, matching the KHANT premium mark.
    final crown = Path()
      ..moveTo(center.dx - 11 * k, center.dy - 31 * k)
      ..lineTo(center.dx - 15 * k, center.dy - 43 * k)
      ..lineTo(center.dx - 5 * k, center.dy - 36 * k)
      ..lineTo(center.dx, center.dy - 47 * k)
      ..lineTo(center.dx + 6 * k, center.dy - 36 * k)
      ..lineTo(center.dx + 15 * k, center.dy - 43 * k)
      ..lineTo(center.dx + 11 * k, center.dy - 31 * k)
      ..close();

    // Layered premium-gold bloom: keep the K itself gold in every state,
    // while making its silhouette visibly luminous like the KHANT reference.
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFB51B).withValues(alpha: .34 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFE6A0).withValues(alpha: .30 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    c.drawPath(
      crown,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF0A8), Color(0xFFFFC32B), Color(0xFFB87508)],
        ).createShader(Rect.fromCenter(
          center: center.translate(0, -39 * k),
          width: 32 * k,
          height: 20 * k,
        )),
    );
    c.drawCircle(center.translate(-15 * k, -43 * k), 2.2 * k,
        Paint()..color = goldLight);
    c.drawCircle(center.translate(15 * k, -43 * k), 2.2 * k,
        Paint()..color = goldLight);
    c.drawCircle(center.translate(0, -47 * k), 2.2 * k,
        Paint()..color = goldLight);

    final swoosh = Path()
      ..moveTo(center.dx - 34 * k, center.dy + 19 * k)
      ..cubicTo(
        center.dx - 5 * k, center.dy + 5 * k,
        center.dx + 18 * k, center.dy + 10 * k,
        center.dx + 37 * k, center.dy - 23 * k,
      )
      ..cubicTo(
        center.dx + 18 * k, center.dy + 4 * k,
        center.dx - 12 * k, center.dy + 32 * k,
        center.dx - 34 * k, center.dy + 19 * k,
      );
    if (connected) {
      c.drawPath(
        swoosh,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2 * k
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF35FF45).withValues(alpha: .42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    c.drawPath(
      swoosh,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * k
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF0A8), Color(0xFFFFC32B), Color(0xFFB87508)],
        ).createShader(Rect.fromCenter(
          center: center,
          width: r * .9,
          height: r * .6,
        )),
    );

    final logoBounds = Rect.fromCenter(
      center: center,
      width: r * .9,
      height: r * .9,
    );
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: opacity),
            const Color(0xFFFFF4C2).withValues(alpha: opacity),
            const Color(0xFFFFD13D).withValues(alpha: opacity),
            const Color(0xFFE99A08).withValues(alpha: opacity),
            const Color(0xFFFFEAA0).withValues(alpha: opacity),
            const Color(0xFF9A5700).withValues(alpha: opacity),
          ],
          stops: const [0, .16, .34, .52, .76, 1],
        ).createShader(logoBounds),
    );

    // A soft metallic highlight travels across the K without changing its
    // silhouette. The bright edge gives the gold mark a polished, reflective finish.
    final shine = .5 + .5 * math.sin(t * .85);
    final shineCenter = Offset(
      center.dx + (shine - .5) * r * 1.15,
      center.dy - r * .08,
    );
    final shineRect = Rect.fromCenter(
      center: shineCenter,
      width: r * .34,
      height: r * 1.25,
    );
    c.save();
    c.clipPath(path);
    c.drawRect(
      Rect.fromCircle(center: center, radius: r),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(shineRect.left, shineRect.bottom),
          Offset(shineRect.right, shineRect.top),
          [
            Colors.white.withValues(alpha: 0),
            const Color(0xFFFFF6D5).withValues(alpha: .08 * opacity),
            const Color(0xFFFFFFFF).withValues(alpha: .42 * opacity),
            const Color(0xFFFFE9A0).withValues(alpha: .12 * opacity),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .35, .5, .65, 1],
        ),
    );
    c.restore();

    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 1.8
        ..color = const Color(0xFFFFF1BC).withValues(alpha: .95 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    // Crisp reflective edge on top of the soft bloom.
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * .55
        ..color = const Color(0xFFFFFFFF).withValues(alpha: .78 * opacity),
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
