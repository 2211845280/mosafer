import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/trip.dart';
import '../active_trip_controller.dart';
import 'my_trips_controller.dart';

class MyTripsPage extends ConsumerWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(myTripsControllerProvider);
    final controller = ref.read(myTripsControllerProvider.notifier);

    return state.when(
      loading: () => const Scaffold(
        backgroundColor: _TripsColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _TripsColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizeUserFacingError(error, l10n),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _TripsColors.coral),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadTrips,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) {
        final trips = state.filteredTrips;
        return Scaffold(
          backgroundColor: _TripsColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 28, 14, 0),
                    sliver: SliverList.list(
                      children: [
                        _SearchField(
                          hintText: l10n.tripsSearchHint,
                          onChanged: controller.updateSearchQuery,
                        ),
                        const SizedBox(height: 20),
                        _TripsSegmentedControl(
                          upcomingLabel: l10n.tripsUpcoming,
                          allLabel: l10n.tripsAll,
                          showUpcomingOnly: state.showUpcomingOnly,
                          onUpcomingPressed: controller.showUpcoming,
                          onAllPressed: controller.showAll,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 154),
                    sliver: SliverList.separated(
                      itemCount: trips.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        return _TripCard(
                          trip: trips[index],
                          onDelete: () => _confirmDeleteTrip(
                            context,
                            ref,
                            trips[index],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                end: 18,
                bottom: 104,
                child: FloatingActionButton(
                  onPressed: () => context.goNamed('scan'),
                  backgroundColor: _TripsColors.blue,
                  foregroundColor: _TripsColors.background,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 31),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteTrip(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _TripsColors.card,
          title: Text(
            l10n.tripsDeleteConfirmTitle,
            style: const TextStyle(color: _TripsColors.title),
          ),
          content: Text(
            l10n.tripsDeleteConfirmBody,
            style: const TextStyle(color: _TripsColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tripsDeleteCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tripsDeleteConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(myTripsControllerProvider.notifier).softDeleteTrip(trip);
    ref.invalidate(deletedTripsProvider);
  }
}

class _SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      cursorColor: _TripsColors.blue,
      style: const TextStyle(color: _TripsColors.title, fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _TripsColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: _TripsColors.muted,
          size: 19,
        ),
        filled: true,
        fillColor: _TripsColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _TripsColors.blue),
        ),
      ),
    );
  }
}

class _TripsSegmentedControl extends StatelessWidget {
  final String upcomingLabel;
  final String allLabel;
  final bool showUpcomingOnly;
  final VoidCallback onUpcomingPressed;
  final VoidCallback onAllPressed;

  const _TripsSegmentedControl({
    required this.upcomingLabel,
    required this.allLabel,
    required this.showUpcomingOnly,
    required this.onUpcomingPressed,
    required this.onAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _TripsColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: upcomingLabel,
              isSelected: showUpcomingOnly,
              onPressed: onUpcomingPressed,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: allLabel,
              isSelected: !showUpcomingOnly,
              onPressed: onAllPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? _TripsColors.blue : Colors.transparent,
        foregroundColor: isSelected
            ? _TripsColors.background
            : _TripsColors.title,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDelete;

  const _TripCard({required this.trip, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = trip.status == TripStatus.completed;
    final isExpired = trip.isExpired;
    final isDisabled = isCompleted || isExpired;
    final foreground = isDisabled ? _TripsColors.disabledText : _TripsColors.title;
    final opacity = isExpired ? 0.4 : isCompleted ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onLongPress: isDisabled ? null : onDelete,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/trips/plane.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _AirlineAvatar(label: trip.imageLabel),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            trip.airline,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isExpired)
                          _ExpiredPill(label: l10n.tripsExpired)
                        else
                          _StatusPill(status: trip.status),
                      ],
                    ),
                    const SizedBox(height: 27),
                    _RouteSummary(trip: trip, foreground: foreground),
                    const SizedBox(height: 22),
                    const Divider(color: _TripsColors.divider, height: 1),
                    const SizedBox(height: 19),
                    _TripMetaRow(trip: trip, foreground: foreground),
                    const SizedBox(height: 19),
                    _TripActionButton(trip: trip, isDisabled: isDisabled),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiredPill extends StatelessWidget {
  final String label;

  const _ExpiredPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _TripsColors.completedPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TripsColors.disabledText,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AirlineAvatar extends StatelessWidget {
  final String label;

  const _AirlineAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F2FF), Color(0xFF255C8E)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: _TripsColors.background,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TripStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConfirmed = status == TripStatus.confirmed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConfirmed
            ? _TripsColors.greenPill
            : _TripsColors.completedPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isConfirmed ? l10n.tripsConfirmed : l10n.tripsCompleted,
        style: TextStyle(
          color: isConfirmed ? _TripsColors.green : _TripsColors.disabledText,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final Trip trip;
  final Color foreground;

  const _RouteSummary({required this.trip, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AirportBlock(
          code: trip.fromCode,
          city: trip.fromCity,
          alignment: CrossAxisAlignment.start,
          foreground: foreground,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                const Expanded(child: Divider(color: _TripsColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.flight_takeoff,
                    color: foreground,
                    size: 20,
                  ),
                ),
                const Expanded(child: Divider(color: _TripsColors.divider)),
              ],
            ),
          ),
        ),
        _AirportBlock(
          code: trip.toCode,
          city: trip.toCity,
          alignment: CrossAxisAlignment.end,
          foreground: foreground,
        ),
      ],
    );
  }
}

