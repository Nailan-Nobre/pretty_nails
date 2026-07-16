import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      backgroundColor: colors.bgTertiary,
      appBar: AppBar(
        title: Text(
          'Termos de Uso',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Aceite dos Termos',
              content: 'Ao acessar ou usar o aplicativo Pretty Nails, você concorda com estes Termos de Uso. Se não concordar com algum dos termos, não utilize o aplicativo.',
              colors: colors,
            ),
            _buildSection(
              title: '2. Descrição do Serviço',
              content: 'O Pretty Nails é um aplicativo de gestão para profissionais de manicure e pedicure. O app permite o cadastro de profissionais, agendamento de serviços, gestão de horários, envio de notificações e acompanhamento de atendimentos.',
              colors: colors,
            ),
            _buildSection(
              title: '3. Cadastro e Conta',
              content: 'Para usar o Pretty Nails, é necessário criar uma conta com informações verdadeiras e atualizadas. Você é responsável por manter a confidencialidade da sua senha e por todas as atividades realizadas na sua conta. O profissional deve ter pelo menos 18 anos para se cadastrar.',
              colors: colors,
            ),
            _buildSection(
              title: '4. Uso Adequado',
              content: 'O aplicativo deve ser utilizado exclusivamente para fins lícitos e em conformidade com estes Termos. É proibido:\n\n• Usar o app para fins ilegais ou não autorizados;\n• Tentar acessar contas de outros usuários;\n• Enviar conteúdo ofensivo, difamatório ou inadequado;\n• Interferir no funcionamento do aplicativo;\n• Usar bots ou outros meios automatizados para acessar o app.',
              colors: colors,
            ),
            _buildSection(
              title: '5. Agendamentos',
              content: 'O Pretty Nails facilita o agendamento de serviços entre profissionais e clientes. No entanto, o app atua apenas como intermediário. A responsabilidade pelo cumprimento dos horários e pela qualidade dos serviços é exclusivamente do profissional e do cliente envolvidos.',
              colors: colors,
            ),
            _buildSection(
              title: '6. Pagamentos',
              content: 'O Pretty Nails não processa pagamentos diretamente. Eventuais cobranças por serviços são de responsabilidade entre profissional e cliente, sem interferência do aplicativo.',
              colors: colors,
            ),
            _buildSection(
              title: '7. Propriedade Intelectual',
              content: 'Todo o conteúdo do aplicativo, incluindo logotipos, textos, imagens, código-fonte e design, é protegido por direitos autorais e pertence ao Pretty Nails. Você não pode copiar, modificar, distribuir ou reproduzir qualquer parte do app sem autorização.',
              colors: colors,
            ),
            _buildSection(
              title: '8. Dados e Privacidade',
              content: 'Coletamos e processamos dados pessoais conforme descrito na nossa Política de Privacidade. Ao usar o app, você consente com a coleta e uso de seus dados conforme indicado. Seus dados são utilizados apenas para o funcionamento adequado do serviço.',
              colors: colors,
            ),
            _buildSection(
              title: '9. Notificações',
              content: 'O app pode enviar notificações relacionadas a agendamentos, confirmações e atualizações de perfil. Você pode gerenciar suas preferências de notificação a qualquer momento nas configurações do aplicativo.',
              colors: colors,
            ),
            _buildSection(
              title: '10. Isenção de Responsabilidade',
              content: 'O Pretty Nails é fornecido "como está", sem garantias de qualquer tipo. Não nos responsabilizamos por:\n\n• Danos decorrentes do uso do aplicativo;\n• Indisponibilidade temporária do serviço;\n• Ações de terceiros dentro do aplicativo;\n• Perda de dados por motivos técnicos.',
              colors: colors,
            ),
            _buildSection(
              title: '11. Alterações nos Termos',
              content: 'Reservamo-nos o direito de alterar estes Termos a qualquer momento. Usuários serão notificados sobre mudanças significativas. O uso continuado do app após alterações implica aceitação dos novos termos.',
              colors: colors,
            ),
            _buildSection(
              title: '12. Rescisão',
              content: 'Podemos suspender ou encerrar sua conta a qualquer momento, sem aviso prévio, caso detectemos violação destes Termos ou uso inadequado do aplicativo.',
              colors: colors,
            ),
            _buildSection(
              title: '13. Lei Aplicável',
              content: 'Estes Termos são regidos pelas leis da República Federativa do Brasil. Qualquer disputa será resolvida nos tribunais competentes do Brasil.',
              colors: colors,
            ),
            _buildSection(
              title: '14. Contato',
              content: 'Em caso de dúvidas sobre estes Termos de Uso, entre em contato conosco pelo e-mail: focusinbeauty25@gmail.com',
              colors: colors,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Última atualização: 16 de julho de 2026',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pretty Nails',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    Text(
                      'Termos de Uso e Política de Privacidade',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ao utilizar o Pretty Nails, você concorda com todos os termos descritos neste documento. Leia atentamente antes de usar o aplicativo.',
            style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required AppColors colors}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
