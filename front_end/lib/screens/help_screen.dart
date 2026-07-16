import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final profile = await AuthService.getProfile(useCache: true);
      if (mounted) {
        setState(() {
          _userEmail = profile.email;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      backgroundColor: colors.bgTertiary,
      appBar: AppBar(
        title: Text(
          'Central de Ajuda',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 20),
            _buildSectionTitle('Perguntas Frequentes', colors),
            const SizedBox(height: 8),
            _buildFaqItem(
              question: 'Como faço para agendar um horário?',
              answer: 'Acesse o perfil da manicure desejada, clique em "Agendar" e escolha o dia, horário e serviço desejado. Você receberá uma confirmação por e-mail ou notificação.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Como cancelo um agendamento?',
              answer: 'Vá até a aba "Agendamentos" e selecione o agendamento que deseja cancelar. Clique em "Cancelar" e confirme a ação.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Como altero minhas informações de perfil?',
              answer: 'Acesse a aba "Perfil" e clique no ícone de edição. Lá você pode alterar nome, telefone, foto, localização e outros dados.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Esqueci minha senha. O que fazer?',
              answer: 'Na tela de login, clique em "Esqueci minha senha" e informe seu e-mail. Você receberá um link para redefinir sua senha.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Como faço para excluir minha conta?',
              answer: 'Vá até "Configurações" > "Excluir Conta". Esta ação é irreversível e todos os seus dados serão apagados.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Como recebo notificações de agendamentos?',
              answer: 'Ative as notificações em "Configurações" > "Notificações". Você pode optar por receber notificações no app ou por e-mail.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'O app é gratuito?',
              answer: 'Sim! O Pretty Nails é gratuito para clientes que desejam agendar serviços. Os profissionais também podem usar o app gratuitamente para gerenciar seus atendimentos.',
              colors: colors,
            ),
            _buildFaqItem(
              question: 'Como entro em contato com o suporte?',
              answer: 'Utilize o formulário abaixo para nos enviar sua mensagem. Responderemos o mais breve possível pelo seu e-mail.',
              colors: colors,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Fale Conosco', colors),
            const SizedBox(height: 8),
            _buildContactForm(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.help_outline, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como podemos ajudar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confira as perguntas frequentes ou envie sua mensagem.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer, required AppColors colors}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: colors.primary,
        collapsedIconColor: colors.textSecondary,
        title: Text(
          question,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(AppColors colors) {
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
          Text(
            'Envie sua mensagem',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Sua mensagem será enviada para nossa equipe de suporte.',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          if (_userEmail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: colors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enviando como:',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                        Text(
                          _userEmail,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Sua mensagem',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_outlined, color: colors.primary),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.textLight),
                    )
                  : Icon(Icons.send, size: 18, color: colors.textLight),
              label: Text(
                _sending ? 'Enviando...' : 'Enviar Mensagem',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textLight),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackbar('Escreva sua mensagem.');
      return;
    }

    setState(() => _sending = true);

    try {
      final response = await ApiService.post('/auth/support', body: {
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        _showSnackbar(response['message'] ?? 'Mensagem enviada com sucesso!');
        _messageController.clear();
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showSnackbar(e.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackbar('Erro ao enviar mensagem. Tente novamente.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    final colors = ThemeProvider.of(context).colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? colors.danger : colors.primary,
      ),
    );
  }
}
