import 'package:flutter_test/flutter_test.dart';
import 'package:nalamai_mobile/core/accessibility/global_voice_commands.dart';

void main() {
  group('GlobalVoiceCommands.parse', () {
    test('recognises the navigation commands in English', () {
      expect(GlobalVoiceCommands.parse('go home'), GlobalVoiceCommand.home);
      expect(GlobalVoiceCommands.parse('go back'), GlobalVoiceCommand.back);
      expect(GlobalVoiceCommands.parse('scan a product'), GlobalVoiceCommand.scan);
      expect(GlobalVoiceCommands.parse('my history'), GlobalVoiceCommand.history);
      expect(GlobalVoiceCommands.parse('my profile'), GlobalVoiceCommand.profile);
      expect(GlobalVoiceCommands.parse('settings'), GlobalVoiceCommand.settings);
    });

    test('recognises the orientation commands a blind user depends on', () {
      expect(GlobalVoiceCommands.parse('help'), GlobalVoiceCommand.help);
      expect(GlobalVoiceCommands.parse('what can i say'), GlobalVoiceCommand.help);
      expect(GlobalVoiceCommands.parse('where am i'), GlobalVoiceCommand.whereAmI);
      expect(GlobalVoiceCommands.parse('repeat that'), GlobalVoiceCommand.repeat);
      expect(GlobalVoiceCommands.parse('stop talking'), GlobalVoiceCommand.stopTalking);
    });

    test('recognises Tamil equivalents', () {
      expect(GlobalVoiceCommands.parse('முகப்பு'), GlobalVoiceCommand.home);
      expect(GlobalVoiceCommands.parse('பின் செல்'), GlobalVoiceCommand.back);
      expect(GlobalVoiceCommands.parse('உதவி'), GlobalVoiceCommand.help);
      expect(GlobalVoiceCommands.parse('வரலாறு'), GlobalVoiceCommand.history);
    });

    test('is case- and whitespace-insensitive', () {
      expect(GlobalVoiceCommands.parse('  GO Home  '), GlobalVoiceCommand.home);
    });

    // The regression this guards: global commands are checked before every screen's own
    // parser, so a bare substring match would hijack ordinary questions on the assistant
    // screen — the user would ask about sugar and be navigated to Settings instead.
    group('does not hijack questions that merely contain a command word', () {
      const questions = [
        'is this good for my back',
        'how much sugar should i stop at',
        'does this product have a long history of recalls',
        'what is the scan telling me about the profile of this oil',
        'can i help my mother choose this',
      ];

      for (final question in questions) {
        test('"$question"', () {
          expect(GlobalVoiceCommands.parse(question), GlobalVoiceCommand.unknown);
        });
      }
    });

    test('still accepts a bare command word said on its own', () {
      expect(GlobalVoiceCommands.parse('back'), GlobalVoiceCommand.back);
      expect(GlobalVoiceCommands.parse('scan'), GlobalVoiceCommand.scan);
      expect(GlobalVoiceCommands.parse('history'), GlobalVoiceCommand.history);
      expect(GlobalVoiceCommands.parse('stop'), GlobalVoiceCommand.stopTalking);
    });

    test('accepts a command word inside a short spoken phrase', () {
      expect(GlobalVoiceCommands.parse('okay back'), GlobalVoiceCommand.back);
      expect(GlobalVoiceCommands.parse('scan please'), GlobalVoiceCommand.scan);
    });

    test('returns unknown for empty or unrelated speech', () {
      expect(GlobalVoiceCommands.parse(''), GlobalVoiceCommand.unknown);
      expect(GlobalVoiceCommands.parse('   '), GlobalVoiceCommand.unknown);
      expect(GlobalVoiceCommands.parse('does this contain milk'), GlobalVoiceCommand.unknown);
    });
  });
}
