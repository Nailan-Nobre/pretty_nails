import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/onesignal_service.dart';
import '../services/api_service.dart';

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
        await NotificationService.startBadgePolling();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de notificações negada. Ative nas configurações do celular.')),
        );
      }
    } else {
      await OneSignalService.revokePermission();
      NotificationService.stopBadgePolling();
    }

    try {
      await ApiService.put('/auth/profile', body: {
        'notificacoes_email': enabled && _notifType == 'email',
        'notificacoes_push': enabled && _notifType == 'app',
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
        await NotificationService.startBadgePolling();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de notificações negada.')),
        );
      }
    } else {
      await OneSignalService.revokePermission();
      NotificationService.stopBadgePolling();
    }

    try {
      await ApiService.put('/auth/profile', body: {
        'notificacoes_email': _notifEnabled && type == 'email',
        'notificacoes_push': _notifEnabled && type == 'app',
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
                _buildThemeSection(colors, themeProvider),
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
                  subtitle: 'Alterar o e-mail da conta',
                  colors: colors,
                  onTap: () => _showChangeEmailDialog(context),
                ),
                _buildActionTile(
                  icon: Icons.lock_outlined,
                  title: 'Alterar Senha',
                  subtitle: 'Alterar a senha da conta',
                  colors: colors,
                  onTap: () => _showChangePasswordDialog(context),
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
            Row(
              children: [
                Expanded(
                  child: _buildNotifOption(
                    icon: Icons.phone_android,
                    label: 'App',
                    isActive: _notifType == 'app',
                    colors: colors,
                    onTap: () => _saveNotifType('app'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNotifOption(
                    icon: Icons.email_outlined,
                    label: 'E-mail',
                    isActive: _notifType == 'email',
                    colors: colors,
                    onTap: () => _saveNotifType('email'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotifOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? colors.primary.withValues(alpha: 0.15) : colors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? colors.primary : colors.borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isActive ? colors.primary : colors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? colors.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(AppColors colors, ThemeProvider themeProvider) {
    final followingSystem = themeProvider.isFollowingSystem;
    final currentMode = themeProvider.isDark ? 'Escuro' : 'Claro';
    final subtitle = followingSystem
        ? 'Seguindo o tema do sistema ($currentMode)'
        : 'Modo manual: $currentMode';

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
                child: Icon(Icons.dark_mode, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  icon: Icons.phone_iphone,
                  label: 'Sistema',
                  isActive: followingSystem,
                  colors: colors,
                  onTap: () => themeProvider.followSystem(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  icon: Icons.light_mode,
                  label: 'Claro',
                  isActive: !followingSystem && !themeProvider.isDark,
                  colors: colors,
                  onTap: () => themeProvider.setDarkMode(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  icon: Icons.dark_mode,
                  label: 'Escuro',
                  isActive: !followingSystem && themeProvider.isDark,
                  colors: colors,
                  onTap: () => themeProvider.setDarkMode(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colors.primary.withValues(alpha: 0.15) : colors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? colors.primary : colors.borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isActive ? colors.primary : colors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? colors.primary : colors.textSecondary,
              ),
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

  void _showSnackbar(String message, {bool isError = false}) {
    final colors = ThemeProvider.of(context).colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? colors.danger : colors.success,
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    final currentPasswordController = TextEditingController();
    final newEmailController = TextEditingController();
    final confirmEmailController = TextEditingController();
    bool _loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Alterar E-mail', style: TextStyle(color: colors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Um link de confirmação será enviado para o novo e-mail.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    prefixIcon: Icon(Icons.lock_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Novo e-mail',
                    prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Confirmar novo e-mail',
                    prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: _loading ? null : () async {
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe sua senha atual')),
                  );
                  return;
                }
                if (newEmailController.text.isEmpty || !newEmailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe um e-mail válido')),
                  );
                  return;
                }
                if (newEmailController.text != confirmEmailController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Os e-mails não coincidem')),
                  );
                  return;
                }

                setDialogState(() => _loading = true);

                try {
                  final result = await AuthService.changeEmail(
                    newEmail: newEmailController.text.trim(),
                    password: currentPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackbar(result['message'] ?? 'E-mail alterado. Verifique sua caixa de entrada.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains(':') ? e.toString().split(':').last.trim() : 'Erro ao alterar e-mail'),
                        backgroundColor: colors.danger,
                      ),
                    );
                  }
                }
              },
              child: _loading
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                  : Text('Alterar', style: TextStyle(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Alterar Senha', style: TextStyle(color: colors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    prefixIcon: Icon(Icons.lock_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    prefixIcon: Icon(Icons.lock_reset_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nova senha',
                    prefixIcon: Icon(Icons.lock_reset_outlined, color: colors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: _loading ? null : () async {
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe sua senha atual')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A nova senha deve ter pelo menos 6 caracteres')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('As senhas não coincidem')),
                  );
                  return;
                }

                setDialogState(() => _loading = true);

                try {
                  final result = await AuthService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackbar(result['message'] ?? 'Senha alterada com sucesso!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains(':') ? e.toString().split(':').last.trim() : 'Erro ao alterar senha'),
                        backgroundColor: colors.danger,
                      ),
                    );
                  }
                }
              },
              child: _loading
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                  : Text('Alterar', style: TextStyle(color: colors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    final passwordController = TextEditingController();
    bool _loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Excluir Conta', style: TextStyle(color: colors.danger)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tem certeza que deseja excluir sua conta? Esta ação é irreversível e todos os seus dados serão perdidos.',
                  style: TextStyle(color: colors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Digite sua senha para confirmar',
                    prefixIcon: Icon(Icons.lock_outlined, color: colors.danger),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: _loading ? null : () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe sua senha para confirmar')),
                  );
                  return;
                }

                setDialogState(() => _loading = true);

                try {
                  await AuthService.deleteAccount(password: passwordController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains(':') ? e.toString().split(':').last.trim() : 'Erro ao excluir conta'),
                        backgroundColor: colors.danger,
                      ),
                    );
                  }
                }
              },
              child: _loading
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.danger))
                  : Text('Excluir', style: TextStyle(color: colors.danger)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair da conta', style: TextStyle(color: colors.textPrimary)),
        content: Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService.logout();
              navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text('Sair', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }
}
