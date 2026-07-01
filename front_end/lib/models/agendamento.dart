enum AgendamentoStatus {
  pendente,
  confirmado,
  cancelado,
  concluido,
  recusado,
}

AgendamentoStatus agendamentoStatusFromString(String status) {
  switch (status) {
    case 'pendente':
      return AgendamentoStatus.pendente;
    case 'confirmado':
      return AgendamentoStatus.confirmado;
    case 'cancelado':
      return AgendamentoStatus.cancelado;
    case 'concluido':
      return AgendamentoStatus.concluido;
    case 'recusado':
      return AgendamentoStatus.recusado;
    default:
      return AgendamentoStatus.pendente;
  }
}

String agendamentoStatusToString(AgendamentoStatus status) {
  switch (status) {
    case AgendamentoStatus.pendente:
      return 'pendente';
    case AgendamentoStatus.confirmado:
      return 'confirmado';
    case AgendamentoStatus.cancelado:
      return 'cancelado';
    case AgendamentoStatus.concluido:
      return 'concluido';
    case AgendamentoStatus.recusado:
      return 'recusado';
  }
}

String agendamentoStatusLabel(AgendamentoStatus status) {
  switch (status) {
    case AgendamentoStatus.pendente:
      return 'Pendente';
    case AgendamentoStatus.confirmado:
      return 'Confirmado';
    case AgendamentoStatus.cancelado:
      return 'Cancelado';
    case AgendamentoStatus.concluido:
      return 'Concluído';
    case AgendamentoStatus.recusado:
      return 'Recusado';
  }
}

class Agendamento {
  final String id;
  final String manicureId;
  final String clienteNome;
  final String? clienteEmail;
  final String? clienteCpf;
  final String? clienteTelefone;
  final DateTime dataHora;
  final String servico;
  final String? observacoes;
  final String? imagemReferencia;
  final double? valor;
  final AgendamentoStatus status;
  final bool? avaliado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Agendamento({
    required this.id,
    required this.manicureId,
    required this.clienteNome,
    this.clienteEmail,
    this.clienteCpf,
    this.clienteTelefone,
    required this.dataHora,
    required this.servico,
    this.observacoes,
    this.imagemReferencia,
    this.valor,
    required this.status,
    this.avaliado,
    this.createdAt,
    this.updatedAt,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'] ?? '',
      manicureId: json['manicure_id'] ?? '',
      clienteNome: json['cliente_nome'] ?? '',
      clienteEmail: json['cliente_email'],
      clienteCpf: json['cliente_cpf'],
      clienteTelefone: json['cliente_telefone'],
      dataHora: DateTime.parse(json['data_hora']),
      servico: json['servico'] ?? '',
      observacoes: json['observacoes'],
      imagemReferencia: json['imagem_referencia'],
      valor: json['valor'] != null ? (json['valor'] as num).toDouble() : null,
      status: agendamentoStatusFromString(json['status'] ?? 'pendente'),
      avaliado: json['avaliado'],
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
      'manicure_id': manicureId,
      'cliente_nome': clienteNome,
      'cliente_email': clienteEmail,
      'cliente_cpf': clienteCpf,
      'cliente_telefone': clienteTelefone,
      'data_hora': dataHora.toIso8601String(),
      'servico': servico,
      'observacoes': observacoes,
      'imagem_referencia': imagemReferencia,
      'valor': valor,
      'status': agendamentoStatusToString(status),
      'avaliado': avaliado,
    };
  }

  Agendamento copyWith({
    String? id,
    String? manicureId,
    String? clienteNome,
    String? clienteEmail,
    String? clienteCpf,
    String? clienteTelefone,
    DateTime? dataHora,
    String? servico,
    String? observacoes,
    String? imagemReferencia,
    double? valor,
    AgendamentoStatus? status,
    bool? avaliado,
  }) {
    return Agendamento(
      id: id ?? this.id,
      manicureId: manicureId ?? this.manicureId,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      clienteCpf: clienteCpf ?? this.clienteCpf,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      dataHora: dataHora ?? this.dataHora,
      servico: servico ?? this.servico,
      observacoes: observacoes ?? this.observacoes,
      imagemReferencia: imagemReferencia ?? this.imagemReferencia,
      valor: valor ?? this.valor,
      status: status ?? this.status,
      avaliado: avaliado ?? this.avaliado,
    );
  }
}
