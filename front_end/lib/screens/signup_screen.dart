import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cidadeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefoneController.dispose();
    _estadoController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await AuthService.signUp(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        telefone: _telefoneController.text.trim(),
        estado: _estadoController.text.trim(),
        cidade: _cidadeController.text.trim(),
      );

      if (mounted) {
        if (response['error'] != null) {
          setState(() {
            _errorMessage = response['error'] is String
                ? response['error']
                : 'Erro ao criar conta.';
          });
        } else {
          setState(() {
            _successMessage = 'Conta criada! Verifique seu e-mail para confirmar.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString();
          if (msg.contains('already') || msg.contains('já') || msg.contains('registered')) {
            _errorMessage = 'Este e-mail já está cadastrado.';
          } else {
            _errorMessage = 'Erro ao criar conta. Tente novamente.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    final colors = ThemeProvider.of(context).colors;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colors.primary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context).colors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 60,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pretty Nails',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua conta',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Nome completo', Icons.person_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu nome';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('E-mail', Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu e-mail';
                      if (!value.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      'Senha',
                      Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: colors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe sua senha';
                      if (value.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Telefone', Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu telefone';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _estadoController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration('Estado', Icons.map_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Obrigatório';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cidadeController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration('Cidade', Icons.location_city_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Obrigatório';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: colors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: colors.success, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.textLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: colors.textLight,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cadastrar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Já tem uma conta? Entrar',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
