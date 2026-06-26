// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مسافر';

  @override
  String get brandMosafer => 'مسافر';

  @override
  String get navFlights => 'الرحلات';

  @override
  String get navMyTrips => 'رحلاتي';

  @override
  String get navProfile => 'الحساب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get add => 'إضافة';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get ok => 'حسناً';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsNotificationsSection => 'إعدادات الإشعارات';

  @override
  String get settingsDisplaySection => 'إعدادات العرض';

  @override
  String get settingsThemeTileTitle => 'الوضع الداكن';

  @override
  String get settingsThemeTileSubtitle => 'التبديل بين الوضع الفاتح والداكن';

  @override
  String get settingsAccountSection => 'الحساب';

  @override
  String get settingsNotificationTileTitle => 'السماح بوصول الإشعارات';

  @override
  String get settingsNotificationTileSubtitle =>
      'تلقَّ تحديثات رحلتك في الوقت المناسب';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsSwitchAccount => 'تبديل الحساب';

  @override
  String get settingsSwitchAccountSubtitle => 'تسجيل الدخول ببريد إلكتروني آخر';

  @override
  String get settingsLogout => 'تسجيل الخروج';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'لغة التطبيق واتجاه الواجهة';

  @override
  String get settingsChooseLanguageTitle => 'اختر اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get travelerDefault => 'مسافر';

  @override
  String get mosaferAccountDefault => 'حساب مسافر';

  @override
  String get settingsEditProfileTwoLines => 'تعديل الملف الشخصي';

  @override
  String get loginTagline => 'مرشدك الرقمي لرحلاتك بثقة وراحة';

  @override
  String get loginEmailLabel => 'البريد الإلكتروني';

  @override
  String get loginEmailHint => 'voyager@ethereal.com';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginForgot => 'هل نسيت كلمة المرور؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginNewToVoyage => 'جديد معنا؟ ';

  @override
  String get loginRegisterNow => 'أنشئ حساباً';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get forgotPasswordSubmit => 'إرسال رابط الإعادة';

  @override
  String get forgotPasswordSuccess =>
      'إذا وُجد حساب بهذا البريد، فقد أُرسل رابط إعادة التعيين.';

  @override
  String get forgotPasswordBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get resetPasswordTitle => 'كلمة مرور جديدة';

  @override
  String get resetPasswordSubtitle => 'أدخل كلمة مرور جديدة لحسابك.';

  @override
  String get resetPasswordSubmit => 'تحديث كلمة المرور';

  @override
  String get resetPasswordSuccess =>
      'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.';

  @override
  String get resetPasswordInvalidLink =>
      'رابط إعادة التعيين غير صالح أو منتهٍ الصلاحية.';

  @override
  String get registerStartJourneyTitle => 'ابدأ رحلتك.';

  @override
  String get registerJoinCommunity => 'انضم إلى مجتمع المسافرين حول العالم.';

  @override
  String get registerFullNameLabel => 'الاسم الكامل';

  @override
  String get registerFullNameHint => 'Julianne Smith';

  @override
  String get registerEmailHint => 'curator@musafir.travel';

  @override
  String get registerPasswordLabel => 'كلمة المرور';

  @override
  String get registerConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get registerTermsNotAccepted =>
      'يرجى الموافقة على شروط الاستخدام وسياسة الخصوصية.';

  @override
  String get registerAccountCreated =>
      'تم التسجيل بنجاح. يرجى تأكيد بريدك الإلكتروني.';

  @override
  String get registerCreateAccount => 'إنشاء حساب';

  @override
  String get registerAlreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get registerLogIn => 'سجّل الدخول';

  @override
  String get registerLoginArrow => 'تسجيل الدخول ←';

  @override
  String get passwordStrengthWeak => 'ضعيفة';

  @override
  String get passwordStrengthModerate => 'متوسطة';

  @override
  String get passwordStrengthStrong => 'قوية';

  @override
  String passwordStrengthLabel(String strength) {
    return 'قوة كلمة المرور: $strength';
  }

  @override
  String get termsAgreePrefix => 'أوافق على ';

  @override
  String get termsOfService => 'شروط الاستخدام';

  @override
  String get termsAnd => ' و';

  @override
  String get termsPrivacyPolicy => 'سياسة\nالخصوصية.';

  @override
  String fieldRequired(String fieldName) {
    return 'حقل $fieldName مطلوب';
  }

  @override
  String get emailRequired => 'أدخل البريد الإلكتروني';

  @override
  String get emailInvalid => 'صيغة البريد غير صحيحة';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String passwordMinLength(int count) {
    return 'كلمة المرور يجب أن تكون $count أحرف على الأقل';
  }

  @override
  String get confirmPasswordRequired => 'أكد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get phoneRequired => 'رقم الجوال مطلوب';

  @override
  String get phoneInvalid => 'أدخل رقماً صحيحاً';

  @override
  String get validationFieldFullName => 'الاسم الكامل';

  @override
  String get validationFieldCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get errorGeneric => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get errorConnectionTimeout => 'انتهت مهلة الاتصال. حاول مرة أخرى.';

  @override
  String get errorNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.';

  @override
  String get errorUnauthorized => 'انتهت الجلسة. سجّل الدخول من جديد.';

  @override
  String get errorUnableUpdatePassword => 'تعذّر تحديث كلمة المرور';

  @override
  String get errorSeatAlreadyTaken => 'المقعد محجوز بالفعل';

  @override
  String get errorSeatNoLongerAvailable => 'المقعد لم يعد متاحاً';

  @override
  String get errorSeatNotInBooking => 'المقعد غير مضمّن في هذا الحجز';

  @override
  String get errorDuplicateSeats => 'أرقام مقاعد مكررة في نفس الحجز';

  @override
  String get errorInvalidSeatFormat => 'صيغة المقعد غير صالحة (مثال: 12A)';

  @override
  String get errorCheckoutExpired => 'انتهت صلاحية جلسة الحجز';

  @override
  String get errorPassengerDetailsSubmitted => 'تم إرسال بيانات المسافر مسبقاً';

  @override
  String get errorReservationNotFound => 'لم يُعثر على الحجز';

  @override
  String get errorNotYourReservation => 'هذا الحجز لا يخصك';

  @override
  String get errorAlreadyCancelled => 'تم إلغاء الحجز مسبقاً';

  @override
  String get errorCannotCancelPastFlight => 'لا يمكن إلغاء رحلة منتهية';

  @override
  String get errorDuplicatePassports => 'أرقام جوازات مكررة في نفس الحجز';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errorEmailNotVerified =>
      'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get errorAccountDisabled => 'الحساب معطّل.';

  @override
  String get errorServerUnavailable =>
      'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ API.';

  @override
  String get errorEmailAlreadyExists => 'يوجد حساب بهذا البريد مسبقاً';

  @override
  String get errorCurrentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get flightsTitle => 'الرحلات';

  @override
  String get flightsIntro =>
      'يربط مسافر حجزك ورمز تذكرتك وتخطيط المغادرة وتجربة المطار وقائمة التجهيز والمهام والإشعارات في مساعد سفر واحد.';

  @override
  String get bookingHowTitle => 'كيفية الحجز';

  @override
  String get bookingStep1 => 'افتح موقع الحجز واختر رحلتك.';

  @override
  String get bookingStep2 =>
      'أكمل الحجز واحتفظ بالتذكرة أو صورة رمز الاستجابة.';

  @override
  String get bookingStep3 =>
      'ارجع إلى مسافر، امسح التذكرة أو ارفعها، ثم أدر رحلتك.';

  @override
  String get openBookingWebsite => 'فتح موقع الحجز';

  @override
  String get noActiveTripTitle => 'لم تختر رحلة بعد.';

  @override
  String get noActiveTripSubtitle =>
      'افتح رحلة أو امسح تذكرة لبدء المساعدة خطوة بخطوة.';

  @override
  String get scanTicket => 'مسح التذكرة';

  @override
  String get sectionHome => 'مخططات الرحلة';

  @override
  String get stageHomeTitle => 'في المنزل';

  @override
  String get stageHomeSubtitle => 'تخطيط المسار';

  @override
  String get stageOnWayTitle => 'في الطريق';

  @override
  String get stageOnWaySubtitle => 'الوقت المتوقع مباشرة';

  @override
  String get stageAirportTitle => 'في المطار';

  @override
  String get stageAirportSubtitle => 'جاهزية البوابة';

  @override
  String get prepDepartureTitle => 'تخطيط المغادرة من المنزل';

  @override
  String get prepDepartureSubtitle =>
      'وقت المغادرة، هامش المرور، والمسار على الخريطة.';

  @override
  String get prepTodosTitle => 'المهام والجدول الزمني';

  @override
  String get prepTodosSubtitle => 'جهّز الوثائق والتجهيز ومهام المطار.';

  @override
  String boardingInMinutes(String minutes) {
    return 'الصعود خلال $minutes د';
  }

  @override
  String get flightMetaDate => 'التاريخ';

  @override
  String get flightMetaGate => 'البوابة';

  @override
  String get flightMetaTerminal => 'المبنى';

  @override
  String get flightMetaSeat => 'المقعد';

  @override
  String get departurePlan => 'خطة المغادرة';

  @override
  String get packingList => 'قائمة التجهيز';

  @override
  String get timeline => 'الجدول الزمني';

  @override
  String get todosLabel => 'قائمة المهام';

  @override
  String get attachmentsSection => 'المرفقات';

  @override
  String get twoFiles => 'ملفان';

  @override
  String get uploadAttachment => 'رفع مرفق';

  @override
  String get openAirportExperience => 'تجربة المطار';

  @override
  String get tripsSearchHint => 'ابحث باسم المطار أو رقم الرحلة';

  @override
  String get tripsUpcoming => 'القادمة';

  @override
  String get tripsAll => 'الكل';

  @override
  String get tripsConfirmed => 'مؤكدة';

  @override
  String get tripsCompleted => 'مكتملة';

  @override
  String get tripsViewHistory => 'عرض السجل';

  @override
  String get tripsOpenTrip => 'عرض تفاصيل الرحلة';

  @override
  String get tripsExpired => 'منتهية';

  @override
  String get tripsDeleteConfirmTitle => 'حذف التذكرة؟';

  @override
  String get tripsDeleteConfirmBody =>
      'ستُنقل التذكرة إلى سلة المحذوفات. يمكنك استرجاعها من الإعدادات.';

  @override
  String get tripsDeleteConfirm => 'حذف';

  @override
  String get tripsDeleteCancel => 'إلغاء';

  @override
  String get settingsDeletedTrips => 'سلة المحذوفات';

  @override
  String get settingsDeletedTripsSubtitle => 'استرجاع التذاكر المحذوفة';

  @override
  String get deletedTripsTitle => 'سلة المحذوفات';

  @override
  String get deletedTripsEmpty => 'لا توجد تذاكر محذوفة.';

  @override
  String get deletedTripsRestore => 'استرجاع';

  @override
  String get deletedTripsDeletePermanent => 'حذف نهائي';

  @override
  String get deletedTripsDeleteConfirmTitle => 'حذف نهائي؟';

  @override
  String get deletedTripsDeleteConfirmBody => 'لن يمكن استرجاع هذه التذكرة.';

  @override
  String get deletedTripsAutoPurgeNotice =>
      'بعد مرور 7 أيام على حذف التذكرة، تُحذف تلقائياً ولا يمكن استرجاعها.';

  @override
  String get scanPastePayload => 'الصق محتوى رمز التذكرة';

  @override
  String get scanPayloadHint => 'نص الرمز أو رقم التذكرة';

  @override
  String get validateTicket => 'التحقق من التذكرة';

  @override
  String get scanTicketAddedSuccess => 'تم إضافة التذكرة.';

  @override
  String get scanValidateTicketError => 'تعذّر التحقق من التذكرة.';

  @override
  String get scanNoQrInImage => 'لم يُعثر على رمز QR في هذه الصورة.';

  @override
  String get scanTicketNotFound => 'لم نعثر على التذكرة في سجلاتنا.';

  @override
  String get scanTicketInvalid => 'التذكرة غير صالحة أو تعذّر قراءتها.';

  @override
  String get scanTicketExpired => 'انتهت صلاحية هذه التذكرة.';

  @override
  String get scanTicketAlreadyAssigned =>
      'هذه التذكرة مرتبطة بحساب آخر بالفعل.';

  @override
  String get scanImageUploadError => 'تعذّر رفع صورة التذكرة. حاول مرة أخرى.';

  @override
  String get scanTabScanQr => 'مسح الرمز';

  @override
  String get scanTabUploadImage => 'رفع صورة';

  @override
  String get scanUploadTitle => 'رفع صورة التذكرة';

  @override
  String get scanUploadBody =>
      'اختر تذكرة أو بطاقة صعود من معرض الصور. يقرأها مسافر ويضيف الرحلة إن كانت صالحة.';

  @override
  String get scanChooseImage => 'اختيار صورة';

  @override
  String get scanChooseImageLoading => 'جاري قراءة التذكرة...';

  @override
  String get scanCenterQr => 'ضع رمز التذكرة داخل\nالإطار.';

  @override
  String get scanScanNow => 'مسح الآن';

  @override
  String get notificationsReadAll => 'تعيين الكل كمقروء';

  @override
  String get notificationsNoYet => 'لا توجد إشعارات بعد.';

  @override
  String get notificationsDeleteConfirm => 'حذف هذا الإشعار؟';

  @override
  String get notificationsDelete => 'حذف';

  @override
  String get notificationsCancel => 'إلغاء';

  @override
  String get notificationsToday => 'اليوم';

  @override
  String get notificationsEarlier => 'سابقاً';

  @override
  String get timeAgoNow => 'الآن';

  @override
  String timeAgoMinutes(int minutes) {
    return 'منذ $minutes د';
  }

  @override
  String timeAgoHours(int hours) {
    return 'منذ $hours س';
  }

  @override
  String timeAgoDays(int days) {
    return 'منذ $days ي';
  }

  @override
  String get planDepartureSelectTrip => 'اختر رحلة';

  @override
  String get planDepartureSafeToLeave => 'آمن للمغادرة';

  @override
  String get planDepartureHeroSubtitle => 'أفضل وقت لمغادرة المنزل نحو الرحلة';

  @override
  String get planDepartureTransportMode => 'وسيلة التنقل';

  @override
  String get planDepartureModeCar => 'سيارة';

  @override
  String get planDepartureModeTrain => 'قطار';

  @override
  String get planDepartureModeTaxi => 'أجرة';

  @override
  String get planDepartureTitle => 'خطة المغادرة';

  @override
  String get planDepartureRouteSummary => 'ملخص المسار';

  @override
  String planDepartureDemoRoute(String airportCode) {
    return 'ميدان تقسيم ← مطار $airportCode';
  }

  @override
  String get planDepartureLiveTraffic => 'حركة\nمباشرة';

  @override
  String get planDepartureDistance => 'المسافة';

  @override
  String planDepartureDistanceValue(String km) {
    return '$km كم';
  }

  @override
  String get trafficLow => 'ازدحام خفيف';

  @override
  String get trafficModerate => 'ازدحام متوسط';

  @override
  String get trafficHeavy => 'ازدحام شديد';

  @override
  String get onWayTraffic => 'الازدحام';

  @override
  String get onWayOpenInMaps => 'فتح في خرائط Google';

  @override
  String get onWayExpandMap => 'توسيع الخريطة';

  @override
  String get planDepartureTravelTime => 'مدة الطريق';

  @override
  String get planDepartureBuffer => 'هامش الأمان';

  @override
  String get planDepartureNoTrainsInCountry => 'لا يوجد قطارات داخل هذه البلد';

  @override
  String get planDepartureEstArrival => 'الوصول المتوقع';

  @override
  String get planDepartureUnitMinutes => 'د';

  @override
  String onWaySubtitle(String airportCode) {
    return 'من موقعك الحالي إلى مطار $airportCode';
  }

  @override
  String onWayDemoSubtitle(String airportCode) {
    return 'من ميدان تقسيم إلى مطار $airportCode';
  }

  @override
  String get packingLinenShirtDescription =>
      'مثالي لنسيم دبي\nالمسائي والرطوبة.';

  @override
  String get openTripFirstSnackbar => 'افتح رحلة أولاً.';

  @override
  String get openTripFirstAirportFull =>
      'افتح رحلة أولاً لاستخدام تجربة المطار.';

  @override
  String get unableOpenMaps => 'تعذّر فتح الخرائط على هذا الجهاز.';

  @override
  String get profileImageUpdated => 'تم تحديث صورة الملف.';

  @override
  String get unableUploadProfileImage => 'تعذّر رفع الصورة.';

  @override
  String get editProfileTitle => 'تعديل الملف';

  @override
  String get editProfileVoyagerTag => 'مسافر فوياجر';

  @override
  String get travelPreferences => 'تفضيلات السفر';

  @override
  String get fullNameLabel => 'الاسم';

  @override
  String get emailAddressLabel => 'البريد الإلكتروني';

  @override
  String get phoneNumberLabel => 'رقم الجوال';

  @override
  String get homeLocationLabel => 'موقع المنزل';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordCurrentLabel => 'كلمة المرور الحالية';

  @override
  String get changePasswordCurrentHint => 'أدخل كلمة المرور الحالية';

  @override
  String get changePasswordNewLabel => 'كلمة المرور الجديدة';

  @override
  String get changePasswordNewHint => 'أدخل كلمة المرور الجديدة';

  @override
  String get changePasswordConfirmLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get changePasswordConfirmHint => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get changePasswordSave => 'حفظ كلمة المرور';

  @override
  String get changePasswordRepeatHint => 'كرر كلمة المرور الجديدة';

  @override
  String get passwordStrengthMeterTitle => 'قوة كلمة المرور';

  @override
  String get passwordStrengthMeterWeak => 'ضعيفة';

  @override
  String get passwordStrengthMeterGood => 'جيدة';

  @override
  String get passwordStrengthMeterStrong => 'قوية';

  @override
  String get safetyTipTitle => 'نصيحة أمان';

  @override
  String get safetyTipBody =>
      'امزج بين أحرف وأرقام\nورموز لتكون كلمة المرور\nأقوى.';

  @override
  String get profilePersonalInfo => 'المعلومات الشخصية';

  @override
  String get profileTravelPreferences => 'تفضيلات السفر';

  @override
  String get profileAddPhone => 'أضف رقم الجوال';

  @override
  String get profileFullNameLabel => 'الاسم';

  @override
  String get profileEmailLabel => 'البريد الإلكتروني';

  @override
  String get profilePhoneLabel => 'رقم الجوال';

  @override
  String get profileHomeLocationLabel => 'موقع المنزل';

  @override
  String get airportConcierge => 'كونسيرج';

  @override
  String get airportLiveExperience => 'تجربة مباشرة';

  @override
  String airportWelcomeLine(String airportName, String terminal) {
    return 'مرحباً بك في\n$airportName • $terminal';
  }

  @override
  String get airportAtAirportPill => 'في\nالمطار';

  @override
  String get airportTerminalLabel => 'المبنى';

  @override
  String get airportAssignedGate => 'البوابة المخصصة';

  @override
  String airportBoardingInMin(int minutes) {
    return 'الصعود خلال $minutes د';
  }

  @override
  String airportWalkEstimate(int minutes) {
    return 'مشي تقريبي $minutes د';
  }

  @override
  String airportWalkFollowSigns(String gate) {
    return 'اتبع إرشادات المطار نحو $gate';
  }

  @override
  String get airportCurrentLocation => 'موقعك الحالي';

  @override
  String get airportYouPin => 'أنت';

  @override
  String get airportExpandMap => 'توسيع الخريطة';

  @override
  String airportShopsNear(String gate) {
    return 'متاجر قرب $gate';
  }

  @override
  String get airportNearGate => 'قرب بوابتك';

  @override
  String get airportOpenNow => 'مفتوح الآن';

  @override
  String airportProceedToGate(String gate) {
    return 'التوجه إلى $gate';
  }

  @override
  String get indoorMapTitle => 'خريطة المطار الداخلية';

  @override
  String get indoorMapUnsupported =>
      'الخريطة الداخلية متاحة حالياً لمطار إسطنبول (IST) فقط.';

  @override
  String indoorMapGateHighlight(String gate) {
    return 'البوابة المحددة: $gate';
  }

  @override
  String indoorMapGoToGate(String gate) {
    return 'الذهاب إلى $gate';
  }

  @override
  String get indoorMapHideRoute => 'إخفاء المسار';

  @override
  String indoorMapRouteTitle(String gate) {
    return 'مسار تجريبي إلى $gate';
  }

  @override
  String indoorMapRouteEta(int minutes) {
    return '$minutes د';
  }

  @override
  String get indoorMapOpenLevelUpSource =>
      'خريطة OpenLevelUp مباشرة من OpenStreetMap.';

  @override
  String get indoorMapOpenFullMap => 'فتح خريطة OSM كاملة';

  @override
  String get indoorMapRetry => 'إعادة المحاولة';

  @override
  String get indoorMapBack => 'رجوع';

  @override
  String get indoorMapLoading => 'جاري تحميل الخريطة الداخلية…';

  @override
  String indoorMapGateLevel(String gate, String level) {
    return 'البوابة $gate · المستوى $level';
  }

  @override
  String get indoorMapRouteWrongLevel => 'المسار يظهر على مستوى البوابة فقط.';

  @override
  String indoorMapLevelBadge(String level) {
    return 'OpenLevelUp · IST · المستوى $level';
  }

  @override
  String indoorMapHighlightBadge(String level, String category) {
    return 'المستوى $level · إبراز $category';
  }

  @override
  String indoorMapCoffeeNearGate(String gate) {
    return 'قهوة قرب $gate';
  }

  @override
  String indoorMapFoodNearGate(String gate) {
    return 'وجبات سريعة قرب $gate';
  }

  @override
  String get indoorMapRouteStepEntrance => 'المدخل 7';

  @override
  String get indoorMapRouteStepSecurity => 'التفتيش الأمني';

  @override
  String get indoorMapRouteStepDutyFree => 'قاعة Duty Free';

  @override
  String get indoorMapRouteStepConcourse => 'اتبع ممر G';

  @override
  String indoorMapRouteStepArrive(String gate) {
    return 'الوصول إلى البوابة $gate';
  }

  @override
  String get airportQrNoTicket => 'لا توجد تذكرة صعود لهذا الحجز.';

  @override
  String get airportQrInvalidTicket => 'توجد تذكرة لكن بيانات الرمز غير صالحة.';

  @override
  String get airportLoungeFallback => 'صالة المطار';

  @override
  String get airportCoffeeFallback => 'مقهى';

  @override
  String get airportGateDash => 'بوابة --';

  @override
  String get airportArrivedAtAirport => 'وصلت إلى المطار';

  @override
  String get airportArrivalStatusTitle => 'حالة الوصول';

  @override
  String get airportCheckInTitle => 'تسجيل الوصول';

  @override
  String get airportCheckInDisclaimer =>
      'تجريبي فقط — ليس تسجيل وصول حقيقي لشركة الطيران.';

  @override
  String airportCheckInGateLabel(String gate) {
    return 'بوابتك: $gate';
  }

  @override
  String get airportCheckInStepArrived => 'وصلت إلى المطار';

  @override
  String get airportCheckInStepStarted => 'بدأ تسجيل الوصول';

  @override
  String get airportCheckInStepBoardingPass => 'بطاقة الصعود جاهزة';

  @override
  String get airportCheckInStepSecurity => 'توجّه إلى الأمن';

  @override
  String airportCheckInStepGoToGate(String gate) {
    return 'اذهب إلى البوابة $gate';
  }

  @override
  String get airportCheckInNextStep => 'الخطوة التالية';

  @override
  String get airportCheckInReset => 'إعادة ضبط';

  @override
  String airportOpenGateMap(String gate) {
    return 'فتح خريطة البوابة';
  }

  @override
  String get onWayTitle => 'في الطريق';

  @override
  String get onWayStartNavigation => 'بدء التوجيه';

  @override
  String get onWayTrackingStarted => 'التتبع نشط';

  @override
  String get onWayLocationUnavailable => 'إذن الموقع أو الخدمة غير متاح.';

  @override
  String get onWayTrackingActive => 'التتبع المباشر يعمل.';

  @override
  String get onWayYou => 'أنت';

  @override
  String get onWayLiveConnected => 'الموقع المباشر متصل';

  @override
  String get onWayPressStart => 'اضغط بدء التوجيه لربط الموقع المباشر';

  @override
  String get onWayDemoOriginName => 'ميدان تقسيم';

  @override
  String get onWayDemoOriginActive =>
      'يتم استخدام ميدان تقسيم كنقطة بداية تجريبية';

  @override
  String get onWayDistance => 'المسافة';

  @override
  String get onWayEta => 'الوقت المتوقع';

  @override
  String get onWayTracking => 'التتبع';

  @override
  String get onWayTrackingActiveState => 'نشط';

  @override
  String get onWayTrackingNotStarted => 'لم يبدأ';

  @override
  String get onWayDepartureAddressTitle => 'عنوان الانطلاق';

  @override
  String get onWayDepartureAddressSubtitle =>
      'اختر GPS أو أدخل عنوان منزلك لتخطيط المسار.';

  @override
  String get onWayUseCurrentLocation => 'الموقع الحالي (GPS)';

  @override
  String get onWayUseCurrentLocationHint => 'استخدم GPS المباشر عند توفره';

  @override
  String get onWayUseSavedAddress => 'عنواني المحفوظ';

  @override
  String get onWaySavedAddressReady => 'العنوان المحفوظ جاهز';

  @override
  String get onWaySavedAddressMissing => 'أضف عنواناً أدناه أولاً';

  @override
  String get onWayManualOriginActive => 'نستخدم عنوانك المحفوظ كنقطة انطلاق';

  @override
  String onWayManualSubtitle(String airportCode) {
    return 'من عنوانك المحفوظ إلى مطار $airportCode';
  }

  @override
  String get onWayDepartureFrom => 'الانطلاق من';

  @override
  String get onWayChangeAddress => 'تغيير';

  @override
  String get homeAddressHint => 'الشارع، المدينة، الدولة';

  @override
  String get homeAddressSave => 'حفظ العنوان';

  @override
  String get homeAddressTooShort => 'أدخل 3 أحرف على الأقل';

  @override
  String get homeAddressGeocodeFailed =>
      'تعذّر العثور على هذا العنوان. جرّب إضافة المدينة والدولة.';

  @override
  String get homeAddressSaved => 'تم حفظ عنوان المنزل';

  @override
  String get flightWeatherTitle => 'طقس يوم الرحلة';

  @override
  String flightWeatherDepartureDay(String city) {
    return 'المغادرة · $city';
  }

  @override
  String flightWeatherArrivalDay(String city) {
    return 'الوصول · $city';
  }

  @override
  String flightWeatherBufferAdded(int minutes) {
    return 'تمت إضافة $minutes د بسبب الطقس';
  }

  @override
  String get timelineJourneyTag => 'رحلة مسافر';

  @override
  String get timelineYourJourney => 'رحلتك';

  @override
  String get addingEllipsis => 'جاري الإضافة...';

  @override
  String addSelectedToTodos(int count) {
    return 'إضافة $count المحدد إلى المهام';
  }

  @override
  String addSelectedToTripTodos(int count) {
    return 'إضافة $count المحدد إلى مهام الرحلة';
  }

  @override
  String get packingOpenTripFirst => 'افتح رحلة أولاً.';

  @override
  String get timelineOpenTripFirst => 'افتح رحلة أولاً.';

  @override
  String get packingLoading => 'جاري إنشاء قائمة التجهيز...';

  @override
  String get timelineLoading => 'جاري إنشاء الجدول الزمني...';

  @override
  String get packingLoadFailed => 'تعذّر تحميل قائمة التجهيز.';

  @override
  String get timelineLoadFailed => 'تعذّر تحميل الجدول الزمني.';

  @override
  String get timelineNoUpcomingTasks =>
      'لا توجد مهام قادمة في الجدول الزمني لهذه الرحلة.';

  @override
  String get packingRetry => 'إعادة المحاولة';

  @override
  String get timelineRetry => 'إعادة المحاولة';

  @override
  String timelineDayBefore(int days) {
    return 'قبل $days يوم';
  }

  @override
  String get todosOpenTripFirst => 'افتح رحلة أولاً.';

  @override
  String get todosOpenTripFirstView => 'افتح رحلة أولاً لعرض مهامها.';

  @override
  String get todoAddTitle => 'إضافة مهمة';

  @override
  String get todoEditTitle => 'تعديل المهمة';

  @override
  String get todoTitleHint => 'عنوان المهمة';

  @override
  String get todoAdded => 'تمت إضافة المهمة.';

  @override
  String get todosEmptyDefault => 'لا توجد مهام في هذا التصنيف بعد.';

  @override
  String get todosAddTodo => 'إضافة مهمة';

  @override
  String get todosCategoryAll => 'الكل';

  @override
  String get todosCategoryPacking => 'التجهيز';

  @override
  String get todosCategoryDocuments => 'الوثائق';

  @override
  String get todosTabDocuments => 'الوثائق';

  @override
  String get todosTabPacking => 'التجهيز';

  @override
  String get todosTabLogistics => 'الخدمات';

  @override
  String get tripTaskDefault => 'مهمة الرحلة';

  @override
  String get packingMustHave => 'ضروري';

  @override
  String get packingAllItemsInTodos =>
      'كل عناصر التجهيز موجودة في مهام الرحلة.';

  @override
  String packingWeatherSummary(
    int days,
    String city,
    String condition,
    int temp,
  ) {
    return '$days أيام في $city • $condition • $temp°C';
  }

  @override
  String get weatherClear => 'مشمس';

  @override
  String get weatherCloudy => 'غائم';

  @override
  String get weatherRain => 'ممطر';

  @override
  String get weatherSnow => 'ثلج';

  @override
  String get weatherStorm => 'عاصف';

  @override
  String get packingRecommended => 'موصى به';

  @override
  String get packingOptional => 'اختياري';

  @override
  String get packingTagCrucial => 'أساسي';

  @override
  String get packingOptionalTag => 'اختياري';

  @override
  String get packingResortDay => 'يوم المنتجع';

  @override
  String get packingTransitLeisure => 'أثناء التنقل';

  @override
  String get packingItemPassport => 'جواز السفر';

  @override
  String get packingItemFlightTickets => 'تذاكر الطيران';

  @override
  String get packingItemPowerAdapter => 'محول الطاقة';

  @override
  String get packingItemSunglasses => 'نظارة شمسية';

  @override
  String get packingItemSunscreen => 'واقي شمس';

  @override
  String get packingItemSwimwear => 'ملابس سباحة';

  @override
  String get packingItemReadingBook => 'كتاب للقراءة';

  @override
  String get packingItemLinenShirt => 'قميص كتان خفيف';

  @override
  String get timelineTaskPassport => 'تحقق من صلاحية الجواز';

  @override
  String get timelineTaskVisa => 'تقديم طلب التأشيرة';

  @override
  String get timelineTaskSecurity => 'جدولة أمان المنزل';

  @override
  String get timelineTaskPet => 'ترتيب إقامة الحيوان';

  @override
  String get timelineTaskPacking => 'إكمال قائمة التجهيز';

  @override
  String get timelineTaskTaxi => 'حجز أجرة للمطار';

  @override
  String get timelineDay14 => 'قبل 14 يوماً';

  @override
  String get timelineDay7 => 'قبل 7 أيام';

  @override
  String get timelineDay1 => 'قبل يوم';

  @override
  String get timelineDay0 => 'يوم الرحلة';

  @override
  String get timelineHourBefore => 'قبل ساعة';

  @override
  String timelineHoursBefore(int hours) {
    return 'قبل $hours ساعة';
  }

  @override
  String get todoResearchHealthRequirements => 'البحث عن متطلبات الصحة';

  @override
  String get todoCreatePackingList => 'إنشاء قائمة التجهيز';

  @override
  String get todoChargeDevices => 'شحن الأجهزة';

  @override
  String get todoHeadToAirport => 'التوجه إلى المطار';

  @override
  String get todoReviewDeparturePlan => 'مراجعة خطة المغادرة';

  @override
  String get todoVisaTravelDocuments => 'فحص التأشيرة ووثائق السفر';

  @override
  String get todoHealthVaccinations => 'الفحص الصحي والتطعيمات';

  @override
  String get todoConfirmTransportArrangements => 'تأكيد ترتيبات النقل';

  @override
  String get todoConfirmFlightTickets => 'تأكيد تذاكر الطيران';

  @override
  String get packingItemMedications => 'الأدوية';

  @override
  String get packingItemWalkingShoes => 'حذاء مريح للمشي';

  @override
  String get packingItemWaterBottle => 'زجاجة ماء قابلة لإعادة الاستخدام';

  @override
  String get packingItemTravelPillow => 'وسادة سفر';

  @override
  String get notificationPaymentSuccessful => 'تم الدفع بنجاح';

  @override
  String notificationPaymentSuccessfulBody(String amount, String currency) {
    return 'تمت معالجة دفعتك بمبلغ $amount $currency.';
  }

  @override
  String get notificationPaymentFailed => 'فشل الدفع';

  @override
  String get notificationPaymentFailedBody => 'تعذّر معالجة دفعتك.';

  @override
  String get notificationPaymentRefunded => 'تم استرداد الدفع';

  @override
  String notificationPaymentRefundedBody(String amount, String currency) {
    return 'تم استرداد $amount $currency إلى حسابك.';
  }

  @override
  String get notificationFullRefund => 'استرداد كامل';

  @override
  String notificationFullRefundBody(String amount, String currency) {
    return 'تم استرداد $amount $currency بالكامل.';
  }

  @override
  String get notificationPartialRefund => 'استرداد جزئي';

  @override
  String notificationPartialRefundBody(String amount, String currency) {
    return 'تم استرداد $amount $currency جزئياً.';
  }

  @override
  String get notificationBookingCanceled => 'تم إلغاء الحجز';

  @override
  String get notificationBookingCanceledBody => 'تم إلغاء حجز رحلتك.';

  @override
  String notificationDepartureUrgent(String flight) {
    return 'انطلق الآن! – $flight';
  }

  @override
  String notificationDepartureWarning(String flight) {
    return 'يجب أن تنطلق قريباً – $flight';
  }

  @override
  String notificationDepartureReminder(String flight) {
    return 'تذكير لطيف – $flight';
  }

  @override
  String notificationDepartureBody(
    String flight,
    String departureTime,
    String leaveTime,
    int travelMinutes,
    int bufferMinutes,
  ) {
    return 'رحلتك $flight تغادر الساعة $departureTime. المغادرة الموصى بها: $leaveTime ($travelMinutes دقيقة سفر، $bufferMinutes دقيقة احتياط للطقس).';
  }

  @override
  String get notificationTripTodoTitle => 'تذكير بمهام الرحلة';

  @override
  String notificationTripTodoEmptyBody(String flight) {
    return 'عليك تعبئة قائمة مهام الرحلة $flight.';
  }

  @override
  String notificationTripTodoIncompleteBody(String flight) {
    return 'عليك إكمال مهام الرحلة $flight.';
  }

  @override
  String get notificationDepartureScheduleTitle => 'تذكير بموعد المغادرة';

  @override
  String notificationFlightDeparture6hBody(String flight) {
    return 'تبقى على موعد رحلتك $flight 6 ساعات.';
  }

  @override
  String notificationHomeDeparture2hBody(String flight) {
    return 'تبقى على موعد المغادرة من المنزل نحو المطار ساعتين ($flight).';
  }

  @override
  String notificationHomeDeparture30mBody(String flight) {
    return 'تبقى على المغادرة من المنزل نصف ساعة ($flight).';
  }

  @override
  String get notificationHomeDepartureCriticalTitle => 'موعد المغادرة الحاسم';

  @override
  String notificationHomeDepartureCriticalBody(String flight) {
    return 'يجب المغادرة حالاً من المنزل نحو المطار ($flight).';
  }

  @override
  String get timelineBadgeDocument => 'وثائق';

  @override
  String get timelineBadgeTask => 'مهمة';

  @override
  String get timelineBadgePacking => 'تجهيز';

  @override
  String get timelineTitleDocuments => 'وثائق السفر';

  @override
  String get timelineTitlePreparation => 'التحضير';

  @override
  String get timelineTitlePacking => 'التجهيز والخدمات';

  @override
  String get ticketBoardingPass => 'بطاقة الصعود';

  @override
  String get ticketScanForBoarding => 'امسح للصعود';

  @override
  String get ticketSafeWorkSecure => 'عمل آمن\nومحمي';

  @override
  String get ticketDirect => 'مباشرة';

  @override
  String get ticketDeparture => 'المغادرة';

  @override
  String timelineItemsAddedToTodos(int count) {
    return 'تمت إضافة $count عنصراً من الجدول إلى المهام.';
  }

  @override
  String packingItemsAddedToTodos(int count) {
    return 'تمت إضافة $count عنصراً من التجهيز إلى المهام.';
  }

  @override
  String get todosSelectPacking => 'تحديد مهام لحذفها';

  @override
  String get todosCancelSelection => 'إلغاء التحديد';

  @override
  String todosDeleteSelected(int count) {
    return 'حذف المحدد ($count)';
  }

  @override
  String todosDeletedCount(int count) {
    return 'تم حذف $count مهمة';
  }

  @override
  String get todoConfirmBookingDetails => 'تأكيد بيانات الحجز';
}
