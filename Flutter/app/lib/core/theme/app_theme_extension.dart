import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.background,
    required this.backgroundAlt,
    required this.nav,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSoft,
    required this.card,
    required this.field,
    required this.divider,
    required this.border,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    required this.title,
    required this.body,
    required this.section,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onMuted,
    required this.onPrimary,
    required this.onSecondary,
    required this.error,
    required this.errorLight,
    required this.success,
    required this.warning,
    required this.disabled,
    required this.disabledBackground,
    required this.overlay,
    required this.iconBackground,
    required this.avatarBackground,
    required this.logoutBackground,
    required this.logoutBorder,
    required this.salmon,
    required this.muted,
    required this.hint,
    required this.ice,
    required this.coral,
    required this.chip,
    required this.selectedCard,
    required this.optionalCard,
    required this.attachment,
    required this.attachmentBorder,
    required this.dashedBorder,
    required this.buttonText,
    required this.pdfBackground,
    required this.pdf,
    required this.tabBackground,
    required this.frame,
    required this.buttonShell,
    required this.activeChip,
    required this.activeChipText,
    required this.readTitle,
    required this.readIcon,
    required this.readDot,
    required this.unreadDot,
    required this.warningBackground,
    required this.label,
    required this.header,
    required this.progressTrack,
    required this.mapBackground,
    required this.mapCorridor,
    required this.mapHall,
    required this.mapHighlight,
    required this.mapRoute,
    required this.mapDot,
    required this.mapSuccess,
    required this.mapWarning,
    required this.scanGradientStart,
    required this.scanGradientMid,
    required this.scanGradientEnd,
    required this.scanGradientBottom,
    required this.loginGradientStart,
    required this.loginGradientMid,
    required this.loginGradientEnd,
    required this.loginGradientBottom,
    required this.icon,
    required this.strengthWeak,
    required this.strengthModerate,
    required this.strengthStrong,
    required this.documents,
    required this.logistics,
    required this.done,
    required this.danger,
    required this.disabledText,
    required this.completedPill,
    required this.inactiveButton,
  });

  final Color background;
  final Color backgroundAlt;
  final Color nav;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSoft;
  final Color card;
  final Color field;
  final Color divider;
  final Color border;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final Color title;
  final Color body;
  final Color section;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onMuted;
  final Color onPrimary;
  final Color onSecondary;
  final Color error;
  final Color errorLight;
  final Color success;
  final Color warning;
  final Color disabled;
  final Color disabledBackground;
  final Color overlay;
  final Color iconBackground;
  final Color avatarBackground;
  final Color logoutBackground;
  final Color logoutBorder;
  final Color salmon;
  final Color muted;
  final Color hint;
  final Color ice;
  final Color coral;
  final Color chip;
  final Color selectedCard;
  final Color optionalCard;
  final Color attachment;
  final Color attachmentBorder;
  final Color dashedBorder;
  final Color buttonText;
  final Color pdfBackground;
  final Color pdf;
  final Color tabBackground;
  final Color frame;
  final Color buttonShell;
  final Color activeChip;
  final Color activeChipText;
  final Color readTitle;
  final Color readIcon;
  final Color readDot;
  final Color unreadDot;
  final Color warningBackground;
  final Color label;
  final Color header;
  final Color progressTrack;
  final Color mapBackground;
  final Color mapCorridor;
  final Color mapHall;
  final Color mapHighlight;
  final Color mapRoute;
  final Color mapDot;
  final Color mapSuccess;
  final Color mapWarning;
  final Color scanGradientStart;
  final Color scanGradientMid;
  final Color scanGradientEnd;
  final Color scanGradientBottom;
  final Color loginGradientStart;
  final Color loginGradientMid;
  final Color loginGradientEnd;
  final Color loginGradientBottom;
  final Color icon;
  final Color strengthWeak;
  final Color strengthModerate;
  final Color strengthStrong;
  final Color documents;
  final Color logistics;
  final Color done;
  final Color danger;
  final Color disabledText;
  final Color completedPill;
  final Color inactiveButton;

  static const AppThemeExtension dark = AppThemeExtension(
    background: AppColors.background,
    backgroundAlt: AppColors.backgroundAlt,
    nav: AppColors.nav,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceSoft: AppColors.surfaceSoft,
    card: Color(0xFF101F36),
    field: AppColors.field,
    divider: AppColors.divider,
    border: AppColors.border,
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    secondary: AppColors.secondary,
    secondaryLight: AppColors.secondaryLight,
    accent: AppColors.accent,
    title: Color(0xFFD5E4FF),
    body: Color(0xFF9FB0CE),
    section: Color(0xFF8FA2C2),
    onBackground: AppColors.onBackground,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    onMuted: AppColors.onMuted,
    onPrimary: AppColors.onPrimary,
    onSecondary: AppColors.onSecondary,
    error: AppColors.error,
    errorLight: AppColors.errorLight,
    success: AppColors.success,
    warning: AppColors.warning,
    disabled: AppColors.disabled,
    disabledBackground: AppColors.disabledBackground,
    overlay: AppColors.overlay,
    iconBackground: Color(0xFF1C2D48),
    avatarBackground: Color(0xFFE7F2FF),
    logoutBackground: Color(0xFF2A0D23),
    logoutBorder: Color(0xFF551A3A),
    salmon: Color(0xFFFFACA6),
    muted: Color(0xFF8FA0BA),
    hint: Color(0xFF586983),
    ice: Color(0xFFE4ECFF),
    coral: Color(0xFFFF8B6E),
    chip: Color(0xFF24344E),
    selectedCard: Color(0xFF1B2B44),
    optionalCard: Color(0xFF07172C),
    attachment: Color(0xFF1B2A42),
    attachmentBorder: Color(0xFF263B59),
    dashedBorder: Color(0xFF334762),
    buttonText: Color(0xFF4E1017),
    pdfBackground: Color(0xFF4B2538),
    pdf: Color(0xFFFFA8A0),
    tabBackground: Color(0xFF2B3B55),
    frame: Color(0xFFBFD0FF),
    buttonShell: Color(0xFF1D2D47),
    activeChip: Color(0xFFDCE6FF),
    activeChipText: Color(0xFF061326),
    readTitle: Color(0xFFB8C5DA),
    readIcon: Color(0xFF8795AA),
    readDot: Color(0xFF33445F),
    unreadDot: Color(0xFFAEC8FF),
    warningBackground: Color(0xFF41213A),
    label: Color(0xFFAABCE0),
    header: Color(0xFF07172D),
    progressTrack: Color(0xFF36445A),
    mapBackground: Color(0xFF07172D),
    mapCorridor: Color(0xFF1A3050),
    mapHall: Color(0xFF0C1B31),
    mapHighlight: Color(0xFF4A91F8),
    mapRoute: Color(0xFF2CE59B),
    mapDot: Color(0xFFFF8B6E),
    mapSuccess: Color(0xFF81C784),
    mapWarning: Color(0xFFFFB74D),
    scanGradientStart: Color(0xFF101B20),
    scanGradientMid: Color(0xFF17232A),
    scanGradientEnd: Color(0xFF233242),
    scanGradientBottom: Color(0xFF080D14),
    loginGradientStart: Color(0xFF08243D),
    loginGradientMid: Color(0xFF19304A),
    loginGradientEnd: Color(0xFF08213A),
    loginGradientBottom: Color(0xFF031021),
    icon: Color(0xFF97BBFF),
    strengthWeak: Color(0xFFE9413A),
    strengthModerate: Color(0xFFFFC34A),
    strengthStrong: Color(0xFF38D67A),
    documents: Color(0xFF8FA9DB),
    logistics: Color(0xFFFFA982),
    done: Color(0xFF81C784),
    danger: Color(0xFFFFACA6),
    disabledText: Color(0xFF7C8BA7),
    completedPill: Color(0xFF69D8A3),
    inactiveButton: Color(0xFF263751),
  );

  static const AppThemeExtension light = AppThemeExtension(
    background: Color(0xFFF4F7FC),
    backgroundAlt: Color(0xFFE8EEF8),
    nav: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0F4FA),
    surfaceSoft: Color(0xFFE2EAF5),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFF0F4FA),
    divider: Color(0xFFD8E2F0),
    border: Color(0xFFC5D3E8),
    primary: Color(0xFF4A91F8),
    primaryLight: Color(0xFF97BBFF),
    primaryDark: Color(0xFF255C8E),
    secondary: Color(0xFFFFA982),
    secondaryLight: Color(0xFFFFACA6),
    accent: Color(0xFF16D8A4),
    title: Color(0xFF061326),
    body: Color(0xFF5C6F8C),
    section: Color(0xFF6B7D9A),
    onBackground: Color(0xFF061326),
    onSurface: Color(0xFF1A2B45),
    onSurfaceVariant: Color(0xFF4A5F7A),
    onMuted: Color(0xFF7A8DA8),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF4E1017),
    error: Color(0xFFE85D3B),
    errorLight: Color(0xFFFFACA6),
    success: Color(0xFF2EAD72),
    warning: Color(0xFFE6A820),
    disabled: Color(0xFF9AA8BE),
    disabledBackground: Color(0xFFE8EDF5),
    overlay: Color(0xAA061326),
    iconBackground: Color(0xFFE8EEF8),
    avatarBackground: Color(0xFFDCE8FF),
    logoutBackground: Color(0xFFFFF0F0),
    logoutBorder: Color(0xFFFFC9C9),
    salmon: Color(0xFFE85D3B),
    muted: Color(0xFF6B7D9A),
    hint: Color(0xFF8A9BB5),
    ice: Color(0xFF1A2B45),
    coral: Color(0xFFE85D3B),
    chip: Color(0xFFE2EAF5),
    selectedCard: Color(0xFFE8F0FF),
    optionalCard: Color(0xFFF8FAFD),
    attachment: Color(0xFFF0F4FA),
    attachmentBorder: Color(0xFFD0DBEB),
    dashedBorder: Color(0xFFB8C8DE),
    buttonText: Color(0xFFFFFFFF),
    pdfBackground: Color(0xFFFFF0EE),
    pdf: Color(0xFFE85D3B),
    tabBackground: Color(0xFFE2EAF5),
    frame: Color(0xFF4A91F8),
    buttonShell: Color(0xFFE8EEF8),
    activeChip: Color(0xFF4A91F8),
    activeChipText: Color(0xFFFFFFFF),
    readTitle: Color(0xFF7A8DA8),
    readIcon: Color(0xFF9AA8BE),
    readDot: Color(0xFFC5D3E8),
    unreadDot: Color(0xFF4A91F8),
    warningBackground: Color(0xFFFFF3E8),
    label: Color(0xFF4A5F7A),
    header: Color(0xFFFFFFFF),
    progressTrack: Color(0xFFD8E2F0),
    mapBackground: Color(0xFFF0F4FA),
    mapCorridor: Color(0xFFDCE8F8),
    mapHall: Color(0xFFE8EEF8),
    mapHighlight: Color(0xFF4A91F8),
    mapRoute: Color(0xFF16D8A4),
    mapDot: Color(0xFFE85D3B),
    mapSuccess: Color(0xFF2EAD72),
    mapWarning: Color(0xFFE6A820),
    scanGradientStart: Color(0xFFE8EEF8),
    scanGradientMid: Color(0xFFF0F4FA),
    scanGradientEnd: Color(0xFFDCE8F8),
    scanGradientBottom: Color(0xFFF4F7FC),
    loginGradientStart: Color(0xFFE8F0FF),
    loginGradientMid: Color(0xFFF0F5FF),
    loginGradientEnd: Color(0xFFE2ECFF),
    loginGradientBottom: Color(0xFFF4F7FC),
    icon: Color(0xFF4A91F8),
    strengthWeak: Color(0xFFE9413A),
    strengthModerate: Color(0xFFE6A820),
    strengthStrong: Color(0xFF2EAD72),
    documents: Color(0xFF5C6F8C),
    logistics: Color(0xFFFFA982),
    done: Color(0xFF2EAD72),
    danger: Color(0xFFE85D3B),
    disabledText: Color(0xFF9AA8BE),
    completedPill: Color(0xFF2EAD72),
    inactiveButton: Color(0xFFE8EDF5),
  );

  @override
  AppThemeExtension copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? nav,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSoft,
    Color? card,
    Color? field,
    Color? divider,
    Color? border,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryLight,
    Color? accent,
    Color? title,
    Color? body,
    Color? section,
    Color? onBackground,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? onMuted,
    Color? onPrimary,
    Color? onSecondary,
    Color? error,
    Color? errorLight,
    Color? success,
    Color? warning,
    Color? disabled,
    Color? disabledBackground,
    Color? overlay,
    Color? iconBackground,
    Color? avatarBackground,
    Color? logoutBackground,
    Color? logoutBorder,
    Color? salmon,
    Color? muted,
    Color? hint,
    Color? ice,
    Color? coral,
    Color? chip,
    Color? selectedCard,
    Color? optionalCard,
    Color? attachment,
    Color? attachmentBorder,
    Color? dashedBorder,
    Color? buttonText,
    Color? pdfBackground,
    Color? pdf,
    Color? tabBackground,
    Color? frame,
    Color? buttonShell,
    Color? activeChip,
    Color? activeChipText,
    Color? readTitle,
    Color? readIcon,
    Color? readDot,
    Color? unreadDot,
    Color? warningBackground,
    Color? label,
    Color? header,
    Color? progressTrack,
    Color? mapBackground,
    Color? mapCorridor,
    Color? mapHall,
    Color? mapHighlight,
    Color? mapRoute,
    Color? mapDot,
    Color? mapSuccess,
    Color? mapWarning,
    Color? scanGradientStart,
    Color? scanGradientMid,
    Color? scanGradientEnd,
    Color? scanGradientBottom,
    Color? loginGradientStart,
    Color? loginGradientMid,
    Color? loginGradientEnd,
    Color? loginGradientBottom,
    Color? icon,
    Color? strengthWeak,
    Color? strengthModerate,
    Color? strengthStrong,
    Color? documents,
    Color? logistics,
    Color? done,
    Color? danger,
    Color? disabledText,
    Color? completedPill,
    Color? inactiveButton,
  }) {
    return AppThemeExtension(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      nav: nav ?? this.nav,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      card: card ?? this.card,
      field: field ?? this.field,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      accent: accent ?? this.accent,
      title: title ?? this.title,
      body: body ?? this.body,
      section: section ?? this.section,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onMuted: onMuted ?? this.onMuted,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      disabled: disabled ?? this.disabled,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      overlay: overlay ?? this.overlay,
      iconBackground: iconBackground ?? this.iconBackground,
      avatarBackground: avatarBackground ?? this.avatarBackground,
      logoutBackground: logoutBackground ?? this.logoutBackground,
      logoutBorder: logoutBorder ?? this.logoutBorder,
      salmon: salmon ?? this.salmon,
      muted: muted ?? this.muted,
      hint: hint ?? this.hint,
      ice: ice ?? this.ice,
      coral: coral ?? this.coral,
      chip: chip ?? this.chip,
      selectedCard: selectedCard ?? this.selectedCard,
      optionalCard: optionalCard ?? this.optionalCard,
      attachment: attachment ?? this.attachment,
      attachmentBorder: attachmentBorder ?? this.attachmentBorder,
      dashedBorder: dashedBorder ?? this.dashedBorder,
      buttonText: buttonText ?? this.buttonText,
      pdfBackground: pdfBackground ?? this.pdfBackground,
      pdf: pdf ?? this.pdf,
      tabBackground: tabBackground ?? this.tabBackground,
      frame: frame ?? this.frame,
      buttonShell: buttonShell ?? this.buttonShell,
      activeChip: activeChip ?? this.activeChip,
      activeChipText: activeChipText ?? this.activeChipText,
      readTitle: readTitle ?? this.readTitle,
      readIcon: readIcon ?? this.readIcon,
      readDot: readDot ?? this.readDot,
      unreadDot: unreadDot ?? this.unreadDot,
      warningBackground: warningBackground ?? this.warningBackground,
      label: label ?? this.label,
      header: header ?? this.header,
      progressTrack: progressTrack ?? this.progressTrack,
      mapBackground: mapBackground ?? this.mapBackground,
      mapCorridor: mapCorridor ?? this.mapCorridor,
      mapHall: mapHall ?? this.mapHall,
      mapHighlight: mapHighlight ?? this.mapHighlight,
      mapRoute: mapRoute ?? this.mapRoute,
      mapDot: mapDot ?? this.mapDot,
      mapSuccess: mapSuccess ?? this.mapSuccess,
      mapWarning: mapWarning ?? this.mapWarning,
      scanGradientStart: scanGradientStart ?? this.scanGradientStart,
      scanGradientMid: scanGradientMid ?? this.scanGradientMid,
      scanGradientEnd: scanGradientEnd ?? this.scanGradientEnd,
      scanGradientBottom: scanGradientBottom ?? this.scanGradientBottom,
      loginGradientStart: loginGradientStart ?? this.loginGradientStart,
      loginGradientMid: loginGradientMid ?? this.loginGradientMid,
      loginGradientEnd: loginGradientEnd ?? this.loginGradientEnd,
      loginGradientBottom: loginGradientBottom ?? this.loginGradientBottom,
      icon: icon ?? this.icon,
      strengthWeak: strengthWeak ?? this.strengthWeak,
      strengthModerate: strengthModerate ?? this.strengthModerate,
      strengthStrong: strengthStrong ?? this.strengthStrong,
      documents: documents ?? this.documents,
      logistics: logistics ?? this.logistics,
      done: done ?? this.done,
      danger: danger ?? this.danger,
      disabledText: disabledText ?? this.disabledText,
      completedPill: completedPill ?? this.completedPill,
      inactiveButton: inactiveButton ?? this.inactiveButton,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get colors =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
