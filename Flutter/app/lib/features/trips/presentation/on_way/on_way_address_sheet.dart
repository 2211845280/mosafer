import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/home_address_controller.dart';
import '../../../../l10n/app_localizations.dart';
import 'on_way_theme.dart';

Future<void> showOnWayAddressSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: OnWayColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _OnWayAddressSheet(onSaved: onSaved),
  );
}

class _OnWayAddressSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSaved;

  const _OnWayAddressSheet({this.onSaved});

  @override
  ConsumerState<_OnWayAddressSheet> createState() => _OnWayAddressSheetState();
}

class _OnWayAddressSheetState extends ConsumerState<_OnWayAddressSheet> {
  late final TextEditingController _addressController;
  bool _useManual = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final home = ref.read(homeAddressControllerProvider);
    _addressController = TextEditingController(text: home.address ?? '');
    _useManual = home.useManualOrigin;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.length < 3) {
      setState(() => _error = l10n.homeAddressTooShort);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final geocoded = await ref.read(geocodingServiceProvider).geocode(address);
      final syncError = await ref
          .read(homeAddressControllerProvider.notifier)
          .setManualAddress(
            address: address,
            lat: geocoded.lat,
            lng: geocoded.lng,
            formattedAddress: geocoded.formattedAddress,
          );
      if (!mounted) return;
      if (syncError != null) {
        setState(() => _error = syncError);
        return;
      }
      widget.onSaved?.call();
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.homeAddressGeocodeFailed);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _applyOriginMode(bool useManual) async {
    setState(() => _useManual = useManual);
    final notifier = ref.read(homeAddressControllerProvider.notifier);
    if (useManual) {
      await notifier.setUseManualOrigin(true);
    } else {
      await notifier.setUseGpsOrigin();
    }
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final home = ref.watch(homeAddressControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: OnWayColors.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onWayDepartureAddressTitle,
            style: const TextStyle(
              color: OnWayColors.title,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onWayDepartureAddressSubtitle,
            style: const TextStyle(
              color: OnWayColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _OriginModeTile(
            icon: Icons.my_location,
            title: l10n.onWayUseCurrentLocation,
            subtitle: l10n.onWayUseCurrentLocationHint,
            selected: !_useManual,
            onTap: () => _applyOriginMode(false),
          ),
          const SizedBox(height: 10),
          _OriginModeTile(
            icon: Icons.home_outlined,
            title: l10n.onWayUseSavedAddress,
            subtitle: home.hasCoordinates
                ? (home.address ?? l10n.onWaySavedAddressReady)
                : l10n.onWaySavedAddressMissing,
            selected: _useManual,
            onTap: home.hasCoordinates ? () => _applyOriginMode(true) : null,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _addressController,
            maxLines: 2,
            style: const TextStyle(color: OnWayColors.title),
            decoration: InputDecoration(
              labelText: l10n.homeLocationLabel,
              hintText: l10n.homeAddressHint,
              labelStyle: const TextStyle(color: OnWayColors.muted),
              hintStyle: TextStyle(
                color: OnWayColors.muted.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: OnWayColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFF8A80),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.homeAddressSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _OriginModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? OnWayColors.background
          : OnWayColors.background.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: OnWayColors.title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: OnWayColors.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: OnWayColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? OnWayColors.title : OnWayColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
