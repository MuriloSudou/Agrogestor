
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tela_selecao_propriedade.dart'; 

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
  final List<String> _propriedadesAdicionadas = [];

  final String apiUrl = 'http://192.168.3.186/api/cadastro_propriedade.php';

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

    setState(() { _carregando = true; });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'agricultor_id': widget.agricultorId.toString(),
          'nome': _propriedadeController.text,
          'matricula': _matriculaController.text,
          'area_ha': _areaController.text,
          'endereco': _enderecoController.text,
        },
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        setState(() {
          _propriedadesAdicionadas.add(_propriedadeController.text);
          
          _propriedadeController.clear();
          _matriculaController.clear();
          _areaController.clear();
          _enderecoController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propriedade salva! Adicione a próxima ou conclua.'),
            backgroundColor: Colors.green,
          ),
        );
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

  
  void _navegarParaSelecao() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => TelaSelecaoPropriedade(
          agricultorId: widget.agricultorId,
          nomeAgricultor: widget.nomeAgricultor,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Propriedades'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Insira os dados da propriedade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(controller: _propriedadeController, decoration: const InputDecoration(labelText: 'Nome da Propriedade'), validator: (v) => v!.isEmpty ? 'Insira o nome' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _matriculaController, decoration: const InputDecoration(labelText: 'Matrícula'), validator: (v) => v!.isEmpty ? 'Insira a matrícula' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _areaController, decoration: const InputDecoration(labelText: 'Área (ha)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Insira a área' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _enderecoController, decoration: const InputDecoration(labelText: 'Endereço'), validator: (v) => v!.isEmpty ? 'Insira o endereço' : null),
                  const SizedBox(height: 32),
                  _carregando ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _salvarPropriedade, child: const Text('Adicionar Propriedade')),
                ],
              ),
            ),
            const Divider(height: 40),
            const Text('Propriedades adicionadas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _propriedadesAdicionadas.isEmpty
                ? const Text('Nenhuma propriedade adicionada ainda.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _propriedadesAdicionadas.length,
                    itemBuilder: (context, index) => Card(child: ListTile(title: Text(_propriedadesAdicionadas[index]))),
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navegarParaSelecao,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Concluir e Selecionar'),
            ),
          ],
        ),
      ),
    );
  }
}
