import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip.dart';
import '../my_trips/my_trips_controller.dart';
import '../../../../core/theme/app_theme_extension.dart';

class DeletedTripsPage extends ConsumerWidget {
  const DeletedTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final deletedAsync = ref.watch(deletedTripsProvider);

    return Scaffold(
      backgroundColor: colors.background,
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
                    style: TextStyle(color: colors.title),
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
                              style: TextStyle(
                                color: colors.muted,
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
        final dialogColors = dialogContext.colors;
        return AlertDialog(
          backgroundColor: dialogColors.card,
          title: Text(
            l10n.deletedTripsDeleteConfirmTitle,
            style: TextStyle(color: dialogColors.title),
          ),
          content: Text(
            l10n.deletedTripsDeleteConfirmBody,
            style: TextStyle(color: dialogColors.muted),
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
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.muted,
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: colors.title),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.title,
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.airline,
            style: TextStyle(
              color: colors.title,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.fromCode} → ${trip.toCode}',
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.fromCity} → ${trip.toCity}',
            style: TextStyle(
              color: colors.muted,
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
                    foregroundColor: colors.title,
                    side: BorderSide(color: colors.border),
                  ),
                  child: Text(l10n.deletedTripsRestore),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDeletePermanent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(color: colors.danger),
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
