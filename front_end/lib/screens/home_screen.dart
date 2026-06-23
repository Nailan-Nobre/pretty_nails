import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../models/manicure.dart';
import '../models/feedback.dart';
import '../services/auth_service.dart';
import '../services/agendamento_service.dart';
import '../services/feedback_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Manicure? _manicure;
  List<FeedbackModel> _feedbacks = [];
  Map<String, dynamic> _estatisticas = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _loadFromServer();
  }

  Future<void> _loadFromCache() async {
    try {
      final manicure = await AuthService.getProfile();
      final feedbacks = await FeedbackService.listarPorManicure(manicure.id);
      final estatisticas = await AgendamentoService.obterEstatisticas();

      if (mounted) {
        setState(() {
          _manicure = manicure;
          _feedbacks = feedbacks;
          _estatisticas = estatisticas;
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
      final manicure = await AuthService.getProfile(useCache: false);
      final feedbacks = await FeedbackService.listarPorManicure(manicure.id, useCache: false);
      final estatisticas = await AgendamentoService.obterEstatisticas(useCache: false);

      if (mounted) {
        setState(() {
          _manicure = manicure;
          _feedbacks = feedbacks;
          _estatisticas = estatisticas;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.book, size: 24, color: colors.textLight),
            const SizedBox(width: 12),
            Text(
              'Painel De Trabalho',
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
      backgroundColor: colors.bgTertiary,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _loadFromServer,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatisticsCard(context, colors),
                    const SizedBox(height: 16),
                    _buildFeedbackCard(context, colors),
                    const SizedBox(height: 16),
                    _buildWorkDaysCard(context, colors),
                    const SizedBox(height: 16),
                    _buildWorkHoursCard(context, colors),
                    const SizedBox(height: 16),
                    _buildServicesCard(context, colors),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, AppColors colors) {
    final total = _estatisticas['total'] ?? 0;
    final pendentes = _estatisticas['pendentes'] ?? 0;
    final confirmados = _estatisticas['confirmados'] ?? 0;
    final concluidos = _estatisticas['concluidos'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas da manicure',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '$total', colors),
                _buildStatItem('Pendentes', '$pendentes', colors),
                _buildStatItem('Confirmados', '$confirmados', colors),
                _buildStatItem('Concluídos', '$concluidos', colors),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showHistoricoModal(context, colors),
                icon: Icon(Icons.history, size: 16, color: colors.primary),
                label: Text(
                  'Ver Histórico Completo',
                  style: TextStyle(fontSize: 13, color: colors.primary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bgTertiary,
                  foregroundColor: colors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }

  void _showHistoricoModal(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoricoModal(colors: colors),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, AppColors colors) {
    final recentFeedbacks = _feedbacks.take(4).toList();
    final mediaEstrelas = _manicure?.estrelas ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  mediaEstrelas.toStringAsFixed(1),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStars(mediaEstrelas, 18, colors),
                    Text(
                      '(${_feedbacks.length} avaliações)',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Feedbacks Recentes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (recentFeedbacks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'Nenhum feedback ainda',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: recentFeedbacks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _buildFeedbackItem(recentFeedbacks[i], colors),
                ),
              ),
            const SizedBox(height: 10),
            if (_feedbacks.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showFeedbacksModal(context, colors),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Ver todos os feedbacks',
                    style: TextStyle(fontSize: 13, color: colors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(FeedbackModel feedback, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.clienteNome,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary),
                ),
              ),
              _buildStars(feedback.estrelas.toDouble(), 12, colors),
              const SizedBox(width: 4),
              Text(
                feedback.createdAt != null ? _formatDate(feedback.createdAt!) : '',
                style: TextStyle(fontSize: 10, color: colors.textSecondary),
              ),
            ],
          ),
          if (feedback.comentario != null && feedback.comentario!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              feedback.comentario!,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} semana(s) atrás';
    return '${(diff.inDays / 30).floor()} mês(es) atrás';
  }

  void _showFeedbacksModal(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbacksModal(
        colors: colors,
        feedbacks: _feedbacks,
      ),
    );
  }

  Widget _buildWorkDaysCard(BuildContext context, AppColors colors) {
    final diasTrabalho = _manicure?.diasTrabalho ?? [];
    final allDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Dias de Trabalho',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(allDays.length, (index) {
                final dayNum = index;
                final isActive = diasTrabalho.contains(dayNum);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? colors.primary.withValues(alpha: 0.15) : colors.bgTertiary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? colors.primary : colors.borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: isActive ? colors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        allDays[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: isActive ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkHoursCard(BuildContext context, AppColors colors) {
    final horarios = _manicure?.horarios ?? [];
    final intervalo = _manicure?.intervalo ?? 30;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Horários',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                if (intervalo > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$intervalo min',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.primary),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (horarios.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'Nenhum horário configurado',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              )
            else
              ...horarios.map((item) {
                final inicio = item['inicio'] ?? '';
                final fim = item['fim'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.schedule, color: colors.success, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$inicio às $fim',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard(BuildContext context, AppColors colors) {
    final servicos = _manicure?.servicos ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✂️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Serviços',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (servicos.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'Nenhum serviço cadastrado',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: servicos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final service = servicos[i];
                    final name = service['nome'] ?? '';
                    final price = service['preco'];
                    final priceStr = price != null ? 'R\$${price.toString()}' : '';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
                            ),
                          ),
                          if (priceStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                priceStr,
                                style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating, double size, AppColors colors) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: colors.warning, size: size);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: colors.warning, size: size);
        } else {
          return Icon(Icons.star_border, color: colors.warning, size: size);
        }
      }),
    );
  }
}

class _HistoricoModal extends StatefulWidget {
  final AppColors colors;
  const _HistoricoModal({required this.colors});

  @override
  State<_HistoricoModal> createState() => _HistoricoModalState();
}

class _HistoricoModalState extends State<_HistoricoModal> {
  bool _isYearMode = false;
  int _currentYear = DateTime.now().year;
  late DateTime _currentWeekStart;
  Map<String, dynamic> _yearStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getMonday(DateTime.now());
    _loadStats();
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AgendamentoService.obterHistoricoEstatisticas(_currentYear);
      if (mounted) {
        setState(() {
          _yearStats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _previousYear() {
    setState(() {
      _currentYear--;
    });
    _loadStats();
  }

  void _nextYear() {
    if (_currentYear < DateTime.now().year) {
      setState(() {
        _currentYear++;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Histórico Completo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildPeriodToggle(colors),
          const SizedBox(height: 8),
          _buildNavigationHeader(colors),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : _isYearMode
                    ? _buildYearChart(colors)
                    : _buildEmptyState(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isYearMode = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isYearMode ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Mês',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !_isYearMode ? colors.textLight : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isYearMode = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isYearMode ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Ano',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isYearMode ? colors.textLight : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationHeader(AppColors colors) {
    if (_isYearMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colors.primary),
            onPressed: _previousYear,
          ),
          Text(
            '$_currentYear',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _currentYear < DateTime.now().year ? colors.primary : colors.disabledText,
            ),
            onPressed: _currentYear < DateTime.now().year ? _nextYear : null,
          ),
        ],
      );
    }

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final monthLabel = _getMonthName(_currentWeekStart.month);
    final now = DateTime.now();
    final isCurrentWeek = _currentWeekStart.year == now.year &&
        _currentWeekStart.month == now.month &&
        _currentWeekStart.day == _getMonday(now).day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: colors.primary),
          onPressed: _previousWeek,
        ),
        Column(
          children: [
            Text(
              '$monthLabel ${_currentWeekStart.year}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            Text(
              '${_currentWeekStart.day} - ${weekEnd.day}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentWeek ? colors.disabledText : colors.primary,
          ),
          onPressed: isCurrentWeek ? null : _nextWeek,
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month];
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Nenhum agendamento nesta semana', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildYearChart(AppColors colors) {
    final months = _yearStats['meses'] ?? {};
    final now = DateTime.now();
    final maxMonth = _currentYear == now.year ? now.month : 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agendamentos por mês',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(maxMonth, (i) {
                final m = i + 1;
                final count = months['$m'] ?? 0;
                final maxCount = months.values.fold<int>(0, (max, v) => (v as int) > max ? v : max);
                final ratio = maxCount > 0 ? count / maxCount : 0.0;
                final barHeight = ratio * 160;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight > 4 ? barHeight : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMonthName(m).substring(0, 3),
                        style: TextStyle(fontSize: 10, color: colors.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbacksModal extends StatefulWidget {
  final AppColors colors;
  final List<FeedbackModel> feedbacks;
  const _FeedbacksModal({required this.colors, required this.feedbacks});

  @override
  State<_FeedbacksModal> createState() => _FeedbacksModalState();
}

class _FeedbacksModalState extends State<_FeedbacksModal> {
  int? _selectedRating;

  List<FeedbackModel> get _filteredFeedbacks {
    if (_selectedRating == null) return widget.feedbacks;
    return widget.feedbacks.where((f) => f.estrelas == _selectedRating).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Todos os Feedbacks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildStarFilter(colors),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredFeedbacks.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum feedback com $_selectedRating estrela(s)',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredFeedbacks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final fb = _filteredFeedbacks[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.bgTertiary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fb.clienteNome,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (si) {
                                    return Icon(
                                      si < fb.estrelas ? Icons.star : Icons.star_border,
                                      size: 14,
                                      color: colors.warning,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (fb.comentario != null && fb.comentario!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                fb.comentario!,
                                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              fb.createdAt != null ? _formatDate(fb.createdAt!) : '',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} semana(s) atrás';
    return '${(diff.inDays / 30).floor()} mês(es) atrás';
  }

  Widget _buildStarFilter(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildFilterButton(null, 'Todos', colors),
            ...List.generate(5, (i) {
              final stars = 5 - i;
              return _buildFilterButton(stars, '$stars', colors);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(int? rating, String label, AppColors colors) {
    final isActive = _selectedRating == rating;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRating = rating),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: rating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: isActive ? colors.textLight : colors.warning),
                      const SizedBox(width: 2),
                      Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? colors.textLight : colors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? colors.textLight : colors.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
