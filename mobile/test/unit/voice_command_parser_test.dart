import 'package:flutter_test/flutter_test.dart';
import 'package:nalamai_mobile/core/accessibility/voice_command_parser.dart';

void main() {
  group('CommonVoiceCommands', () {
    test('recognises back and home phrases', () {
      expect(CommonVoiceCommands.isBack('go back please'), isTrue);
      expect(CommonVoiceCommands.isHome('take me home'), isTrue);
      expect(CommonVoiceCommands.isBack('what is the sugar content'), isFalse);
    });
  });

  group('ProductResultVoiceParser', () {
    test('treats a direct question as askQuestion, not unknown', () {
      expect(ProductResultVoiceParser.parse('does this contain milk?'), ProductResultCommand.askQuestion);
      expect(ProductResultVoiceParser.parse('what is the sugar content'), ProductResultCommand.askQuestion);
    });

    test('falls back to askQuestion for anything unrecognised, never unknown', () {
      // Core to the "interrupt the read-through and it answers you" behaviour — nothing the
      // user says while interrupting should be silently dropped.
      expect(ProductResultVoiceParser.parse('tell me something random'), ProductResultCommand.askQuestion);
    });

    test('bare topic words still act as fast-path navigation shortcuts', () {
      expect(ProductResultVoiceParser.parse('ingredients'), ProductResultCommand.viewIngredients);
      expect(ProductResultVoiceParser.parse('nutrition'), ProductResultCommand.viewNutrition);
    });

    test('recognises rescan, compare, and repeat commands', () {
      expect(ProductResultVoiceParser.parse('scan again'), ProductResultCommand.rescan);
      expect(ProductResultVoiceParser.parse('compare this'), ProductResultCommand.compare);
      expect(ProductResultVoiceParser.parse('repeat that'), ProductResultCommand.repeatLast);
    });

    test('only empty input is unknown', () {
      expect(ProductResultVoiceParser.parse(''), ProductResultCommand.unknown);
      expect(ProductResultVoiceParser.parse('   '), ProductResultCommand.unknown);
    });
  });
}
