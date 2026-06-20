class FeedbackModel {
  final String id;
  final String? agendamentoId;
  final String manicureId;
  final String clienteNome;
  final String? clienteCpf;
  final int estrelas;
  final String? comentario;
  final DateTime? createdAt;

  FeedbackModel({
    required this.id,
    this.agendamentoId,
    required this.manicureId,
    required this.clienteNome,
    this.clienteCpf,
    required this.estrelas,
    this.comentario,
    this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      agendamentoId: json['agendamento_id'],
      manicureId: json['manicure_id'] ?? '',
      clienteNome: json['cliente_nome'] ?? '',
      clienteCpf: json['cliente_cpf'],
      estrelas: json['estrelas'] ?? 0,
      comentario: json['comentario'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agendamento_id': agendamentoId,
      'manicure_id': manicureId,
      'cliente_nome': clienteNome,
      'cliente_cpf': clienteCpf,
      'estrelas': estrelas,
      'comentario': comentario,
    };
  }
}
