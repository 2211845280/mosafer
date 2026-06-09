import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip.dart';
import '../my_trips/my_trips_controller.dart';

class DeletedTripsPage extends ConsumerWidget {
  const DeletedTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final deletedAsync = ref.watch(deletedTripsProvider);

    return Scaffold(
      backgroundColor: _DeletedTripsColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DeletedTripsAppBar(
              title: l10n.deletedTripsTitle,
              onBack: () => context.goNamed('settings'),
            ),
            Expanded(
              child: deletedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    l10n.retry,
                    style: const TextStyle(color: _DeletedTripsColors.title),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.deletedTripsEmpty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _DeletedTripsColors.muted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _AutoPurgeNotice(text: l10n.deletedTripsAutoPurgeNotice),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 130),
                    itemCount: entries.length + 1,
                    separatorBuilder: (context, index) {
                      if (index >= entries.length - 1) {
                        return const SizedBox(height: 20);
                      }
                      return const SizedBox(height: 14);
                    },
                    itemBuilder: (context, index) {
                      if (index == entries.length) {
                        return _AutoPurgeNotice(
                          text: l10n.deletedTripsAutoPurgeNotice,
                        );
                      }

                      final entry = entries[index];
                      return _DeletedTripTile(
                        trip: entry.trip,
                        onRestore: () async {
                          await ref
                              .read(myTripsControllerProvider.notifier)
                              .restoreTrip(entry.trip.reservationId);
                          ref.invalidate(deletedTripsProvider);
                        },
                        onDeletePermanent: () => _confirmPermanentDelete(
                          context,
                          ref,
                          entry.trip,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _DeletedTripsColors.card,
          title: Text(
            l10n.deletedTripsDeleteConfirmTitle,
            style: const TextStyle(color: _DeletedTripsColors.title),
          ),
          content: Text(
            l10n.deletedTripsDeleteConfirmBody,
            style: const TextStyle(color: _DeletedTripsColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tripsDeleteCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deletedTripsDeletePermanent),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref
        .read(myTripsControllerProvider.notifier)
        .permanentlyDeleteTrip(trip.reservationId);
    ref.invalidate(deletedTripsProvider);
  }
}

class _AutoPurgeNotice extends StatelessWidget {
  final String text;

  const _AutoPurgeNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _DeletedTripsColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DeletedTripsColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _DeletedTripsColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DeletedTripsAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _DeletedTripsAppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: _DeletedTripsColors.title),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _DeletedTripsColors.title,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedTripTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanent;

  const _DeletedTripTile({
    required this.trip,
    required this.onRestore,
    required this.onDeletePermanent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DeletedTripsColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DeletedTripsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.airline,
            style: const TextStyle(
              color: _DeletedTripsColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.fromCode} → ${trip.toCode}',
            style: const TextStyle(
              color: _DeletedTripsColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.fromCity} → ${trip.toCity}',
            style: const TextStyle(
              color: _DeletedTripsColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRestore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DeletedTripsColors.title,
                    side: const BorderSide(color: _DeletedTripsColors.border),
                  ),
                  child: Text(l10n.deletedTripsRestore),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDeletePermanent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DeletedTripsColors.danger,
                    side: const BorderSide(color: _DeletedTripsColors.danger),
                  ),
                  child: Text(
                    l10n.deletedTripsDeletePermanent,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeletedTripsColors {
  _DeletedTripsColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color border = Color(0xFF314663);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF77879E);
  static const Color danger = Color(0xFFE57373);
}
