import '../models/agendamento.dart';
import 'api_service.dart';

class AgendamentoService {
  static Future<List<Agendamento>> listarPendentes() async {
    final response = await ApiService.get('/api/agendamentos/pendentes');
    final list = response is List ? response : (response['data'] ?? []);
    return (list as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarConfirmados() async {
    final response = await ApiService.get('/api/agendamentos/confirmados');
    final list = response is List ? response : (response['data'] ?? []);
    return (list as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarHistorico() async {
    final response = await ApiService.get('/api/agendamentos/historico');
    final list = response is List ? response : (response['data'] ?? []);
    return (list as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarMeusAgendamentos() async {
    final response = await ApiService.get('/api/agendamentos/meus-agendamentos');
    final list = response is List ? response : (response['data'] ?? []);
    return (list as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<Agendamento> atualizarStatus(String id, AgendamentoStatus status) async {
    final response = await ApiService.patch(
      '/api/agendamentos/$id/status',
      body: {'status': agendamentoStatusToString(status)},
    );
    return Agendamento.fromJson(response);
  }

  static Future<Map<String, dynamic>> obterEstatisticas() async {
    return await ApiService.get('/api/agendamentos/estatisticas');
  }

  static Future<Map<String, dynamic>> obterHistoricoEstatisticas(int ano) async {
    return await ApiService.get('/api/agendamentos/historico-estatisticas?ano=$ano');
  }
}
