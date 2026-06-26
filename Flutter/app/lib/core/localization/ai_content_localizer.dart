import '../../l10n/app_localizations.dart';

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[/\\_\-–—]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String? _mapByNormalizedTitle(String title, AppLocalizations l10n) {
  final normalized = _normalize(title);
  return switch (normalized) {
    'research health requirements' => l10n.todoResearchHealthRequirements,
    'health check and vaccinations' ||
    'health checks and vaccinations' ||
    'الفحص الصحي والتطعيمات' ||
    'البحث عن متطلبات الصحة' =>
      l10n.todoHealthVaccinations,
    'create packing list' => l10n.todoCreatePackingList,
    'قم بعمل قائمة التعبئة' => l10n.todoCreatePackingList,
    'check passport validity' ||
    'التحقق من صلاحية جواز السفر' =>
      l10n.timelineTaskPassport,
    'check visa and travel documents' ||
    'check visa travel documents' ||
    'visa and travel documents' ||
    'فحص التأشيرة ووثائق السفر' =>
      l10n.todoVisaTravelDocuments,
    'apply for entry visa' || 'تقديم طلب تأشيرة الدخول' =>
      l10n.timelineTaskVisa,
    'schedule home security' || 'جدولة أمان المنزل' =>
      l10n.timelineTaskSecurity,
    'arrange pet boarding' || 'ترتيب إيواء الحيوانات الأليفة' =>
      l10n.timelineTaskPet,
    'complete all packing list' ||
    'إكمال قائمة التعبئة' ||
    'بدء تجهيز الأساسيات' =>
      l10n.timelineTaskPacking,
    'book airport taxi' || 'حجز أجرة المطار' => l10n.timelineTaskTaxi,
    'start packing essentials' => l10n.timelineTaskPacking,
    'charge devices' || 'شحن الأجهزة' => l10n.todoChargeDevices,
    'head to airport' || 'التوجه إلى المطار' => l10n.todoHeadToAirport,
    'review departure plan' || 'مراجعة خطة المغادرة' =>
      l10n.todoReviewDeparturePlan,
    'confirm booking details' || 'تأكيد بيانات الحجز' =>
      l10n.todoConfirmBookingDetails,
    'book flight tickets' ||
    'book flight ticket' ||
    'book tickets' ||
    'احجز تذاكر الطيران' ||
    'احجز تذكرة الطيران' =>
      l10n.todoConfirmFlightTickets,
    'arrange transportation' ||
    'arrange transport' ||
    'confirm transportation arrangements' ||
    'confirm transport arrangements' ||
    'ترتيب وسائل النقل' ||
    'تأكيد ترتيبات النقل' =>
      l10n.todoConfirmTransportArrangements,
    'charge electronic devices' ||
    'charge electronics' ||
    'قم بشحن الأجهزة الإلكترونية' ||
    'شحن الأجهزة الإلكترونية' =>
      l10n.todoChargeDevices,
    'passport / id' || 'passport/id' => l10n.packingItemPassport,
    'phone charger & adapter' => l10n.packingItemPowerAdapter,
    'medications' => l10n.packingItemMedications,
    'comfortable walking shoes' => l10n.packingItemWalkingShoes,
    'reusable water bottle' => l10n.packingItemWaterBottle,
    'travel pillow' => l10n.packingItemTravelPillow,
    'flight tickets' => l10n.packingItemFlightTickets,
    'power adapter' => l10n.packingItemPowerAdapter,
    'sunglasses' => l10n.packingItemSunglasses,
    'sunscreen' => l10n.packingItemSunscreen,
    'swimwear' => l10n.packingItemSwimwear,
    'reading book' => l10n.packingItemReadingBook,
    'light linen shirt' => l10n.packingItemLinenShirt,
    _ => null,
  };
}

/// Localizes known AI-generated todo/packing/timeline titles for display.
String? localizeKnownAiContentTitleOrNull(
  String title,
  AppLocalizations l10n,
) {
  if (title.trim().isEmpty) return null;
  return _mapByNormalizedTitle(title, l10n);
}

/// Localizes known AI-generated todo/packing/timeline titles for display.
String localizeAiContentTitle(String title, AppLocalizations l10n) {
  if (title.trim().isEmpty) return title;
  return localizeKnownAiContentTitleOrNull(title, l10n) ?? title;
}
