import '../error/failure.dart';
import '../models/scan.dart';
import '../network/api_client.dart';

class ScansRepository {
  ScansRepository(this._client);
  final ApiClient _client;

  Future<Result<Scan>> createScan({String? imageBase64, String? barcode, String languageHint = 'auto'}) {
    return _client.guard((dio) async {
      final res = await dio.post('/scans', data: {
        'imageBase64': ?imageBase64,
        'barcode': ?barcode,
        'languageHint': languageHint,
      });
      return Scan.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<({List<ScanSummary> items, String? nextCursor})>> listScans({
    int limit = 20,
    String? cursor,
  }) {
    return _client.guard((dio) async {
      final res = await dio.get('/scans', queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
      });
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => ScanSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, nextCursor: data['nextCursor'] as String?);
    });
  }

  Future<Result<Scan>> getScan(String scanId) {
    return _client.guard((dio) async {
      final res = await dio.get('/scans/$scanId');
      return Scan.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<ScanComparison>> compareScans({required String scanIdA, required String scanIdB}) {
    return _client.guard((dio) async {
      final res = await dio.get('/scans/compare', queryParameters: {'a': scanIdA, 'b': scanIdB});
      return ScanComparison.fromJson(res.data as Map<String, dynamic>);
    });
  }
}
