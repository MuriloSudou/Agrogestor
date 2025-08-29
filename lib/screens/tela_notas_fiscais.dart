import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'tela_visualizar_nf.dart';

class TelaNotasFiscais extends StatefulWidget {
  final int propriedadeId;
  final NotaFiscal? notaParaEditar; 

  const TelaNotasFiscais({
    super.key, 
    required this.propriedadeId, 
    this.notaParaEditar
  });

  @override
  State<TelaNotasFiscais> createState() => _TelaNotasFiscaisState();
}

class _TelaNotasFiscaisState extends State<TelaNotasFiscais> {
  final _formKey = GlobalKey<FormState>();
  final _numeroNotaController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime? _dataSelecionada;
  bool _carregando = false;
  bool get _modoEdicao => widget.notaParaEditar != null;

  final String apiUrlCadastro = 'http://192.168.3.186/api/cadastro_nf.php';
  final String apiUrlEdicao = 'http://192.168.3.186/api/editar_nf.php';

  @override
  void initState() {
    super.initState();
    
    if (_modoEdicao) {
      final nota = widget.notaParaEditar!;
      _numeroNotaController.text = nota.numero;
      _valorController.text = nota.valor.replaceAll(',', '.');
      _dataSelecionada = DateFormat('dd/MM/yyyy').parse(nota.dataEmissao);
    }
  }

  @override
  void dispose() {
    _numeroNotaController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  Future<void> _salvarOuAtualizar() async {
    if (!_formKey.currentState!.validate() || _dataSelecionada == null) return;

    setState(() { _carregando = true; });

    
    final String url = _modoEdicao ? apiUrlEdicao : apiUrlCadastro;
    final Map<String, String> body = {
      'propriedade_id': widget.propriedadeId.toString(),
      'numero_nota': _numeroNotaController.text,
      'valor': _valorController.text.replaceAll(',', '.'),
      'data_emissao': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
    };
    if (_modoEdicao) {
      body['id'] = widget.notaParaEditar!.id.toString();
    }

    try {
      final response = await http.post(Uri.parse(url), body: body);
      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        
        if(mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Tratar erro
    } finally {
      if(mounted) setState(() { _carregando = false; });
    }
  }

  
  void _navegarParaVisualizacao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaVisualizarNF(propriedadeId: widget.propriedadeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modoEdicao ? 'Editar Nota Fiscal' : 'Adicionar Nota Fiscal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _numeroNotaController,
                decoration: const InputDecoration(labelText: 'Número da Nota'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dataSelecionada == null
                      ? 'Selecionar Data'
                      : DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
                ),
                onPressed: () => _selecionarData(context),
              ),
              const SizedBox(height: 32),
              if (_carregando)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _salvarOuAtualizar,
                  child: Text(_modoEdicao ? 'Atualizar NF' : 'Salvar NF'),
                ),
              
              
              if (!_modoEdicao) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _navegarParaVisualizacao,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Visualizar NFs Cadastradas'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
