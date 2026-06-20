import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../models/agendamento.dart';
import '../services/agendamento_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Agendamento> _pendentes = [];
  List<Agendamento> _confirmados = [];
  List<Agendamento> _historico = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      final pendentes = await AgendamentoService.listarPendentes();
      final confirmados = await AgendamentoService.listarConfirmados();
      final historico = await AgendamentoService.listarHistorico();

      if (mounted) {
        setState(() {
          _pendentes = pendentes;
          _confirmados = confirmados;
          _historico = historico;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _getStatusColor(AgendamentoStatus status, AppColors colors) {
    switch (status) {
      case AgendamentoStatus.pendente:
        return colors.warning;
      case AgendamentoStatus.confirmado:
        return colors.info;
      case AgendamentoStatus.concluido:
        return colors.success;
      case AgendamentoStatus.cancelado:
        return colors.danger;
      case AgendamentoStatus.recusado:
        return colors.danger;
    }
  }

  String _getStatusLabel(AgendamentoStatus status) {
    return agendamentoStatusLabel(status);
  }

  IconData _getStatusIcon(AgendamentoStatus status) {
    switch (status) {
      case AgendamentoStatus.pendente:
        return Icons.hourglass_top;
      case AgendamentoStatus.confirmado:
        return Icons.check_circle;
      case AgendamentoStatus.concluido:
        return Icons.done_all;
      case AgendamentoStatus.cancelado:
        return Icons.cancel;
      case AgendamentoStatus.recusado:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_today, size: 24, color: colors.textLight),
            const SizedBox(width: 12),
            Text(
              'Agendamentos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textLight,
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.textLight,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.textLight,
          indicatorWeight: 3,
          labelColor: colors.textLight,
          unselectedLabelColor: colors.textLight.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Confirmados'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      backgroundColor: colors.bgPrimary,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : Container(
              color: colors.bgPrimary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(_pendentes, 'pendentes', colors),
                  _buildAppointmentsList(_confirmados, 'confirmados', colors),
                  _buildAppointmentsList(_historico, 'historico', colors),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentsList(List<Agendamento> appointments, String type, AppColors colors) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pendentes'
                  ? Icons.hourglass_empty
                  : type == 'confirmados'
                      ? Icons.check_circle_outline
                      : Icons.history,
              size: 64,
              color: colors.primaryLight.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'pendentes'
                  ? 'Nenhum agendamento pendente'
                  : type == 'confirmados'
                      ? 'Nenhum agendamento confirmado'
                      : 'Nenhum agendamento no histórico',
              style: TextStyle(fontSize: 16, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Os agendamentos aparecerão aqui',
              style: TextStyle(fontSize: 14, color: colors.textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildAppointmentCard(appointments[index], colors);
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Agendamento appointment, AppColors colors) {
    final statusColor = _getStatusColor(appointment.status, colors);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowSm,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.clienteNome,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(appointment.status), size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusLabel(appointment.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.servico,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 16, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy - HH:mm').format(appointment.dataHora),
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
          if (appointment.clienteTelefone != null && appointment.clienteTelefone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  appointment.clienteTelefone!,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ],
          if (appointment.observacoes != null && appointment.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.observacoes!,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (appointment.status == AgendamentoStatus.pendente ||
              appointment.status == AgendamentoStatus.confirmado) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (appointment.status == AgendamentoStatus.pendente) ...[
                  _buildActionButton(
                    'Confirmar', Icons.check, colors.success, colors,
                    () => _updateStatus(appointment, AgendamentoStatus.confirmado),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Recusar', Icons.block, colors.danger, colors,
                    () => _updateStatus(appointment, AgendamentoStatus.recusado),
                  ),
                ],
                if (appointment.status == AgendamentoStatus.confirmado) ...[
                  _buildActionButton(
                    'Concluir', Icons.done_all, colors.info, colors,
                    () => _updateStatus(appointment, AgendamentoStatus.concluido),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Cancelar', Icons.cancel, colors.danger, colors,
                    () => _updateStatus(appointment, AgendamentoStatus.cancelado),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    AppColors colors,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(Agendamento appointment, AgendamentoStatus newStatus) async {
    try {
      await AgendamentoService.atualizarStatus(appointment.id, newStatus);
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agendamento ${agendamentoStatusLabel(newStatus).toLowerCase()} com sucesso!'),
            backgroundColor: ThemeProvider.of(context).colors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: ThemeProvider.of(context).colors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
