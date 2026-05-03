import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trips_repository.dart';
import '../active_trip_controller.dart';

class PackingPage extends ConsumerStatefulWidget {
  const PackingPage({super.key});

  @override
  ConsumerState<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends ConsumerState<PackingPage> {
  final Set<String> _selectedItems = {'Passport', 'Flight Tickets'};
  bool _isAdding = false;

  static const _mustHave = [
    _PackingItemData('Passport', Icons.badge_outlined),
    _PackingItemData('Flight Tickets', Icons.confirmation_number_outlined),
    _PackingItemData('Power Adapter', Icons.power_outlined),
  ];

  static const _recommended = [
    _PackingItemData('Sunglasses', Icons.dark_mode_outlined),
    _PackingItemData('Sunscreen', Icons.wb_sunny_outlined),
  ];

  static const _optional = [
    _PackingItemData('Swimwear', Icons.pool_outlined, subtitle: 'RESORT DAY'),
    _PackingItemData(
      'Reading Book',
      Icons.menu_book_outlined,
      subtitle: 'TRANSIT LEISURE',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PackingColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 180),
                sliver: SliverList.list(
                  children: [
                    const _WeatherChip(),
                    const SizedBox(height: 33),
                    const _SectionHeader(title: 'Must-have', tag: 'CRUCIAL'),
                    const SizedBox(height: 17),
                    ..._mustHave.map(_packingTile),
                    const SizedBox(height: 21),
                    const _SectionHeader(title: 'Recommended', isAccent: true),
                    const SizedBox(height: 18),
                    const _RecommendationCard(),
                    const SizedBox(height: 15),
                    ..._recommended.map(_packingTile),
                    const SizedBox(height: 21),
                    const _SectionHeader(title: 'Optional', isAccent: true),
                    const SizedBox(height: 18),
                    ..._optional.map(_optionalTile),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _AddTripTodosButton(
              count: _selectedItems.length,
              isLoading: _isAdding,
              onPressed: _selectedItems.isEmpty || _isAdding
                  ? null
                  : _addSelectedToTodos,
            ),
          ),
        ],
      ),
    );
  }

  Widget _packingTile(_PackingItemData item) {
    final selected = _selectedItems.contains(item.title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _PackingCheckTile(
        title: item.title,
        icon: item.icon,
        isChecked: selected,
        isMuted: selected,
        onTap: () => _toggleItem(item.title),
      ),
    );
  }

  Widget _optionalTile(_PackingItemData item) {
    final selected = _selectedItems.contains(item.title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _OptionalPackingItem(
        title: item.title,
        subtitle: item.subtitle ?? 'OPTIONAL',
        icon: item.icon,
        isChecked: selected,
        onTap: () => _toggleItem(item.title),
      ),
    );
  }

  void _toggleItem(String title) {
    setState(() {
      if (!_selectedItems.remove(title)) {
        _selectedItems.add(title);
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
          titles: _selectedItems.toList(),
          category: 'packing',
          priority: 'recommended',
        );
    if (!mounted) return;
    setState(() => _isAdding = false);
    result.when(
      success: (count) => _showMessage('$count packing items added to todos.'),
      failure: _showMessage,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PackingItemData {
  final String title;
  final IconData icon;
  final String? subtitle;

  const _PackingItemData(this.title, this.icon, {this.subtitle});
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: _PackingColors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              color: _PackingColors.title,
              size: 13,
            ),
            SizedBox(width: 10),
            Text(
              '7 DAYS IN DUBAI • SUNNY • 32°C',
              style: TextStyle(
                color: _PackingColors.title,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isAccent ? _PackingColors.salmon : _PackingColors.title,
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
              color: _PackingColors.card,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag!,
              style: const TextStyle(
                color: _PackingColors.title,
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
  final IconData icon;
  final bool isChecked;
  final bool isMuted;
  final VoidCallback? onTap;

  const _PackingCheckTile({
    required this.title,
    required this.icon,
    this.isChecked = false,
    this.isMuted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: isChecked ? _PackingColors.card : _PackingColors.selectedCard,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _PackingColors.border),
        ),
        child: Row(
          children: [
            _CheckDot(isChecked: isChecked),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isMuted ? _PackingColors.muted : _PackingColors.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: isMuted ? TextDecoration.lineThrough : null,
                  decorationColor: _PackingColors.muted,
                ),
              ),
            ),
            Icon(
              icon,
              color: isMuted ? _PackingColors.muted : _PackingColors.title,
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
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: isChecked ? _PackingColors.blue : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChecked ? _PackingColors.blue : _PackingColors.muted,
          width: 2,
        ),
      ),
      child: isChecked
          ? const Icon(Icons.check, color: _PackingColors.background, size: 13)
          : null,
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 14),
      decoration: BoxDecoration(
        color: _PackingColors.card,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _CheckDot(isChecked: false),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Light Linen Shirt',
                  style: TextStyle(
                    color: _PackingColors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Perfect for Dubai's\nevening breeze and\nhumidity.",
                  style: TextStyle(
                    color: _PackingColors.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 80,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6F8FA0), Color(0xFF1A2434)],
              ),
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              color: _PackingColors.title,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionalPackingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isChecked;
  final VoidCallback? onTap;

  const _OptionalPackingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isChecked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: BoxDecoration(
                color: _PackingColors.optionalCard,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _PackingColors.border),
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
                          style: const TextStyle(
                            color: _PackingColors.title,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _PackingColors.salmon,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: _PackingColors.salmon, size: 21),
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
  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AddTripTodosButton({
    required this.count,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _PackingColors.salmon,
          foregroundColor: _PackingColors.buttonText,
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
          isLoading ? 'Adding...' : 'Add $count selected to Trip Todos',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PackingColors {
  _PackingColors._();

  static const Color background = Color(0xFF061326);
  static const Color chip = Color(0xFF24344E);
  static const Color card = Color(0xFF101F36);
  static const Color selectedCard = Color(0xFF1B2B44);
  static const Color optionalCard = Color(0xFF07172C);
  static const Color border = Color(0xFF243A56);
  static const Color title = Color(0xFFD5E4FF);
  static const Color body = Color(0xFFC7D2E5);
  static const Color muted = Color(0xFF73819B);
  static const Color blue = Color(0xFF4A91F8);
  static const Color salmon = Color(0xFFFFACA6);
  static const Color buttonText = Color(0xFF4E1017);
}
