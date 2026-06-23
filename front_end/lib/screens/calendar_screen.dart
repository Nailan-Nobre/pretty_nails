import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../models/agendamento.dart';
import '../services/agendamento_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<Agendamento>> _appointments = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadFromCache();
    _loadFromServer();
  }

  Future<void> _loadFromCache() async {
    try {
      final agendamentos = await AgendamentoService.listarMeusAgendamentos();
      if (mounted) {
        setState(() {
          _appointments.clear();
          for (final a in agendamentos) {
            final key = DateTime(a.dataHora.year, a.dataHora.month, a.dataHora.day);
            if (!_appointments.containsKey(key)) {
              _appointments[key] = [];
            }
            _appointments[key]!.add(a);
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadFromServer() async {
    try {
      final agendamentos = await AgendamentoService.listarMeusAgendamentos(useCache: false);
      if (mounted) {
        setState(() {
          _appointments.clear();
          for (final a in agendamentos) {
            final key = DateTime(a.dataHora.year, a.dataHora.month, a.dataHora.day);
            if (!_appointments.containsKey(key)) {
              _appointments[key] = [];
            }
            _appointments[key]!.add(a);
          }
        });
      }
    } catch (_) {}
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
            Icon(Icons.calendar_month, size: 24, color: colors.textLight),
            const SizedBox(width: 12),
            Text(
              'Calendário de Agendamentos',
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
      ),
      backgroundColor: colors.bgPrimary,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : Container(
              color: colors.bgPrimary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildCalendar(colors),
                    _buildAppointmentsList(colors),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar(AppColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowSm,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: 40,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: colors.primaryLight, size: 28),
          rightChevronIcon: Icon(Icons.chevron_right, color: colors.primaryLight, size: 28),
        ),
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: colors.primaryLight,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          todayTextStyle: TextStyle(
            color: colors.textLight,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.primary,
              width: 2,
            ),
          ),
          selectedTextStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(color: colors.textPrimary),
          weekendTextStyle: TextStyle(color: colors.danger),
          outsideTextStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
          cellMargin: const EdgeInsets.all(4),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          return _appointments[key] ?? [];
        },
      ),
    );
  }

  Widget _buildAppointmentsList(AppColors colors) {
    final appointments = _getAppointmentsForDay(_selectedDay ?? _focusedDay);

    if (appointments.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.all(32),
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
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 64, color: colors.primaryLight.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Nenhum agendamento para este dia',
              style: TextStyle(fontSize: 16, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione outro dia no calendário',
              style: TextStyle(fontSize: 14, color: colors.textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📋 Agendamentos do dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${appointments.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...appointments.map((appointment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAppointmentCard(appointment, colors),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Agendamento> _getAppointmentsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _appointments[key] ?? [];
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(appointment.dataHora),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(appointment.dataHora),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clienteNome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  appointment.servico,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}
