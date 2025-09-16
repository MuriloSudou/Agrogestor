import 'package:flutter/material.dart';
// imports removidos: 'dart:convert' e 'package:http/http.dart' não são mais necessários
import 'tela_propriedade.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    setState(() {
      _carregando = true;
    });
    try {
      // Cria usuário no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );
      // Salva dados no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso! Bem-vindo!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TelaPropriedade(
              agricultorId: userCredential.user!.uid,
              nomeAgricultor: _nomeController.text,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Ocorreu um erro.';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'Este email já está cadastrado.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'A senha é muito fraca.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Crie sua Conta',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('lib/img/img1/logo.png', height: 100.0),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Insira seu nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Insira seu email';
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Insira um email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                obscureText: _senhaOculta,
                decoration: InputDecoration(
                  labelText: 'Senha (mín. 6 caracteres)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaOculta ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _senhaOculta = !_senhaOculta),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Insira uma senha';
                  if (value.length < 6) {
                    return 'A senha deve ter no mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmaSenhaController,
                obscureText: _confirmaSenhaOculta,
                decoration: InputDecoration(
                  labelText: 'Confirme sua Senha',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_clock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmaSenhaOculta
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _confirmaSenhaOculta = !_confirmaSenhaOculta,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value != _senhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _cadastrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('Cadastrar e Acessar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
