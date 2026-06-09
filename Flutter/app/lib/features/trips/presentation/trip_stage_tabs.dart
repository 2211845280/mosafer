import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

int tripStageIndexForPath(String path) => switch (path) {
  '/on-way' => 1,
  '/airport-experience' => 2,
  _ => 0,
};

String tripStagePathForIndex(int index) => switch (index) {
  1 => '/on-way',
  2 => '/airport-experience',
  _ => '/dashboard',
};

class TripStageTabs extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const TripStageTabs({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _StageTabCard(
            title: l10n.stageHomeTitle,
            icon: Icons.home_outlined,
            isActive: activeIndex == 0,
            onTap: () => onTabSelected(0),
            backgroundAsset: 'assets/images/dashboard/house.jpg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StageTabCard(
            title: l10n.stageOnWayTitle,
            icon: Icons.navigation_outlined,
            isActive: activeIndex == 1,
            onTap: () => onTabSelected(1),
            backgroundAsset: 'assets/images/dashboard/chicago.jpg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StageTabCard(
            title: l10n.stageAirportTitle,
            icon: Icons.local_airport,
            isActive: activeIndex == 2,
            onTap: () => onTabSelected(2),
            backgroundAsset: 'assets/images/dashboard/airport.webp',
          ),
        ),
      ],
    );
  }
}

class _StageTabCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String? backgroundAsset;

  const _StageTabCard({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.backgroundAsset,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = _TripStageTabColors.title;
    final iconColor = _TripStageTabColors.title;

    final card = Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: isActive
            ? Border.all(color: _TripStageTabColors.blue, width: 2.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isActive ? 15.5 : 18),
        child: Stack(
          children: [
            if (backgroundAsset != null)
              Positioned.fill(
                child: Image.asset(backgroundAsset!, fit: BoxFit.cover),
              ),
            if (backgroundAsset != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: isActive ? 0.35 : 0.5),
                        Colors.black.withValues(alpha: isActive ? 0.72 : 0.82),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 19),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isActive) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class _TripStageTabColors {
  _TripStageTabColors._();

  static const Color title = Color(0xFFD5E4FF);
  static const Color blue = Color(0xFF4A91F8);
}
