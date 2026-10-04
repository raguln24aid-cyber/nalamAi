import '../error/failure.dart';
import '../models/chat_message.dart';
import '../network/api_client.dart';

class AssistantRepository {
  AssistantRepository(this._client);
  final ApiClient _client;

  Future<Result<AssistantAnswer>> query({
    required String scanId,
    required String question,
    String language = 'auto',
    String? compareScanId,
  }) {
    return _client.guard((dio) async {
      final res = await dio.post('/assistant/query', data: {
        'scanId': scanId,
        'question': question,
        'language': language,
        'compareScanId': ?compareScanId,
      });
      return AssistantAnswer.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<List<ChatMessage>>> getHistory(String scanId) {
    return _client.guard((dio) async {
      final res = await dio.get('/assistant/history', queryParameters: {'scanId': scanId});
      return (res.data as List<dynamic>).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
