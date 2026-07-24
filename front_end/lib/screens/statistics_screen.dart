import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/agendamento_service.dart';
import '../services/feedback_service.dart';
import '../services/auth_service.dart';
import '../models/feedback.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> _estatisticas = {};
  Map<String, dynamic> _historico = {};
  List<FeedbackModel> _feedbacks = [];
  bool _loading = true;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await AuthService.getProfile(useCache: false);
      final estatisticas = await AgendamentoService.obterEstatisticas(useCache: false);
      final historico = await AgendamentoService.obterHistoricoEstatisticas(_currentYear);
      final feedbacks = await FeedbackService.listarPorManicure(profile.id, useCache: false);

      if (mounted) {
        setState(() {
          _estatisticas = estatisticas;
          _historico = historico;
          _feedbacks = feedbacks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      backgroundColor: colors.bgTertiary,
      appBar: AppBar(
        title: Text(
          'Estatísticas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
        ),
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.borderColor),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(colors),
                    const SizedBox(height: 16),
                    _buildStatusPieChart(colors),
                    const SizedBox(height: 16),
                    _buildMonthlyBarChart(colors),
                    const SizedBox(height: 16),
                    _buildTrendChart(colors),
                    const SizedBox(height: 16),
                    _buildRatingOverview(colors),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(AppColors colors) {
    final total = (_estatisticas['total'] ?? 0) as int;
    final concluidos = (_estatisticas['concluidos'] ?? 0) as int;
    final cancelados = (_estatisticas['cancelados'] ?? 0) as int;
    final expirados = (_estatisticas['expirados'] ?? 0) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumo Geral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 4),
        Text('Visão geral dos seus agendamentos', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMiniCard('Total', '$total', Icons.calendar_month, colors.primary, colors)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniCard('Concluídos', '$concluidos', Icons.check_circle, colors.success, colors)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMiniCard('Cancelados', '$cancelados', Icons.cancel, colors.danger, colors)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniCard('Expirados', '$expirados', Icons.schedule, colors.warning, colors)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(AppColors colors) {
    final concluidos = (_estatisticas['concluidos'] ?? 0) as int;
    final cancelados = (_estatisticas['cancelados'] ?? 0) as int;
    final expirados = (_estatisticas['expirados'] ?? 0) as int;
    final total = concluidos + cancelados + expirados;

    final segments = [
      _PieSegment(label: 'Concluídos', value: concluidos, color: colors.success),
      _PieSegment(label: 'Cancelados', value: cancelados, color: colors.danger),
      _PieSegment(label: 'Expirados', value: expirados, color: colors.warning),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Distribuição por Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mostra a proporção de agendamentos concluídos, cancelados e expirados. Quanto maior a fatia, mais agendamentos aquele status representa.',
            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            _buildEmptyChart('Nenhum agendamento registrado', colors)
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _PieChartPainter(segments: segments, total: total),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: segments.map((s) {
                      final pct = total > 0 ? (s.value / total * 100).round() : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s.label, style: TextStyle(fontSize: 12, color: colors.textPrimary))),
                            Text('${s.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                            const SizedBox(width: 4),
                            Text('($pct%)', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(AppColors colors) {
    final dadosConcluidos = (_historico['dadosConcluidos'] ?? []) as List;
    final dadosCancelados = (_historico['dadosCancelados'] ?? []) as List;
    final labels = (_historico['labels'] ?? []) as List;

    int maxVal = 0;
    for (int i = 0; i < dadosConcluidos.length; i++) {
      final c = (dadosConcluidos[i] ?? 0) as int;
      final ca = (dadosCancelados[i] ?? 0) as int;
      if (c > maxVal) maxVal = c;
      if (ca > maxVal) maxVal = ca;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Agendamentos por Mês', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cada barra representa um mês. As barras verdes mostram agendamentos concluídos e as vermelhos os cancelados. Barras mais altas significam mais agendamentos naquele mês.',
            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 10, height: 10, color: colors.success),
              const SizedBox(width: 4),
              Text('Concluídos', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
              const SizedBox(width: 12),
              Container(width: 10, height: 10, color: colors.danger),
              const SizedBox(width: 4),
              Text('Cancelados', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (dadosConcluidos.isEmpty || maxVal == 0)
            _buildEmptyChart('Nenhum dado mensal disponível', colors)
          else
            SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(dadosConcluidos.length, (i) {
                      final c = (dadosConcluidos[i] ?? 0) as int;
                      final ca = (dadosCancelados[i] ?? 0) as int;
                      final hConcl = maxVal > 0 ? (c / maxVal) * (constraints.maxHeight - 40) : 0.0;
                      final hCancel = maxVal > 0 ? (ca / maxVal) * (constraints.maxHeight - 40) : 0.0;
                      final label = i < labels.length ? (labels[i] as String).substring(0, 3) : '';

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (c > 0 || ca > 0)
                                Text('${c + ca}', style: TextStyle(fontSize: 8, color: colors.textSecondary)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 8,
                                    height: hConcl.clamp(1.0, constraints.maxHeight - 40),
                                    decoration: BoxDecoration(color: colors.success, borderRadius: BorderRadius.circular(2)),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 8,
                                    height: hCancel.clamp(1.0, constraints.maxHeight - 40),
                                    decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(2)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(label, style: TextStyle(fontSize: 9, color: colors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AppColors colors) {
    final dadosConcluidos = (_historico['dadosConcluidos'] ?? []) as List;
    final dadosCancelados = (_historico['dadosCancelados'] ?? []) as List;

    List<int> dados = [];
    for (int i = 0; i < dadosConcluidos.length; i++) {
      dados.add(((dadosConcluidos[i] ?? 0) as int) + ((dadosCancelados[i] ?? 0) as int));
    }

    int maxVal = 0;
    for (final v in dados) {
      if (v > maxVal) maxVal = v;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Tendência', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Linha que mostra a evolução do total de agendamentos ao longo dos meses. Se a linha sobe, seus agendamentos estão crescendo. Se desce, estão diminuindo.',
            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (dados.isEmpty || maxVal == 0)
            _buildEmptyChart('Sem dados de tendência', colors)
          else
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: Size.infinite,
                painter: _LineChartPainter(
                  data: dados,
                  maxVal: maxVal,
                  color: colors.primary,
                  lineColor: colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview(AppColors colors) {
    final ratings = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final fb in _feedbacks) {
      ratings[fb.estrelas] = (ratings[fb.estrelas] ?? 0) + 1;
    }

    final totalFb = _feedbacks.length;
    final maxCount = ratings.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rate_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Avaliações', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Barras que mostram quantas avaliações você recebeu de cada nota. A barra de 5 estrelas representa as melhores avaliações.',
            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (totalFb == 0)
            _buildEmptyChart('Nenhuma avaliação recebida', colors)
          else
            ...List.generate(5, (i) {
              final star = 5 - i;
              final count = ratings[star] ?? 0;
              final ratio = maxCount > 0 ? count / maxCount : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('$star', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    Icon(Icons.star, size: 12, color: colors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: colors.bgTertiary,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$count', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message, AppColors colors) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
    );
  }
}

class _PieSegment {
  final String label;
  final int value;
  final Color color;
  const _PieSegment({required this.label, required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final int total;
  _PieChartPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    double startAngle = -pi / 2;

    for (final seg in segments) {
      if (seg.value == 0) continue;
      final sweep = (seg.value / total) * 2 * pi;
      final paint = Paint()..color = seg.color..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // Center circle (donut)
    final centerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineChartPainter extends CustomPainter {
  final List<int> data;
  final int maxVal;
  final Color color;
  final Color lineColor;

  _LineChartPainter({
    required this.data,
    required this.maxVal,
    required this.color,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxVal == 0) return;

    final padding = const EdgeInsets.fromLTRB(8, 8, 8, 20);
    final w = size.width - padding.left - padding.right;
    final h = size.height - padding.top - padding.bottom;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + (w / (data.length - 1)) * i;
      final y = padding.top + h - (data[i] / maxVal) * h;
      points.add(Offset(x, y));
    }

    // Fill gradient
    final fillPath = Path()
      ..moveTo(points.first.dx, padding.top + h)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, padding.top + h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = lineColor..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
