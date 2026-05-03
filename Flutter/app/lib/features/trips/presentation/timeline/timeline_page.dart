import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final Set<String> _selectedTasks = {
    'Check Passport Validity',
    'Complete All Packing List',
  };
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TimelineColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 180),
                sliver: SliverList.list(
                  children: [
                    const _JourneyHero(),
                    const SizedBox(height: 31),
                    _TimelineList(
                      selectedTasks: _selectedTasks,
                      onTaskToggle: _toggleTask,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _SyncTimelineButton(
              count: _selectedTasks.length,
              isLoading: _isAdding,
              onPressed: _selectedTasks.isEmpty || _isAdding
                  ? null
                  : _addSelectedToTodos,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTask(String label) {
    setState(() {
      if (!_selectedTasks.remove(label)) {
        _selectedTasks.add(label);
      }
    });
  }

  Future<void> _addSelectedToTodos() async {
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      _showMessage('Open a trip first.');
      return;
    }
    setState(() => _isAdding = true);
    final result = await ref
        .read(tripsRepositoryProvider)
        .createTodos(
          reservationId: trip.reservationId,
          titles: _selectedTasks.toList(),
          category: 'timeline',
          priority: 'important',
        );
    if (!mounted) return;
    setState(() => _isAdding = false);
    result.when(
      success: (count) => _showMessage('$count timeline items added to todos.'),
      failure: _showMessage,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 153,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6BA2B2),
            Color(0xFFFFC28C),
            Color(0xFF18324B),
            Color(0xFF071326),
          ],
          stops: [0, 0.23, 0.57, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(painter: _CloudPainter()),
            ),
          ),
          const Positioned(
            left: 20,
            bottom: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUSAFIR JOURNEY',
                  style: TextStyle(
                    color: _TimelineColors.salmon,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your Journey',
                  style: TextStyle(
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
  final Set<String> selectedTasks;
  final ValueChanged<String> onTaskToggle;

  const _TimelineList({
    required this.selectedTasks,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
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
            _TimelineEntry(
              day: 'D-14',
              badge: 'DOCUMENT',
              dotColor: _TimelineColors.blue,
              title: 'Travel Documents',
              tasks: [
                _TimelineTask(
                  'Check Passport Validity',
                  selectedTasks.contains('Check Passport Validity'),
                ),
                _TimelineTask(
                  'Apply for Entry Visa',
                  selectedTasks.contains('Apply for Entry Visa'),
                ),
              ],
              onTaskToggle: onTaskToggle,
            ),
            const SizedBox(height: 34),
            _TimelineEntry(
              day: 'D-7',
              badge: 'TASK',
              dotColor: _TimelineColors.salmon,
              title: 'Preparation',
              tasks: [
                _TimelineTask(
                  'Schedule Home Security',
                  selectedTasks.contains('Schedule Home Security'),
                ),
                _TimelineTask(
                  'Arrange Pet Boarding',
                  selectedTasks.contains('Arrange Pet Boarding'),
                ),
              ],
              onTaskToggle: onTaskToggle,
            ),
            const SizedBox(height: 34),
            _TimelineEntry(
              day: 'D-1',
              badge: 'PACKING',
              dotColor: _TimelineColors.pink,
              title: 'Packing & Logistics',
              tasks: [
                _TimelineTask(
                  'Complete All Packing List',
                  selectedTasks.contains('Complete All Packing List'),
                  isWarm: true,
                ),
                _TimelineTask(
                  'Book Airport Taxi',
                  selectedTasks.contains('Book Airport Taxi'),
                ),
              ],
              onTaskToggle: onTaskToggle,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String day;
  final String badge;
  final Color dotColor;
  final String title;
  final List<_TimelineTask> tasks;
  final ValueChanged<String> onTaskToggle;

  const _TimelineEntry({
    required this.day,
    required this.badge,
    required this.dotColor,
    required this.title,
    required this.tasks,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
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
                      day,
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
                title: title,
                tasks: tasks,
                onTaskToggle: onTaskToggle,
              ),
            ],
          ),
        ),
      ],
    );
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
  final List<_TimelineTask> tasks;
  final ValueChanged<String> onTaskToggle;

  const _TimelineCard({
    required this.title,
    required this.tasks,
    required this.onTaskToggle,
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
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _TaskRow(
                task: task,
                onTap: () => onTaskToggle(task.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTask {
  final String label;
  final bool isDone;
  final bool isWarm;

  const _TimelineTask(this.label, this.isDone, {this.isWarm = false});
}

class _TaskRow extends StatelessWidget {
  final _TimelineTask task;
  final VoidCallback onTap;

  const _TaskRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = task.isWarm
        ? _TimelineColors.pink
        : _TimelineColors.blue;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: task.isDone ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isDone ? activeColor : _TimelineColors.muted,
                width: 2,
              ),
            ),
            child: task.isDone
                ? const Icon(
                    Icons.check,
                    color: _TimelineColors.background,
                    size: 13,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.label,
              style: const TextStyle(
                color: _TimelineColors.title,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncTimelineButton extends StatelessWidget {
  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SyncTimelineButton({
    required this.count,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _TimelineColors.button,
          foregroundColor: _TimelineColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          isLoading ? 'Adding...' : 'Add $count selected to Todos',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
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
  static const Color button = Color(0xFF4A91F8);
  static const Color buttonText = Color(0xFF061326);
}
