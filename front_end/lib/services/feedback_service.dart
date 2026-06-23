import '../models/feedback.dart';
import 'api_service.dart';
import 'cache_service.dart';

class FeedbackService {
  static Future<List<FeedbackModel>> listarPorManicure(String manicureId, {bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadFeedbacks(manicureId);
      if (cached != null) {
        return cached.map((e) => FeedbackModel.fromJson(e)).toList();
      }
    }
    final response = await ApiService.get('/feedback/manicure/$manicureId');
    final list = response['feedbacks'] ?? [];
    final data = (list as List).cast<Map<String, dynamic>>();
    await CacheService.saveFeedbacks(manicureId, data);
    return data.map((e) => FeedbackModel.fromJson(e)).toList();
  }
}
