import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../error/failure.dart';
import '../network/api_client.dart';

/// Cloud TTS fallback — only used when on-device `flutter_tts` quality is insufficient
/// (see core/accessibility/tts_service.dart). Returns raw MP3 bytes to be played via just_audio.
class TtsRepository {
  TtsRepository(this._client);
  final ApiClient _client;

  Future<Result<Uint8List>> synthesize({required String text, required String language}) {
    return _client.guard((dio) async {
      final res = await dio.post<List<int>>(
        '/tts/synthesize',
        data: {'text': text, 'language': language},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data!);
    });
  }
}
