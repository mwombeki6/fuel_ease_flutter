import 'package:flutter/material.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/flip_fuel_card.dart';

class FuelCardItem extends StatelessWidget {
  const FuelCardItem({
    required this.card,
    this.onTap,
    super.key,
  });

  final FuelCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CardFrontFace(card: card),
      ),
    );
  }
}
