import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NalamAI'**
  String get appName;

  /// No description provided for @welcomeSpoken.
  ///
  /// In en, this message translates to:
  /// **'Hello! Use the camera to check a food product.'**
  String get welcomeSpoken;

  /// No description provided for @welcomeVisual.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NalamAI'**
  String get welcomeVisual;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Some features are unavailable offline.'**
  String get errorNetwork;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'NalamAI Home'**
  String get homeTitle;

  /// No description provided for @homeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera button, or say \"check this product\", to scan a food label.'**
  String get homeInstructions;

  /// No description provided for @scanButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan a food product'**
  String get scanButtonLabel;

  /// No description provided for @micIdleLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap and speak a command'**
  String get micIdleLabel;

  /// No description provided for @micListeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get micListeningLabel;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @goToHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan history'**
  String get goToHistory;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get goToProfile;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get goToSettings;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the food label. NalamAI will guide you.'**
  String get scannerInstructions;

  /// No description provided for @guidanceMoveCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the label'**
  String get guidanceMoveCloser;

  /// No description provided for @guidanceMoveFarther.
  ///
  /// In en, this message translates to:
  /// **'Move a little farther away'**
  String get guidanceMoveFarther;

  /// No description provided for @guidanceMoveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move the camera left'**
  String get guidanceMoveLeft;

  /// No description provided for @guidanceMoveRight.
  ///
  /// In en, this message translates to:
  /// **'Move the camera right'**
  String get guidanceMoveRight;

  /// No description provided for @guidanceHoldSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold steady'**
  String get guidanceHoldSteady;

  /// No description provided for @guidanceTooBlurry.
  ///
  /// In en, this message translates to:
  /// **'The image looks blurry, hold the camera steady'**
  String get guidanceTooBlurry;

  /// No description provided for @guidanceTooDark.
  ///
  /// In en, this message translates to:
  /// **'It\'s too dark, try moving to better light'**
  String get guidanceTooDark;

  /// No description provided for @guidanceTooBright.
  ///
  /// In en, this message translates to:
  /// **'There\'s too much glare, tilt the camera slightly'**
  String get guidanceTooBright;

  /// No description provided for @guidanceReadyToCapture.
  ///
  /// In en, this message translates to:
  /// **'Good, capturing now'**
  String get guidanceReadyToCapture;

  /// No description provided for @guidanceCapturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing the label, please hold still'**
  String get guidanceCapturing;

  /// No description provided for @guidanceBarcodeDetected.
  ///
  /// In en, this message translates to:
  /// **'Barcode detected, scanning'**
  String get guidanceBarcodeDetected;

  /// No description provided for @guidanceNoTextFound.
  ///
  /// In en, this message translates to:
  /// **'No label text was found, please try again'**
  String get guidanceNoTextFound;

  /// No description provided for @captureButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get captureButtonLabel;

  /// No description provided for @switchToBarcodeMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to barcode scanning'**
  String get switchToBarcodeMode;

  /// No description provided for @switchToLabelMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to label photo scanning'**
  String get switchToLabelMode;

  /// No description provided for @productResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Result'**
  String get productResultTitle;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown product'**
  String get unknownProduct;

  /// No description provided for @unknownBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand not detected'**
  String get unknownBrand;

  /// No description provided for @viewNutritionDetails.
  ///
  /// In en, this message translates to:
  /// **'View nutrition details'**
  String get viewNutritionDetails;

  /// No description provided for @viewIngredientsAllergens.
  ///
  /// In en, this message translates to:
  /// **'View ingredients and allergens'**
  String get viewIngredientsAllergens;

  /// No description provided for @askAssistantButton.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI food assistant'**
  String get askAssistantButton;

  /// No description provided for @compareWithAnother.
  ///
  /// In en, this message translates to:
  /// **'Compare with another product'**
  String get compareWithAnother;

  /// No description provided for @rescanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get rescanButton;

  /// No description provided for @safetyFlagsHeading.
  ///
  /// In en, this message translates to:
  /// **'Things to know about this product'**
  String get safetyFlagsHeading;

  /// No description provided for @noSafetyFlags.
  ///
  /// In en, this message translates to:
  /// **'No allergen matches or nutrition warnings were found for your profile on this label.'**
  String get noSafetyFlags;

  /// No description provided for @summaryGoodPoints.
  ///
  /// In en, this message translates to:
  /// **'Good points'**
  String get summaryGoodPoints;

  /// No description provided for @summaryWatchOut.
  ///
  /// In en, this message translates to:
  /// **'Things to watch'**
  String get summaryWatchOut;

  /// No description provided for @summaryHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get summaryHigh;

  /// No description provided for @summaryNoneNoted.
  ///
  /// In en, this message translates to:
  /// **'nothing notable'**
  String get summaryNoneNoted;

  /// No description provided for @summaryAskPrompt.
  ///
  /// In en, this message translates to:
  /// **'That is the summary. Ask me anything about this product, or say ingredients, nutrition, or compare.'**
  String get summaryAskPrompt;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Details'**
  String get nutritionTitle;

  /// No description provided for @nutritionPer100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 grams'**
  String get nutritionPer100g;

  /// No description provided for @servingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get servingSize;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Total fat'**
  String get fat;

  /// No description provided for @saturatedFat.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat'**
  String get saturatedFat;

  /// No description provided for @sodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get sodium;

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Dietary fibre'**
  String get fiber;

  /// No description provided for @valueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this label'**
  String get valueNotAvailable;

  /// No description provided for @ingredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients & Allergens'**
  String get ingredientsTitle;

  /// No description provided for @ingredientsHeading.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsHeading;

  /// No description provided for @noIngredientsFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredients list could be detected on this label.'**
  String get noIngredientsFound;

  /// No description provided for @allergensHeading.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergensHeading;

  /// No description provided for @noAllergensFound.
  ///
  /// In en, this message translates to:
  /// **'No allergens were detected on this label.'**
  String get noAllergensFound;

  /// No description provided for @allergenDeclared.
  ///
  /// In en, this message translates to:
  /// **'Declared on label'**
  String get allergenDeclared;

  /// No description provided for @allergenInferred.
  ///
  /// In en, this message translates to:
  /// **'Possible match, not explicitly declared'**
  String get allergenInferred;

  /// No description provided for @dietInfoHeading.
  ///
  /// In en, this message translates to:
  /// **'Dietary information'**
  String get dietInfoHeading;

  /// No description provided for @dietFlagVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietFlagVegetarian;

  /// No description provided for @dietFlagNonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-vegetarian'**
  String get dietFlagNonVegetarian;

  /// No description provided for @dietFlagVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietFlagVegan;

  /// No description provided for @dietFlagGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get dietFlagGlutenFree;

  /// No description provided for @dietFlagContainsGluten.
  ///
  /// In en, this message translates to:
  /// **'Contains gluten'**
  String get dietFlagContainsGluten;

  /// No description provided for @provenanceLabelStated.
  ///
  /// In en, this message translates to:
  /// **'The label explicitly says: {text}'**
  String provenanceLabelStated(Object text);

  /// No description provided for @provenanceOcrDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected from the label text: {text}'**
  String provenanceOcrDetected(Object text);

  /// No description provided for @provenanceAiInterpreted.
  ///
  /// In en, this message translates to:
  /// **'Our AI interpretation: {text}'**
  String provenanceAiInterpreted(Object text);

  /// No description provided for @provenanceUnverified.
  ///
  /// In en, this message translates to:
  /// **'This could not be verified from the label.'**
  String get provenanceUnverified;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Food Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about this product, for example \"What is the sugar content?\" or \"Does this contain milk?\"'**
  String get assistantHint;

  /// No description provided for @assistantInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type or speak a question'**
  String get assistantInputHint;

  /// No description provided for @assistantSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get assistantSendButton;

  /// No description provided for @assistantListening.
  ///
  /// In en, this message translates to:
  /// **'Listening for your question'**
  String get assistantListening;

  /// No description provided for @assistantUncertainNotice.
  ///
  /// In en, this message translates to:
  /// **'This answer could not be fully verified from the label.'**
  String get assistantUncertainNotice;

  /// No description provided for @comparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare Products'**
  String get comparisonTitle;

  /// No description provided for @comparisonSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a second scan to compare with this product'**
  String get comparisonSelectPrompt;

  /// No description provided for @comparisonNoDifferences.
  ///
  /// In en, this message translates to:
  /// **'No notable nutrition differences were found.'**
  String get comparisonNoDifferences;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get profileTitle;

  /// No description provided for @dietaryPreferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Dietary preference'**
  String get dietaryPreferenceLabel;

  /// No description provided for @dietPrefNone.
  ///
  /// In en, this message translates to:
  /// **'No preference set'**
  String get dietPrefNone;

  /// No description provided for @dietPrefVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietPrefVegetarian;

  /// No description provided for @dietPrefVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietPrefVegan;

  /// No description provided for @dietPrefEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get dietPrefEggetarian;

  /// No description provided for @dietPrefNonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-vegetarian'**
  String get dietPrefNonVegetarian;

  /// No description provided for @allergiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesTitle;

  /// No description provided for @addAllergyButton.
  ///
  /// In en, this message translates to:
  /// **'Add an allergy'**
  String get addAllergyButton;

  /// No description provided for @allergySeverityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get allergySeverityMild;

  /// No description provided for @allergySeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get allergySeverityModerate;

  /// No description provided for @allergySeveritySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get allergySeveritySevere;

  /// No description provided for @restrictionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dietary restrictions'**
  String get restrictionsTitle;

  /// No description provided for @addRestrictionButton.
  ///
  /// In en, this message translates to:
  /// **'Add a restriction'**
  String get addRestrictionButton;

  /// No description provided for @noAllergiesYet.
  ///
  /// In en, this message translates to:
  /// **'No allergies added yet'**
  String get noAllergiesYet;

  /// No description provided for @noRestrictionsYet.
  ///
  /// In en, this message translates to:
  /// **'No dietary restrictions added yet'**
  String get noRestrictionsYet;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t scanned any products yet'**
  String get historyEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect (Tamil / English)'**
  String get languageAuto;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil (தமிழ்)'**
  String get languageTamil;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @voiceSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Voice & accessibility'**
  String get voiceSettingsSection;

  /// No description provided for @hapticFeedbackToggle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback for warnings'**
  String get hapticFeedbackToggle;

  /// No description provided for @cloudVoiceFallbackToggle.
  ///
  /// In en, this message translates to:
  /// **'Use higher-quality cloud voice when available'**
  String get cloudVoiceFallbackToggle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @switchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get switchToRegister;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get switchToLogin;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing your saved scan history.'**
  String get offlineBannerMessage;

  /// No description provided for @permissionCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to scan food labels. Please enable it in settings.'**
  String get permissionCameraDenied;

  /// No description provided for @permissionMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required for voice commands. Please enable it in settings.'**
  String get permissionMicDenied;

  /// No description provided for @bootSpoken.
  ///
  /// In en, this message translates to:
  /// **'Starting NalamAI. One moment.'**
  String get bootSpoken;

  /// No description provided for @bootVisual.
  ///
  /// In en, this message translates to:
  /// **'Starting NalamAI'**
  String get bootVisual;

  /// No description provided for @voiceSetupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NalamAI. This app works entirely by voice. To set up your account now, just say: start. You will never need an email address or a password.'**
  String get voiceSetupPrompt;

  /// No description provided for @voiceSetupWorking.
  ///
  /// In en, this message translates to:
  /// **'Setting up your account. One moment.'**
  String get voiceSetupWorking;

  /// No description provided for @voiceSetupDone.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. From now on this app opens straight to the microphone.'**
  String get voiceSetupDone;

  /// No description provided for @voiceSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not set up your account. Please check your internet connection, then say: try again.'**
  String get voiceSetupFailed;

  /// No description provided for @voiceSetupRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Say start to set up your account, or try again to retry.'**
  String get voiceSetupRetryHint;

  /// No description provided for @voiceSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Set up by voice'**
  String get voiceSetupButton;

  /// No description provided for @voiceSignInWorking.
  ///
  /// In en, this message translates to:
  /// **'Signing you in.'**
  String get voiceSignInWorking;

  /// No description provided for @voiceSetupTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Advanced: sign in with an email address instead'**
  String get voiceSetupTypeInstead;

  /// No description provided for @signedOutSpoken.
  ///
  /// In en, this message translates to:
  /// **'You are signed out. Say sign in to come back.'**
  String get signedOutSpoken;

  /// No description provided for @voiceSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are signed out. Say sign in to come back.'**
  String get voiceSignInPrompt;

  /// No description provided for @whereAmIAnswer.
  ///
  /// In en, this message translates to:
  /// **'You are on the {screen} screen.'**
  String whereAmIAnswer(Object screen);

  /// No description provided for @helpGlobal.
  ///
  /// In en, this message translates to:
  /// **'Anywhere in the app you can say: scan a product, my history, my profile, settings, go back, go home, repeat that, where am I, stop talking, or help.'**
  String get helpGlobal;

  /// No description provided for @helpHome.
  ///
  /// In en, this message translates to:
  /// **'You are at the start. Say scan a product to check a food label.'**
  String get helpHome;

  /// No description provided for @helpScanner.
  ///
  /// In en, this message translates to:
  /// **'Hold the product label in front of the camera. I will guide you. Say capture to take the picture now, or go back to leave.'**
  String get helpScanner;

  /// No description provided for @helpProductResult.
  ///
  /// In en, this message translates to:
  /// **'Say ingredients, or nutrition, to hear the details. Ask any question out loud, such as: does this contain milk. Say scan again for a new product.'**
  String get helpProductResult;

  /// No description provided for @helpAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask any question about this product out loud. Say go back to return to the result.'**
  String get helpAssistant;

  /// No description provided for @helpHistory.
  ///
  /// In en, this message translates to:
  /// **'Say a number, such as one, to open that scan. Say next or previous to move through the list.'**
  String get helpHistory;

  /// No description provided for @helpProfile.
  ///
  /// In en, this message translates to:
  /// **'Say my allergies to change what I warn you about.'**
  String get helpProfile;

  /// No description provided for @helpSettings.
  ///
  /// In en, this message translates to:
  /// **'Say Tamil or English to change the language.'**
  String get helpSettings;

  /// No description provided for @micPermissionExplainSpoken.
  ///
  /// In en, this message translates to:
  /// **'NalamAI needs the microphone so you can control the app with your voice. Please allow microphone access when you are asked.'**
  String get micPermissionExplainSpoken;

  /// No description provided for @micUnavailableSpoken.
  ///
  /// In en, this message translates to:
  /// **'I cannot reach the microphone. Touch the middle of the screen to try again.'**
  String get micUnavailableSpoken;

  /// No description provided for @micRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try the microphone again'**
  String get micRetryAction;

  /// No description provided for @voiceNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I did not catch that. Say help to hear what you can say.'**
  String get voiceNotUnderstood;

  /// No description provided for @tamilSpeechUnavailableSpoken.
  ///
  /// In en, this message translates to:
  /// **'Tamil speech recognition is not installed on this device, so I will listen in English. I can still answer you in Tamil.'**
  String get tamilSpeechUnavailableSpoken;

  /// No description provided for @listeningSpoken.
  ///
  /// In en, this message translates to:
  /// **'Listening.'**
  String get listeningSpoken;

  /// No description provided for @doubleTapToTalkHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap anywhere to talk. Press and hold to repeat the last thing I said.'**
  String get doubleTapToTalkHint;

  /// No description provided for @scannerAutoCaptureOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic capture is off. Say capture when you are ready.'**
  String get scannerAutoCaptureOff;

  /// No description provided for @scannerAutoCaptureOn.
  ///
  /// In en, this message translates to:
  /// **'Automatic capture is on. I will take the picture when the label is framed.'**
  String get scannerAutoCaptureOn;

  /// No description provided for @voiceIdleStopped.
  ///
  /// In en, this message translates to:
  /// **'I have stopped listening for now. Double tap anywhere, or tap the microphone button, when you want to talk again.'**
  String get voiceIdleStopped;
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
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
