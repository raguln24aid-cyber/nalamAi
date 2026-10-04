import 'package:equatable/equatable.dart';
import 'product.dart';
import 'provenance.dart';

enum ScanStatus {
  processing,
  completed,
  failed;

  static ScanStatus fromJson(String value) => ScanStatus.values.firstWhere(
        (v) => v.name == value,
        orElse: () => ScanStatus.failed,
      );
}

enum SafetyFlagType {
  allergenMatch,
  nutritionThreshold,
  possibleAllergenUnconfirmed;

  static SafetyFlagType fromJson(String value) => switch (value) {
        'allergen_match' => SafetyFlagType.allergenMatch,
        'nutrition_threshold' => SafetyFlagType.nutritionThreshold,
        'possible_allergen_unconfirmed' => SafetyFlagType.possibleAllergenUnconfirmed,
        _ => SafetyFlagType.nutritionThreshold,
      };
}

enum SafetyFlagSeverity {
  info,
  warning,
  critical;

  static SafetyFlagSeverity fromJson(String value) => SafetyFlagSeverity.values.firstWhere(
        (v) => v.name == value,
        orElse: () => SafetyFlagSeverity.info,
      );
}

class SafetyFlag extends Equatable {
  final SafetyFlagType type;
  final SafetyFlagSeverity severity;
  final String message;
  final ProvenanceSource provenance;

  const SafetyFlag({
    required this.type,
    required this.severity,
    required this.message,
    required this.provenance,
  });

  factory SafetyFlag.fromJson(Map<String, dynamic> json) => SafetyFlag(
        type: SafetyFlagType.fromJson(json['type'] as String),
        severity: SafetyFlagSeverity.fromJson(json['severity'] as String),
        message: json['message'] as String,
        provenance: ProvenanceSource.fromJson(json['provenance'] as String? ?? 'unverified'),
      );

  @override
  List<Object?> get props => [type, severity, message, provenance];
}

/// One extraction reason returned by the backend as `error.details.reason` on a 422
/// EXTRACTION_FAILED response — mapped directly to spoken guidance by the Scanner screen.
enum ExtractionFailureReason {
  noTextDetected,
  imageTooBlurry,
  barcodeNotFound,
  providerError,
  unknown;

  static ExtractionFailureReason fromJson(String? value) => switch (value) {
        'no_text_detected' => ExtractionFailureReason.noTextDetected,
        'image_too_blurry' => ExtractionFailureReason.imageTooBlurry,
        'barcode_not_found' => ExtractionFailureReason.barcodeNotFound,
        'provider_error' => ExtractionFailureReason.providerError,
        _ => ExtractionFailureReason.unknown,
      };
}

class Scan extends Equatable {
  final String scanId;
  final ScanStatus status;
  final Product? product;
  final List<SafetyFlag> safetyFlags;
  final String? languageDetected;
  final String? errorMessage;
  final DateTime createdAt;

  const Scan({
    required this.scanId,
    required this.status,
    required this.product,
    required this.safetyFlags,
    required this.languageDetected,
    required this.errorMessage,
    required this.createdAt,
  });

  factory Scan.fromJson(Map<String, dynamic> json) => Scan(
        scanId: json['scanId'] as String,
        status: ScanStatus.fromJson(json['status'] as String),
        product: json['product'] == null ? null : Product.fromJson(json['product'] as Map<String, dynamic>),
        safetyFlags: (json['safetyFlags'] as List<dynamic>? ?? [])
            .map((e) => SafetyFlag.fromJson(e as Map<String, dynamic>))
            .toList(),
        languageDetected: json['languageDetected'] as String?,
        errorMessage: json['errorMessage'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'scanId': scanId,
        'status': status.name,
        'product': product?.toJson(),
        'safetyFlags': safetyFlags
            .map((f) => {
                  'type': f.type.name,
                  'severity': f.severity.name,
                  'message': f.message,
                  'provenance': f.provenance.name,
                })
            .toList(),
        'languageDetected': languageDetected,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get hasCriticalFlag => safetyFlags.any((f) => f.severity == SafetyFlagSeverity.critical);

  @override
  List<Object?> get props =>
      [scanId, status, product, safetyFlags, languageDetected, errorMessage, createdAt];
}

class ScanSummary extends Equatable {
  final String scanId;
  final ScanStatus status;
  final String? productName;
  final String? brand;
  final bool hasCriticalSafetyFlag;
  final DateTime createdAt;

  const ScanSummary({
    required this.scanId,
    required this.status,
    required this.productName,
    required this.brand,
    required this.hasCriticalSafetyFlag,
    required this.createdAt,
  });

  factory ScanSummary.fromJson(Map<String, dynamic> json) => ScanSummary(
        scanId: json['scanId'] as String,
        status: ScanStatus.fromJson(json['status'] as String),
        productName: json['productName'] as String?,
        brand: json['brand'] as String?,
        hasCriticalSafetyFlag: json['hasCriticalSafetyFlag'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [scanId, status, productName, brand, hasCriticalSafetyFlag, createdAt];
}

class ScanComparison extends Equatable {
  final Scan a;
  final Scan b;
  final List<ComparisonDifference> differences;

  const ScanComparison({required this.a, required this.b, required this.differences});

  factory ScanComparison.fromJson(Map<String, dynamic> json) => ScanComparison(
        a: Scan.fromJson(json['a'] as Map<String, dynamic>),
        b: Scan.fromJson(json['b'] as Map<String, dynamic>),
        differences: (json['differences'] as List<dynamic>? ?? [])
            .map((e) => ComparisonDifference.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [a, b, differences];
}

class ComparisonDifference extends Equatable {
  final String field;
  final num? a;
  final num? b;
  final String note;

  const ComparisonDifference({required this.field, required this.a, required this.b, required this.note});

  factory ComparisonDifference.fromJson(Map<String, dynamic> json) => ComparisonDifference(
        field: json['field'] as String,
        a: json['a'] as num?,
        b: json['b'] as num?,
        note: json['note'] as String,
      );

  @override
  List<Object?> get props => [field, a, b, note];
}
