import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';

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
    final trip = ref.read(activeTripProvider);
    if (trip == null || trip.reservationId == 0) {
      setState(() {
        _isLoading = false;
        _error = 'Open a trip first to view its todos.';
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
          _error = error;
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

  Future<void> _addTodo() async {
    final title = await _showTodoTitleSheet(title: 'Add Todo');
    if (title == null || title.trim().isEmpty) return;
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final result = await ref
        .read(tripsRepositoryProvider)
        .createTodo(reservationId: trip.reservationId, title: title.trim());
    if (!mounted) return;
    result.when(
      success: (item) => setState(() => _todos.add(_TripTodo.fromJson(item))),
      failure: _showError,
    );
  }

  Future<void> _addTypedTodo() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty || _isAddingQuickTodo) return;
    final trip = ref.read(activeTripProvider);
    if (trip == null) {
      _showError('Open a trip first.');
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
        _showError('Todo added.');
      },
      failure: _showError,
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
        _showError(error);
      },
    );
  }

  Future<void> _editTodo(_TripTodo todo) async {
    final title = await _showTodoTitleSheet(
      title: 'Edit Todo',
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
      failure: _showError,
    );
  }

  Future<void> _deleteTodo(_TripTodo todo) async {
    final trip = ref.read(activeTripProvider);
    if (trip == null) return;
    final previous = List<_TripTodo>.from(_todos);
    setState(() => _todos.removeWhere((entry) => entry.id == todo.id));
    final result = await ref
        .read(tripsRepositoryProvider)
        .deleteTodo(reservationId: trip.reservationId, todoId: todo.id);
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (error) {
        setState(() {
          _todos
            ..clear()
            ..addAll(previous);
        });
        _showError(error);
      },
    );
  }

  Future<String?> _showTodoTitleSheet({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _TripTodosColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _TripTodosColors.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: _TripTodosColors.title),
                decoration: const InputDecoration(hintText: 'Todo title'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final visibleTodos = _visibleTodos;

    return Scaffold(
      backgroundColor: _TripTodosColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 180),
                sliver: SliverList.list(
                  children: [
                    _FilterChips(
                      selectedFilter: _selectedFilter,
                      onSelected: (filter) =>
                          setState(() => _selectedFilter = filter),
                    ),
                    const SizedBox(height: 18),
                    _QuickAddTodo(
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
                          child: _TodoCard(
                            todo: todo,
                            onTap: () => _toggleTodo(todo.id),
                            onEdit: () => _editTodo(todo),
                            onDelete: () => _deleteTodo(todo),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 96,
            child: _AddTodoButton(onPressed: _addTodo),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _TodoFilter selectedFilter;
  final ValueChanged<_TodoFilter> onSelected;

  const _FilterChips({required this.selectedFilter, required this.onSelected});

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
                  label: filter.label,
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
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: isSelected ? 52 : 90),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _TripTodosColors.activeChip
              : _TripTodosColors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? _TripTodosColors.activeChipText
                  : _TripTodosColors.title,
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
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAdd;

  const _QuickAddTodo({
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: _TripTodosColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: _TripTodosColors.title),
              decoration: const InputDecoration(
                hintText: 'Write a new todo...',
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
                  : const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final _TripTodo todo;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 67),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _TripTodosColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _TodoCheckBox(isDone: todo.isDone),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: const TextStyle(
                      color: _TripTodosColors.title,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    todo.category.label,
                    style: TextStyle(
                      color: todo.category.accent,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: _TripTodosColors.card,
              icon: const Icon(
                Icons.more_vert,
                color: _TripTodosColors.title,
                size: 19,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isDone ? _TripTodosColors.activeChip : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: isDone
          ? const Icon(
              Icons.check,
              color: _TripTodosColors.background,
              size: 16,
            )
          : null,
    );
  }
}

class _EmptyTodosMessage extends StatelessWidget {
  final String message;

  const _EmptyTodosMessage({this.message = 'No todos in this category yet.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _TripTodosColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _TripTodosColors.title,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddTodoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddTodoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _TripTodosColors.salmon,
          foregroundColor: _TripTodosColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add, size: 21),
        label: const Text(
          'Add Todo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TripTodo {
  static int _nextId = 0;

  final int id;
  final String title;
  final _TodoCategory category;
  final bool isDone;

  _TripTodo({
    required this.title,
    required this.category,
    this.isDone = false,
    int? id,
  }) : id = id ?? _nextId++;

  factory _TripTodo.fromJson(Map<String, dynamic> json) {
    final category = _TodoCategory.fromName(json['category'] as String?);
    return _TripTodo(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Trip task',
      category: category,
      isDone: json['is_completed'] == true,
    );
  }

  const _TripTodo._({
    required this.id,
    required this.title,
    required this.category,
    required this.isDone,
  });

  _TripTodo copyWith({bool? isDone}) {
    return _TripTodo._(
      id: id,
      title: title,
      category: category,
      isDone: isDone ?? this.isDone,
    );
  }
}

enum _TodoFilter {
  all('All'),
  packing('Packing'),
  documents('Documents');

  final String label;

  const _TodoFilter(this.label);
}

enum _TodoCategory {
  documents('DOCUMENTS', _TripTodosColors.documents),
  packing('PACKING', _TripTodosColors.salmon),
  logistics('LOGISTICS', _TripTodosColors.logistics);

  final String label;
  final Color accent;

  const _TodoCategory(this.label, this.accent);

  static _TodoCategory fromName(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.contains('document')) return documents;
    if (normalized.contains('packing')) return packing;
    return logistics;
  }
}

class _TripTodosColors {
  _TripTodosColors._();

  static const Color background = Color(0xFF061326);
  static const Color card = Color(0xFF101F36);
  static const Color chip = Color(0xFF27364F);
  static const Color activeChip = Color(0xFFDCE6FF);
  static const Color activeChipText = Color(0xFF061326);
  static const Color title = Color(0xFFD5E4FF);
  static const Color documents = Color(0xFF8FA9DB);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color logistics = Color(0xFFFFA982);
  static const Color buttonText = Color(0xFF4E1017);
}
