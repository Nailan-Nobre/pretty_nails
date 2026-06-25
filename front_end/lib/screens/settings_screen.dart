import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/onesignal_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  String _notifType = 'app';
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifEnabled = prefs.getBool('notif_enabled') ?? true;
      _notifType = prefs.getString('notif_type') ?? 'app';
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _saveNotifPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', enabled);
    await prefs.setBool('notif_app', enabled && _notifType == 'app');
    setState(() => _notifEnabled = enabled);

    if (enabled && _notifType == 'app') {
      final granted = await OneSignalService.requestPermission();
      if (granted) {
        await OneSignalService.optIn();
        await NotificationService.startPolling();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de notificações negada. Ative nas configurações do celular.')),
        );
      }
    } else {
      await OneSignalService.optOut();
      NotificationService.stopPolling();
    }

    try {
      await ApiService.put('/auth/profile', body: {
        'notificacoes_email': enabled && _notifType == 'email',
      });
    } catch (_) {}
  }

  Future<void> _saveNotifType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_type', type);
    await prefs.setBool('notif_app', _notifEnabled && type == 'app');
    setState(() => _notifType = type);

    if (type == 'app' && _notifEnabled) {
      final granted = await OneSignalService.requestPermission();
      if (granted) {
        await OneSignalService.optIn();
        await NotificationService.startPolling();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de notificações negada.')),
        );
      }
    } else {
      await OneSignalService.optOut();
      NotificationService.stopPolling();
    }

    try {
      await ApiService.put('/auth/profile', body: {
        'notificacoes_email': _notifEnabled && type == 'email',
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      backgroundColor: colors.bgTertiary,
      appBar: AppBar(
        title: Text(
          'Configurações',
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
          children: [
            _buildSection(
              title: 'Configurações Gerais',
              colors: colors,
              children: [
                _buildNotifSection(colors),
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Modo Escuro',
                  subtitle: 'Ativar tema escuro',
                  value: themeProvider.isDark,
                  colors: colors,
                  onChanged: (value) => themeProvider.setDarkMode(value),
                ),
                _buildSwitchTile(
                  icon: Icons.volume_up,
                  title: 'Sons',
                  subtitle: 'Ativar sons do aplicativo',
                  value: _soundEnabled,
                  colors: colors,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('sound_enabled', value);
                    setState(() => _soundEnabled = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Configurações de Conta',
              colors: colors,
              children: [
                _buildActionTile(
                  icon: Icons.email_outlined,
                  title: 'Alterar E-mail',
                  subtitle: 'maria.silva@email.com',
                  colors: colors,
                  onTap: () => _showSnackbar('Alterar e-mail'),
                ),
                _buildActionTile(
                  icon: Icons.lock_outlined,
                  title: 'Alterar Senha',
                  subtitle: '••••••••',
                  colors: colors,
                  onTap: () => _showSnackbar('Alterar senha'),
                ),
                _buildActionTile(
                  icon: Icons.delete_outline,
                  title: 'Excluir Conta',
                  subtitle: 'Esta ação é irreversível',
                  colors: colors,
                  onTap: () => _showDeleteAccountDialog(context),
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Privacidade e Segurança',
              colors: colors,
              children: [
                _buildActionTile(
                  icon: Icons.visibility_outlined,
                  title: 'Conta Privada/Pública',
                  subtitle: 'Atualmente: Pública',
                  colors: colors,
                  onTap: () => _showSnackbar('Alterar visibilidade'),
                ),
                _buildActionTile(
                  icon: Icons.security_outlined,
                  title: 'Permissões do App',
                  subtitle: 'Gerenciar permissões',
                  colors: colors,
                  onTap: () => _showSnackbar('Permissões do app'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Suporte e Ajuda',
              colors: colors,
              children: [
                _buildActionTile(
                  icon: Icons.help_outline,
                  title: 'Central de Ajuda',
                  subtitle: 'Tire suas dúvidas',
                  colors: colors,
                  onTap: () => _showSnackbar('Central de ajuda'),
                ),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  subtitle: 'Política de Privacidade',
                  colors: colors,
                  onTap: () => _showSnackbar('Termos de uso'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Versão do App',
              colors: colors,
              children: [
                _buildActionTile(
                  icon: Icons.sync_outlined,
                  title: 'Verificar Atualizações',
                  subtitle: 'Versão 1.0.0',
                  colors: colors,
                  onTap: () => _showSnackbar('Verificando atualizações...'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(Icons.logout, size: 20, color: colors.danger),
                label: Text('Sair', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.danger)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bgTertiary,
                  foregroundColor: colors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.borderColor)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifSection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderLight))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.notifications, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificações', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                    Text('Receber notificações de agendamentos', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: _notifEnabled,
                onChanged: (v) => _saveNotifPref(v),
                activeThumbColor: colors.primary,
                activeTrackColor: colors.primaryLight,
              ),
            ],
          ),
          if (_notifEnabled) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                children: [
                  _buildNotifTypeTile('app', 'Notificações no App', 'Receber notificações push no aplicativo', Icons.phone_android, colors),
                  _buildNotifTypeTile('email', 'Notificações por E-mail', 'Receber e-mail sobre agendamentos', Icons.email_outlined, colors),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotifTypeTile(String value, String title, String subtitle, IconData icon, AppColors colors) {
    final isSelected = _notifType == value;
    return InkWell(
      onTap: () => _saveNotifType(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.primary.withValues(alpha: 0.3) : colors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? colors.primary : colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required AppColors colors, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.shadowSm, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary, letterSpacing: 0.5)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon, required String title, required String subtitle,
    required bool value, required AppColors colors, required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderLight))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: colors.primary, activeTrackColor: colors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon, required String title, required String subtitle,
    required AppColors colors, required VoidCallback onTap, bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderLight))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? colors.danger.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isDestructive ? colors.danger : colors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDestructive ? colors.danger : colors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDestructive ? colors.danger.withValues(alpha: 0.7) : colors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1), backgroundColor: ThemeProvider.of(context).colors.bgTertiary),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir Conta', style: TextStyle(color: colors.danger)),
        content: Text('Tem certeza que deseja excluir sua conta? Esta ação é irreversível.', style: TextStyle(color: colors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: colors.textSecondary))),
          TextButton(
            onPressed: () { Navigator.pop(context); _showSnackbar('Conta excluída com sucesso'); },
            child: Text('Excluir', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair da conta', style: TextStyle(color: colors.textPrimary)),
        content: Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: colors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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
}
