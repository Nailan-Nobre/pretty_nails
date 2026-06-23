import '../models/agendamento.dart';
import 'api_service.dart';
import 'cache_service.dart';

class AgendamentoService {
  static Future<List<Agendamento>> listarPendentes({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadPendentes();
      if (cached != null) {
        return cached.map((e) => Agendamento.fromJson(e)).toList();
      }
    }
    final response = await ApiService.get('/api/agendamentos/pendentes');
    final list = response['agendamentos'] ?? [];
    final data = (list as List).cast<Map<String, dynamic>>();
    await CacheService.savePendentes(data);
    return data.map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarConfirmados({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadConfirmados();
      if (cached != null) {
        return cached.map((e) => Agendamento.fromJson(e)).toList();
      }
    }
    final response = await ApiService.get('/api/agendamentos/confirmados');
    final list = response['agendamentos'] ?? [];
    final data = (list as List).cast<Map<String, dynamic>>();
    await CacheService.saveConfirmados(data);
    return data.map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarHistorico({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadHistorico();
      if (cached != null) {
        return cached.map((e) => Agendamento.fromJson(e)).toList();
      }
    }
    final response = await ApiService.get('/api/agendamentos/historico');
    final list = response['agendamentos'] ?? [];
    final data = (list as List).cast<Map<String, dynamic>>();
    await CacheService.saveHistorico(data);
    return data.map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<List<Agendamento>> listarMeusAgendamentos({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadMeusAgendamentos();
      if (cached != null) {
        return cached.map((e) => Agendamento.fromJson(e)).toList();
      }
    }
    final response = await ApiService.get('/api/agendamentos/meus-agendamentos');
    final agendamentos = response['agendamentos'] ?? {};
    final comoManicure = agendamentos['comoManicure'] ?? [];
    final data = (comoManicure as List).cast<Map<String, dynamic>>();
    await CacheService.saveMeusAgendamentos(data);
    return data.map((e) => Agendamento.fromJson(e)).toList();
  }

  static Future<Agendamento> atualizarStatus(String id, AgendamentoStatus status) async {
    final response = await ApiService.patch(
      '/api/agendamentos/$id/status',
      body: {'status': agendamentoStatusToString(status)},
    );
    return Agendamento.fromJson(response['agendamento'] ?? response);
  }

  static Future<Map<String, dynamic>> obterEstatisticas({bool useCache = true}) async {
    if (useCache) {
      final cached = await CacheService.loadEstatisticas();
      if (cached != null) return cached;
    }
    final response = await ApiService.get('/api/agendamentos/estatisticas');
    final estatisticas = response['estatisticas'] ?? {};
    final concluidos = estatisticas['totalConcluidos'] ?? 0;
    final cancelados = estatisticas['totalCancelados'] ?? 0;
    final result = {
      'total': concluidos + cancelados,
      'pendentes': 0,
      'confirmados': 0,
      'concluidos': concluidos,
    };
    await CacheService.saveEstatisticas(result);
    return result;
  }

  static Future<Map<String, dynamic>> obterHistoricoEstatisticas(int ano) async {
    final response = await ApiService.get('/api/agendamentos/historico-estatisticas?ano=$ano');
    final historico = response['historico'] ?? {};
    final labels = historico['labels'] ?? [];
    final dadosConcluidos = historico['dadosConcluidos'] ?? [];
    final dadosCancelados = historico['dadosCancelados'] ?? [];

    final meses = <String, int>{};
    for (int i = 0; i < labels.length; i++) {
      final total = (dadosConcluidos[i] ?? 0) + (dadosCancelados[i] ?? 0);
      meses['${i + 1}'] = total;
    }

    return {
      'ano': ano,
      'meses': meses,
      'labels': labels,
      'dadosConcluidos': dadosConcluidos,
      'dadosCancelados': dadosCancelados,
    };
  }
}
