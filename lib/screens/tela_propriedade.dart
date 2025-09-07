import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class TelaPropriedade extends StatefulWidget {
  final int agricultorId;
  final String nomeAgricultor;

  const TelaPropriedade({
    super.key,
    required this.agricultorId,
    required this.nomeAgricultor,
  });

  @override
  State<TelaPropriedade> createState() => _TelaPropriedadeState();
}

class _TelaPropriedadeState extends State<TelaPropriedade> {
  final _propriedadeController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _areaController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://10.0.2.2/api';
    return 'http://localhost/api';
  }

  String get apiUrl => '$_apiUrlBase/cadastrar_propriedade.php';

  @override
  void dispose() {
    _propriedadeController.dispose();
    _matriculaController.dispose();
    _areaController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          // Nomes dos campos corrigidos para corresponder à API
          'agricultor_id': widget.agricultorId.toString(),
          'nome': _propriedadeController.text,
          'matricula': _matriculaController.text,
          'area_ha': _areaController.text.replaceAll(',', '.'),
          'endereco': _enderecoController.text,
        },
      );
      final responseData = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Ocorreu um erro.'),
            backgroundColor: responseData['status'] == 'success'
                ? Colors.green
                : Colors.red,
          ),
        );
        // CORRIGIDO: Se o cadastro for bem-sucedido, fecha a tela e retorna 'true'
        // para que a tela anterior possa atualizar a lista.
        if (responseData['status'] == 'success') {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível conectar ao servidor.'),
          ),
        );
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Nova Propriedade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Insira os dados da sua nova propriedade',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _propriedadeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Propriedade*',
                ),
                validator: (v) => v!.isEmpty ? 'Insira o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Área (ha)*'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Insira a área' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço (opcional)',
                ),
              ),
              const SizedBox(height: 32),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _salvarPropriedade,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Salvar Propriedade'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
