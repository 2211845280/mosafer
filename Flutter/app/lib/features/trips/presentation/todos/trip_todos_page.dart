import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/ai_content_localizer.dart';
import '../../../../core/localization/error_message_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';
import '../packing/packing_todo_sync.dart';
import '../../../../core/theme/app_theme_extension.dart';

class TripTodosPage extends ConsumerStatefulWidget {
  const TripTodosPage({super.key});

  @override
  ConsumerState<TripTodosPage> createState() => _TripTodosPageState();
}

class _TripTodosPageState extends ConsumerState<TripTodosPage> {
  final List<_TripTodo> _todos = [];
  final TextEditingController _quickAddController = TextEditingController();

  _TodoFilter _selectedFilter = _TodoFilter.all;
  bool _isLoading = true;
  String? _error;
  bool _isAddingQuickTodo = false;
  bool _selectionMode = false;
  final Set<int> _selectedTodoIds = {};
  bool _isDeletingBulk = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTodos);
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      setState(() {
        _isLoading = false;
        _error = l10n.todosOpenTripFirstView;
      });
      return;
    }
    final result = await ref
        .read(tripsRepositoryProvider)
        .getTodos(trip.reservationId);
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _isLoading = false;
          _error = null;
          _todos
            ..clear()
            ..addAll(items.map(_TripTodo.fromJson));
        });
      },
      failure: (error) {
        setState(() {
          _isLoading = false;
          _error = localizeUserFacingError(error, l10n);
        });
      },
    );
  }

  List<_TripTodo> get _visibleTodos {
    return _todos.where((todo) {
      return switch (_selectedFilter) {
        _TodoFilter.all => true,
        _TodoFilter.packing => todo.category == _TodoCategory.packing,
        _TodoFilter.documents => todo.category == _TodoCategory.documents,
      };
    }).toList();
  }

  Future<void> _addTypedTodo() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty || _isAddingQuickTodo) return;
    final trip = ref.read(activeTripProvider);
    if (trip == null) {
      _showUserMessage(AppLocalizations.of(context)!.todosOpenTripFirst);
      return;
    }
    setState(() => _isAddingQuickTodo = true);
    final result = await ref
        .read(tripsRepositoryProvider)
        .createTodo(reservationId: trip.reservationId, title: title);
    if (!mounted) return;
    setState(() => _isAddingQuickTodo = false);
    result.when(
      success: (item) {
        _quickAddController.clear();
        setState(() => _todos.add(_TripTodo.fromJson(item)));
        _showUserMessage(AppLocalizations.of(context)!.todoAdded);
      },
      failure: _showErrorFromObject,
    );
  }

  Future<void> _toggleTodo(int id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return;
    }
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final current = _todos[index];
    final nextValue = !current.isDone;

    setState(() {
      _todos[index] = current.copyWith(isDone: nextValue);
    });
    final result = await ref
        .read(tripsRepositoryProvider)
        .updateTodo(
          reservationId: trip.reservationId,
          todoId: id,
          isCompleted: nextValue,
        );
    if (!mounted) return;
    result.when(
      success: (item) =>
          setState(() => _todos[index] = _TripTodo.fromJson(item)),
      failure: (error) {
        setState(() => _todos[index] = current);
        _showErrorFromObject(error);
      },
    );
  }

  Future<void> _editTodo(_TripTodo todo) async {
    final l10n = AppLocalizations.of(context)!;
    final title = await _showTodoTitleSheet(
      title: l10n.todoEditTitle,
      initialValue: todo.title,
    );
    if (title == null || title.trim().isEmpty || title.trim() == todo.title) {
      return;
    }
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final result = await ref
        .read(tripsRepositoryProvider)
        .updateTodo(
          reservationId: trip.reservationId,
          todoId: todo.id,
          title: title.trim(),
        );
    if (!mounted) return;
    result.when(
      success: (item) {
        final index = _todos.indexWhere((entry) => entry.id == todo.id);
        if (index != -1) {
          setState(() => _todos[index] = _TripTodo.fromJson(item));
        }
      },
      failure: _showErrorFromObject,
    );
  }

  List<_TripTodo> get _packingTodos =>
      _todos.where((todo) => todo.category == _TodoCategory.packing).toList();

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedTodoIds.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      if (_selectionMode) {
        _selectionMode = false;
        _selectedTodoIds.clear();
      } else {
        _selectionMode = true;
        _selectedTodoIds.clear();
      }
    });
  }

  void _toggleTodoSelection(int id) {
    setState(() {
      if (!_selectedTodoIds.remove(id)) {
        _selectedTodoIds.add(id);
      }
    });
  }

  Future<void> _deleteTodos(Iterable<_TripTodo> todos) async {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final targets = todos.toList(growable: false);
    if (targets.isEmpty) return;

    final previous = List<_TripTodo>.from(_todos);
    final targetIds = targets.map((todo) => todo.id).toSet();
    setState(() => _todos.removeWhere((entry) => targetIds.contains(entry.id)));

    final result = await ref.read(tripsRepositoryProvider).deleteTodos(
          reservationId: trip.reservationId,
          todoIds: targets.map((todo) => todo.id).toList(growable: false),
        );
    if (!mounted) return;
    result.when(
      success: (count) {
        for (final todo in targets) {
          if (todo.category == _TodoCategory.packing) {
            ref.read(packingTodoSyncProvider.notifier).markRemoved(
                  trip.reservationId,
                  todo.sourceKey ?? todo.title,
                );
          }
        }
        if (_selectionMode) {
          _exitSelectionMode();
        }
        _showUserMessage(AppLocalizations.of(context)!.todosDeletedCount(count));
      },
      failure: (error) {
        setState(() {
          _todos
            ..clear()
            ..addAll(previous);
        });
        _showErrorFromObject(error);
      },
    );
  }

  Future<void> _deleteSelectedTodos() async {
    if (_isDeletingBulk || _selectedTodoIds.isEmpty) return;
    setState(() => _isDeletingBulk = true);
    final selected = _todos
        .where(
          (todo) =>
              _selectedTodoIds.contains(todo.id) &&
              todo.category == _TodoCategory.packing,
        )
        .toList(growable: false);
    await _deleteTodos(selected);
    if (mounted) {
      setState(() => _isDeletingBulk = false);
    }
  }

  Future<void> _deleteTodo(_TripTodo todo) async {
    await _deleteTodos([todo]);
  }

  Future<String?> _showTodoTitleSheet({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final dialogColors = dialogContext.colors;
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return Dialog(
          backgroundColor: dialogColors.card,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: dialogColors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: dialogColors.title),
                  decoration: InputDecoration(
                    hintText: dialogL10n.todoTitleHint,
                    filled: true,
                    fillColor: dialogColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: dialogColors.body,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(dialogL10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(controller.text),
                        child: Text(dialogL10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _showErrorFromObject(Object error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizeUserFacingError(error, l10n))),
    );
  }

  void _showUserMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final visibleTodos = _visibleTodos;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88 + 24;
    final packingTodos = _packingTodos;
    final showPackingActions = packingTodos.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset),
            sliver: SliverList.list(
              children: [
                _FilterChips(
                  l10n: l10n,
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                      if (filter != _TodoFilter.packing && _selectionMode) {
                        _exitSelectionMode();
                      }
                    });
                  },
                ),
                if (showPackingActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!_selectionMode) const Spacer(),
                      TextButton.icon(
                        onPressed: _toggleSelectionMode,
                        icon: Icon(
                          _selectionMode
                              ? Icons.close
                              : Icons.delete_outline,
                          size: 18,
                          color: _selectionMode ? colors.primary : colors.coral,
                        ),
                        label: Text(
                          _selectionMode
                              ? l10n.todosCancelSelection
                              : l10n.todosSelectPacking,
                          style: TextStyle(
                            color:
                                _selectionMode ? colors.primary : colors.coral,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (_selectionMode) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: _selectedTodoIds.isEmpty || _isDeletingBulk
                              ? null
                              : _deleteSelectedTodos,
                          child: _isDeletingBulk
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.coral,
                                  ),
                                )
                              : Text(
                                  l10n.todosDeleteSelected(
                                    _selectedTodoIds.length,
                                  ),
                                  style: TextStyle(
                                    color: colors.coral,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _QuickAddTodo(
                  l10n: l10n,
                  controller: _quickAddController,
                  isLoading: _isAddingQuickTodo,
                  onAdd: _addTypedTodo,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  _EmptyTodosMessage(message: _error!)
                else if (visibleTodos.isEmpty)
                  const _EmptyTodosMessage()
                else
                  ...visibleTodos.map(
                    (todo) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _TodoListTile(
                        l10n: l10n,
                        todo: todo,
                        selectionMode: _selectionMode,
                        isSelected: _selectedTodoIds.contains(todo.id),
                        onTap: () {
                          if (_selectionMode && todo.canBulkSelect) {
                            _toggleTodoSelection(todo.id);
                            return;
                          }
                          _toggleTodo(todo.id);
                        },
                        onEdit: () => _editTodo(todo),
                        onDelete: () => _deleteTodo(todo),
                        onSelectToggle: () => _toggleTodoSelection(todo.id),
                      ),
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

class _FilterChips extends StatelessWidget {
  final AppLocalizations l10n;
  final _TodoFilter selectedFilter;
  final ValueChanged<_TodoFilter> onSelected;

  const _FilterChips({
    required this.l10n,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _TodoFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FilterChipButton(
                  label: filter.label(l10n),
                  isSelected: selectedFilter == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: isSelected ? 52 : 90),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.activeChip
              : colors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? colors.activeChipText
                  : colors.title,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddTodo extends StatefulWidget {
  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAdd;

  const _QuickAddTodo({
    required this.l10n,
    required this.controller,
    required this.isLoading,
    required this.onAdd,
  });

  @override
  State<_QuickAddTodo> createState() => _QuickAddTodoState();
}

class _QuickAddTodoState extends State<_QuickAddTodo> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_syncTextState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTextState);
    super.dispose();
  }

  void _syncTextState() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasText) {
      setState(() => _hasText = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: TextStyle(color: colors.title),
              decoration: InputDecoration(
                hintText: widget.l10n.todoTitleHint,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => widget.onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            height: 38,
            child: ElevatedButton(
              onPressed: !_hasText || widget.isLoading ? null : widget.onAdd,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.l10n.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoListTile extends StatelessWidget {
  final AppLocalizations l10n;
  final _TripTodo todo;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSelectToggle;

  const _TodoListTile({
    required this.l10n,
    required this.todo,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final card = _TodoCard(
      l10n: l10n,
      todo: todo,
      selectionMode: selectionMode,
      isSelected: isSelected,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      onSelectToggle: onSelectToggle,
    );

    if (!todo.canSwipeDelete || selectionMode) {
      return card;
    }

    final colors = context.colors;
    return Dismissible(
      key: ValueKey('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.coral,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_outline, color: colors.coral, size: 22),
        ),
      ),
      child: card,
    );
  }
}

class _TodoCard extends StatelessWidget {
  final AppLocalizations l10n;
  final _TripTodo todo;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSelectToggle;

  const _TodoCard({
    required this.l10n,
    required this.todo,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 67),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (selectionMode && todo.canBulkSelect)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: onSelectToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? colors.primary : colors.muted,
                    size: 22,
                  ),
                ),
              )
            else
              _TodoCheckBox(isDone: todo.isDone),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.displayTitle(l10n),
                    style: TextStyle(
                      color: todo.isDone
                          ? colors.muted
                          : colors.title,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                      decoration:
                          todo.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    todo.category.tabLabel(l10n),
                    style: TextStyle(
                      color: todo.category.accentColor(colors),
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            if (!selectionMode)
              PopupMenuButton<String>(
                color: colors.card,
                icon: Icon(
                  Icons.more_vert,
                  color: colors.title,
                  size: 19,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TodoCheckBox extends StatelessWidget {
  final bool isDone;

  const _TodoCheckBox({required this.isDone});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
    );
  }
}

class _EmptyTodosMessage extends StatelessWidget {
  final String? message;

  const _EmptyTodosMessage({this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final text = message ?? l10n.todosEmptyDefault;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.title,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TripTodo {
  static int _nextId = 0;

  final int id;
  final String title;
  final String? source;
  final String? sourceKey;
  final String? titleAr;
  final String? titleEn;
  final _TodoCategory category;
  final DateTime? dueDate;
  final bool isDone;

  _TripTodo({
    required this.title,
    required this.source,
    required this.sourceKey,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.dueDate,
    this.isDone = false,
    int? id,
  }) : id = id ?? _nextId++;

  factory _TripTodo.fromJson(Map<String, dynamic> json) {
    final category = _TodoCategory.fromName(json['category'] as String?);
    final dueDateRaw = json['due_date'] as String?;
    return _TripTodo(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      source: (json['source'] as String?)?.toLowerCase(),
      sourceKey: json['source_key'] as String?,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      category: category,
      dueDate: dueDateRaw == null ? null : DateTime.tryParse(dueDateRaw),
      isDone: json['is_completed'] == true,
    );
  }

  const _TripTodo._({
    required this.id,
    required this.title,
    required this.source,
    required this.sourceKey,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.dueDate,
    required this.isDone,
  });

  bool get canBulkSelect => category == _TodoCategory.packing;

  bool get canSwipeDelete => category == _TodoCategory.packing;

  bool get shouldLocalizeTitle =>
      source == null ||
      source == 'ai' ||
      category == _TodoCategory.packing ||
      dueDate != null;

  String displayTitle(AppLocalizations l10n) {
    final raw = title.isEmpty ? l10n.tripTaskDefault : title;
    if (category == _TodoCategory.packing) {
      final localized = l10n.localeName.startsWith('ar') ? titleAr : titleEn;
      if (localized != null && localized.trim().isNotEmpty) {
        return localized;
      }
    }
    if (!shouldLocalizeTitle) return raw;
    return localizeKnownAiContentTitleOrNull(raw, l10n) ?? raw;
  }

  _TripTodo copyWith({bool? isDone}) {
    return _TripTodo._(
      id: id,
      title: title,
      source: source,
      sourceKey: sourceKey,
      titleAr: titleAr,
      titleEn: titleEn,
      category: category,
      dueDate: dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}

enum _TodoFilter { all, packing, documents }

extension _TodoFilterX on _TodoFilter {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _TodoFilter.all:
        return l10n.todosCategoryAll;
      case _TodoFilter.packing:
        return l10n.todosCategoryPacking;
      case _TodoFilter.documents:
        return l10n.todosCategoryDocuments;
    }
  }
}

enum _TodoCategory {
  documents,
  packing,
  logistics;

  Color accentColor(AppThemeExtension colors) {
    return switch (this) {
      _TodoCategory.documents => colors.documents,
      _TodoCategory.packing => colors.salmon,
      _TodoCategory.logistics => colors.logistics,
    };
  }

  String tabLabel(AppLocalizations l10n) {
    switch (this) {
      case _TodoCategory.documents:
        return l10n.todosTabDocuments;
      case _TodoCategory.packing:
        return l10n.todosTabPacking;
      case _TodoCategory.logistics:
        return l10n.todosTabLogistics;
    }
  }

  static _TodoCategory fromName(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.contains('document')) return documents;
    if (normalized.contains('packing')) return packing;
    return logistics;
  }
}
