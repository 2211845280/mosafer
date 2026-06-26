import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mosafer'**
  String get appTitle;

  /// No description provided for @brandMosafer.
  ///
  /// In en, this message translates to:
  /// **'Mosafer'**
  String get brandMosafer;

  /// No description provided for @navFlights.
  ///
  /// In en, this message translates to:
  /// **'FLIGHTS'**
  String get navFlights;

  /// No description provided for @navMyTrips.
  ///
  /// In en, this message translates to:
  /// **'MY TRIPS'**
  String get navMyTrips;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get navProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'SEE ALL'**
  String get seeAll;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION SETTINGS'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsDisplaySection.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY SETTINGS'**
  String get settingsDisplaySection;

  /// No description provided for @settingsThemeTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsThemeTileTitle;

  /// No description provided for @settingsThemeTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark appearance'**
  String get settingsThemeTileSubtitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsAccountSection;

  /// No description provided for @settingsNotificationTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settingsNotificationTileTitle;

  /// No description provided for @settingsNotificationTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay updated on your flights'**
  String get settingsNotificationTileSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsSwitchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get settingsSwitchAccount;

  /// No description provided for @settingsSwitchAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a different email'**
  String get settingsSwitchAccountSubtitle;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language and layout direction'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsChooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsChooseLanguageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @travelerDefault.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get travelerDefault;

  /// No description provided for @mosaferAccountDefault.
  ///
  /// In en, this message translates to:
  /// **'Mosafer account'**
  String get mosaferAccountDefault;

  /// No description provided for @settingsEditProfileTwoLines.
  ///
  /// In en, this message translates to:
  /// **'Edit personal profile'**
  String get settingsEditProfileTwoLines;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'YOUR DIGITAL CURATOR FOR THE UNKNOWN'**
  String get loginTagline;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'voyager@ethereal.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'SECURITY KEY'**
  String get loginPasswordLabel;

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgot;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login to Mosafer'**
  String get loginButton;

  /// No description provided for @loginNewToVoyage.
  ///
  /// In en, this message translates to:
  /// **'New to the voyage? '**
  String get loginNewToVoyage;

  /// No description provided for @loginRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get loginRegisterNow;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated. You can sign in now.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'This reset link is invalid or has expired.'**
  String get resetPasswordInvalidLink;

  /// No description provided for @registerStartJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your journey.'**
  String get registerStartJourneyTitle;

  /// No description provided for @registerJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our community of global curators.'**
  String get registerJoinCommunity;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get registerFullNameLabel;

  /// No description provided for @registerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Julianne Smith'**
  String get registerFullNameHint;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'curator@musafir.travel'**
  String get registerEmailHint;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get registerPasswordLabel;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerTermsNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy.'**
  String get registerTermsNotAccepted;

  /// No description provided for @registerAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please verify your email.'**
  String get registerAccountCreated;

  /// No description provided for @registerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerCreateAccount;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLogIn;

  /// No description provided for @registerLoginArrow.
  ///
  /// In en, this message translates to:
  /// **'Login →'**
  String get registerLoginArrow;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get passwordStrengthModerate;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {strength}'**
  String passwordStrengthLabel(String strength);

  /// No description provided for @termsAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get termsAgreePrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAnd;

  /// No description provided for @termsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy\nPolicy.'**
  String get termsPrivacyPolicy;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String fieldRequired(String fieldName);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {count} characters'**
  String passwordMinLength(int count);

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneInvalid;

  /// No description provided for @validationFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get validationFieldFullName;

  /// No description provided for @validationFieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get validationFieldCurrentPassword;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get errorConnectionTimeout;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorUnableUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Unable to update password'**
  String get errorUnableUpdatePassword;

  /// No description provided for @errorSeatAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This seat is already taken'**
  String get errorSeatAlreadyTaken;

  /// No description provided for @errorSeatNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This seat is no longer available'**
  String get errorSeatNoLongerAvailable;

  /// No description provided for @errorSeatNotInBooking.
  ///
  /// In en, this message translates to:
  /// **'Seat is not part of this booking'**
  String get errorSeatNotInBooking;

  /// No description provided for @errorDuplicateSeats.
  ///
  /// In en, this message translates to:
  /// **'Duplicate seat numbers in the same booking'**
  String get errorDuplicateSeats;

  /// No description provided for @errorInvalidSeatFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid seat format (use row 1-99 and letter A-F, e.g. 12A)'**
  String get errorInvalidSeatFormat;

  /// No description provided for @errorCheckoutExpired.
  ///
  /// In en, this message translates to:
  /// **'Checkout session expired'**
  String get errorCheckoutExpired;

  /// No description provided for @errorPassengerDetailsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Passenger details already submitted'**
  String get errorPassengerDetailsSubmitted;

  /// No description provided for @errorReservationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Reservation not found'**
  String get errorReservationNotFound;

  /// No description provided for @errorNotYourReservation.
  ///
  /// In en, this message translates to:
  /// **'Not your reservation'**
  String get errorNotYourReservation;

  /// No description provided for @errorAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Already cancelled'**
  String get errorAlreadyCancelled;

  /// No description provided for @errorCannotCancelPastFlight.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel a past flight'**
  String get errorCannotCancelPastFlight;

  /// No description provided for @errorDuplicatePassports.
  ///
  /// In en, this message translates to:
  /// **'Duplicate passport numbers in the same booking'**
  String get errorDuplicatePassports;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before logging in.'**
  String get errorEmailNotVerified;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account is disabled.'**
  String get errorAccountDisabled;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Ensure the API is running.'**
  String get errorServerUnavailable;

  /// No description provided for @errorEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists'**
  String get errorEmailAlreadyExists;

  /// No description provided for @errorCurrentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get errorCurrentPasswordIncorrect;

  /// No description provided for @flightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flightsTitle;

  /// No description provided for @flightsIntro.
  ///
  /// In en, this message translates to:
  /// **'Mosafer connects your booking, ticket QR, departure planning, airport guidance, packing, todos and notifications in one travel assistant.'**
  String get flightsIntro;

  /// No description provided for @bookingHowTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW BOOKING WORKS'**
  String get bookingHowTitle;

  /// No description provided for @bookingStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the booking website and choose your flight.'**
  String get bookingStep1;

  /// No description provided for @bookingStep2.
  ///
  /// In en, this message translates to:
  /// **'Complete the reservation and keep your ticket or QR image.'**
  String get bookingStep2;

  /// No description provided for @bookingStep3.
  ///
  /// In en, this message translates to:
  /// **'Return to Mosafer, scan or upload the ticket, then manage your trip.'**
  String get bookingStep3;

  /// No description provided for @openBookingWebsite.
  ///
  /// In en, this message translates to:
  /// **'OPEN BOOKING WEBSITE'**
  String get openBookingWebsite;

  /// No description provided for @noActiveTripTitle.
  ///
  /// In en, this message translates to:
  /// **'No active trip selected.'**
  String get noActiveTripTitle;

  /// No description provided for @noActiveTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a trip or scan a ticket to start your guided journey.'**
  String get noActiveTripSubtitle;

  /// No description provided for @scanTicket.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket'**
  String get scanTicket;

  /// No description provided for @sectionHome.
  ///
  /// In en, this message translates to:
  /// **'Trip planners'**
  String get sectionHome;

  /// No description provided for @stageHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get stageHomeTitle;

  /// No description provided for @stageHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan route'**
  String get stageHomeSubtitle;

  /// No description provided for @stageOnWayTitle.
  ///
  /// In en, this message translates to:
  /// **'On way'**
  String get stageOnWayTitle;

  /// No description provided for @stageOnWaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live ETA'**
  String get stageOnWaySubtitle;

  /// No description provided for @stageAirportTitle.
  ///
  /// In en, this message translates to:
  /// **'At airport'**
  String get stageAirportTitle;

  /// No description provided for @stageAirportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gate ready'**
  String get stageAirportSubtitle;

  /// No description provided for @prepDepartureTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan departure from home'**
  String get prepDepartureTitle;

  /// No description provided for @prepDepartureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get leave time, traffic buffer and map route.'**
  String get prepDepartureSubtitle;

  /// No description provided for @prepTodosTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip todos and timeline'**
  String get prepTodosTitle;

  /// No description provided for @prepTodosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare documents, packing and airport tasks.'**
  String get prepTodosSubtitle;

  /// No description provided for @boardingInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Boarding in {minutes} min'**
  String boardingInMinutes(String minutes);

  /// No description provided for @flightMetaDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get flightMetaDate;

  /// No description provided for @flightMetaGate.
  ///
  /// In en, this message translates to:
  /// **'GATE'**
  String get flightMetaGate;

  /// No description provided for @flightMetaTerminal.
  ///
  /// In en, this message translates to:
  /// **'TERMINAL'**
  String get flightMetaTerminal;

  /// No description provided for @flightMetaSeat.
  ///
  /// In en, this message translates to:
  /// **'SEAT'**
  String get flightMetaSeat;

  /// No description provided for @departurePlan.
  ///
  /// In en, this message translates to:
  /// **'Departure Plan'**
  String get departurePlan;

  /// No description provided for @packingList.
  ///
  /// In en, this message translates to:
  /// **'Packing List'**
  String get packingList;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @todosLabel.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todosLabel;

  /// No description provided for @attachmentsSection.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS'**
  String get attachmentsSection;

  /// No description provided for @twoFiles.
  ///
  /// In en, this message translates to:
  /// **'2 FILES'**
  String get twoFiles;

  /// No description provided for @uploadAttachment.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD ATTACHMENT'**
  String get uploadAttachment;

  /// No description provided for @openAirportExperience.
  ///
  /// In en, this message translates to:
  /// **'OPEN AIRPORT EXPERIENCE'**
  String get openAirportExperience;

  /// No description provided for @tripsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by airport name or flight #'**
  String get tripsSearchHint;

  /// No description provided for @tripsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripsUpcoming;

  /// No description provided for @tripsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tripsAll;

  /// No description provided for @tripsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get tripsConfirmed;

  /// No description provided for @tripsCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get tripsCompleted;

  /// No description provided for @tripsViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get tripsViewHistory;

  /// No description provided for @tripsOpenTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip details'**
  String get tripsOpenTrip;

  /// No description provided for @tripsExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get tripsExpired;

  /// No description provided for @tripsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket?'**
  String get tripsDeleteConfirmTitle;

  /// No description provided for @tripsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The ticket will move to the recycle bin. You can restore it from Settings.'**
  String get tripsDeleteConfirmBody;

  /// No description provided for @tripsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tripsDeleteConfirm;

  /// No description provided for @tripsDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tripsDeleteCancel;

  /// No description provided for @settingsDeletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get settingsDeletedTrips;

  /// No description provided for @settingsDeletedTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore deleted tickets'**
  String get settingsDeletedTripsSubtitle;

  /// No description provided for @deletedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get deletedTripsTitle;

  /// No description provided for @deletedTripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deleted tickets.'**
  String get deletedTripsEmpty;

  /// No description provided for @deletedTripsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get deletedTripsRestore;

  /// No description provided for @deletedTripsDeletePermanent.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletedTripsDeletePermanent;

  /// No description provided for @deletedTripsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get deletedTripsDeleteConfirmTitle;

  /// No description provided for @deletedTripsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This ticket cannot be restored.'**
  String get deletedTripsDeleteConfirmBody;

  /// No description provided for @deletedTripsAutoPurgeNotice.
  ///
  /// In en, this message translates to:
  /// **'Tickets are permanently removed 7 days after you delete them.'**
  String get deletedTripsAutoPurgeNotice;

  /// No description provided for @scanPastePayload.
  ///
  /// In en, this message translates to:
  /// **'Paste ticket QR payload'**
  String get scanPastePayload;

  /// No description provided for @scanPayloadHint.
  ///
  /// In en, this message translates to:
  /// **'QR raw payload or ticket code'**
  String get scanPayloadHint;

  /// No description provided for @validateTicket.
  ///
  /// In en, this message translates to:
  /// **'Validate Ticket'**
  String get validateTicket;

  /// No description provided for @scanTicketAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ticket added successfully.'**
  String get scanTicketAddedSuccess;

  /// No description provided for @scanValidateTicketError.
  ///
  /// In en, this message translates to:
  /// **'Unable to validate ticket.'**
  String get scanValidateTicketError;

  /// No description provided for @scanNoQrInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code was found in this image.'**
  String get scanNoQrInImage;

  /// No description provided for @scanTicketNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching ticket was found in our records.'**
  String get scanTicketNotFound;

  /// No description provided for @scanTicketInvalid.
  ///
  /// In en, this message translates to:
  /// **'This ticket is not valid or could not be read.'**
  String get scanTicketInvalid;

  /// No description provided for @scanTicketExpired.
  ///
  /// In en, this message translates to:
  /// **'This ticket has expired.'**
  String get scanTicketExpired;

  /// No description provided for @scanTicketAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'This ticket is already linked to another account.'**
  String get scanTicketAlreadyAssigned;

  /// No description provided for @scanImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the ticket image. Please try again.'**
  String get scanImageUploadError;

  /// No description provided for @scanTabScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanTabScanQr;

  /// No description provided for @scanTabUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get scanTabUploadImage;

  /// No description provided for @scanUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a ticket image'**
  String get scanUploadTitle;

  /// No description provided for @scanUploadBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a ticket or boarding pass from your gallery. Mosafer will read it and add the trip when it is valid.'**
  String get scanUploadBody;

  /// No description provided for @scanChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get scanChooseImage;

  /// No description provided for @scanChooseImageLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading ticket...'**
  String get scanChooseImageLoading;

  /// No description provided for @scanCenterQr.
  ///
  /// In en, this message translates to:
  /// **'Center your ticket QR code within the\nframe.'**
  String get scanCenterQr;

  /// No description provided for @scanScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan Now'**
  String get scanScanNow;

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get notificationsReadAll;

  /// No description provided for @notificationsNoYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsNoYet;

  /// No description provided for @notificationsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this notification?'**
  String get notificationsDeleteConfirm;

  /// No description provided for @notificationsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationsDelete;

  /// No description provided for @notificationsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notificationsCancel;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get notificationsToday;

  /// No description provided for @notificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get notificationsEarlier;

  /// No description provided for @timeAgoNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeAgoMinutes(int minutes);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeAgoHours(int hours);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeAgoDays(int days);

  /// No description provided for @planDepartureSelectTrip.
  ///
  /// In en, this message translates to:
  /// **'Select a trip'**
  String get planDepartureSelectTrip;

  /// No description provided for @planDepartureSafeToLeave.
  ///
  /// In en, this message translates to:
  /// **'SAFE TO LEAVE'**
  String get planDepartureSafeToLeave;

  /// No description provided for @planDepartureHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best time to leave for your flight'**
  String get planDepartureHeroSubtitle;

  /// No description provided for @planDepartureTransportMode.
  ///
  /// In en, this message translates to:
  /// **'TRANSPORT MODE'**
  String get planDepartureTransportMode;

  /// No description provided for @planDepartureModeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get planDepartureModeCar;

  /// No description provided for @planDepartureModeTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get planDepartureModeTrain;

  /// No description provided for @planDepartureModeTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get planDepartureModeTaxi;

  /// No description provided for @planDepartureTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Departure'**
  String get planDepartureTitle;

  /// No description provided for @planDepartureRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'ROUTE SUMMARY'**
  String get planDepartureRouteSummary;

  /// No description provided for @planDepartureDemoRoute.
  ///
  /// In en, this message translates to:
  /// **'Taksim Square → {airportCode} airport'**
  String planDepartureDemoRoute(String airportCode);

  /// No description provided for @planDepartureLiveTraffic.
  ///
  /// In en, this message translates to:
  /// **'Live\nTraffic'**
  String get planDepartureLiveTraffic;

  /// No description provided for @planDepartureDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get planDepartureDistance;

  /// No description provided for @planDepartureDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String planDepartureDistanceValue(String km);

  /// No description provided for @trafficLow.
  ///
  /// In en, this message translates to:
  /// **'Light traffic'**
  String get trafficLow;

  /// No description provided for @trafficModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate traffic'**
  String get trafficModerate;

  /// No description provided for @trafficHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy traffic'**
  String get trafficHeavy;

  /// No description provided for @onWayTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get onWayTraffic;

  /// No description provided for @onWayOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get onWayOpenInMaps;

  /// No description provided for @onWayExpandMap.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get onWayExpandMap;

  /// No description provided for @planDepartureTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Road duration'**
  String get planDepartureTravelTime;

  /// No description provided for @planDepartureBuffer.
  ///
  /// In en, this message translates to:
  /// **'SECURITY BUFFER'**
  String get planDepartureBuffer;

  /// No description provided for @planDepartureNoTrainsInCountry.
  ///
  /// In en, this message translates to:
  /// **'No trains available in this country'**
  String get planDepartureNoTrainsInCountry;

  /// No description provided for @planDepartureEstArrival.
  ///
  /// In en, this message translates to:
  /// **'EST. ARRIVAL'**
  String get planDepartureEstArrival;

  /// No description provided for @planDepartureUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get planDepartureUnitMinutes;

  /// No description provided for @onWaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'From your current location to {airportCode} airport'**
  String onWaySubtitle(String airportCode);

  /// No description provided for @onWayDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Route from Taksim Square to {airportCode} airport'**
  String onWayDemoSubtitle(String airportCode);

  /// No description provided for @packingLinenShirtDescription.
  ///
  /// In en, this message translates to:
  /// **'Perfect for Dubai\'s\nevening breeze and\nhumidity.'**
  String get packingLinenShirtDescription;

  /// No description provided for @openTripFirstSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first.'**
  String get openTripFirstSnackbar;

  /// No description provided for @openTripFirstAirportFull.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first to use Airport Experience.'**
  String get openTripFirstAirportFull;

  /// No description provided for @unableOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Unable to open maps on this device.'**
  String get unableOpenMaps;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated.'**
  String get profileImageUpdated;

  /// No description provided for @unableUploadProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload image.'**
  String get unableUploadProfileImage;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileVoyagerTag.
  ///
  /// In en, this message translates to:
  /// **'MUSAFIR VOYAGER'**
  String get editProfileVoyagerTag;

  /// No description provided for @travelPreferences.
  ///
  /// In en, this message translates to:
  /// **'TRAVEL PREFERENCES'**
  String get travelPreferences;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get fullNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddressLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phoneNumberLabel;

  /// No description provided for @homeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'HOME LOCATION'**
  String get homeLocationLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PASSWORD'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get changePasswordCurrentHint;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get changePasswordNewHint;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM NEW PASSWORD'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get changePasswordConfirmHint;

  /// No description provided for @changePasswordSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE PASSWORD'**
  String get changePasswordSave;

  /// No description provided for @changePasswordRepeatHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get changePasswordRepeatHint;

  /// No description provided for @passwordStrengthMeterTitle.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD STRENGTH'**
  String get passwordStrengthMeterTitle;

  /// No description provided for @passwordStrengthMeterWeak.
  ///
  /// In en, this message translates to:
  /// **'WEAK'**
  String get passwordStrengthMeterWeak;

  /// No description provided for @passwordStrengthMeterGood.
  ///
  /// In en, this message translates to:
  /// **'GOOD'**
  String get passwordStrengthMeterGood;

  /// No description provided for @passwordStrengthMeterStrong.
  ///
  /// In en, this message translates to:
  /// **'STRONG'**
  String get passwordStrengthMeterStrong;

  /// No description provided for @safetyTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Tip'**
  String get safetyTipTitle;

  /// No description provided for @safetyTipBody.
  ///
  /// In en, this message translates to:
  /// **'Use a combination of letters, numbers,\nand symbols to create a stronger\npassword.'**
  String get safetyTipBody;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// No description provided for @profileTravelPreferences.
  ///
  /// In en, this message translates to:
  /// **'Travel Preferences'**
  String get profileTravelPreferences;

  /// No description provided for @profileAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get profileAddPhone;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get profileFullNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get profileEmailLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get profilePhoneLabel;

  /// No description provided for @profileHomeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'HOME LOCATION'**
  String get profileHomeLocationLabel;

  /// No description provided for @airportConcierge.
  ///
  /// In en, this message translates to:
  /// **'The Concierge'**
  String get airportConcierge;

  /// No description provided for @airportLiveExperience.
  ///
  /// In en, this message translates to:
  /// **'LIVE EXPERIENCE'**
  String get airportLiveExperience;

  /// No description provided for @airportWelcomeLine.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\n{airportName} • {terminal}'**
  String airportWelcomeLine(String airportName, String terminal);

  /// No description provided for @airportAtAirportPill.
  ///
  /// In en, this message translates to:
  /// **'AT\nAIRPORT'**
  String get airportAtAirportPill;

  /// No description provided for @airportTerminalLabel.
  ///
  /// In en, this message translates to:
  /// **'TERMINAL'**
  String get airportTerminalLabel;

  /// No description provided for @airportAssignedGate.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED GATE'**
  String get airportAssignedGate;

  /// No description provided for @airportBoardingInMin.
  ///
  /// In en, this message translates to:
  /// **'Boarding in {minutes} min'**
  String airportBoardingInMin(int minutes);

  /// No description provided for @airportWalkEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated {minutes} min walk'**
  String airportWalkEstimate(int minutes);

  /// No description provided for @airportWalkFollowSigns.
  ///
  /// In en, this message translates to:
  /// **'Follow airport signs to {gate}'**
  String airportWalkFollowSigns(String gate);

  /// No description provided for @airportCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LOCATION'**
  String get airportCurrentLocation;

  /// No description provided for @airportYouPin.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get airportYouPin;

  /// No description provided for @airportExpandMap.
  ///
  /// In en, this message translates to:
  /// **'EXPAND MAP'**
  String get airportExpandMap;

  /// No description provided for @airportShopsNear.
  ///
  /// In en, this message translates to:
  /// **'Shops near {gate}'**
  String airportShopsNear(String gate);

  /// No description provided for @airportNearGate.
  ///
  /// In en, this message translates to:
  /// **'Near your gate'**
  String get airportNearGate;

  /// No description provided for @airportOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get airportOpenNow;

  /// No description provided for @airportProceedToGate.
  ///
  /// In en, this message translates to:
  /// **'Proceed to {gate}'**
  String airportProceedToGate(String gate);

  /// No description provided for @indoorMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Indoor Airport Map'**
  String get indoorMapTitle;

  /// No description provided for @indoorMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Indoor map is only available for Istanbul Airport (IST) at this time.'**
  String get indoorMapUnsupported;

  /// No description provided for @indoorMapGateHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlighted gate: {gate}'**
  String indoorMapGateHighlight(String gate);

  /// No description provided for @indoorMapGoToGate.
  ///
  /// In en, this message translates to:
  /// **'Go to {gate}'**
  String indoorMapGoToGate(String gate);

  /// No description provided for @indoorMapHideRoute.
  ///
  /// In en, this message translates to:
  /// **'Hide route'**
  String get indoorMapHideRoute;

  /// No description provided for @indoorMapRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulated route to {gate}'**
  String indoorMapRouteTitle(String gate);

  /// No description provided for @indoorMapRouteEta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String indoorMapRouteEta(int minutes);

  /// No description provided for @indoorMapOpenLevelUpSource.
  ///
  /// In en, this message translates to:
  /// **'Live OpenLevelUp indoor map from OpenStreetMap.'**
  String get indoorMapOpenLevelUpSource;

  /// No description provided for @indoorMapOpenFullMap.
  ///
  /// In en, this message translates to:
  /// **'Open full OSM map'**
  String get indoorMapOpenFullMap;

  /// No description provided for @indoorMapRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get indoorMapRetry;

  /// No description provided for @indoorMapBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get indoorMapBack;

  /// No description provided for @indoorMapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading indoor map…'**
  String get indoorMapLoading;

  /// No description provided for @indoorMapGateLevel.
  ///
  /// In en, this message translates to:
  /// **'Gate {gate} · Level {level}'**
  String indoorMapGateLevel(String gate, String level);

  /// No description provided for @indoorMapRouteWrongLevel.
  ///
  /// In en, this message translates to:
  /// **'Route is shown on the gate level only.'**
  String get indoorMapRouteWrongLevel;

  /// No description provided for @indoorMapLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'OpenLevelUp · IST · Level {level}'**
  String indoorMapLevelBadge(String level);

  /// No description provided for @indoorMapHighlightBadge.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {category} highlights'**
  String indoorMapHighlightBadge(String level, String category);

  /// No description provided for @indoorMapCoffeeNearGate.
  ///
  /// In en, this message translates to:
  /// **'Coffee near {gate}'**
  String indoorMapCoffeeNearGate(String gate);

  /// No description provided for @indoorMapFoodNearGate.
  ///
  /// In en, this message translates to:
  /// **'Quick bites near {gate}'**
  String indoorMapFoodNearGate(String gate);

  /// No description provided for @indoorMapRouteStepEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance 7'**
  String get indoorMapRouteStepEntrance;

  /// No description provided for @indoorMapRouteStepSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security check'**
  String get indoorMapRouteStepSecurity;

  /// No description provided for @indoorMapRouteStepDutyFree.
  ///
  /// In en, this message translates to:
  /// **'Duty Free hall'**
  String get indoorMapRouteStepDutyFree;

  /// No description provided for @indoorMapRouteStepConcourse.
  ///
  /// In en, this message translates to:
  /// **'Follow G concourse'**
  String get indoorMapRouteStepConcourse;

  /// No description provided for @indoorMapRouteStepArrive.
  ///
  /// In en, this message translates to:
  /// **'Arrive at gate {gate}'**
  String indoorMapRouteStepArrive(String gate);

  /// No description provided for @airportQrNoTicket.
  ///
  /// In en, this message translates to:
  /// **'No boarding ticket found for the current booking.'**
  String get airportQrNoTicket;

  /// No description provided for @airportQrInvalidTicket.
  ///
  /// In en, this message translates to:
  /// **'This booking has a ticket, but QR payload is invalid.'**
  String get airportQrInvalidTicket;

  /// No description provided for @airportLoungeFallback.
  ///
  /// In en, this message translates to:
  /// **'Airport Lounge'**
  String get airportLoungeFallback;

  /// No description provided for @airportCoffeeFallback.
  ///
  /// In en, this message translates to:
  /// **'Coffee Shop'**
  String get airportCoffeeFallback;

  /// No description provided for @airportGateDash.
  ///
  /// In en, this message translates to:
  /// **'Gate --'**
  String get airportGateDash;

  /// No description provided for @airportArrivedAtAirport.
  ///
  /// In en, this message translates to:
  /// **'I arrived at the airport'**
  String get airportArrivedAtAirport;

  /// No description provided for @airportArrivalStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Airport arrival'**
  String get airportArrivalStatusTitle;

  /// No description provided for @airportCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get airportCheckInTitle;

  /// No description provided for @airportCheckInDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Demo only — not a real airline check-in.'**
  String get airportCheckInDisclaimer;

  /// No description provided for @airportCheckInGateLabel.
  ///
  /// In en, this message translates to:
  /// **'Your gate: {gate}'**
  String airportCheckInGateLabel(String gate);

  /// No description provided for @airportCheckInStepArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived at airport'**
  String get airportCheckInStepArrived;

  /// No description provided for @airportCheckInStepStarted.
  ///
  /// In en, this message translates to:
  /// **'Check-in started'**
  String get airportCheckInStepStarted;

  /// No description provided for @airportCheckInStepBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'Boarding pass ready'**
  String get airportCheckInStepBoardingPass;

  /// No description provided for @airportCheckInStepSecurity.
  ///
  /// In en, this message translates to:
  /// **'Proceed to security'**
  String get airportCheckInStepSecurity;

  /// No description provided for @airportCheckInStepGoToGate.
  ///
  /// In en, this message translates to:
  /// **'Go to gate {gate}'**
  String airportCheckInStepGoToGate(String gate);

  /// No description provided for @airportCheckInNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get airportCheckInNextStep;

  /// No description provided for @airportCheckInReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get airportCheckInReset;

  /// No description provided for @airportOpenGateMap.
  ///
  /// In en, this message translates to:
  /// **'Open gate map'**
  String airportOpenGateMap(String gate);

  /// No description provided for @onWayTitle.
  ///
  /// In en, this message translates to:
  /// **'On way'**
  String get onWayTitle;

  /// No description provided for @onWayStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'START NAVIGATION'**
  String get onWayStartNavigation;

  /// No description provided for @onWayTrackingStarted.
  ///
  /// In en, this message translates to:
  /// **'TRACKING STARTED'**
  String get onWayTrackingStarted;

  /// No description provided for @onWayLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location permission or service is not available.'**
  String get onWayLocationUnavailable;

  /// No description provided for @onWayTrackingActive.
  ///
  /// In en, this message translates to:
  /// **'Live tracking is active.'**
  String get onWayTrackingActive;

  /// No description provided for @onWayYou.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get onWayYou;

  /// No description provided for @onWayLiveConnected.
  ///
  /// In en, this message translates to:
  /// **'Live location connected'**
  String get onWayLiveConnected;

  /// No description provided for @onWayPressStart.
  ///
  /// In en, this message translates to:
  /// **'Press Start Navigation to connect live location'**
  String get onWayPressStart;

  /// No description provided for @onWayDemoOriginName.
  ///
  /// In en, this message translates to:
  /// **'Taksim Square'**
  String get onWayDemoOriginName;

  /// No description provided for @onWayDemoOriginActive.
  ///
  /// In en, this message translates to:
  /// **'Using Taksim Square as the demo start point'**
  String get onWayDemoOriginActive;

  /// No description provided for @onWayDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get onWayDistance;

  /// No description provided for @onWayEta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get onWayEta;

  /// No description provided for @onWayTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get onWayTracking;

  /// No description provided for @onWayTrackingActiveState.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get onWayTrackingActiveState;

  /// No description provided for @onWayTrackingNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get onWayTrackingNotStarted;

  /// No description provided for @onWayDepartureAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure address'**
  String get onWayDepartureAddressTitle;

  /// No description provided for @onWayDepartureAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose GPS or enter your home address for route planning.'**
  String get onWayDepartureAddressSubtitle;

  /// No description provided for @onWayUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location (GPS)'**
  String get onWayUseCurrentLocation;

  /// No description provided for @onWayUseCurrentLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Use live GPS when available'**
  String get onWayUseCurrentLocationHint;

  /// No description provided for @onWayUseSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'My saved address'**
  String get onWayUseSavedAddress;

  /// No description provided for @onWaySavedAddressReady.
  ///
  /// In en, this message translates to:
  /// **'Saved address ready'**
  String get onWaySavedAddressReady;

  /// No description provided for @onWaySavedAddressMissing.
  ///
  /// In en, this message translates to:
  /// **'Add an address below first'**
  String get onWaySavedAddressMissing;

  /// No description provided for @onWayManualOriginActive.
  ///
  /// In en, this message translates to:
  /// **'Using your saved address as the start point'**
  String get onWayManualOriginActive;

  /// No description provided for @onWayManualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From your saved address to {airportCode} airport'**
  String onWayManualSubtitle(String airportCode);

  /// No description provided for @onWayDepartureFrom.
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get onWayDepartureFrom;

  /// No description provided for @onWayChangeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get onWayChangeAddress;

  /// No description provided for @homeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, city, country'**
  String get homeAddressHint;

  /// No description provided for @homeAddressSave.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get homeAddressSave;

  /// No description provided for @homeAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get homeAddressTooShort;

  /// No description provided for @homeAddressGeocodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not find that address. Try adding city and country.'**
  String get homeAddressGeocodeFailed;

  /// No description provided for @homeAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Home address saved'**
  String get homeAddressSaved;

  /// No description provided for @flightWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'FLIGHT DAY WEATHER'**
  String get flightWeatherTitle;

  /// No description provided for @flightWeatherDepartureDay.
  ///
  /// In en, this message translates to:
  /// **'Departure · {city}'**
  String flightWeatherDepartureDay(String city);

  /// No description provided for @flightWeatherArrivalDay.
  ///
  /// In en, this message translates to:
  /// **'Arrival · {city}'**
  String flightWeatherArrivalDay(String city);

  /// No description provided for @flightWeatherBufferAdded.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min added for weather conditions'**
  String flightWeatherBufferAdded(int minutes);

  /// No description provided for @timelineJourneyTag.
  ///
  /// In en, this message translates to:
  /// **'MUSAFIR JOURNEY'**
  String get timelineJourneyTag;

  /// No description provided for @timelineYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get timelineYourJourney;

  /// No description provided for @addingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addingEllipsis;

  /// No description provided for @addSelectedToTodos.
  ///
  /// In en, this message translates to:
  /// **'Add {count} selected to Todos'**
  String addSelectedToTodos(int count);

  /// No description provided for @addSelectedToTripTodos.
  ///
  /// In en, this message translates to:
  /// **'Add {count} selected to Trip Todos'**
  String addSelectedToTripTodos(int count);

  /// No description provided for @packingOpenTripFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first.'**
  String get packingOpenTripFirst;

  /// No description provided for @timelineOpenTripFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first.'**
  String get timelineOpenTripFirst;

  /// No description provided for @packingLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating your packing list...'**
  String get packingLoading;

  /// No description provided for @timelineLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating your journey timeline...'**
  String get timelineLoading;

  /// No description provided for @packingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load packing list.'**
  String get packingLoadFailed;

  /// No description provided for @timelineLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load timeline.'**
  String get timelineLoadFailed;

  /// No description provided for @timelineNoUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming timeline tasks for this trip.'**
  String get timelineNoUpcomingTasks;

  /// No description provided for @packingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get packingRetry;

  /// No description provided for @timelineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get timelineRetry;

  /// No description provided for @timelineDayBefore.
  ///
  /// In en, this message translates to:
  /// **'D-{days}'**
  String timelineDayBefore(int days);

  /// No description provided for @todosOpenTripFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first.'**
  String get todosOpenTripFirst;

  /// No description provided for @todosOpenTripFirstView.
  ///
  /// In en, this message translates to:
  /// **'Open a trip first to view its todos.'**
  String get todosOpenTripFirstView;

  /// No description provided for @todoAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get todoAddTitle;

  /// No description provided for @todoEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo'**
  String get todoEditTitle;

  /// No description provided for @todoTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Todo title'**
  String get todoTitleHint;

  /// No description provided for @todoAdded.
  ///
  /// In en, this message translates to:
  /// **'Todo added.'**
  String get todoAdded;

  /// No description provided for @todosEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No todos in this category yet.'**
  String get todosEmptyDefault;

  /// No description provided for @todosAddTodo.
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get todosAddTodo;

  /// No description provided for @todosCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get todosCategoryAll;

  /// No description provided for @todosCategoryPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get todosCategoryPacking;

  /// No description provided for @todosCategoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get todosCategoryDocuments;

  /// No description provided for @todosTabDocuments.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get todosTabDocuments;

  /// No description provided for @todosTabPacking.
  ///
  /// In en, this message translates to:
  /// **'PACKING'**
  String get todosTabPacking;

  /// No description provided for @todosTabLogistics.
  ///
  /// In en, this message translates to:
  /// **'LOGISTICS'**
  String get todosTabLogistics;

  /// No description provided for @tripTaskDefault.
  ///
  /// In en, this message translates to:
  /// **'Trip task'**
  String get tripTaskDefault;

  /// No description provided for @packingMustHave.
  ///
  /// In en, this message translates to:
  /// **'Must-have'**
  String get packingMustHave;

  /// No description provided for @packingAllItemsInTodos.
  ///
  /// In en, this message translates to:
  /// **'All packing items are already in your trip todos.'**
  String get packingAllItemsInTodos;

  /// No description provided for @packingWeatherSummary.
  ///
  /// In en, this message translates to:
  /// **'{days} days in {city} • {condition} • {temp}°C'**
  String packingWeatherSummary(
    int days,
    String city,
    String condition,
    int temp,
  );

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherClear;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherStorm.
  ///
  /// In en, this message translates to:
  /// **'Storm'**
  String get weatherStorm;

  /// No description provided for @packingRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get packingRecommended;

  /// No description provided for @packingOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get packingOptional;

  /// No description provided for @packingTagCrucial.
  ///
  /// In en, this message translates to:
  /// **'CRUCIAL'**
  String get packingTagCrucial;

  /// No description provided for @packingOptionalTag.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get packingOptionalTag;

  /// No description provided for @packingResortDay.
  ///
  /// In en, this message translates to:
  /// **'RESORT DAY'**
  String get packingResortDay;

  /// No description provided for @packingTransitLeisure.
  ///
  /// In en, this message translates to:
  /// **'TRANSIT LEISURE'**
  String get packingTransitLeisure;

  /// No description provided for @packingItemPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get packingItemPassport;

  /// No description provided for @packingItemFlightTickets.
  ///
  /// In en, this message translates to:
  /// **'Flight Tickets'**
  String get packingItemFlightTickets;

  /// No description provided for @packingItemPowerAdapter.
  ///
  /// In en, this message translates to:
  /// **'Power Adapter'**
  String get packingItemPowerAdapter;

  /// No description provided for @packingItemSunglasses.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get packingItemSunglasses;

  /// No description provided for @packingItemSunscreen.
  ///
  /// In en, this message translates to:
  /// **'Sunscreen'**
  String get packingItemSunscreen;

  /// No description provided for @packingItemSwimwear.
  ///
  /// In en, this message translates to:
  /// **'Swimwear'**
  String get packingItemSwimwear;

  /// No description provided for @packingItemReadingBook.
  ///
  /// In en, this message translates to:
  /// **'Reading Book'**
  String get packingItemReadingBook;

  /// No description provided for @packingItemLinenShirt.
  ///
  /// In en, this message translates to:
  /// **'Light Linen Shirt'**
  String get packingItemLinenShirt;

  /// No description provided for @timelineTaskPassport.
  ///
  /// In en, this message translates to:
  /// **'Check Passport Validity'**
  String get timelineTaskPassport;

  /// No description provided for @timelineTaskVisa.
  ///
  /// In en, this message translates to:
  /// **'Apply for Entry Visa'**
  String get timelineTaskVisa;

  /// No description provided for @timelineTaskSecurity.
  ///
  /// In en, this message translates to:
  /// **'Schedule Home Security'**
  String get timelineTaskSecurity;

  /// No description provided for @timelineTaskPet.
  ///
  /// In en, this message translates to:
  /// **'Arrange Pet Boarding'**
  String get timelineTaskPet;

  /// No description provided for @timelineTaskPacking.
  ///
  /// In en, this message translates to:
  /// **'Complete All Packing List'**
  String get timelineTaskPacking;

  /// No description provided for @timelineTaskTaxi.
  ///
  /// In en, this message translates to:
  /// **'Book Airport Taxi'**
  String get timelineTaskTaxi;

  /// No description provided for @timelineDay14.
  ///
  /// In en, this message translates to:
  /// **'D-14'**
  String get timelineDay14;

  /// No description provided for @timelineDay7.
  ///
  /// In en, this message translates to:
  /// **'D-7'**
  String get timelineDay7;

  /// No description provided for @timelineDay1.
  ///
  /// In en, this message translates to:
  /// **'D-1'**
  String get timelineDay1;

  /// No description provided for @timelineDay0.
  ///
  /// In en, this message translates to:
  /// **'Flight day'**
  String get timelineDay0;

  /// No description provided for @timelineHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1h before'**
  String get timelineHourBefore;

  /// No description provided for @timelineHoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{hours}h before'**
  String timelineHoursBefore(int hours);

  /// No description provided for @todoResearchHealthRequirements.
  ///
  /// In en, this message translates to:
  /// **'Research Health Requirements'**
  String get todoResearchHealthRequirements;

  /// No description provided for @todoCreatePackingList.
  ///
  /// In en, this message translates to:
  /// **'Create Packing List'**
  String get todoCreatePackingList;

  /// No description provided for @todoChargeDevices.
  ///
  /// In en, this message translates to:
  /// **'Charge Devices'**
  String get todoChargeDevices;

  /// No description provided for @todoHeadToAirport.
  ///
  /// In en, this message translates to:
  /// **'Head to Airport'**
  String get todoHeadToAirport;

  /// No description provided for @todoReviewDeparturePlan.
  ///
  /// In en, this message translates to:
  /// **'Review Departure Plan'**
  String get todoReviewDeparturePlan;

  /// No description provided for @todoVisaTravelDocuments.
  ///
  /// In en, this message translates to:
  /// **'Check Visa and Travel Documents'**
  String get todoVisaTravelDocuments;

  /// No description provided for @todoHealthVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Health Check and Vaccinations'**
  String get todoHealthVaccinations;

  /// No description provided for @todoConfirmTransportArrangements.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transport Arrangements'**
  String get todoConfirmTransportArrangements;

  /// No description provided for @todoConfirmFlightTickets.
  ///
  /// In en, this message translates to:
  /// **'Confirm Flight Tickets'**
  String get todoConfirmFlightTickets;

  /// No description provided for @packingItemMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get packingItemMedications;

  /// No description provided for @packingItemWalkingShoes.
  ///
  /// In en, this message translates to:
  /// **'Comfortable Walking Shoes'**
  String get packingItemWalkingShoes;

  /// No description provided for @packingItemWaterBottle.
  ///
  /// In en, this message translates to:
  /// **'Reusable Water Bottle'**
  String get packingItemWaterBottle;

  /// No description provided for @packingItemTravelPillow.
  ///
  /// In en, this message translates to:
  /// **'Travel Pillow'**
  String get packingItemTravelPillow;

  /// No description provided for @notificationPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get notificationPaymentSuccessful;

  /// No description provided for @notificationPaymentSuccessfulBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment of {amount} {currency} has been processed.'**
  String notificationPaymentSuccessfulBody(String amount, String currency);

  /// No description provided for @notificationPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get notificationPaymentFailed;

  /// No description provided for @notificationPaymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment could not be processed.'**
  String get notificationPaymentFailedBody;

  /// No description provided for @notificationPaymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Payment Refunded'**
  String get notificationPaymentRefunded;

  /// No description provided for @notificationPaymentRefundedBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment of {amount} {currency} has been refunded.'**
  String notificationPaymentRefundedBody(String amount, String currency);

  /// No description provided for @notificationFullRefund.
  ///
  /// In en, this message translates to:
  /// **'Full Refund'**
  String get notificationFullRefund;

  /// No description provided for @notificationFullRefundBody.
  ///
  /// In en, this message translates to:
  /// **'A full refund of {amount} {currency} has been issued.'**
  String notificationFullRefundBody(String amount, String currency);

  /// No description provided for @notificationPartialRefund.
  ///
  /// In en, this message translates to:
  /// **'Partial Refund'**
  String get notificationPartialRefund;

  /// No description provided for @notificationPartialRefundBody.
  ///
  /// In en, this message translates to:
  /// **'A partial refund of {amount} {currency} has been issued.'**
  String notificationPartialRefundBody(String amount, String currency);

  /// No description provided for @notificationBookingCanceled.
  ///
  /// In en, this message translates to:
  /// **'Booking Canceled'**
  String get notificationBookingCanceled;

  /// No description provided for @notificationBookingCanceledBody.
  ///
  /// In en, this message translates to:
  /// **'Your flight booking has been canceled.'**
  String get notificationBookingCanceledBody;

  /// No description provided for @notificationDepartureUrgent.
  ///
  /// In en, this message translates to:
  /// **'Leave now! – {flight}'**
  String notificationDepartureUrgent(String flight);

  /// No description provided for @notificationDepartureWarning.
  ///
  /// In en, this message translates to:
  /// **'You should leave soon – {flight}'**
  String notificationDepartureWarning(String flight);

  /// No description provided for @notificationDepartureReminder.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminder – {flight}'**
  String notificationDepartureReminder(String flight);

  /// No description provided for @notificationDepartureBody.
  ///
  /// In en, this message translates to:
  /// **'Your flight {flight} departs at {departureTime}. Recommended departure: {leaveTime} ({travelMinutes} min travel, {bufferMinutes} min weather buffer).'**
  String notificationDepartureBody(
    String flight,
    String departureTime,
    String leaveTime,
    int travelMinutes,
    int bufferMinutes,
  );

  /// No description provided for @notificationTripTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip tasks reminder'**
  String get notificationTripTodoTitle;

  /// No description provided for @notificationTripTodoEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your trip task list for {flight}.'**
  String notificationTripTodoEmptyBody(String flight);

  /// No description provided for @notificationTripTodoIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Please complete your trip tasks for {flight}.'**
  String notificationTripTodoIncompleteBody(String flight);

  /// No description provided for @notificationDepartureScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure time reminder'**
  String get notificationDepartureScheduleTitle;

  /// No description provided for @notificationFlightDeparture6hBody.
  ///
  /// In en, this message translates to:
  /// **'Your flight {flight} departs in 6 hours.'**
  String notificationFlightDeparture6hBody(String flight);

  /// No description provided for @notificationHomeDeparture2hBody.
  ///
  /// In en, this message translates to:
  /// **'Leave home for the airport in 2 hours ({flight}).'**
  String notificationHomeDeparture2hBody(String flight);

  /// No description provided for @notificationHomeDeparture30mBody.
  ///
  /// In en, this message translates to:
  /// **'Leave home in 30 minutes ({flight}).'**
  String notificationHomeDeparture30mBody(String flight);

  /// No description provided for @notificationHomeDepartureCriticalTitle.
  ///
  /// In en, this message translates to:
  /// **'Critical departure time'**
  String get notificationHomeDepartureCriticalTitle;

  /// No description provided for @notificationHomeDepartureCriticalBody.
  ///
  /// In en, this message translates to:
  /// **'Leave home for the airport now ({flight}).'**
  String notificationHomeDepartureCriticalBody(String flight);

  /// No description provided for @timelineBadgeDocument.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT'**
  String get timelineBadgeDocument;

  /// No description provided for @timelineBadgeTask.
  ///
  /// In en, this message translates to:
  /// **'TASK'**
  String get timelineBadgeTask;

  /// No description provided for @timelineBadgePacking.
  ///
  /// In en, this message translates to:
  /// **'PACKING'**
  String get timelineBadgePacking;

  /// No description provided for @timelineTitleDocuments.
  ///
  /// In en, this message translates to:
  /// **'Travel Documents'**
  String get timelineTitleDocuments;

  /// No description provided for @timelineTitlePreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get timelineTitlePreparation;

  /// No description provided for @timelineTitlePacking.
  ///
  /// In en, this message translates to:
  /// **'Packing & Logistics'**
  String get timelineTitlePacking;

  /// No description provided for @ticketBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'BOARDING PASS'**
  String get ticketBoardingPass;

  /// No description provided for @ticketScanForBoarding.
  ///
  /// In en, this message translates to:
  /// **'Scan for Boarding'**
  String get ticketScanForBoarding;

  /// No description provided for @ticketSafeWorkSecure.
  ///
  /// In en, this message translates to:
  /// **'Safe work\nsecure'**
  String get ticketSafeWorkSecure;

  /// No description provided for @ticketDirect.
  ///
  /// In en, this message translates to:
  /// **'DIRECT'**
  String get ticketDirect;

  /// No description provided for @ticketDeparture.
  ///
  /// In en, this message translates to:
  /// **'DEPARTURE'**
  String get ticketDeparture;

  /// No description provided for @timelineItemsAddedToTodos.
  ///
  /// In en, this message translates to:
  /// **'{count} timeline items added to todos.'**
  String timelineItemsAddedToTodos(int count);

  /// No description provided for @packingItemsAddedToTodos.
  ///
  /// In en, this message translates to:
  /// **'{count} packing items added to todos.'**
  String packingItemsAddedToTodos(int count);

  /// No description provided for @todosSelectPacking.
  ///
  /// In en, this message translates to:
  /// **'Select tasks to delete'**
  String get todosSelectPacking;

  /// No description provided for @todosCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get todosCancelSelection;

  /// No description provided for @todosDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected ({count})'**
  String todosDeleteSelected(int count);

  /// No description provided for @todosDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks deleted'**
  String todosDeletedCount(int count);

  /// No description provided for @todoConfirmBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking Details'**
  String get todoConfirmBookingDetails;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
