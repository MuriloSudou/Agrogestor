import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; 
import 'tela_cadastro.dart';
import 'package:agrogestor/screens/tela_selecao_propriedade.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _senhaOculta = true;
  bool _carregando = false;


  final String apiUrl = 'http://192.168.3.186/api/login_agricultor.php';

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _carregando = true; });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': _emailController.text,
          'senha': _senhaController.text,
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final int agricultorId = responseData['data']['id'];
        final String nomeAgricultor = responseData['data']['nome'];

        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TelaSelecaoPropriedade(
              agricultorId: agricultorId,
              nomeAgricultor: nomeAgricultor,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Erro desconhecido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível conectar ao servidor.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) { setState(() { _carregando = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color formBackgroundColor = Colors.white;
    const Color buttonColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('lib/img/img1/logo.png', height: 120.0),
              const SizedBox(height: 48.0),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: formBackgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Insira seu email';
                          if (!v.contains('@')) return 'Insira um email válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _senhaOculta,
                        decoration: InputDecoration(
                            labelText: 'Senha',
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_senhaOculta ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
                            )),
                        validator: (v) => v == null || v.isEmpty ? 'Insira sua senha' : null,
                      ),
                      const SizedBox(height: 24.0),
                      if (_carregando)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _fazerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                      const SizedBox(height: 12.0),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TelaCadastro()),
                            );
                          },
                          child: const Text(
                            'Cadastre-se',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
