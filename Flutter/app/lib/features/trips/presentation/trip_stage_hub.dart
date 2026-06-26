import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../explore/presentation/explore_page.dart';
import 'airport_experience/airport_experience_page.dart';
import 'on_way/on_way_page.dart';
import 'trip_stage_tabs.dart';
import '../../../core/theme/app_theme_extension.dart';

class TripStageHub extends ConsumerStatefulWidget {
  final int initialPage;

  const TripStageHub({super.key, required this.initialPage});

  @override
  ConsumerState<TripStageHub> createState() => _TripStageHubState();
}

class _TripStageHubState extends ConsumerState<TripStageHub> {
  late final PageController _pageController;
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void didUpdateWidget(TripStageHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.initialPage) {
      _activeIndex = widget.initialPage;
      _pageController.jumpToPage(widget.initialPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _activeIndex) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_activeIndex == index) {
      return;
    }
    setState(() => _activeIndex = index);
    final path = tripStagePathForIndex(index);
    if (GoRouterState.of(context).uri.path != path) {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: TripStageTabs(
              activeIndex: _activeIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                _KeepAliveStagePage(child: DashboardStageContent()),
                _KeepAliveStagePage(child: OnWayPage(embedded: true)),
                _KeepAliveStagePage(child: AirportExperiencePage(embedded: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveStagePage extends StatefulWidget {
  final Widget child;

  const _KeepAliveStagePage({required this.child});

  @override
  State<_KeepAliveStagePage> createState() => _KeepAliveStagePageState();
}

class _KeepAliveStagePageState extends State<_KeepAliveStagePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    super.build(context);
    return widget.child;
  }
}

Page<void> buildTripStageHubPage(GoRouterState state, int initialPage) {
  return CustomTransitionPage<void>(
    key: const ValueKey('trip-stage-hub'),
    child: TripStageHub(initialPage: initialPage),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(
        position: offset,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
