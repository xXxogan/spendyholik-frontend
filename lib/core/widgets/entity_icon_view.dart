import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/models/entity_icon.dart';

extension EntityIconData on EntityIcon {
  IconData get data => switch (this) {
    EntityIcon.cart => Icons.shopping_cart_outlined,
    EntityIcon.cafe => Icons.local_cafe_outlined,
    EntityIcon.bus => Icons.directions_bus_outlined,
    EntityIcon.home => Icons.home_outlined,
    EntityIcon.film => Icons.movie_outlined,
    EntityIcon.health => Icons.favorite_border,
    EntityIcon.bag => Icons.shopping_bag_outlined,
    EntityIcon.subscription => Icons.autorenew,
    EntityIcon.salary => Icons.payments_outlined,
    EntityIcon.freelance => Icons.laptop_mac,
    EntityIcon.percent => Icons.percent,
    EntityIcon.transfer => Icons.swap_horiz,
    EntityIcon.card => Icons.credit_card,
    EntityIcon.cash => Icons.account_balance_wallet_outlined,
    EntityIcon.savings => Icons.savings_outlined,
    EntityIcon.credit => Icons.credit_score_outlined,
    EntityIcon.gift => Icons.card_giftcard,
    EntityIcon.other => Icons.category_outlined,
  };
}

class EntityIconView extends StatelessWidget {
  const EntityIconView({required this.icon, required this.color, this.size = 40, super.key});

  final EntityIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon.data, color: color, size: size * 0.5),
    );
  }
}
