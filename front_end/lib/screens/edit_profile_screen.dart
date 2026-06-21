import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme_provider.dart';
import '../models/manicure.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Manicure? _manicure;
  bool _loading = true;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _bioController = TextEditingController();
  final _regrasController = TextEditingController();

  File? _selectedImage;
  String? _base64Image;

  List<int> _diasTrabalho = [];
  List<Map<String, dynamic>> _horarios = [];
  int _intervalo = 30;
  Map<String, List<Map<String, dynamic>>> _horariosPorDia = {};
  List<Map<String, dynamic>> _servicos = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _estadoController.dispose();
    _cidadeController.dispose();
    _bioController.dispose();
    _regrasController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final manicure = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _manicure = manicure;
          _nomeController.text = manicure.nome;
          _telefoneController.text = manicure.telefone ?? '';
          _estadoController.text = manicure.estado ?? '';
          _cidadeController.text = manicure.cidade ?? '';
          _bioController.text = manicure.bio ?? '';
          _regrasController.text = manicure.regras ?? '';
          _diasTrabalho = List<int>.from(manicure.diasTrabalho ?? []);
          _horarios = (manicure.horarios ?? []).map((h) => Map<String, dynamic>.from(h)).toList();
          _intervalo = manicure.intervalo ?? 30;
          _horariosPorDia = (manicure.horariosPorDia ?? {}).map(
            (key, value) => MapEntry(key, value.map((h) => Map<String, dynamic>.from(h)).toList()),
          );
          _servicos = List<Map<String, dynamic>>.from(
            (manicure.servicos ?? []).map((s) => Map<String, dynamic>.from(s)),
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, maxWidth: 500, maxHeight: 500, imageQuality: 50);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mime = 'image/jpeg';

    setState(() {
      _selectedImage = File(picked.path);
      _base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      String? newFotoUrl = _manicure?.foto;

      if (_base64Image != null) {
        try {
          newFotoUrl = await AuthService.uploadPhoto(
            _base64Image!,
            fotoAntiga: _manicure?.foto,
          );
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao enviar foto. Salvando dados sem nova foto.')),
            );
          }
        }
      }

      final data = <String, dynamic>{
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'estado': _estadoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'bio': _bioController.text.trim(),
        'regras': _regrasController.text.trim(),
        'dias_trabalho': _diasTrabalho,
        'horarios': _horarios,
        'intervalo': _intervalo,
        'horarios_por_dia': _horariosPorDia,
        'servicos': _servicos,
      };

      if (newFotoUrl != null) {
        data['foto'] = newFotoUrl;
      }

      final updated = await AuthService.updateProfile(data);

      if (mounted) {
        setState(() {
          _manicure = updated;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          backgroundColor: colors.primary,
          foregroundColor: colors.textLight,
        ),
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: colors.primary,
        foregroundColor: colors.textLight,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoSection(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Informações Pessoais', colors),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nomeController,
              label: 'Nome',
              icon: Icons.person_outline,
              colors: colors,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _telefoneController,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              colors: colors,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _estadoController,
              label: 'Estado',
              icon: Icons.location_on_outlined,
              colors: colors,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _cidadeController,
              label: 'Cidade',
              icon: Icons.location_city_outlined,
              colors: colors,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Sobre Mim', colors),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.format_quote,
              colors: colors,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Dias de Trabalho', colors),
            const SizedBox(height: 12),
            _buildDiasTrabalho(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Horários de Trabalho', colors),
            const SizedBox(height: 8),
            _buildIntervaloInfo(colors),
            const SizedBox(height: 12),
            _buildIntervaloSelector(colors),
            const SizedBox(height: 12),
            _buildHorarios(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Exceções por Dia', colors),
            const SizedBox(height: 8),
            _buildExcecoesInfo(colors),
            const SizedBox(height: 12),
            _buildExcecoes(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Serviços', colors),
            const SizedBox(height: 12),
            _buildServicos(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Regras', colors),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _regrasController,
              label: 'Regras de atendimento',
              icon: Icons.rule_outlined,
              colors: colors,
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.textLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _saving
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: colors.textLight, strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar Alterações',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(AppColors colors) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryLight, colors.primary],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: _buildPhotoContent(colors),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8)],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt, color: colors.textLight, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoContent(AppColors colors) {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, width: 120, height: 120, fit: BoxFit.cover);
    }
    if (_manicure?.foto != null && _manicure!.foto!.isNotEmpty) {
      return Image.network(
        _manicure!.foto!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatar(colors),
      );
    }
    return _buildDefaultAvatar(colors);
  }

  Widget _buildDefaultAvatar(AppColors colors) {
    return Container(
      width: 120,
      height: 120,
      color: colors.primaryLight.withValues(alpha: 0.3),
      child: Icon(Icons.person, size: 60, color: colors.primary),
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColors colors,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colors.primary),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderColor),
        ),
        filled: true,
        fillColor: colors.cardBg,
      ),
    );
  }

  Widget _buildDiasTrabalho(AppColors colors) {
    final weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(weekDays.length, (index) {
        final dayNum = index;
        final isActive = _diasTrabalho.contains(dayNum);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isActive) {
                _diasTrabalho.remove(dayNum);
              } else {
                _diasTrabalho.add(dayNum);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? colors.primary.withValues(alpha: 0.15) : colors.cardBg,
              borderRadius: BorderRadius.circular(20),
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
                  size: 16,
                  color: isActive ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: isActive ? colors.primary : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIntervaloInfo(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Defina os períodos em que você trabalha (ex: 8:00 às 12:00 e 14:00 às 18:00). '
              'O intervalo define a duração de cada atendimento — os horários disponíveis para agendamento serão gerados automaticamente.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervaloSelector(AppColors colors) {
    final intervals = [15, 20, 30, 40, 45, 60];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Text('Intervalo: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(width: 4),
          DropdownButton<int>(
            value: _intervalo,
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600),
            items: intervals.map((i) => DropdownMenuItem(value: i, child: Text('$i min'))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _intervalo = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorarios(AppColors colors) {
    return Column(
      children: [
        ..._horarios.asMap().entries.map((entry) {
          final i = entry.key;
          final horario = entry.value;
          final inicio = horario['inicio'] ?? '';
          final fim = horario['fim'] ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.access_time, color: colors.success, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$inicio às $fim',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      Text(
                        '${_horarios.length} período(s) configurado(s)',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.danger, size: 18),
                  onPressed: () {
                    setState(() => _horarios.removeAt(i));
                  },
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddHorarioDialog(colors),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Adicionar Período',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (_horarios.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildHorarioPreview(),
                    style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _buildHorarioPreview() {
    if (_horarios.isEmpty) return '';
    final slots = <String>[];
    for (final h in _horarios) {
      final inicio = h['inicio'] ?? '';
      final fim = h['fim'] ?? '';
      if (inicio.isEmpty || fim.isEmpty) continue;

      final startMinutes = _timeToMinutes(inicio);
      final endMinutes = _timeToMinutes(fim);
      var current = startMinutes;
      while (current <= endMinutes) {
        slots.add(_minutesToTime(current));
        current += _intervalo;
      }
    }
    if (slots.isEmpty) return 'Nenhum horário gerado';
    final display = slots.length > 6 ? slots.sublist(0, 6) : slots;
    final suffix = slots.length > 6 ? '... e mais ${slots.length - 6}' : '';
    return 'Horários: ${display.join(", ")}$suffix';
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showAddHorarioDialog(AppColors colors) {
    TimeOfDay? selectedStart;
    TimeOfDay? selectedEnd;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Adicionar Período de Trabalho', style: TextStyle(color: colors.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Define o início e o fim do período em que você atende.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.play_circle_outline, color: colors.success),
                title: Text(
                  selectedStart != null
                      ? 'Início: ${selectedStart!.hour.toString().padLeft(2, '0')}:${selectedStart!.minute.toString().padLeft(2, '0')}'
                      : 'Horário de início',
                  style: TextStyle(color: colors.textPrimary),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colors.borderColor),
                ),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                  if (time != null) setDialogState(() => selectedStart = time);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.stop_circle_outlined, color: colors.danger),
                title: Text(
                  selectedEnd != null
                      ? 'Fim: ${selectedEnd!.hour.toString().padLeft(2, '0')}:${selectedEnd!.minute.toString().padLeft(2, '0')}'
                      : 'Horário de fim',
                  style: TextStyle(color: colors.textPrimary),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colors.borderColor),
                ),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                  if (time != null) setDialogState(() => selectedEnd = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (selectedStart != null && selectedEnd != null) {
                  final startMin = selectedStart!.hour * 60 + selectedStart!.minute;
                  final endMin = selectedEnd!.hour * 60 + selectedEnd!.minute;
                  if (startMin >= endMin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('O horário de início deve ser anterior ao fim')),
                    );
                    return;
                  }
                  final start = '${selectedStart!.hour.toString().padLeft(2, '0')}:${selectedStart!.minute.toString().padLeft(2, '0')}';
                  final end = '${selectedEnd!.hour.toString().padLeft(2, '0')}:${selectedEnd!.minute.toString().padLeft(2, '0')}';
                  setState(() => _horarios.add({'inicio': start, 'fim': end}));
                  Navigator.pop(context);
                }
              },
              child: Text('Adicionar', style: TextStyle(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcecoesInfo(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se algum dia da semana tem horários diferentes do padrão, você pode adicionar uma exceção aqui. '
              'Dias sem exceção usam o horário padrão definido acima.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcecoes(AppColors colors) {
    final allDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final diasComExcecao = _horariosPorDia.keys.toList();

    if (_diasTrabalho.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'Selecione os dias de trabalho primeiro',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        ...diasComExcecao.map((dayKey) {
          final dayIndex = int.tryParse(dayKey) ?? -1;
          if (dayIndex < 0 || dayIndex > 6) return const SizedBox();
          final periodos = _horariosPorDia[dayKey] ?? [];
          final periodosText = periodos.map((p) => '${p['inicio']}-${p['fim']}').join(', ');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_calendar, color: colors.warning, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allDays[dayIndex],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      Text(
                        periodosText,
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.danger, size: 18),
                  onPressed: () {
                    setState(() => _horariosPorDia.remove(dayKey));
                  },
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddExcecaoDialog(colors),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Adicionar Exceção',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddExcecaoDialog(AppColors colors) {
    final allDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final diasDisponiveis = _diasTrabalho.where((d) => !_horariosPorDia.containsKey(d.toString())).toList();

    if (diasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os dias de trabalho já têm exceção ou nenhum dia está selecionado')),
      );
      return;
    }

    int? selectedDay;
    final periodos = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Nova Exceção', style: TextStyle(color: colors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolha o dia e defina os horários específicos para ele.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text('Dia da semana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: diasDisponiveis.map((d) {
                      final isSelected = selectedDay == d;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedDay = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.primary : colors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            allDays[d],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? colors.textLight : colors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (selectedDay != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Períodos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        GestureDetector(
                          onTap: () async {
                            TimeOfDay? start;
                            TimeOfDay? end;
                            await showDialog(
                              context: context,
                              builder: (ctx) => StatefulBuilder(
                                builder: (ctx, setInner) => AlertDialog(
                                  backgroundColor: colors.cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Novo período', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: Icon(Icons.play_circle_outline, color: colors.success),
                                        title: Text(
                                          start != null ? 'Início: ${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}' : 'Horário de início',
                                          style: TextStyle(color: colors.textPrimary),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colors.borderColor)),
                                        onTap: () async {
                                          final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 8, minute: 0));
                                          if (t != null) setInner(() => start = t);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      ListTile(
                                        leading: Icon(Icons.stop_circle_outlined, color: colors.danger),
                                        title: Text(
                                          end != null ? 'Fim: ${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}' : 'Horário de fim',
                                          style: TextStyle(color: colors.textPrimary),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colors.borderColor)),
                                        onTap: () async {
                                          final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 18, minute: 0));
                                          if (t != null) setInner(() => end = t);
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: colors.textSecondary))),
                                    TextButton(
                                      onPressed: () {
                                        if (start != null && end != null) {
                                          final s = '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}';
                                          final e = '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}';
                                          setDialogState(() => periodos.add({'inicio': s, 'fim': e}));
                                          Navigator.pop(ctx);
                                        }
                                      },
                                      child: Text('Adicionar', style: TextStyle(color: colors.primary)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('+ Período', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (periodos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        child: Text('Nenhum período adicionado', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      )
                    else
                      ...periodos.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.bgTertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: colors.primary),
                              const SizedBox(width: 6),
                              Expanded(child: Text('${p['inicio']} às ${p['fim']}', style: TextStyle(fontSize: 13, color: colors.textPrimary))),
                              GestureDetector(
                                onTap: () => setDialogState(() => periodos.removeAt(i)),
                                child: Icon(Icons.close, size: 14, color: colors.danger),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (selectedDay == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione um dia da semana')),
                  );
                  return;
                }
                if (periodos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adicione pelo menos um período')),
                  );
                  return;
                }
                setState(() {
                  _horariosPorDia[selectedDay.toString()] = List<Map<String, dynamic>>.from(periodos);
                });
                Navigator.pop(context);
              },
              child: Text('Salvar', style: TextStyle(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicos(AppColors colors) {
    return Column(
      children: [
        ..._servicos.asMap().entries.map((entry) {
          final i = entry.key;
          final servico = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.cut, color: colors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servico['nome'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                      ),
                      if (servico['preco'] != null)
                        Text(
                          'R\$${servico['preco']}',
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.danger, size: 18),
                  onPressed: () {
                    setState(() => _servicos.removeAt(i));
                  },
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddServicoDialog(colors),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Adicionar Serviço',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddServicoDialog(AppColors colors) {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adicionar Serviço', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do serviço',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Preço (R\$)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nomeController.text.trim().isNotEmpty) {
                setState(() {
                  _servicos.add({
                    'nome': nomeController.text.trim(),
                    'preco': double.tryParse(precoController.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Adicionar', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
