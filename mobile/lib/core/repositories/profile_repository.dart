import '../error/failure.dart';
import '../models/profile.dart';
import '../network/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final ApiClient _client;

  Future<Result<UserProfile>> getProfile() {
    return _client.guard((dio) async {
      final res = await dio.get('/profile');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<void>> updateDietaryPreference(DietaryPreference preference) {
    return _client.guard((dio) async {
      await dio.put('/profile', data: {'dietaryPreference': preference.toJson()});
    });
  }

  Future<Result<Allergy>> addAllergy({required String allergen, required AllergySeverity severity}) {
    return _client.guard((dio) async {
      final res = await dio.post('/profile/allergies', data: {
        'allergen': allergen,
        'severity': severity.name,
      });
      return Allergy.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<void>> removeAllergy(String id) {
    return _client.guard((dio) async {
      await dio.delete('/profile/allergies/$id');
    });
  }

  Future<Result<DietaryRestriction>> addRestriction(String restriction) {
    return _client.guard((dio) async {
      final res = await dio.post('/profile/restrictions', data: {'restriction': restriction});
      return DietaryRestriction.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<void>> removeRestriction(String id) {
    return _client.guard((dio) async {
      await dio.delete('/profile/restrictions/$id');
    });
  }
}
