import 'package:flutter/material.dart';

/// Large (well above the 56dp minimum touch target), high-contrast mic control used anywhere
/// the app needs a primary voice-input affordance (Home, AI Assistant). Its Semantics label
/// changes with [isListening] so TalkBack/VoiceOver announces state changes, not just a static
/// "microphone" label.
class BigMicButton extends StatelessWidget {
  const BigMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    required this.idleLabel,
    required this.listeningLabel,
  });

  final bool isListening;
  final VoidCallback onPressed;
  final String idleLabel;
  final String listeningLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isListening ? theme.colorScheme.error : theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: isListening ? listeningLabel : idleLabel,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: theme.colorScheme.onPrimary,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}
