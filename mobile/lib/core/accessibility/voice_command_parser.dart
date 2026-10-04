/// Top-level voice commands recognised from the Home screen's always-listening mic button.
/// Keyword-based (not a full NLU model) — practical for a fixed, small command set where every
/// action must also be reachable by touch, per the accessibility requirements.
enum VoiceCommand {
  scanProduct,
  openHistory,
  openProfile,
  openSettings,
  askAssistant,
  repeatLast,
  unknown,
}

class VoiceCommandParser {
  VoiceCommandParser._();

  static const _scanKeywords = [
    'check this product', 'check product', 'scan', 'scan product', 'scan this',
    'check this', 'பொருளை check', 'check பண்ணு', 'ஸ்கேன்', 'ஸ்கேன் செய்', 'படம்',
  ];
  static const _historyKeywords = ['history', 'scan history', 'வரலாறு', 'past scans', 'previous scans'];
  static const _profileKeywords = ['profile', 'my profile', 'சுயவிவரம்', 'allergies', 'ஒவ்வாமை'];
  static const _settingsKeywords = ['settings', 'அமைப்பு', 'அமைப்புகள்', 'language settings', 'மொழி'];
  static const _assistantKeywords = [
    'ask', 'question', 'assistant', 'உதவியாளர்', 'கேள்வி', 'what is', 'does this contain',
    'is this', 'read the ingredients', 'compare with',
  ];
  static const _repeatKeywords = ['repeat', 'say again', 'மீண்டும் சொல்', 'திரும்ப சொல்'];

  static VoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return VoiceCommand.unknown;

    if (_matchesAny(text, _assistantKeywords)) return VoiceCommand.askAssistant;
    if (_matchesAny(text, _scanKeywords)) return VoiceCommand.scanProduct;
    if (_matchesAny(text, _historyKeywords)) return VoiceCommand.openHistory;
    if (_matchesAny(text, _profileKeywords)) return VoiceCommand.openProfile;
    if (_matchesAny(text, _settingsKeywords)) return VoiceCommand.openSettings;
    if (_matchesAny(text, _repeatKeywords)) return VoiceCommand.repeatLast;

    return VoiceCommand.unknown;
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k.toLowerCase()));
}

/// "Go back" / "go home" recognised the same way on every screen, since navigating away by
/// voice has to work everywhere for the app to be genuinely hands-free, not just each screen's
/// own primary actions.
class CommonVoiceCommands {
  CommonVoiceCommands._();

  static const _backKeywords = ['go back', 'back', 'previous screen', 'பின் செல்', 'திரும்பு'];
  static const _homeKeywords = ['go home', 'home screen', 'main menu', 'home', 'முகப்பு', 'முகப்பு பக்கம்'];

  static bool isBack(String text) => _matches(text, _backKeywords);
  static bool isHome(String text) => _matches(text, _homeKeywords);

  static bool _matches(String rawText, List<String> keywords) {
    final text = rawText.trim().toLowerCase();
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }
}

/// Voice commands recognised on the Product Result screen's always-listening follow-up loop
/// (spoken right after the scan summary). A subset overlaps with [VoiceCommand] deliberately —
/// e.g. "ingredients" means something specific and consistent everywhere in the app.
enum ProductResultCommand {
  viewNutrition,
  viewIngredients,
  askQuestion,
  compare,
  rescan,
  repeatLast,
  unknown,
}

class ProductResultVoiceParser {
  ProductResultVoiceParser._();

  static const _nutritionKeywords = [
    'nutrition', 'calories', 'sugar', 'protein', 'fat', 'sodium', 'ஊட்டச்சத்து', 'கலோரி', 'சர்க்கரை',
  ];
  static const _ingredientsKeywords = [
    'ingredients', 'allergen', 'allergy', 'contains', 'பொருட்கள்', 'ஒவ்வாமை',
  ];
  static const _compareKeywords = ['compare', 'ஒப்பிடு', 'ஒப்பிடுக'];
  static const _rescanKeywords = ['scan again', 'rescan', 'new scan', 'மீண்டும் ஸ்கேன்', 'புதிய ஸ்கேன்'];
  static const _repeatKeywords = ['repeat', 'say again', 'மீண்டும் சொல்', 'திரும்ப சொல்'];
  static const _questionMarkers = [
    'what', 'does', 'is this', 'is it', 'how much', 'can i', 'should i', 'read the',
    'என்ன', 'இதில்', 'இருக்கா', 'உள்ளதா',
  ];

  /// Unlike [VoiceCommandParser.parse], free-form speech that isn't one of the specific nav
  /// commands below always classifies as [ProductResultCommand.askQuestion] — used to interrupt
  /// the full label read-through (see ProductResultScreen._announce): whatever the user says
  /// while it's reading is forwarded verbatim to the AI Assistant rather than being dropped as
  /// unrecognised, since "anything you say interrupts and gets answered" is the whole point.
  /// A bare topic word ("ingredients", "nutrition") is still a fast-path shortcut to that
  /// screen; a real question ("does this contain milk?") is checked first so it gets answered
  /// directly instead of just opening a list screen.
  static ProductResultCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return ProductResultCommand.unknown;

    if (_matchesAny(text, _rescanKeywords)) return ProductResultCommand.rescan;
    if (_matchesAny(text, _compareKeywords)) return ProductResultCommand.compare;
    if (_matchesAny(text, _repeatKeywords)) return ProductResultCommand.repeatLast;
    if (_matchesAny(text, _questionMarkers)) return ProductResultCommand.askQuestion;
    if (_matchesAny(text, _ingredientsKeywords)) return ProductResultCommand.viewIngredients;
    if (_matchesAny(text, _nutritionKeywords)) return ProductResultCommand.viewNutrition;

    return ProductResultCommand.askQuestion;
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k.toLowerCase()));
}
