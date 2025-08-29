import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tela_propriedade.dart'; 


class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});
  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _senhaOculta = true;
  bool _confirmaSenhaOculta = true;
  bool _carregando = false;

  final String apiUrl = 'http://192.168.3.186/api/cadastro_agricultor.php';

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _carregando = true; });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
        },
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final int agricultorId = responseData['id'];
        
        if (mounted) {
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TelaPropriedade(
                agricultorId: agricultorId,
                nomeAgricultor: _nomeController.text,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Ocorreu um erro.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao servidor.')),
      );
    } finally {
      if (mounted) { setState(() { _carregando = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color buttonColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('lib/img/img1/logo.png', height: 120.0),
                const SizedBox(height: 16),
                const Text(
                  'Realize Seu Cadastro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildTextField(
                  label: 'Nome',
                  controller: _nomeController,
                  validator: (value) => value == null || value.isEmpty ? 'Insira seu nome' : null,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Insira seu email';
                    if (!value.contains('@')) return 'Insira um email válido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Senha',
                  controller: _senhaController,
                  obscureText: _senhaOculta,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Insira uma senha';
                    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_senhaOculta ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Confirme sua Senha',
                  controller: _confirmaSenhaController,
                  obscureText: _confirmaSenhaOculta,
                  validator: (value) {
                    if (value != _senhaController.text) return 'As senhas não coincidem';
                    return null;
                  },
                   suffixIcon: IconButton(
                    icon: Icon(_confirmaSenhaOculta ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _confirmaSenhaOculta = !_confirmaSenhaOculta),
                  ),
                ),
                const SizedBox(height: 40),
                _carregando
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ElevatedButton(
                        onPressed: _cadastrarUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Cadastrar'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
