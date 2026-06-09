import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class TicketDetailsPage extends StatelessWidget {
  const TicketDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TicketColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
            sliver: SliverList.list(
              children: [
                const _BoardingPassPreview(),
                const SizedBox(height: 19),
                const _BoardingTitle(),
                const SizedBox(height: 25),
                const _TicketInfoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardingPassPreview extends StatelessWidget {
  const _BoardingPassPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 224,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _TicketColors.card,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Container(
          width: 190,
          height: 190,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Container(
            color: const Color(0xFF282528),
            child: Center(
              child: Container(
                width: 73,
                height: 98,
                color: Colors.white,
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ticketBoardingPass,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.brandMosafer,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: CustomPaint(
                        painter: _QrPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ticketSafeWorkSecure,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardingTitle extends StatelessWidget {
  const _BoardingTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.ticketBoardingPass,
          style: const TextStyle(
            color: _TicketColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.ticketScanForBoarding,
          style: const TextStyle(
            color: _TicketColors.title,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TicketInfoCard extends StatelessWidget {
  const _TicketInfoCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: BoxDecoration(
        color: _TicketColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TicketColors.border),
      ),
      child: Column(
        children: [
          const _TicketHeaderRow(),
          const SizedBox(height: 12),
          const _TicketRouteRow(),
          const SizedBox(height: 26),
          const Divider(color: _TicketColors.divider, height: 1),
          const SizedBox(height: 22),
          _TicketDetailsGrid(l10n: l10n),
        ],
      ),
    );
  }
}

class _TicketHeaderRow extends StatelessWidget {
  const _TicketHeaderRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'SKY-442',
            style: TextStyle(
              color: _TicketColors.coral,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          l10n.ticketDirect,
          style: const TextStyle(
            color: _TicketColors.coral,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TicketRouteRow extends StatelessWidget {
  const _TicketRouteRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _TicketAirport(
          code: 'LHR',
          name: 'London Heathrow',
          alignment: CrossAxisAlignment.start,
        ),
        Expanded(
          child: Column(
            children: [
              Icon(Icons.flight_takeoff, color: _TicketColors.title, size: 22),
              SizedBox(height: 3),
              Text(
                '7H 45M',
                style: TextStyle(
                  color: _TicketColors.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _TicketAirport(
          code: 'DXB',
          name: 'Dubai International',
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _TicketAirport extends StatelessWidget {
  final String code;
  final String name;
  final CrossAxisAlignment alignment;

  const _TicketAirport({
    required this.code,
    required this.name,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          code,
          style: const TextStyle(
            color: _TicketColors.title,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          style: const TextStyle(
            color: _TicketColors.body,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TicketDetailsGrid extends StatelessWidget {
  final AppLocalizations l10n;

  const _TicketDetailsGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailCell(
                label: l10n.flightMetaSeat,
                value: '12A',
                suffix: ' (Window)',
              ),
            ),
            Expanded(
              child: _DetailCell(label: l10n.flightMetaGate, value: 'B24'),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: _DetailCell(label: l10n.flightMetaTerminal, value: '5'),
            ),
            Expanded(
              child: _DetailCell(
                label: l10n.ticketDeparture,
                value: '10:00 AM',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _DetailCell({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _TicketColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: value,
            children: [
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    color: _TicketColors.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          style: const TextStyle(
            color: _TicketColors.title,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const grid = 9;
    final cell = size.width / grid;
    const pattern = [
      [1, 1, 1, 0, 1, 0, 1, 1, 1],
      [1, 0, 1, 1, 0, 1, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 1, 1, 1],
      [0, 1, 0, 1, 0, 1, 0, 1, 0],
      [1, 0, 1, 1, 1, 0, 1, 0, 1],
      [0, 1, 1, 0, 1, 1, 0, 1, 1],
      [1, 1, 0, 1, 0, 1, 1, 0, 1],
      [1, 0, 1, 0, 1, 0, 1, 1, 0],
      [1, 1, 1, 1, 0, 1, 0, 1, 1],
    ];

    for (var row = 0; row < grid; row++) {
      for (var col = 0; col < grid; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell * 0.82, cell * 0.82),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TicketColors {
  _TicketColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color border = Color(0xFF213650);
  static const Color divider = Color(0xFF263A55);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFFC0CBE0);
  static const Color muted = Color(0xFF7D8BA3);
  static const Color coral = Color(0xFFFFA28E);
}