class _AirportBlock extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment alignment;
  final Color foreground;

  const _AirportBlock({
    required this.code,
    required this.city,
    required this.alignment,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          code,
          style: TextStyle(
            color: foreground,
            fontSize: 30,
            height: 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 92,
          child: Text(
            city,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignment == CrossAxisAlignment.end
                ? TextAlign.end
                : TextAlign.start,
            style: TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w300,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _TripMetaRow extends StatelessWidget {
  final Trip trip;
  final Color foreground;

  const _TripMetaRow({required this.trip, required this.foreground});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Row(
      children: [
        Expanded(
          child: _MetaItem(
            icon: Icons.calendar_month_outlined,
            label: trip.formattedDeparture(locale),
            foreground: foreground,
          ),
        ),
        _MetaItem(
          icon: Icons.chair_outlined,
          label: trip.seat,
          foreground: foreground,
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _TripsColors.coral),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TripActionButton extends ConsumerWidget {
  final Trip trip;
  final bool isDisabled;

  const _TripActionButton({required this.trip, required this.isDisabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = trip.status == TripStatus.completed;

    return IgnorePointer(
      ignoring: isDisabled,
      child: SizedBox(
        height: 43,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isDisabled
              ? null
              : () {
                  ref.read(activeTripProvider.notifier).state = trip;
                  context.goNamed('dashboard');
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled
                ? _TripsColors.inactiveButton
                : _TripsColors.blue,
            foregroundColor: isDisabled
                ? _TripsColors.disabledText
                : _TripsColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(
            isCompleted ? l10n.tripsViewHistory : l10n.tripsOpenTrip,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _TripsColors {
  _TripsColors._();

  static const Color background = Color(0xFF061326);
  static const Color surface = Color(0xFF101F36);
  static const Color card = Color(0xFF101F35);
  static const Color title = Color(0xFFD9E5FF);
  static const Color muted = Color(0xFF70819D);
  static const Color blue = Color(0xFF4A91F8);
  static const Color coral = Color(0xFFFFA982);
  static const Color green = Color(0xFF16D8A4);
  static const Color greenPill = Color(0xFF063B3A);
  static const Color completedPill = Color(0xFF1A263A);
  static const Color disabledText = Color(0xFF7C8BA7);
  static const Color divider = Color(0xFF203149);
  static const Color inactiveButton = Color(0xFF263751);
}
