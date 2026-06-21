import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  String? _selectedEstado;
  String? _selectedCidade;
  List<Map<String, String>> _estados = [];
  List<Map<String, String>> _cidades = [];
  bool _cidadesLoading = false;
  bool _cidadesDisabled = true;

  @override
  void initState() {
    super.initState();
    _carregarEstados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarEstados() async {
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _estados = data.map<Map<String, String>>((e) => {
            'sigla': e['sigla'] as String,
            'nome': e['nome'] as String,
          }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _estados = [
          {'sigla': 'AC', 'nome': 'Acre'},
          {'sigla': 'AL', 'nome': 'Alagoas'},
          {'sigla': 'AP', 'nome': 'Amapá'},
          {'sigla': 'AM', 'nome': 'Amazonas'},
          {'sigla': 'BA', 'nome': 'Bahia'},
          {'sigla': 'CE', 'nome': 'Ceará'},
          {'sigla': 'DF', 'nome': 'Distrito Federal'},
          {'sigla': 'ES', 'nome': 'Espírito Santo'},
          {'sigla': 'GO', 'nome': 'Goiás'},
          {'sigla': 'MA', 'nome': 'Maranhão'},
          {'sigla': 'MT', 'nome': 'Mato Grosso'},
          {'sigla': 'MS', 'nome': 'Mato Grosso do Sul'},
          {'sigla': 'MG', 'nome': 'Minas Gerais'},
          {'sigla': 'PA', 'nome': 'Pará'},
          {'sigla': 'PB', 'nome': 'Paraíba'},
          {'sigla': 'PR', 'nome': 'Paraná'},
          {'sigla': 'PE', 'nome': 'Pernambuco'},
          {'sigla': 'PI', 'nome': 'Piauí'},
          {'sigla': 'RJ', 'nome': 'Rio de Janeiro'},
          {'sigla': 'RN', 'nome': 'Rio Grande do Norte'},
          {'sigla': 'RS', 'nome': 'Rio Grande do Sul'},
          {'sigla': 'RO', 'nome': 'Rondônia'},
          {'sigla': 'RR', 'nome': 'Roraima'},
          {'sigla': 'SC', 'nome': 'Santa Catarina'},
          {'sigla': 'SP', 'nome': 'São Paulo'},
          {'sigla': 'SE', 'nome': 'Sergipe'},
          {'sigla': 'TO', 'nome': 'Tocantins'},
        ];
      });
    }
  }

  Future<void> _carregarCidades(String siglaEstado) async {
    setState(() {
      _cidadesLoading = true;
      _selectedCidade = null;
      _cidades = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$siglaEstado/municipios?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _cidades = data.map<Map<String, String>>((e) => {
            'nome': e['nome'] as String,
          }).toList();
          _cidadesLoading = false;
        });
      }
    } catch (e) {
      setState(() => _cidadesLoading = false);
    }
  }

  void _onEstadoChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedEstado = value;
        _cidadesDisabled = false;
      });
      _carregarCidades(value);
    }
  }

  void _onCidadeChanged(String? value) {
    if (value != null) {
      setState(() => _selectedCidade = value);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEstado == null || _selectedCidade == null) {
      setState(() => _errorMessage = 'Selecione o estado e a cidade.');
      return;
    }

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
        estado: _selectedEstado!,
        cidade: _selectedCidade!,
      );

      if (mounted) {
        if (response['error'] != null) {
          setState(() {
            _errorMessage = response['error'] is String
                ? response['error']
                : 'Erro ao criar conta.';
          });
        } else if (response['success'] == false) {
          setState(() {
            _errorMessage = response['error'] ?? 'Erro ao criar conta.';
          });
        } else {
          setState(() {
            _successMessage = response['message'] ?? 'Conta criada! Verifique seu e-mail para confirmar.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString();
          if (msg.contains('already') || msg.contains('já') || msg.contains('registered')) {
            _errorMessage = 'Este e-mail já está cadastrado. Faça login ou use outro e-mail.';
          } else if (msg.contains('rate') || msg.contains('limit')) {
            _errorMessage = 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
          } else {
            _errorMessage = 'Erro ao criar conta. Verifique seus dados e tente novamente.';
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
    final colors = AppColors.light;
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
    final colors = AppColors.light;

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
                      if (value == null || value.trim().isEmpty) return 'Informe seu nome';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('E-mail', Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      _TelefoneFormatter(),
                    ],
                    decoration: _inputDecoration('Telefone', Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Informe seu telefone';
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) return 'Telefone inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEstado,
                    decoration: _inputDecoration('Estado', Icons.map_outlined),
                    items: _estados.map((estado) {
                      return DropdownMenuItem<String>(
                        value: estado['sigla'],
                        child: Text(estado['nome']!),
                      );
                    }).toList(),
                    onChanged: _onEstadoChanged,
                    validator: (value) {
                      if (value == null) return 'Selecione o estado';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCidade,
                    decoration: _inputDecoration(
                      'Cidade',
                      Icons.location_city_outlined,
                    ),
                    items: _cidadesDisabled
                        ? []
                        : _cidades.map((cidade) {
                            return DropdownMenuItem<String>(
                              value: cidade['nome'],
                              child: Text(cidade['nome']!),
                            );
                          }).toList(),
                    onChanged: _cidadesDisabled
                        ? (value) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Atenção'),
                                content: const Text('Escolha o estado primeiro.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : _onCidadeChanged,
                    validator: (value) {
                      if (_selectedEstado == null) return null;
                      if (value == null) return 'Selecione a cidade';
                      return null;
                    },
                    disabledHint: Text(
                      _selectedEstado == null
                          ? 'Escolha o estado primeiro'
                          : (_cidadesLoading ? 'Carregando cidades...' : 'Selecione a cidade'),
                      style: TextStyle(color: colors.disabledText),
                    ),
                    icon: _cidadesDisabled
                        ? Icon(Icons.lock_outline, color: colors.disabledText)
                        : Icon(Icons.arrow_drop_down, color: colors.textSecondary),
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

class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String formatted;
    if (digits.length <= 2) {
      formatted = '($digits';
    } else if (digits.length <= 7) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else {
      final ddd = digits.substring(0, 2);
      final mid = digits.substring(2, digits.length - 4);
      final last = digits.substring(digits.length - 4);
      formatted = '($ddd) $mid-$last';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
