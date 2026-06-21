import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_provider.dart';
import '../models/manicure.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Manicure? _manicure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final manicure = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _manicure = manicure;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    final manicure = _manicure;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.primary.withValues(alpha: 0.1),
                  colors.bgPrimary,
                  colors.bgPrimary,
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: false,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.cardBg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowSm,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.menu, color: colors.primary, size: 24),
                  ),
                  onPressed: () => _showMenuFullScreen(context, colors),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.cardBg.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowSm,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.share_outlined, color: colors.primary, size: 20),
                    ),
                    onPressed: () => _showShareDialog(colors),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.cardBg.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      manicure?.nome ?? '',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryLight.withValues(alpha: 0.6),
                          colors.primary.withValues(alpha: 0.8),
                          colors.primary,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: colors.textLight.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: colors.textLight.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colors.textLight,
                                          colors.primaryLight,
                                          colors.primary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary.withValues(alpha: 0.4),
                                          blurRadius: 25,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: manicure?.foto != null && manicure!.foto!.isNotEmpty
                                            ? Image.network(
                                                manicure.foto!,
                                                width: 140,
                                                height: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _buildDefaultAvatar(colors),
                                              )
                                            : _buildDefaultAvatar(colors),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                manicure?.nome ?? '',
                                style: TextStyle(
                                  color: colors.textLight,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(blurRadius: 10, color: Colors.black26),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on, color: colors.textLight, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${manicure?.cidade ?? ''}, ${manicure?.estado ?? ''}',
                                    style: TextStyle(
                                      color: colors.textLight.withValues(alpha: 0.9),
                                      fontSize: 14,
                                      shadows: const [
                                        Shadow(blurRadius: 8, color: Colors.black26),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildBioCard(colors),
                  _buildStatsCard(colors),
                  _buildWorkDaysCard(colors),
                  _buildWorkHoursCard(colors),
                  _buildServicesCard(colors),
                  const SizedBox(height: 24),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(AppColors colors) {
    return Container(
      width: 140,
      height: 140,
      color: colors.primaryLight.withValues(alpha: 0.3),
      child: Icon(
        Icons.person,
        size: 70,
        color: colors.primary,
      ),
    );
  }

  Widget _buildBioCard(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.format_quote, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Sobre mim',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _manicure?.bio ?? '',
            style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AppColors colors) {
    final mediaEstrelas = _manicure?.estrelas ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildProfileStatItem('⭐', mediaEstrelas.toStringAsFixed(1), 'Avaliação', colors),
        ],
      ),
    );
  }

  Widget _buildProfileStatItem(String icon, String value, String label, AppColors colors) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }

  Widget _buildWorkDaysCard(AppColors colors) {
    final diasTrabalho = _manicure?.diasTrabalho ?? [];
    final allDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Dias de Trabalho',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(allDays.length, (index) {
              final dayNum = index;
              final isActive = diasTrabalho.contains(dayNum);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.bgTertiary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? colors.primary.withValues(alpha: 0.5) : colors.borderColor,
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
    );
  }

  Widget _buildWorkHoursCard(AppColors colors) {
    final horarios = _manicure?.horarios ?? [];
    final intervalo = _manicure?.intervalo ?? 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Horários de Funcionamento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
          if (intervalo > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Intervalo: $intervalo min',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.primary),
              ),
            ),
          ],
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
                  borderRadius: BorderRadius.circular(10),
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
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildServicesCard(AppColors colors) {
    final servicos = _manicure?.servicos ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cut, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Serviços Oferecidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
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
            ...servicos.map((service) {
              final name = service['nome'] ?? '';
              final price = service['preco'];
              final priceStr = price != null ? 'R\$${price.toString()}' : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
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
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _showMenuFullScreen(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: colors.shadowMd,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.bgTertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: colors.borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Meu Perfil',
                      subtitle: 'Editar perfil',
                      colors: colors,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.calendar_today_outlined,
                      title: 'Meus Agendamentos',
                      subtitle: 'Gerencie todos os agendamentos',
                      colors: colors,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.history,
                      title: 'Histórico',
                      subtitle: 'Veja o histórico completo',
                      colors: colors,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.analytics_outlined,
                      title: 'Estatísticas',
                      subtitle: 'Análise completa do seu negócio',
                      colors: colors,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Configurações',
                      subtitle: 'Ajustes e preferências',
                      colors: colors,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Ajuda e Suporte',
                      subtitle: 'Tire suas dúvidas',
                      colors: colors,
                      onTap: () => Navigator.pop(context),
                    ),
                    Divider(height: 24, color: colors.borderColor),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Sair',
                      subtitle: 'Desconectar-se da conta',
                      colors: colors,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showLogoutDialog(context, colors);
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColors colors,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? colors.danger.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? colors.danger : colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? colors.danger : colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair da conta', style: TextStyle(color: colors.textPrimary)),
        content: Text('Tem certeza que deseja sair da sua conta?',
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Sair', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }

  String _getProfileUrl() {
    final slug = _manicure?.slug ?? '';
    return 'https://pretty-nails-app.vercel.app/agendamento/$slug';
  }

  void _showShareDialog(AppColors colors) {
    final url = _getProfileUrl();
    final nome = _manicure?.nome ?? 'Manicure';
    final texto = 'Confira o perfil de $nome e agende seu horário!';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Text(
              'Compartilhar Perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha como compartilhar',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(
                    icon: Icons.chat_bubble,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    colors: colors,
                    onTap: () async {
                      final encoded = Uri.encodeComponent('$texto\n$url');
                      final uri = Uri.parse('https://wa.me/?text=$encoded');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildSocialButton(
                    icon: Icons.language,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    colors: colors,
                    onTap: () async {
                      final encoded = Uri.encodeComponent(url);
                      final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encoded');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildSocialButton(
                    icon: Icons.alternate_email,
                    label: 'Twitter/X',
                    color: const Color(0xFF000000),
                    colors: colors,
                    onTap: () async {
                      final encoded = Uri.encodeComponent('$texto $url');
                      final uri = Uri.parse('https://twitter.com/intent/tweet?text=$encoded');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(
                    icon: Icons.send,
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    colors: colors,
                    onTap: () async {
                      final encoded = Uri.encodeComponent('$texto\n$url');
                      final uri = Uri.parse('https://t.me/share/url?url=$encoded');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildSocialButton(
                    icon: Icons.link,
                    label: 'Copiar Link',
                    color: colors.primary,
                    colors: colors,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: '$texto\n$url'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiado!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
