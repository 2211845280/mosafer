import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/debug/screenshot_fixtures.dart';
import '../../../../core/debug/screenshot_mode.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../../../core/localization/locale_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../../domain/ai_travel.dart';
import '../active_trip_controller.dart';
import 'packing_todo_sync.dart';
import '../../../../core/theme/app_theme_extension.dart';

class PackingPage extends ConsumerStatefulWidget {
  const PackingPage({super.key});

  @override
  ConsumerState<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends ConsumerState<PackingPage> {
  final Set<String> _selectedKeys = {};
  bool _isAdding = false;
  bool _isLoading = false;
  String? _loadError;
  PackingListResult? _packingList;
  int? _loadedReservationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPackingList());
  }

  Future<void> _loadPackingList({bool force = false}) async {
    final trip = ref.read(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    if (trip == null || trip.reservationId == 0) {
      setState(() {
        _packingList = null;
        _loadError = null;
        _isLoading = false;
        _loadedReservationId = null;
        _selectedKeys.clear();
      });
      return;
    }
    if (!force &&
        _loadedReservationId == trip.reservationId &&
        _packingList != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    if (kScreenshotMode) {
      await ref
          .read(packingTodoSyncProvider.notifier)
          .refreshFromServer(trip.reservationId);
      if (!mounted) return;
      setState(() {
        _packingList = kScreenshotPackingList;
        _loadedReservationId = trip.reservationId;
        _isLoading = false;
        _loadError = null;
        _selectedKeys
          ..clear()
          ..addAll(['must:0', 'must:1']);
      });
      return;
    }

    await ref
        .read(packingTodoSyncProvider.notifier)
        .refreshFromServer(trip.reservationId);

    final result = await ref
        .read(tripsRepositoryProvider)
        .fetchPackingList(trip.reservationId);

    if (!mounted) return;

    result.when(
      success: (packing) {
        setState(() {
          _packingList = packing;
          _loadedReservationId = trip.reservationId;
          _isLoading = false;
          _loadError = null;
          _selectedKeys.clear();
        });
        _selectDefaultMustHave();
      },
      failure: (error) {
        setState(() {
          _packingList = null;
          _loadedReservationId = trip.reservationId;
          _isLoading = false;
          _loadError = localizeUserFacingError(error, l10n);
          _selectedKeys.clear();
        });
      },
    );
  }

  String _itemKey(String section, int index) => '$section:$index';

  String _packingKey(PackingItem item, String fallbackKey) {
    return normalizePackingTodoKey(item.stableKey(fallbackKey));
  }

  bool _isInTodos(
    PackingItem item,
    Set<String> inTodoKeys,
    String fallbackKey,
  ) {
    final aliases = [
      _packingKey(item, fallbackKey),
      normalizePackingTodoTitle(item.title),
      normalizePackingTodoTitle(item.titleAr),
      normalizePackingTodoTitle(item.titleEn),
    ].where((key) => key.isNotEmpty);
    return aliases.any(inTodoKeys.contains);
  }

  void _selectDefaultMustHave() {
    final trip = ref.read(activeTripProvider);
    final packing = _packingList;
    if (trip == null || packing == null) return;

    final inTodoTitles =
        ref.read(packingTodoTitlesForProvider(trip.reservationId));
    final mustHaveKeys = <String>{};
    for (var i = 0; i < packing.mustHave.length; i++) {
      final key = _itemKey('must', i);
      if (!_isInTodos(packing.mustHave[i], inTodoTitles, key)) {
        mustHaveKeys.add(key);
      }
    }

    setState(() => _selectedKeys.addAll(mustHaveKeys));
  }

  void _selectReturnedMustHave(Set<String> previousInTodos, Set<String> nextInTodos) {
    final returnedTitles = previousInTodos.difference(nextInTodos);
    if (returnedTitles.isEmpty) return;

    final packing = _packingList;
    if (packing == null) return;

    final keysToSelect = <String>{};
    for (var i = 0; i < packing.mustHave.length; i++) {
      final key = _itemKey('must', i);
      final normalized = _packingKey(packing.mustHave[i], key);
      if (returnedTitles.contains(normalized)) {
        keysToSelect.add(key);
      }
    }

    if (keysToSelect.isEmpty) return;
    setState(() => _selectedKeys.addAll(keysToSelect));
  }

  void _pruneSelectedKeys() {
    final trip = ref.read(activeTripProvider);
    final packing = _packingList;
    if (trip == null || packing == null) return;

    final inTodoTitles = ref.read(packingTodoTitlesForProvider(trip.reservationId));
    final visibleKeys = <String>{};
    for (var i = 0; i < packing.mustHave.length; i++) {
      final key = _itemKey('must', i);
      if (!_isInTodos(packing.mustHave[i], inTodoTitles, key)) {
        visibleKeys.add(key);
      }
    }
    for (var i = 0; i < packing.recommended.length; i++) {
      final key = _itemKey('rec', i);
      if (!_isInTodos(packing.recommended[i], inTodoTitles, key)) {
        visibleKeys.add(key);
      }
    }
    for (var i = 0; i < packing.optional.length; i++) {
      final key = _itemKey('opt', i);
      if (!_isInTodos(packing.optional[i], inTodoTitles, key)) {
        visibleKeys.add(key);
      }
    }

    final pruned = _selectedKeys.where(visibleKeys.contains).toSet();
    if (pruned.length != _selectedKeys.length) {
      setState(() => _selectedKeys
        ..clear()
        ..addAll(pruned));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(activeTripProvider);

    ref.listen(activeTripProvider, (previous, next) {
      if (previous?.reservationId != next?.reservationId) {
        _loadPackingList(force: true);
      }
    });

    ref.listen(appLocaleProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        setState(() {});
      }
    });

    if (trip != null && trip.reservationId != 0) {
      ref.listen(packingTodoTitlesForProvider(trip.reservationId), (previous, next) {
        if (previous != next) {
          _pruneSelectedKeys();
          if (previous != null) {
            _selectReturnedMustHave(previous, next);
          }
          setState(() {});
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: colors.primary,
            onRefresh: () => _loadPackingList(force: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 180),
                  sliver: SliverList.list(
                    children: [
                      if (_packingList?.weather != null)
                        _WeatherChip(
                          weather: _packingList!.weather!,
                          l10n: l10n,
                        ),
                      const SizedBox(height: 33),
                      ..._buildBody(l10n, trip),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _AddTripTodosButton(
              l10n: l10n,
              count: _selectedKeys.length,
              isLoading: _isAdding,
              onPressed: _selectedKeys.isEmpty || _isAdding || _isLoading
                  ? null
                  : _addSelectedToTodos,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n, dynamic trip) {
    final colors = context.colors;
    if (trip == null || trip.reservationId == 0) {
      return [
        _MessagePanel(message: l10n.packingOpenTripFirst),
      ];
    }
    if (_isLoading && _packingList == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.packingLoading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.body,
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
          actionLabel: l10n.packingRetry,
          onAction: () => _loadPackingList(force: true),
        ),
      ];
    }

    final packing = _packingList;
    if (packing == null || packing.isEmpty) {
      return [
        _MessagePanel(
          message: l10n.packingLoadFailed,
          actionLabel: l10n.packingRetry,
          onAction: () => _loadPackingList(force: true),
        ),
      ];
    }

    final inTodoTitles = ref.watch(packingTodoTitlesForProvider(trip.reservationId));

    final mustHaveTiles = _sectionTiles(
      items: packing.mustHave,
      section: 'must',
      icon: Icons.luggage_outlined,
      inTodoTitles: inTodoTitles,
    );
    final recommendedTiles = _sectionTiles(
      items: packing.recommended,
      section: 'rec',
      icon: Icons.checkroom_outlined,
      inTodoTitles: inTodoTitles,
    );
    final optionalTiles = _optionalSectionTiles(
      items: packing.optional,
      inTodoTitles: inTodoTitles,
    );

    if (mustHaveTiles.isEmpty &&
        recommendedTiles.isEmpty &&
        optionalTiles.isEmpty) {
      return [
        _MessagePanel(message: l10n.packingAllItemsInTodos),
      ];
    }

    final widgets = <Widget>[];
    if (mustHaveTiles.isNotEmpty) {
      widgets.addAll([
        _SectionHeader(
          title: l10n.packingMustHave,
          tag: l10n.packingTagCrucial,
        ),
        const SizedBox(height: 17),
        ...mustHaveTiles,
      ]);
    }
    if (recommendedTiles.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 21));
      widgets.addAll([
        _SectionHeader(title: l10n.packingRecommended, isAccent: true),
        const SizedBox(height: 18),
        ...recommendedTiles,
      ]);
    }
    if (optionalTiles.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 21));
      widgets.addAll([
        _SectionHeader(title: l10n.packingOptional, isAccent: true),
        const SizedBox(height: 18),
        ...optionalTiles,
      ]);
    }
    return widgets;
  }

  List<Widget> _sectionTiles({
    required List<PackingItem> items,
    required String section,
    required IconData icon,
    required Set<String> inTodoTitles,
  }) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final key = _itemKey(section, i);
      if (_isInTodos(items[i], inTodoTitles, key)) continue;
      widgets.add(
        _packingTile(
          key: key,
          item: items[i],
          icon: icon,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _optionalSectionTiles({
    required List<PackingItem> items,
    required Set<String> inTodoTitles,
  }) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final key = _itemKey('opt', i);
      if (_isInTodos(items[i], inTodoTitles, key)) continue;
      widgets.add(
        _optionalTile(
          key: key,
          item: items[i],
        ),
      );
    }
    return widgets;
  }

  Widget _packingTile({
    required String key,
    required PackingItem item,
    required IconData icon,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedKeys.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _PackingCheckTile(
        title: item.titleFor(l10n),
        subtitle: item.noteFor(l10n).trim().isEmpty ? null : item.noteFor(l10n),
        icon: icon,
        isChecked: selected,
        onTap: () => _toggleItem(key),
      ),
    );
  }

  Widget _optionalTile({required String key, required PackingItem item}) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedKeys.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _OptionalPackingItem(
        title: item.titleFor(l10n),
        subtitle: item.noteFor(l10n).trim().isEmpty ? null : item.noteFor(l10n),
        icon: Icons.star_outline,
        isChecked: selected,
        onTap: () => _toggleItem(key),
      ),
    );
  }

  void _toggleItem(String key) {
    setState(() {
      if (!_selectedKeys.remove(key)) {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _addSelectedToTodos() async {
    final trip = ref.read(activeTripProvider);
    final l10n = AppLocalizations.of(context)!;
    final packing = _packingList;
    if (trip == null || trip.reservationId == 0 || packing == null) {
      _showMessage(l10n.packingOpenTripFirst);
      return;
    }

    final inTodoKeys = ref.read(packingTodoTitlesForProvider(trip.reservationId));
    final drafts = _selectedKeys
        .map((key) => _todoDraftForKey(key, l10n))
        .whereType<TripTodoDraft>()
        .where(
          (draft) =>
              draft.sourceKey != null &&
              !inTodoKeys.contains(normalizePackingTodoKey(draft.sourceKey!)),
        )
        .toList(growable: false);
    if (drafts.isEmpty) return;

    setState(() => _isAdding = true);
    final result = await ref
        .read(tripsRepositoryProvider)
        .createTodos(
          reservationId: trip.reservationId,
          todos: drafts,
          category: 'packing',
          priority: 'recommended',
        );
    if (!mounted) return;
    setState(() => _isAdding = false);
    result.when(
      success: (count) {
        final addedKeys = drafts
            .map((draft) => draft.sourceKey ?? draft.title)
            .map(normalizePackingTodoKey)
            .toSet();
        ref.read(packingTodoSyncProvider.notifier).markAdded(
              trip.reservationId,
              drafts.map((draft) => draft.sourceKey ?? draft.title),
            );
        setState(() {
          for (final key in List<String>.from(_selectedKeys)) {
            final draft = _todoDraftForKey(key, l10n);
            final draftKey = draft?.sourceKey ?? draft?.title;
            if (draftKey != null &&
                addedKeys.contains(normalizePackingTodoKey(draftKey))) {
              _selectedKeys.remove(key);
            }
          }
        });
        _showMessage(l10n.packingItemsAddedToTodos(count));
      },
      failure: (error) => _showMessage(localizeUserFacingError(error, l10n)),
    );
  }

  PackingItem? _itemForKey(String key) {
    final packing = _packingList;
    if (packing == null) return null;

    final parts = key.split(':');
    if (parts.length != 2) return null;
    final section = parts[0];
    final index = int.tryParse(parts[1]);
    if (index == null) return null;

    final items = switch (section) {
      'must' => packing.mustHave,
      'rec' => packing.recommended,
      'opt' => packing.optional,
      _ => null,
    };
    if (items == null) return null;
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  TripTodoDraft? _todoDraftForKey(String key, AppLocalizations l10n) {
    final item = _itemForKey(key);
    if (item == null) return null;
    final sourceKey = item.stableKey(key);
    return TripTodoDraft(
      title: item.titleFor(l10n),
      sourceKey: sourceKey,
      titleAr: item.titleAr.trim().isEmpty ? item.title : item.titleAr,
      titleEn: item.titleEn.trim().isEmpty ? item.title : item.titleEn,
    );
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
              color: colors.body,
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

class _WeatherChip extends StatelessWidget {
  final PackingWeatherContext weather;
  final AppLocalizations l10n;

  const _WeatherChip({required this.weather, required this.l10n});

  String _conditionLabel() {
    return switch (weather.condition) {
      PackingWeatherCondition.clear => l10n.weatherClear,
      PackingWeatherCondition.cloudy => l10n.weatherCloudy,
      PackingWeatherCondition.rain => l10n.weatherRain,
      PackingWeatherCondition.snow => l10n.weatherSnow,
      PackingWeatherCondition.storm => l10n.weatherStorm,
    };
  }

  IconData _conditionIcon() {
    return switch (weather.condition) {
      PackingWeatherCondition.clear => Icons.wb_sunny_outlined,
      PackingWeatherCondition.cloudy => Icons.cloud_outlined,
      PackingWeatherCondition.rain => Icons.water_drop_outlined,
      PackingWeatherCondition.snow => Icons.ac_unit,
      PackingWeatherCondition.storm => Icons.thunderstorm_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final temp = weather.temperatureC.round();
    final summary = l10n.packingWeatherSummary(
      weather.tripDurationDays,
      weather.destinationCity.toUpperCase(),
      _conditionLabel().toUpperCase(),
      temp,
    );

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: colors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _conditionIcon(),
              color: colors.title,
              size: 13,
            ),
            const SizedBox(width: 10),
            Text(
              summary,
              style: TextStyle(
                color: colors.title,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? tag;
  final bool isAccent;

  const _SectionHeader({required this.title, this.tag, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isAccent ? colors.salmon : colors.title,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag!,
              style: TextStyle(
                color: colors.title,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _PackingCheckTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isChecked;
  final VoidCallback? onTap;

  const _PackingCheckTile({
    required this.title,
    required this.icon,
    this.subtitle,
    this.isChecked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: isChecked ? colors.card : colors.selectedCard,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            _CheckDot(isChecked: isChecked),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              icon,
              color: colors.title,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  final bool isChecked;

  const _CheckDot({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: isChecked ? colors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChecked ? colors.primary : colors.muted,
          width: 2,
        ),
      ),
      child: isChecked
          ? Icon(Icons.check, color: colors.background, size: 13)
          : null,
    );
  }
}

class _OptionalPackingItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isChecked;
  final VoidCallback? onTap;

  const _OptionalPackingItem({
    required this.title,
    required this.icon,
    this.subtitle,
    this.isChecked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _CheckDot(isChecked: isChecked),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                color: colors.optionalCard,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.title,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: colors.salmon,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(icon, color: colors.salmon, size: 21),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTripTodosButton extends StatelessWidget {
  final AppLocalizations l10n;
  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AddTripTodosButton({
    required this.l10n,
    required this.count,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.salmon,
          foregroundColor: colors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_task, size: 20),
        label: Text(
          isLoading ? l10n.addingEllipsis : l10n.addSelectedToTripTodos(count),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
