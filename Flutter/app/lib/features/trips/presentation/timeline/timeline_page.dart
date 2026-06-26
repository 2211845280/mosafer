import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/ai_content_localizer.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/localization/locale_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../../domain/ai_travel.dart';
import '../active_trip_controller.dart';
import 'timeline_destination_hero.dart';
import 'timeline_utils.dart';
import '../../../../core/theme/app_theme_extension.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final Set<String> _completedKeys = {};
  bool _isLoading = false;
  String? _loadError;
  TimelineResult? _timeline;
  int? _loadedReservationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTimeline());
  }

  Future<void> _loadTimeline({bool force = false}) async {
    final trip = ref.read(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    if (trip == null || trip.reservationId == 0) {
      setState(() {
        _timeline = null;
        _loadError = null;
        _isLoading = false;
        _loadedReservationId = null;
        _completedKeys.clear();
      });
      return;
    }
    if (!force &&
        _loadedReservationId == trip.reservationId &&
        _timeline != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final result = await ref
        .read(tripsRepositoryProvider)
        .fetchTimeline(trip.reservationId);

    if (!mounted) return;

    final timeline = result.dataOrNull;
    if (timeline != null) {
      final completedKeys = await _loadCompletedKeys(trip.reservationId);
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _loadedReservationId = trip.reservationId;
        _isLoading = false;
        _loadError = null;
        _completedKeys
          ..clear()
          ..addAll(completedKeys);
      });
      return;
    }

    setState(() {
      _timeline = null;
      _loadedReservationId = trip.reservationId;
      _isLoading = false;
      _loadError = localizeUserFacingError(result.errorOrNull ?? '', l10n);
      _completedKeys.clear();
    });
  }

  String _completedPrefsKey(int reservationId) =>
      'timeline_completed:$reservationId';

  Future<Set<String>> _loadCompletedKeys(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_completedPrefsKey(reservationId)) ?? const [])
        .toSet();
  }

  Future<void> _saveCompletedKeys(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _completedKeys.toList()..sort();
    await prefs.setStringList(_completedPrefsKey(reservationId), keys);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    ref.listen(activeTripProvider, (previous, next) {
      if (previous?.reservationId != next?.reservationId) {
        _loadTimeline(force: true);
      }
    });

    ref.listen(appLocaleProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        _loadTimeline(force: true);
      }
    });

    final bottomInset = MediaQuery.paddingOf(context).bottom + 88 + 24;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () => _loadTimeline(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 26, 16, bottomInset),
              sliver: SliverList.list(
                children: [
                  _JourneyHero(),
                  const SizedBox(height: 31),
                  ..._buildBody(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n) {
    final colors = context.colors;
    final trip = ref.watch(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      return [
        _MessagePanel(message: l10n.timelineOpenTripFirst),
      ];
    }
    if (_isLoading && _timeline == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.timelineLoading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.title,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    if (_loadError != null) {
      return [
        _MessagePanel(
          message: _loadError!,
          actionLabel: l10n.timelineRetry,
          onAction: () => _loadTimeline(force: true),
        ),
      ];
    }

    final timeline = _timeline;
    if (timeline == null || timeline.items.isEmpty) {
      return [
        _MessagePanel(
          message: l10n.timelineLoadFailed,
          actionLabel: l10n.timelineRetry,
          onAction: () => _loadTimeline(force: true),
        ),
      ];
    }

    final daysUntil = daysUntilDeparture(trip.departureAt);
    final hasVisibleItems = timeline.items.any(
      (item) => isTimelineItemVisible(item, daysUntil),
    );
    if (!hasVisibleItems) {
      return [
        _MessagePanel(message: l10n.timelineNoUpcomingTasks),
      ];
    }

    return [
      _TimelineList(
        l10n: l10n,
        timeline: timeline,
        daysUntilDeparture: daysUntil,
        departureAt: trip.departureAt,
        completedKeys: _completedKeys,
        onTaskToggle: _toggleTask,
      ),
    ];
  }

  Future<void> _toggleTask(String key) async {
    final trip = ref.read(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    if (trip == null || trip.reservationId == 0 || _timeline == null) {
      _showMessage(l10n.timelineOpenTripFirst);
      return;
    }

    final wasCompleted = _completedKeys.contains(key);
    final nextCompleted = !wasCompleted;

    setState(() {
      if (nextCompleted) {
        _completedKeys.add(key);
      } else {
        _completedKeys.remove(key);
      }
    });
    await _saveCompletedKeys(trip.reservationId);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessagePanel({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _JourneyHero extends ConsumerWidget {
  const _JourneyHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(activeTripProvider);
    final heroAsset = timelineHeroAssetForDestination(trip?.toCode);

    return Container(
      height: 153,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: heroAsset == null
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6BA2B2),
                  Color(0xFFFFC28C),
                  Color(0xFF18324B),
                  Color(0xFF071326),
                ],
                stops: [0, 0.23, 0.57, 1],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (heroAsset != null)
            Positioned.fill(
              child: Image.asset(heroAsset, fit: BoxFit.cover),
            ),
          if (heroAsset != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xCC071326),
                      const Color(0x66071326),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          if (heroAsset == null)
            Positioned.fill(
              child: CustomPaint(painter: _CloudPainter()),
            ),
          Positioned(
            left: 20,
            bottom: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.timelineJourneyTag,
                  style: TextStyle(
                    color: colors.salmon,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.timelineYourJourney,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
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

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;

    for (var row = 0; row < 5; row++) {
      final y = size.height * (0.38 + row * 0.095);
      for (var i = 0; i < 7; i++) {
        final x = -20.0 + i * 56 + row * 18;
        final rect = Rect.fromLTWH(x, y, 84, 16 + row * 2);
        canvas.drawOval(rect, paint);
      }
    }

    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0xCC071326)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelineList extends StatelessWidget {
  final AppLocalizations l10n;
  final TimelineResult timeline;
  final int? daysUntilDeparture;
  final DateTime? departureAt;
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;

  const _TimelineList({
    required this.l10n,
    required this.timeline,
    required this.daysUntilDeparture,
    required this.departureAt,
    required this.completedKeys,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final indexedByDay = <int, List<(int index, TimelineItem item)>>{};
    for (var i = 0; i < timeline.items.length; i++) {
      final item = timeline.items[i];
      if (!isTimelineItemVisible(item, daysUntilDeparture)) continue;
      indexedByDay.putIfAbsent(item.daysBefore, () => []).add((i, item));
    }
    final dayKeys = indexedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Stack(
      children: [
        Positioned(
          left: 17,
          top: 11,
          bottom: 32,
          child: Container(width: 2, color: colors.divider),
        ),
        Column(
          children: [
            for (var i = 0; i < dayKeys.length; i++) ...[
              if (i > 0) const SizedBox(height: 34),
              _TimelineEntry(
                l10n: l10n,
                daysBefore: dayKeys[i],
                departureAt: departureAt,
                indexedItems: indexedByDay[dayKeys[i]]!,
                completedKeys: completedKeys,
                onTaskToggle: onTaskToggle,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final AppLocalizations l10n;
  final int daysBefore;
  final DateTime? departureAt;
  final List<(int index, TimelineItem item)> indexedItems;
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;

  const _TimelineEntry({
    required this.l10n,
    required this.daysBefore,
    required this.departureAt,
    required this.indexedItems,
    required this.completedKeys,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = indexedItems.map((entry) => entry.$2).toList();
    final category = items.first.category;
    final dotColor = _categoryColor(colors, category);
    final badge = _categoryBadge(l10n, category);
    final sectionTitle = _categoryTitle(l10n, category);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timelineOffsetLabel(l10n, daysBefore, departureAt),
                      style: TextStyle(
                        color: dotColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _TimelineBadge(label: badge),
                ],
              ),
              const SizedBox(height: 14),
              _TimelineCard(
                l10n: l10n,
                title: sectionTitle,
                indexedItems: indexedItems,
                completedKeys: completedKeys,
                onTaskToggle: onTaskToggle,
                accentColor: dotColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _categoryColor(AppThemeExtension colors, String category) {
    return switch (category) {
      'document' => colors.primary,
      'packing' => colors.salmon,
      _ => colors.salmon,
    };
  }

  String _categoryBadge(AppLocalizations l10n, String category) {
    return switch (category) {
      'document' => l10n.timelineBadgeDocument,
      'packing' => l10n.timelineBadgePacking,
      _ => l10n.timelineBadgeTask,
    };
  }

  String _categoryTitle(AppLocalizations l10n, String category) {
    return switch (category) {
      'document' => l10n.timelineTitleDocuments,
      'packing' => l10n.timelineTitlePacking,
      _ => l10n.timelineTitlePreparation,
    };
  }
}

class _TimelineBadge extends StatelessWidget {
  final String label;

  const _TimelineBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.title,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String title;
  final List<(int index, TimelineItem item)> indexedItems;
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;
  final Color accentColor;

  const _TimelineCard({
    required this.l10n,
    required this.title,
    required this.indexedItems,
    required this.completedKeys,
    required this.onTaskToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.title,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 17),
          ...indexedItems.map(
            (entry) {
              final key = 'timeline:${entry.$1}';
              final item = entry.$2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: _TaskRow(
                  title: localizeAiContentTitle(item.title, l10n),
                  subtitle: item.description,
                  isDone: completedKeys.contains(key),
                  onTap: () => onTaskToggle(key),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;

  const _TaskRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: isDone ? colors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? colors.success : colors.muted,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 13,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDone ? colors.muted : colors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.muted,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
