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
  final List<String>? horarios;
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
    this.servicos,
    this.regras,
    this.createdAt,
    this.updatedAt,
  });

  factory Manicure.fromJson(Map<String, dynamic> json) {
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
          ? List<String>.from(json['horarios'])
          : null,
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
      'servicos': servicos,
      'regras': regras,
    };
  }
}
