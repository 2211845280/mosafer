// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mosafer';

  @override
  String get brandMosafer => 'MOSAFER';

  @override
  String get navFlights => 'FLIGHTS';

  @override
  String get navMyTrips => 'MY TRIPS';

  @override
  String get navProfile => 'PROFILE';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get seeAll => 'SEE ALL';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotificationsSection => 'NOTIFICATION SETTINGS';

  @override
  String get settingsAccountSection => 'ACCOUNT';

  @override
  String get settingsNotificationTileTitle => 'Notification Setting';

  @override
  String get settingsNotificationTileSubtitle => 'Stay updated on your flights';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsSwitchAccount => 'Switch account';

  @override
  String get settingsSwitchAccountSubtitle => 'Sign in with a different email';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App language and layout direction';

  @override
  String get settingsChooseLanguageTitle => 'Choose language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get travelerDefault => 'Traveler';

  @override
  String get mosaferAccountDefault => 'Mosafer account';

  @override
  String get settingsEditProfileTwoLines => 'Edit personal profile';

  @override
  String get loginTagline => 'YOUR DIGITAL CURATOR FOR THE UNKNOWN';

  @override
  String get loginEmailLabel => 'EMAIL ADDRESS';

  @override
  String get loginEmailHint => 'voyager@ethereal.com';

  @override
  String get loginPasswordLabel => 'SECURITY KEY';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginButton => 'Login to Mosafer';

  @override
  String get loginNewToVoyage => 'New to the voyage? ';

  @override
  String get loginRegisterNow => 'Register Now';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we will send you a link to reset your password.';

  @override
  String get forgotPasswordSubmit => 'Send reset link';

  @override
  String get forgotPasswordSuccess =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get forgotPasswordBackToLogin => 'Back to login';

  @override
  String get resetPasswordTitle => 'Choose new password';

  @override
  String get resetPasswordSubtitle => 'Enter a new password for your account.';

  @override
  String get resetPasswordSubmit => 'Update password';

  @override
  String get resetPasswordSuccess =>
      'Your password has been updated. You can sign in now.';

  @override
  String get resetPasswordInvalidLink =>
      'This reset link is invalid or has expired.';

  @override
  String get registerStartJourneyTitle => 'Start your journey.';

  @override
  String get registerJoinCommunity => 'Join our community of global curators.';

  @override
  String get registerFullNameLabel => 'FULL NAME';

  @override
  String get registerFullNameHint => 'Julianne Smith';

  @override
  String get registerEmailHint => 'curator@musafir.travel';

  @override
  String get registerPasswordLabel => 'PASSWORD';

  @override
  String get registerConfirmPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get registerTermsNotAccepted =>
      'Please accept the Terms of Service and Privacy Policy.';

  @override
  String get registerAccountCreated => 'Account created successfully!';

  @override
  String get registerCreateAccount => 'Create Account';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get registerLogIn => 'Log in';

  @override
  String get registerLoginArrow => 'Login →';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthModerate => 'Moderate';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String passwordStrengthLabel(String strength) {
    return 'Password strength: $strength';
  }

  @override
  String get termsAgreePrefix => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsAnd => ' and ';

  @override
  String get termsPrivacyPolicy => 'Privacy\nPolicy.';

  @override
  String fieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String passwordMinLength(int count) {
    return 'Password must be at least $count characters';
  }

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalid => 'Please enter a valid phone number';

  @override
  String get validationFieldFullName => 'Full name';

  @override
  String get validationFieldCurrentPassword => 'Current password';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorConnectionTimeout =>
      'Connection timed out. Please try again.';

  @override
  String get errorNoInternet =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorUnauthorized => 'Session expired. Please sign in again.';

  @override
  String get errorUnableUpdatePassword => 'Unable to update password';

  @override
  String get flightsTitle => 'Flights';

  @override
  String get flightsIntro =>
      'Mosafer connects your booking, ticket QR, departure planning, airport guidance, packing, todos and notifications in one travel assistant.';

  @override
  String get bookingHowTitle => 'HOW BOOKING WORKS';

  @override
  String get bookingStep1 => 'Open the booking website and choose your flight.';

  @override
  String get bookingStep2 =>
      'Complete the reservation and keep your ticket or QR image.';

  @override
  String get bookingStep3 =>
      'Return to Mosafer, scan or upload the ticket, then manage your trip.';

  @override
  String get openBookingWebsite => 'OPEN BOOKING WEBSITE';

  @override
  String get noActiveTripTitle => 'No active trip selected.';

  @override
  String get noActiveTripSubtitle =>
      'Open a trip or scan a ticket to start your guided journey.';

  @override
  String get scanTicket => 'Scan Ticket';

  @override
  String get sectionHome => 'Trip planners';

  @override
  String get stageHomeTitle => 'At home';

  @override
  String get stageHomeSubtitle => 'Plan route';

  @override
  String get stageOnWayTitle => 'On way';

  @override
  String get stageOnWaySubtitle => 'Live ETA';

  @override
  String get stageAirportTitle => 'At airport';

  @override
  String get stageAirportSubtitle => 'Gate ready';

  @override
  String get prepDepartureTitle => 'Plan departure from home';

  @override
  String get prepDepartureSubtitle =>
      'Get leave time, traffic buffer and map route.';

  @override
  String get prepTodosTitle => 'Trip todos and timeline';

  @override
  String get prepTodosSubtitle =>
      'Prepare documents, packing and airport tasks.';

  @override
  String boardingInMinutes(String minutes) {
    return 'Boarding in $minutes min';
  }

  @override
  String get flightMetaDate => 'DATE';

  @override
  String get flightMetaGate => 'GATE';

  @override
  String get flightMetaTerminal => 'TERMINAL';

  @override
  String get flightMetaSeat => 'SEAT';

  @override
  String get departurePlan => 'Departure Plan';

  @override
  String get packingList => 'Packing List';

  @override
  String get timeline => 'Timeline';

  @override
  String get todosLabel => 'Todos';

  @override
  String get attachmentsSection => 'ATTACHMENTS';

  @override
  String get twoFiles => '2 FILES';

  @override
  String get uploadAttachment => 'UPLOAD ATTACHMENT';

  @override
  String get openAirportExperience => 'OPEN AIRPORT EXPERIENCE';

  @override
  String get tripsSearchHint => 'Search by airport name or flight #';

  @override
  String get tripsUpcoming => 'Upcoming';

  @override
  String get tripsAll => 'All';

  @override
  String get tripsConfirmed => 'CONFIRMED';

  @override
  String get tripsCompleted => 'COMPLETED';

  @override
  String get tripsViewHistory => 'View History';

  @override
  String get tripsOpenTrip => 'View trip details';

  @override
  String get tripsExpired => 'Expired';

  @override
  String get tripsDeleteConfirmTitle => 'Delete ticket?';

  @override
  String get tripsDeleteConfirmBody =>
      'The ticket will move to the recycle bin. You can restore it from Settings.';

  @override
  String get tripsDeleteConfirm => 'Delete';

  @override
  String get tripsDeleteCancel => 'Cancel';

  @override
  String get settingsDeletedTrips => 'Recycle bin';

  @override
  String get settingsDeletedTripsSubtitle => 'Restore deleted tickets';

  @override
  String get deletedTripsTitle => 'Recycle bin';

  @override
  String get deletedTripsEmpty => 'No deleted tickets.';

  @override
  String get deletedTripsRestore => 'Restore';

  @override
  String get deletedTripsDeletePermanent => 'Delete permanently';

  @override
  String get deletedTripsDeleteConfirmTitle => 'Delete permanently?';

  @override
  String get deletedTripsDeleteConfirmBody => 'This ticket cannot be restored.';

  @override
  String get deletedTripsAutoPurgeNotice =>
      'Tickets are permanently removed 7 days after you delete them.';

  @override
  String get scanPastePayload => 'Paste ticket QR payload';

  @override
  String get scanPayloadHint => 'QR raw payload or ticket code';

  @override
  String get validateTicket => 'Validate Ticket';

  @override
  String get scanValidateTicketError => 'Unable to validate ticket.';

  @override
  String get scanTabScanQr => 'Scan QR';

  @override
  String get scanTabUploadImage => 'Upload Image';

  @override
  String get scanUploadTitle => 'Upload a ticket image';

  @override
  String get scanUploadBody =>
      'Choose a ticket or boarding pass from your gallery. Mosafer will read it and add the trip when it is valid.';

  @override
  String get scanChooseImage => 'Choose Image';

  @override
  String get scanChooseImageLoading => 'Reading ticket...';

  @override
  String get scanCenterQr => 'Center your ticket QR code within the\nframe.';

  @override
  String get scanScanNow => 'Scan Now';

  @override
  String get notificationsReadAll => 'Read All';

  @override
  String get notificationsNoYet => 'No notifications yet.';

  @override
  String get notificationsToday => 'TODAY';

  @override
  String get notificationsEarlier => 'EARLIER';

  @override
  String get timeAgoNow => 'now';

  @override
  String timeAgoMinutes(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeAgoDays(int days) {
    return '${days}d ago';
  }

  @override
  String get planDepartureSelectTrip => 'Select a trip';

  @override
  String get planDepartureSafeToLeave => 'SAFE TO LEAVE';

  @override
  String get planDepartureHeroSubtitle => 'Best time to leave for your flight';

  @override
  String get planDepartureTransportMode => 'TRANSPORT MODE';

  @override
  String get planDepartureModeCar => 'Car';

  @override
  String get planDepartureModeTrain => 'Train';

  @override
  String get planDepartureModeTaxi => 'Taxi';

  @override
  String get planDepartureTitle => 'Plan Departure';

  @override
  String get planDepartureRouteSummary => 'ROUTE SUMMARY';

  @override
  String planDepartureDemoRoute(String airportCode) {
    return 'Taksim Square → $airportCode airport';
  }

  @override
  String get planDepartureLiveTraffic => 'Live\nTraffic';

  @override
  String get planDepartureDistance => 'DISTANCE';

  @override
  String planDepartureDistanceValue(String km) {
    return '$km km';
  }

  @override
  String get trafficLow => 'Light traffic';

  @override
  String get trafficModerate => 'Moderate traffic';

  @override
  String get trafficHeavy => 'Heavy traffic';

  @override
  String get onWayTraffic => 'Traffic';

  @override
  String get onWayOpenInMaps => 'Open in Google Maps';

  @override
  String get planDepartureTravelTime => 'Road duration';

  @override
  String get planDepartureBuffer => 'SECURITY BUFFER';

  @override
  String get planDepartureNoTrainsInCountry =>
      'No trains available in this country';

  @override
  String get planDepartureEstArrival => 'EST. ARRIVAL';

  @override
  String get planDepartureUnitMinutes => 'min';

  @override
  String onWaySubtitle(String airportCode) {
    return 'From your current location to $airportCode airport';
  }

  @override
  String onWayDemoSubtitle(String airportCode) {
    return 'Demo route from Taksim Square to $airportCode airport';
  }

  @override
  String get packingLinenShirtDescription =>
      'Perfect for Dubai\'s\nevening breeze and\nhumidity.';

  @override
  String get openTripFirstSnackbar => 'Open a trip first.';

  @override
  String get openTripFirstAirportFull =>
      'Open a trip first to use Airport Experience.';

  @override
  String get unableOpenMaps => 'Unable to open maps on this device.';

  @override
  String get profileImageUpdated => 'Profile image updated.';

  @override
  String get unableUploadProfileImage => 'Unable to upload image.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileVoyagerTag => 'MUSAFIR VOYAGER';

  @override
  String get travelPreferences => 'TRAVEL PREFERENCES';

  @override
  String get fullNameLabel => 'NAME';

  @override
  String get emailAddressLabel => 'EMAIL ADDRESS';

  @override
  String get phoneNumberLabel => 'PHONE NUMBER';

  @override
  String get homeLocationLabel => 'HOME LOCATION';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordCurrentLabel => 'CURRENT PASSWORD';

  @override
  String get changePasswordCurrentHint => 'Enter current password';

  @override
  String get changePasswordNewLabel => 'NEW PASSWORD';

  @override
  String get changePasswordNewHint => 'Enter new password';

  @override
  String get changePasswordConfirmLabel => 'CONFIRM NEW PASSWORD';

  @override
  String get changePasswordConfirmHint => 'Re-enter new password';

  @override
  String get changePasswordSave => 'SAVE PASSWORD';

  @override
  String get changePasswordRepeatHint => 'Repeat new password';

  @override
  String get passwordStrengthMeterTitle => 'PASSWORD STRENGTH';

  @override
  String get passwordStrengthMeterWeak => 'WEAK';

  @override
  String get passwordStrengthMeterGood => 'GOOD';

  @override
  String get passwordStrengthMeterStrong => 'STRONG';

  @override
  String get safetyTipTitle => 'Safety Tip';

  @override
  String get safetyTipBody =>
      'Use a combination of letters, numbers,\nand symbols to create a stronger\npassword.';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profileTravelPreferences => 'Travel Preferences';

  @override
  String get profileAddPhone => 'Add phone number';

  @override
  String get profileFullNameLabel => 'NAME';

  @override
  String get profileEmailLabel => 'EMAIL ADDRESS';

  @override
  String get profilePhoneLabel => 'PHONE NUMBER';

  @override
  String get profileHomeLocationLabel => 'HOME LOCATION';

  @override
  String get airportConcierge => 'The Concierge';

  @override
  String get airportLiveExperience => 'LIVE EXPERIENCE';

  @override
  String airportWelcomeLine(String airportName, String terminal) {
    return 'Welcome to\n$airportName • $terminal';
  }

  @override
  String get airportAtAirportPill => 'AT\nAIRPORT';

  @override
  String get airportTerminalLabel => 'TERMINAL';

  @override
  String get airportAssignedGate => 'ASSIGNED GATE';

  @override
  String airportBoardingInMin(int minutes) {
    return 'Boarding in $minutes min';
  }

  @override
  String airportWalkEstimate(int minutes) {
    return 'Estimated $minutes min walk';
  }

  @override
  String airportWalkFollowSigns(String gate) {
    return 'Follow airport signs to $gate';
  }

  @override
  String get airportCurrentLocation => 'CURRENT LOCATION';

  @override
  String get airportYouPin => 'YOU';

  @override
  String get airportExpandMap => 'EXPAND MAP';

  @override
  String airportShopsNear(String gate) {
    return 'Shops near $gate';
  }

  @override
  String get airportNearGate => 'Near your gate';

  @override
  String get airportOpenNow => 'Open now';

  @override
  String airportProceedToGate(String gate) {
    return 'Proceed to $gate';
  }

  @override
  String get indoorMapTitle => 'Indoor Airport Map';

  @override
  String get indoorMapUnsupported =>
      'Indoor map is only available for Istanbul Airport (IST) at this time.';

  @override
  String indoorMapGateHighlight(String gate) {
    return 'Highlighted gate: $gate';
  }

  @override
  String indoorMapGoToGate(String gate) {
    return 'Go to $gate';
  }

  @override
  String get indoorMapHideRoute => 'Hide route';

  @override
  String indoorMapRouteTitle(String gate) {
    return 'Simulated route to $gate';
  }

  @override
  String indoorMapRouteEta(int minutes) {
    return '$minutes min';
  }

  @override
  String get indoorMapOpenLevelUpSource =>
      'Live OpenLevelUp indoor map from OpenStreetMap.';

  @override
  String get indoorMapOpenFullMap => 'Open full OSM map';

  @override
  String get indoorMapRetry => 'Retry';

  @override
  String get indoorMapBack => 'Go back';

  @override
  String get indoorMapLoading => 'Loading indoor map…';

  @override
  String indoorMapGateLevel(String gate, String level) {
    return 'Gate $gate · Level $level';
  }

  @override
  String get indoorMapRouteWrongLevel =>
      'Route is shown on the gate level only.';

  @override
  String indoorMapLevelBadge(String level) {
    return 'OpenLevelUp · IST · Level $level';
  }

  @override
  String indoorMapHighlightBadge(String level, String category) {
    return 'Level $level · $category highlights';
  }

  @override
  String indoorMapCoffeeNearGate(String gate) {
    return 'Coffee near $gate';
  }

  @override
  String indoorMapFoodNearGate(String gate) {
    return 'Quick bites near $gate';
  }

  @override
  String get indoorMapRouteStepEntrance => 'Entrance 7';

  @override
  String get indoorMapRouteStepSecurity => 'Security check';

  @override
  String get indoorMapRouteStepDutyFree => 'Duty Free hall';

  @override
  String get indoorMapRouteStepConcourse => 'Follow G concourse';

  @override
  String indoorMapRouteStepArrive(String gate) {
    return 'Arrive at gate $gate';
  }

  @override
  String get airportQrNoTicket =>
      'No boarding ticket found for the current booking.';

  @override
  String get airportQrInvalidTicket =>
      'This booking has a ticket, but QR payload is invalid.';

  @override
  String get airportLoungeFallback => 'Airport Lounge';

  @override
  String get airportCoffeeFallback => 'Coffee Shop';

  @override
  String get airportGateDash => 'Gate --';

  @override
  String get airportArrivedAtAirport => 'I arrived at the airport';

  @override
  String get airportArrivalStatusTitle => 'Airport arrival';

  @override
  String get airportCheckInTitle => 'Check-in';

  @override
  String get airportCheckInDisclaimer =>
      'Demo only — not a real airline check-in.';

  @override
  String airportCheckInGateLabel(String gate) {
    return 'Your gate: $gate';
  }

  @override
  String get airportCheckInStepArrived => 'Arrived at airport';

  @override
  String get airportCheckInStepStarted => 'Check-in started';

  @override
  String get airportCheckInStepBoardingPass => 'Boarding pass ready';

  @override
  String get airportCheckInStepSecurity => 'Proceed to security';

  @override
  String airportCheckInStepGoToGate(String gate) {
    return 'Go to gate $gate';
  }

  @override
  String get airportCheckInNextStep => 'Next step';

  @override
  String get airportCheckInReset => 'Reset';

  @override
  String airportOpenGateMap(String gate) {
    return 'Open gate map';
  }

  @override
  String get onWayTitle => 'On way';

  @override
  String get onWayStartNavigation => 'START NAVIGATION';

  @override
  String get onWayTrackingStarted => 'TRACKING STARTED';

  @override
  String get onWayLocationUnavailable =>
      'Location permission or service is not available.';

  @override
  String get onWayTrackingActive => 'Live tracking is active.';

  @override
  String get onWayYou => 'YOU';

  @override
  String get onWayLiveConnected => 'Live location connected';

  @override
  String get onWayPressStart =>
      'Press Start Navigation to connect live location';

  @override
  String get onWayDemoOriginName => 'Taksim Square';

  @override
  String get onWayDemoOriginActive =>
      'Using Taksim Square as the demo start point';

  @override
  String get onWayDistance => 'Distance';

  @override
  String get onWayEta => 'ETA';

  @override
  String get onWayTracking => 'Tracking';

  @override
  String get onWayTrackingActiveState => 'Active';

  @override
  String get onWayTrackingNotStarted => 'Not started';

  @override
  String get onWayDepartureAddressTitle => 'Departure address';

  @override
  String get onWayDepartureAddressSubtitle =>
      'Choose GPS or enter your home address for route planning.';

  @override
  String get onWayUseCurrentLocation => 'Current location (GPS)';

  @override
  String get onWayUseCurrentLocationHint => 'Use live GPS when available';

  @override
  String get onWayUseSavedAddress => 'My saved address';

  @override
  String get onWaySavedAddressReady => 'Saved address ready';

  @override
  String get onWaySavedAddressMissing => 'Add an address below first';

  @override
  String get onWayManualOriginActive =>
      'Using your saved address as the start point';

  @override
  String onWayManualSubtitle(String airportCode) {
    return 'From your saved address to $airportCode airport';
  }

  @override
  String get onWayDepartureFrom => 'Starting from';

  @override
  String get onWayChangeAddress => 'Change';

  @override
  String get homeAddressHint => 'Street, city, country';

  @override
  String get homeAddressSave => 'Save address';

  @override
  String get homeAddressTooShort => 'Enter at least 3 characters';

  @override
  String get homeAddressGeocodeFailed =>
      'Could not find that address. Try adding city and country.';

  @override
  String get homeAddressSaved => 'Home address saved';

  @override
  String get flightWeatherTitle => 'FLIGHT DAY WEATHER';

  @override
  String flightWeatherDepartureDay(String city) {
    return 'Departure · $city';
  }

  @override
  String flightWeatherArrivalDay(String city) {
    return 'Arrival · $city';
  }

  @override
  String flightWeatherBufferAdded(int minutes) {
    return '+$minutes min added for weather conditions';
  }

  @override
  String get timelineJourneyTag => 'MUSAFIR JOURNEY';

  @override
  String get timelineYourJourney => 'Your Journey';

  @override
  String get addingEllipsis => 'Adding...';

  @override
  String addSelectedToTodos(int count) {
    return 'Add $count selected to Todos';
  }

  @override
  String addSelectedToTripTodos(int count) {
    return 'Add $count selected to Trip Todos';
  }

  @override
  String get packingOpenTripFirst => 'Open a trip first.';

  @override
  String get timelineOpenTripFirst => 'Open a trip first.';

  @override
  String get packingLoading => 'Generating your packing list...';

  @override
  String get timelineLoading => 'Generating your journey timeline...';

  @override
  String get packingLoadFailed => 'Could not load packing list.';

  @override
  String get timelineLoadFailed => 'Could not load timeline.';

  @override
  String get timelineNoUpcomingTasks =>
      'No upcoming timeline tasks for this trip.';

  @override
  String get packingRetry => 'Retry';

  @override
  String get timelineRetry => 'Retry';

  @override
  String timelineDayBefore(int days) {
    return 'D-$days';
  }

  @override
  String get todosOpenTripFirst => 'Open a trip first.';

  @override
  String get todosOpenTripFirstView => 'Open a trip first to view its todos.';

  @override
  String get todoAddTitle => 'Add Todo';

  @override
  String get todoEditTitle => 'Edit Todo';

  @override
  String get todoTitleHint => 'Todo title';

  @override
  String get todoAdded => 'Todo added.';

  @override
  String get todosEmptyDefault => 'No todos in this category yet.';

  @override
  String get todosAddTodo => 'Add Todo';

  @override
  String get todosCategoryAll => 'All';

  @override
  String get todosCategoryPacking => 'Packing';

  @override
  String get todosCategoryDocuments => 'Documents';

  @override
  String get todosTabDocuments => 'DOCUMENTS';

  @override
  String get todosTabPacking => 'PACKING';

  @override
  String get todosTabLogistics => 'LOGISTICS';

  @override
  String get tripTaskDefault => 'Trip task';

  @override
  String get packingMustHave => 'Must-have';

  @override
  String get packingAllItemsInTodos =>
      'All packing items are already in your trip todos.';

  @override
  String packingWeatherSummary(
    int days,
    String city,
    String condition,
    int temp,
  ) {
    return '$days days in $city • $condition • $temp°C';
  }

  @override
  String get weatherClear => 'Sunny';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get packingRecommended => 'Recommended';

  @override
  String get packingOptional => 'Optional';

  @override
  String get packingTagCrucial => 'CRUCIAL';

  @override
  String get packingOptionalTag => 'OPTIONAL';

  @override
  String get packingResortDay => 'RESORT DAY';

  @override
  String get packingTransitLeisure => 'TRANSIT LEISURE';

  @override
  String get packingItemPassport => 'Passport';

  @override
  String get packingItemFlightTickets => 'Flight Tickets';

  @override
  String get packingItemPowerAdapter => 'Power Adapter';

  @override
  String get packingItemSunglasses => 'Sunglasses';

  @override
  String get packingItemSunscreen => 'Sunscreen';

  @override
  String get packingItemSwimwear => 'Swimwear';

  @override
  String get packingItemReadingBook => 'Reading Book';

  @override
  String get packingItemLinenShirt => 'Light Linen Shirt';

  @override
  String get timelineTaskPassport => 'Check Passport Validity';

  @override
  String get timelineTaskVisa => 'Apply for Entry Visa';

  @override
  String get timelineTaskSecurity => 'Schedule Home Security';

  @override
  String get timelineTaskPet => 'Arrange Pet Boarding';

  @override
  String get timelineTaskPacking => 'Complete All Packing List';

  @override
  String get timelineTaskTaxi => 'Book Airport Taxi';

  @override
  String get timelineDay14 => 'D-14';

  @override
  String get timelineDay7 => 'D-7';

  @override
  String get timelineDay1 => 'D-1';

  @override
  String get timelineBadgeDocument => 'DOCUMENT';

  @override
  String get timelineBadgeTask => 'TASK';

  @override
  String get timelineBadgePacking => 'PACKING';

  @override
  String get timelineTitleDocuments => 'Travel Documents';

  @override
  String get timelineTitlePreparation => 'Preparation';

  @override
  String get timelineTitlePacking => 'Packing & Logistics';

  @override
  String get ticketBoardingPass => 'BOARDING PASS';

  @override
  String get ticketScanForBoarding => 'Scan for Boarding';

  @override
  String get ticketSafeWorkSecure => 'Safe work\nsecure';

  @override
  String get ticketDirect => 'DIRECT';

  @override
  String get ticketDeparture => 'DEPARTURE';

  @override
  String timelineItemsAddedToTodos(int count) {
    return '$count timeline items added to todos.';
  }

  @override
  String packingItemsAddedToTodos(int count) {
    return '$count packing items added to todos.';
  }
}
