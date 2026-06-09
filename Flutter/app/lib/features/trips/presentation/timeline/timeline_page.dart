import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/localization/locale_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/result.dart';
import '../../data/trips_repository.dart';
import '../../domain/ai_travel.dart';
import '../active_trip_controller.dart';
import 'timeline_destination_hero.dart';
import 'timeline_utils.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final Set<String> _completedKeys = {};
  final Map<String, int> _todoIdByKey = {};
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
        _todoIdByKey.clear();
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

    final repo = ref.read(tripsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchTimeline(trip.reservationId),
      repo.getTodos(trip.reservationId),
    ]);

    if (!mounted) return;

    final timelineResult = results[0] as Result<TimelineResult>;
    final todosResult = results[1] as Result<List<Map<String, dynamic>>>;

    timelineResult.when(
      success: (timeline) {
        final todoIdByKey = <String, int>{};
        final completedKeys = <String>{};

        todosResult.when(
          success: (todos) {
            final todosByMatch = <String, Map<String, dynamic>>{};
            for (final todo in todos) {
              final matchKey = timelineTodoMatchKey(
                title: todo['title'] as String? ?? '',
                category: todo['category'] as String? ?? 'task',
              );
              todosByMatch.putIfAbsent(matchKey, () => todo);
            }

            for (var i = 0; i < timeline.items.length; i++) {
              final item = timeline.items[i];
              final todo = todosByMatch[timelineTodoMatchKeyForItem(item)];
              if (todo == null) continue;
              final key = _itemKey(i);
              final id = todo['id'] as int?;
              if (id == null) continue;
              todoIdByKey[key] = id;
              if (todo['is_completed'] == true) {
                completedKeys.add(key);
              }
            }
          },
          failure: (_) {},
        );

        setState(() {
          _timeline = timeline;
          _loadedReservationId = trip.reservationId;
          _isLoading = false;
          _loadError = null;
          _todoIdByKey
            ..clear()
            ..addAll(todoIdByKey);
          _completedKeys
            ..clear()
            ..addAll(completedKeys);
        });
      },
      failure: (error) {
        setState(() {
          _timeline = null;
          _loadedReservationId = trip.reservationId;
          _isLoading = false;
          _loadError = localizeUserFacingError(error, l10n);
          _completedKeys.clear();
          _todoIdByKey.clear();
        });
      },
    );
  }

  String _itemKey(int index) => 'timeline:$index';

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: _TimelineColors.background,
      body: RefreshIndicator(
        color: _TimelineColors.blue,
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
              const CircularProgressIndicator(color: _TimelineColors.blue),
              const SizedBox(height: 16),
              Text(
                l10n.timelineLoading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _TimelineColors.title,
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
        completedKeys: _completedKeys,
        onTaskToggle: _toggleTask,
      ),
    ];
  }

  Future<void> _toggleTask(String key) async {
    final trip = ref.read(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    final timeline = _timeline;
    if (trip == null || trip.reservationId == 0 || timeline == null) {
      _showMessage(l10n.timelineOpenTripFirst);
      return;
    }

    final item = _itemForKey(key);
    if (item == null) return;

    final wasCompleted = _completedKeys.contains(key);
    final nextCompleted = !wasCompleted;

    setState(() {
      if (nextCompleted) {
        _completedKeys.add(key);
      } else {
        _completedKeys.remove(key);
      }
    });

    final repo = ref.read(tripsRepositoryProvider);
    var todoId = _todoIdByKey[key];

    if (todoId == null) {
      final createResult = await repo.createTodo(
        reservationId: trip.reservationId,
        title: item.title,
        category: item.category.isEmpty ? 'timeline' : item.category,
        priority: 'important',
      );
      if (!mounted) return;
      if (createResult is Failure<Map<String, dynamic>>) {
        setState(() {
          if (wasCompleted) {
            _completedKeys.add(key);
          } else {
            _completedKeys.remove(key);
          }
        });
        _showMessage(localizeUserFacingError(createResult.error, l10n));
        return;
      }
      todoId = (createResult as Success<Map<String, dynamic>>).data['id'] as int?;
      if (todoId == null) return;
      _todoIdByKey[key] = todoId;
    }

    if (nextCompleted) {
      final updateResult = await repo.updateTodo(
        reservationId: trip.reservationId,
        todoId: todoId,
        isCompleted: true,
      );
      if (!mounted) return;
      if (updateResult is Failure<Map<String, dynamic>>) {
        setState(() => _completedKeys.remove(key));
        _showMessage(localizeUserFacingError(updateResult.error, l10n));
      }
      return;
    }

    final updateResult = await repo.updateTodo(
      reservationId: trip.reservationId,
      todoId: todoId,
      isCompleted: false,
    );
    if (!mounted) return;
    if (updateResult is Failure<Map<String, dynamic>>) {
      setState(() => _completedKeys.add(key));
      _showMessage(localizeUserFacingError(updateResult.error, l10n));
    }
  }

  TimelineItem? _itemForKey(String key) {
    final timeline = _timeline;
    if (timeline == null || !key.startsWith('timeline:')) return null;
    final index = int.tryParse(key.split(':').last);
    if (index == null || index < 0 || index >= timeline.items.length) {
      return null;
    }
    return timeline.items[index];
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _TimelineColors.title,
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
                  style: const TextStyle(
                    color: _TimelineColors.salmon,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.timelineYourJourney,
                  style: const TextStyle(
                    color: _TimelineColors.title,
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
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;

  const _TimelineList({
    required this.l10n,
    required this.timeline,
    required this.daysUntilDeparture,
    required this.completedKeys,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Container(width: 2, color: _TimelineColors.line),
        ),
        Column(
          children: [
            for (var i = 0; i < dayKeys.length; i++) ...[
              if (i > 0) const SizedBox(height: 34),
              _TimelineEntry(
                l10n: l10n,
                daysBefore: dayKeys[i],
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
  final List<(int index, TimelineItem item)> indexedItems;
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;

  const _TimelineEntry({
    required this.l10n,
    required this.daysBefore,
    required this.indexedItems,
    required this.completedKeys,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final items = indexedItems.map((entry) => entry.$2).toList();
    final category = items.first.category;
    final dotColor = _categoryColor(category);
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
                      _dayLabel(l10n, daysBefore),
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

  String _dayLabel(AppLocalizations l10n, int days) {
    return switch (days) {
      14 => l10n.timelineDay14,
      7 => l10n.timelineDay7,
      1 => l10n.timelineDay1,
      _ => l10n.timelineDayBefore(days),
    };
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'document' => _TimelineColors.blue,
      'packing' => _TimelineColors.pink,
      _ => _TimelineColors.salmon,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _TimelineColors.badge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TimelineColors.title,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String title;
  final List<(int index, TimelineItem item)> indexedItems;
  final Set<String> completedKeys;
  final ValueChanged<String> onTaskToggle;
  final Color accentColor;

  const _TimelineCard({
    required this.title,
    required this.indexedItems,
    required this.completedKeys,
    required this.onTaskToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 20),
      decoration: BoxDecoration(
        color: _TimelineColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _TimelineColors.title,
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
                  title: item.title,
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
              color: isDone ? _TimelineColors.done : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? _TimelineColors.done : _TimelineColors.muted,
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
                    color: isDone ? _TimelineColors.muted : _TimelineColors.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: _TimelineColors.muted,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _TimelineColors.muted,
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

class _TimelineColors {
  _TimelineColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color badge = Color(0xFF24344E);
  static const Color title = Color(0xFFD5E4FF);
  static const Color muted = Color(0xFF5E6E87);
  static const Color line = Color(0xFF243A56);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFAA84);
  static const Color pink = Color(0xFFFFA6A5);
  static const Color done = Color(0xFF81C784);
}
