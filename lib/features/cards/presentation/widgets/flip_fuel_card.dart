import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

// ── EMV chip ────────────────────────────────────────────────────────────────

class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shader = const LinearGradient(
      colors: [Color(0xFFD4AF37), Color(0xFFF5D97F), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fill = Paint()..shader = shader;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, fill);

    final line = Paint()
      ..color = const Color(0xFFB8962E).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), line);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _CardStatusBadge extends StatelessWidget {
  const _CardStatusBadge({required this.status});
  final String status;

  Color get _color => switch (status) {
        'active' => AppColors.success,
        'blocked' => AppColors.error,
        'expired' => AppColors.textSecondaryDark,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Card gradient helper ──────────────────────────────────────────────────────

Gradient _cardGradient(FuelCard card) {
  if (!card.isActive) {
    return const LinearGradient(
      colors: [Color(0xFF374151), Color(0xFF4B5563)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  return AppColors.fuelCardGradient;
}

// ── Front face ───────────────────────────────────────────────────────────────

class CardFrontFace extends StatelessWidget {
  const CardFrontFace({required this.card, super.key});
  final FuelCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: _cardGradient(card),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomPaint(size: const Size(36, 28), painter: ChipPainter()),
              _CardStatusBadge(status: card.status),
            ],
          ),
          const Spacer(),
          Text(
            '●●●● ●●●● ●●●● ${card.last4}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FUEL EASE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Expires ${card.expiresAt.month.toString().padLeft(2, '0')}/${card.expiresAt.year.toString().substring(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Back face ────────────────────────────────────────────────────────────────

class CardBackFace extends StatelessWidget {
  const CardBackFace({required this.card, super.key});
  final FuelCard card;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/yy');
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: _cardGradient(card),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Magnetic stripe
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(color: Color(0xFF111827)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CVV',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          card.cvv ?? '•••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('VALID THRU',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(card.expiresAt),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '●●●● ●●●● ●●●● ${card.last4}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flip card ────────────────────────────────────────────────────────────────

class FlipFuelCard extends StatefulWidget {
  const FlipFuelCard({required this.card, super.key});
  final FuelCard card;

  @override
  State<FlipFuelCard> createState() => _FlipFuelCardState();
}

class _FlipFuelCardState extends State<FlipFuelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFront = angle <= pi / 2;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? CardFrontFace(card: widget.card)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: CardBackFace(card: widget.card),
                  ),
          );
        },
      ),
    );
  }
}
