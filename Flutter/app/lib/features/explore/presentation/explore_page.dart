import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../trips/domain/trip.dart';
import '../../trips/presentation/active_trip_controller.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static final Uri _bookingUrl = Uri.parse('https://example.com');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 130),
              sliver: SliverList.list(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _DashboardColors.card,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.airplane_ticket_outlined,
                          color: _DashboardColors.blue,
                          size: 34,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Flights',
                          style: TextStyle(
                            color: _DashboardColors.title,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Mosafer connects your booking, ticket QR, departure planning, airport guidance, packing, todos and notifications in one travel assistant.',
                          style: TextStyle(
                            color: _DashboardColors.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _BookingStepsCard(),
                  const SizedBox(height: 18),
                  _BookFlightButton(
                    onPressed: () => launchUrl(
                      _bookingUrl,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingStepsCard extends StatelessWidget {
  const _BookingStepsCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Open the booking website and choose your flight.',
      'Complete the reservation and keep your ticket or QR image.',
      'Return to Mosafer, scan or upload the ticket, then manage your trip.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW BOOKING WORKS',
            style: TextStyle(
              color: _DashboardColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: _DashboardColors.blue,
                    child: Text(
                      '${entry.$1 + 1}',
                      style: const TextStyle(
                        color: _DashboardColors.background,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: const TextStyle(
                        color: _DashboardColors.title,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookFlightButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BookFlightButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new),
        label: const Text(
          'OPEN BOOKING WEBSITE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    if (trip == null) {
      return Scaffold(
        backgroundColor: _DashboardColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: _DashboardColors.blue,
                  size: 42,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No active trip selected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _DashboardColors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Open a trip or scan a ticket to start your guided journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _DashboardColors.muted),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => context.goNamed('scan'),
                  child: const Text('Scan Ticket'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
            sliver: SliverList.list(
              children: [
                const _StageCards(),
                const SizedBox(height: 28),
                _ActiveTripHero(trip: trip),
                const SizedBox(height: 30),
                const _SectionTitle(text: 'HOME'),
                const SizedBox(height: 17),
                const _PreparationGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripHero extends StatelessWidget {
  final Trip trip;

  const _ActiveTripHero({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.airline,
            style: const TextStyle(
              color: _DashboardColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _AirportCode(
                code: trip.fromCode,
                city: trip.fromCity,
                alignment: CrossAxisAlignment.start,
              ),
              const Expanded(
                child: Center(
                  child: Icon(
                    Icons.flight_takeoff,
                    color: _DashboardColors.title,
                    size: 26,
                  ),
                ),
              ),
              _AirportCode(
                code: trip.toCode,
                city: trip.toCity,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 190,
              child: _FlightMetaCard(label: 'DATE', value: trip.dateTime),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCards extends StatelessWidget {
  const _StageCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StageCard(
            title: 'Home',
            subtitle: 'Plan route',
            icon: Icons.home_outlined,
            isActive: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StageCard(
            title: 'On way',
            subtitle: 'Live ETA',
            icon: Icons.navigation_outlined,
            onTapRouteName: 'onWay',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StageCard(
            title: 'Airport',
            subtitle: 'Gate ready',
            icon: Icons.local_airport,
            onTapRouteName: 'airportExperience',
          ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final String? onTapRouteName;

  const _StageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isActive = false,
    this.onTapRouteName,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? _DashboardColors.blue : _DashboardColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isActive
                ? _DashboardColors.background
                : _DashboardColors.title,
            size: 19,
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: isActive
                  ? _DashboardColors.background
                  : _DashboardColors.title,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: isActive
                  ? _DashboardColors.background
                  : _DashboardColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTapRouteName == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.goNamed(onTapRouteName!),
      child: card,
    );
  }
}

// ignore: unused_element
class _PrimaryTripActions extends StatelessWidget {
  final Trip trip;

  const _PrimaryTripActions({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.route_outlined,
          title: 'Plan departure from home',
          subtitle: 'Get leave time, traffic buffer and map route.',
          onTap: () => context.goNamed('planDeparture'),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.checklist_rtl,
          title: 'Trip todos and timeline',
          subtitle: 'Prepare documents, packing and airport tasks.',
          onTap: () => context.goNamed('tripTodos'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DashboardColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _DashboardColors.blue.withValues(alpha: 0.18),
              child: Icon(icon, color: _DashboardColors.blue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _DashboardColors.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _DashboardColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _DashboardColors.title),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _BoardingSummary extends StatelessWidget {
  const _BoardingSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boarding in',
          style: TextStyle(
            color: _DashboardColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '42',
              style: TextStyle(
                color: Colors.white,
                fontSize: 39,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -1.5,
              ),
            ),
            SizedBox(width: 4),
            Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(
                'min',
                style: TextStyle(
                  color: _DashboardColors.title,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RouteSummary extends StatelessWidget {
  const _RouteSummary();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _AirportCode(
          code: 'LHR',
          city: 'LONDON',
          alignment: CrossAxisAlignment.start,
        ),
        Expanded(
          child: Center(
            child: Icon(
              Icons.flight_takeoff,
              color: _DashboardColors.title,
              size: 26,
            ),
          ),
        ),
        _AirportCode(
          code: 'DXB',
          city: 'DUBAI',
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _AirportCode extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment alignment;

  const _AirportCode({
    required this.code,
    required this.city,
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
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            height: 0.95,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          city,
          style: const TextStyle(
            color: _DashboardColors.title,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _FlightMetaCards extends StatelessWidget {
  const _FlightMetaCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FlightMetaCard(label: 'GATE', value: 'B24'),
        ),
        SizedBox(width: 13),
        Expanded(
          child: _FlightMetaCard(label: 'TERMINAL', value: '5'),
        ),
        SizedBox(width: 13),
        Expanded(
          child: _FlightMetaCard(label: 'SEAT', value: '12A'),
        ),
      ],
    );
  }
}

class _FlightMetaCard extends StatelessWidget {
  final String label;
  final String value;

  const _FlightMetaCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _DashboardColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DashboardColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _DashboardColors.title,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _DashboardColors.title,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _PreparationGrid extends StatelessWidget {
  const _PreparationGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      _PreparationItem(
        icon: Icons.map_outlined,
        label: 'Departure Plan',
        routeName: 'planDeparture',
      ),
      _PreparationItem(
        icon: Icons.inventory_2_outlined,
        label: 'Packing List',
        routeName: 'packing',
      ),
      _PreparationItem(
        icon: Icons.article_outlined,
        label: 'Timeline',
        routeName: 'timeline',
      ),
      _PreparationItem(
        icon: Icons.checklist_outlined,
        label: 'Todos',
        routeName: 'tripTodos',
      ),
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: items
          .map(
            (item) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 45) / 2,
              child: item,
            ),
          )
          .toList(),
    );
  }
}

class _PreparationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? routeName;

  const _PreparationItem({
    required this.icon,
    required this.label,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: routeName == null ? () {} : () => context.goNamed(routeName!),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _DashboardColors.blue,
            width: 1,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _DashboardColors.title, size: 20),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _SectionTitle(text: 'ATTACHMENTS')),
            Text(
              '2 FILES',
              style: TextStyle(
                color: _DashboardColors.title,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        _AttachmentCard(
          fileName: 'Visa_Dubai.pdf',
          details: '1.2 MB - Verified',
        ),
        SizedBox(height: 9),
        _AttachmentCard(
          fileName: 'Travel_Insurance.pdf',
          details: '850 KB - Verified',
        ),
        SizedBox(height: 20),
        _UploadAttachmentButton(),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final String fileName;
  final String details;

  const _AttachmentCard({required this.fileName, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 63,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: _DashboardColors.attachment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DashboardColors.attachmentBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: _DashboardColors.pdfBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: _DashboardColors.pdf,
              size: 18,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: _DashboardColors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.visibility_outlined,
              color: _DashboardColors.title,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadAttachmentButton extends StatelessWidget {
  const _UploadAttachmentButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: _DashboardColors.title,
          side: const BorderSide(color: _DashboardColors.dashedBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 14),
        label: const Text(
          'UPLOAD ATTACHMENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AirportExperienceButton extends StatelessWidget {
  const _AirportExperienceButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.goNamed('airportExperience'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _DashboardColors.salmon,
          foregroundColor: _DashboardColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: const Text(
          'OPEN AIRPORT EXPERIENCE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DashboardColors {
  _DashboardColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color attachment = Color(0xFF1B2A42);
  static const Color attachmentBorder = Color(0xFF263B59);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF6F7D94);
  static const Color blue = Color(0xFF4A91F8);
  static const Color dashedBorder = Color(0xFF334762);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color buttonText = Color(0xFF4E1017);
  static const Color pdfBackground = Color(0xFF4B2538);
  static const Color pdf = Color(0xFFFFA8A0);
}
