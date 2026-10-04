/// Mirrors the backend's provenance tagging — see docs/SAFETY_RULES.md.
/// Every extracted fact carries one of these so the UI and TTS layer can say
/// "label explicitly says" vs "AI interpretation" instead of asserting everything equally.
enum ProvenanceSource {
  labelStated,
  ocrDetected,
  aiInterpreted,
  unverified;

  static ProvenanceSource fromJson(String value) => switch (value) {
        'label_stated' => ProvenanceSource.labelStated,
        'ocr_detected' => ProvenanceSource.ocrDetected,
        'ai_interpreted' => ProvenanceSource.aiInterpreted,
        _ => ProvenanceSource.unverified,
      };
}
