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
  List<String> _horarios = [];
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
          _horarios = List<String>.from(manicure.horarios ?? []);
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
            _buildSectionTitle('Horários', colors),
            const SizedBox(height: 12),
            _buildHorarios(colors),
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
    final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(weekDays.length, (index) {
        final dayNum = index + 1;
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

  Widget _buildHorarios(AppColors colors) {
    return Column(
      children: [
        ..._horarios.asMap().entries.map((entry) {
          final i = entry.key;
          final horario = entry.value;
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
                Icon(Icons.access_time, color: colors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(horario, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
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
                  'Adicionar Horário',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
          title: Text('Adicionar Horário', style: TextStyle(color: colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.access_time, color: colors.primary),
                title: Text(
                  selectedStart != null
                      ? 'Início: ${selectedStart!.hour.toString().padLeft(2, '0')}:${selectedStart!.minute.toString().padLeft(2, '0')}'
                      : 'Horário de início',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                  if (time != null) setDialogState(() => selectedStart = time);
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time_filled, color: colors.primary),
                title: Text(
                  selectedEnd != null
                      ? 'Fim: ${selectedEnd!.hour.toString().padLeft(2, '0')}:${selectedEnd!.minute.toString().padLeft(2, '0')}'
                      : 'Horário de fim',
                  style: TextStyle(color: colors.textPrimary),
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
                  final start = '${selectedStart!.hour.toString().padLeft(2, '0')}:${selectedStart!.minute.toString().padLeft(2, '0')}';
                  final end = '${selectedEnd!.hour.toString().padLeft(2, '0')}:${selectedEnd!.minute.toString().padLeft(2, '0')}';
                  setState(() => _horarios.add('$start - $end'));
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
