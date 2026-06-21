class Manicure {
  final String id;
  final String email;
  final String nome;
  final String? foto;
  final String? telefone;
  final String? estado;
  final String? cidade;
  final String? bio;
  final String? slug;
  final double? estrelas;
  final bool? ativa;
  final List<int>? diasTrabalho;
  final List<Map<String, dynamic>>? horarios;
  final int? intervalo;
  final Map<String, List<Map<String, dynamic>>>? horariosPorDia;
  final List<Map<String, dynamic>>? servicos;
  final String? regras;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Manicure({
    required this.id,
    required this.email,
    required this.nome,
    this.foto,
    this.telefone,
    this.estado,
    this.cidade,
    this.bio,
    this.slug,
    this.estrelas,
    this.ativa,
    this.diasTrabalho,
    this.horarios,
    this.intervalo,
    this.horariosPorDia,
    this.servicos,
    this.regras,
    this.createdAt,
    this.updatedAt,
  });

  factory Manicure.fromJson(Map<String, dynamic> json) {
    Map<String, List<Map<String, dynamic>>>? parseHorariosPorDia(dynamic value) {
      if (value == null) return null;
      if (value is! Map) return null;
      final result = <String, List<Map<String, dynamic>>>{};
      value.forEach((key, val) {
        if (val is List) {
          result[key.toString()] = val
              .map((e) => Map<String, dynamic>.from(e is String ? {'inicio': e, 'fim': ''} : e))
              .toList();
        }
      });
      return result;
    }

    return Manicure(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'] ?? '',
      foto: json['foto'],
      telefone: json['telefone'],
      estado: json['estado'],
      cidade: json['cidade'],
      bio: json['bio'] ?? '',
      slug: json['slug'],
      estrelas: json['estrelas'] != null ? (json['estrelas'] as num).toDouble() : null,
      ativa: json['ativa'],
      diasTrabalho: json['dias_trabalho'] != null
          ? List<int>.from(json['dias_trabalho'])
          : null,
      horarios: json['horarios'] != null
          ? (json['horarios'] is List)
              ? List<Map<String, dynamic>>.from(
                  (json['horarios'] as List).map((e) => Map<String, dynamic>.from(e is String ? {'inicio': e, 'fim': ''} : e)),
                )
              : null
          : null,
      intervalo: json['intervalo'] != null ? (json['intervalo'] as num).toInt() : null,
      horariosPorDia: parseHorariosPorDia(json['horarios_por_dia']),
      servicos: json['servicos'] != null
          ? List<Map<String, dynamic>>.from(json['servicos'])
          : null,
      regras: json['regras'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'foto': foto,
      'telefone': telefone,
      'estado': estado,
      'cidade': cidade,
      'bio': bio,
      'slug': slug,
      'estrelas': estrelas,
      'ativa': ativa,
      'dias_trabalho': diasTrabalho,
      'horarios': horarios,
      'intervalo': intervalo,
      'horarios_por_dia': horariosPorDia,
      'servicos': servicos,
      'regras': regras,
    };
  }
}
