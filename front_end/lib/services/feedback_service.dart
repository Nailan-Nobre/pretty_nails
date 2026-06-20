import '../models/feedback.dart';
import 'api_service.dart';

class FeedbackService {
  static Future<List<FeedbackModel>> listarPorManicure(String manicureId) async {
    final response = await ApiService.get('/feedback/manicure/$manicureId');
    final list = response is List ? response : (response['data'] ?? []);
    return (list as List).map((e) => FeedbackModel.fromJson(e)).toList();
  }
}
