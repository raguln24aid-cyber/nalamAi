// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NalamAI';

  @override
  String get welcomeSpoken => 'Hello! Use the camera to check a food product.';

  @override
  String get welcomeVisual => 'Welcome to NalamAI';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'No internet connection. Some features are unavailable offline.';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get homeTitle => 'NalamAI Home';

  @override
  String get homeInstructions =>
      'Tap the camera button, or say \"check this product\", to scan a food label.';

  @override
  String get scanButtonLabel => 'Scan a food product';

  @override
  String get micIdleLabel => 'Tap and speak a command';

  @override
  String get micListeningLabel => 'Listening';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get goToHistory => 'Scan history';

  @override
  String get goToProfile => 'Your profile';

  @override
  String get goToSettings => 'Settings';

  @override
  String get scannerTitle => 'Camera Scanner';

  @override
  String get scannerInstructions =>
      'Point the camera at the food label. NalamAI will guide you.';

  @override
  String get guidanceMoveCloser => 'Move closer to the label';

  @override
  String get guidanceMoveFarther => 'Move a little farther away';

  @override
  String get guidanceMoveLeft => 'Move the camera left';

  @override
  String get guidanceMoveRight => 'Move the camera right';

  @override
  String get guidanceHoldSteady => 'Hold steady';

  @override
  String get guidanceTooBlurry =>
      'The image looks blurry, hold the camera steady';

  @override
  String get guidanceTooDark => 'It\'s too dark, try moving to better light';

  @override
  String get guidanceTooBright =>
      'There\'s too much glare, tilt the camera slightly';

  @override
  String get guidanceReadyToCapture => 'Good, capturing now';

  @override
  String get guidanceCapturing => 'Capturing the label, please hold still';

  @override
  String get guidanceBarcodeDetected => 'Barcode detected, scanning';

  @override
  String get guidanceNoTextFound => 'No label text was found, please try again';

  @override
  String get captureButtonLabel => 'Capture photo';

  @override
  String get switchToBarcodeMode => 'Switch to barcode scanning';

  @override
  String get switchToLabelMode => 'Switch to label photo scanning';

  @override
  String get productResultTitle => 'Product Result';

  @override
  String get unknownProduct => 'Unknown product';

  @override
  String get unknownBrand => 'Brand not detected';

  @override
  String get viewNutritionDetails => 'View nutrition details';

  @override
  String get viewIngredientsAllergens => 'View ingredients and allergens';

  @override
  String get askAssistantButton => 'Ask the AI food assistant';

  @override
  String get compareWithAnother => 'Compare with another product';

  @override
  String get rescanButton => 'Scan again';

  @override
  String get safetyFlagsHeading => 'Things to know about this product';

  @override
  String get noSafetyFlags =>
      'No allergen matches or nutrition warnings were found for your profile on this label.';

  @override
  String get summaryGoodPoints => 'Good points';

  @override
  String get summaryWatchOut => 'Things to watch';

  @override
  String get summaryHigh => 'high';

  @override
  String get summaryNoneNoted => 'nothing notable';

  @override
  String get summaryAskPrompt =>
      'That is the summary. Ask me anything about this product, or say ingredients, nutrition, or compare.';

  @override
  String get nutritionTitle => 'Nutrition Details';

  @override
  String get nutritionPer100g => 'Per 100 grams';

  @override
  String get servingSize => 'Serving size';

  @override
  String get calories => 'Calories';

  @override
  String get sugar => 'Sugar';

  @override
  String get protein => 'Protein';

  @override
  String get fat => 'Total fat';

  @override
  String get saturatedFat => 'Saturated fat';

  @override
  String get sodium => 'Sodium';

  @override
  String get fiber => 'Dietary fibre';

  @override
  String get valueNotAvailable => 'Not available on this label';

  @override
  String get ingredientsTitle => 'Ingredients & Allergens';

  @override
  String get ingredientsHeading => 'Ingredients';

  @override
  String get noIngredientsFound =>
      'No ingredients list could be detected on this label.';

  @override
  String get allergensHeading => 'Allergens';

  @override
  String get noAllergensFound => 'No allergens were detected on this label.';

  @override
  String get allergenDeclared => 'Declared on label';

  @override
  String get allergenInferred => 'Possible match, not explicitly declared';

  @override
  String get dietInfoHeading => 'Dietary information';

  @override
  String get dietFlagVegetarian => 'Vegetarian';

  @override
  String get dietFlagNonVegetarian => 'Non-vegetarian';

  @override
  String get dietFlagVegan => 'Vegan';

  @override
  String get dietFlagGlutenFree => 'Gluten-free';

  @override
  String get dietFlagContainsGluten => 'Contains gluten';

  @override
  String provenanceLabelStated(Object text) {
    return 'The label explicitly says: $text';
  }

  @override
  String provenanceOcrDetected(Object text) {
    return 'Detected from the label text: $text';
  }

  @override
  String provenanceAiInterpreted(Object text) {
    return 'Our AI interpretation: $text';
  }

  @override
  String get provenanceUnverified =>
      'This could not be verified from the label.';

  @override
  String get assistantTitle => 'AI Food Assistant';

  @override
  String get assistantHint =>
      'Ask about this product, for example \"What is the sugar content?\" or \"Does this contain milk?\"';

  @override
  String get assistantInputHint => 'Type or speak a question';

  @override
  String get assistantSendButton => 'Send';

  @override
  String get assistantListening => 'Listening for your question';

  @override
  String get assistantUncertainNotice =>
      'This answer could not be fully verified from the label.';

  @override
  String get comparisonTitle => 'Compare Products';

  @override
  String get comparisonSelectPrompt =>
      'Choose a second scan to compare with this product';

  @override
  String get comparisonNoDifferences =>
      'No notable nutrition differences were found.';

  @override
  String get profileTitle => 'Your Profile';

  @override
  String get dietaryPreferenceLabel => 'Dietary preference';

  @override
  String get dietPrefNone => 'No preference set';

  @override
  String get dietPrefVegetarian => 'Vegetarian';

  @override
  String get dietPrefVegan => 'Vegan';

  @override
  String get dietPrefEggetarian => 'Eggetarian';

  @override
  String get dietPrefNonVegetarian => 'Non-vegetarian';

  @override
  String get allergiesTitle => 'Allergies';

  @override
  String get addAllergyButton => 'Add an allergy';

  @override
  String get allergySeverityMild => 'Mild';

  @override
  String get allergySeverityModerate => 'Moderate';

  @override
  String get allergySeveritySevere => 'Severe';

  @override
  String get restrictionsTitle => 'Dietary restrictions';

  @override
  String get addRestrictionButton => 'Add a restriction';

  @override
  String get noAllergiesYet => 'No allergies added yet';

  @override
  String get noRestrictionsYet => 'No dietary restrictions added yet';

  @override
  String get historyTitle => 'Scan History';

  @override
  String get historyEmpty => 'You haven\'t scanned any products yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageAuto => 'Automatically detect (Tamil / English)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'Tamil (தமிழ்)';

  @override
  String get accountSection => 'Account';

  @override
  String get logoutButton => 'Log out';

  @override
  String get voiceSettingsSection => 'Voice & accessibility';

  @override
  String get hapticFeedbackToggle => 'Haptic feedback for warnings';

  @override
  String get cloudVoiceFallbackToggle =>
      'Use higher-quality cloud voice when available';

  @override
  String get authLoginTitle => 'Log in';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Log in';

  @override
  String get registerButton => 'Create account';

  @override
  String get switchToRegister => 'Don\'t have an account? Create one';

  @override
  String get switchToLogin => 'Already have an account? Log in';

  @override
  String get offlineBannerMessage =>
      'You\'re offline. Showing your saved scan history.';

  @override
  String get permissionCameraDenied =>
      'Camera access is required to scan food labels. Please enable it in settings.';

  @override
  String get permissionMicDenied =>
      'Microphone access is required for voice commands. Please enable it in settings.';

  @override
  String get bootSpoken => 'Starting NalamAI. One moment.';

  @override
  String get bootVisual => 'Starting NalamAI';

  @override
  String get voiceSetupPrompt =>
      'Welcome to NalamAI. This app works entirely by voice. To set up your account now, just say: start. You will never need an email address or a password.';

  @override
  String get voiceSetupWorking => 'Setting up your account. One moment.';

  @override
  String get voiceSetupDone =>
      'Your account is ready. From now on this app opens straight to the microphone.';

  @override
  String get voiceSetupFailed =>
      'I could not set up your account. Please check your internet connection, then say: try again.';

  @override
  String get voiceSetupRetryHint =>
      'Say start to set up your account, or try again to retry.';

  @override
  String get voiceSetupButton => 'Set up by voice';

  @override
  String get voiceSignInWorking => 'Signing you in.';

  @override
  String get voiceSetupTypeInstead =>
      'Advanced: sign in with an email address instead';

  @override
  String get signedOutSpoken => 'You are signed out. Say sign in to come back.';

  @override
  String get voiceSignInPrompt =>
      'You are signed out. Say sign in to come back.';

  @override
  String whereAmIAnswer(Object screen) {
    return 'You are on the $screen screen.';
  }

  @override
  String get helpGlobal =>
      'Anywhere in the app you can say: scan a product, my history, my profile, settings, go back, go home, repeat that, where am I, stop talking, or help.';

  @override
  String get helpHome =>
      'You are at the start. Say scan a product to check a food label.';

  @override
  String get helpScanner =>
      'Hold the product label in front of the camera. I will guide you. Say capture to take the picture now, or go back to leave.';

  @override
  String get helpProductResult =>
      'Say ingredients, or nutrition, to hear the details. Ask any question out loud, such as: does this contain milk. Say scan again for a new product.';

  @override
  String get helpAssistant =>
      'Ask any question about this product out loud. Say go back to return to the result.';

  @override
  String get helpHistory =>
      'Say a number, such as one, to open that scan. Say next or previous to move through the list.';

  @override
  String get helpProfile => 'Say my allergies to change what I warn you about.';

  @override
  String get helpSettings => 'Say Tamil or English to change the language.';

  @override
  String get micPermissionExplainSpoken =>
      'NalamAI needs the microphone so you can control the app with your voice. Please allow microphone access when you are asked.';

  @override
  String get micUnavailableSpoken =>
      'I cannot reach the microphone. Touch the middle of the screen to try again.';

  @override
  String get micRetryAction => 'Try the microphone again';

  @override
  String get voiceNotUnderstood =>
      'Sorry, I did not catch that. Say help to hear what you can say.';

  @override
  String get tamilSpeechUnavailableSpoken =>
      'Tamil speech recognition is not installed on this device, so I will listen in English. I can still answer you in Tamil.';

  @override
  String get listeningSpoken => 'Listening.';

  @override
  String get doubleTapToTalkHint =>
      'Double tap anywhere to talk. Press and hold to repeat the last thing I said.';

  @override
  String get scannerAutoCaptureOff =>
      'Automatic capture is off. Say capture when you are ready.';

  @override
  String get scannerAutoCaptureOn =>
      'Automatic capture is on. I will take the picture when the label is framed.';

  @override
  String get voiceIdleStopped =>
      'I have stopped listening for now. Double tap anywhere, or tap the microphone button, when you want to talk again.';
}
