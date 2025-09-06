import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'tela_visualizar_nf.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class TelaNotasFiscais extends StatefulWidget {
  final int propriedadeId;
  final NotaFiscal? notaParaEditar;

  const TelaNotasFiscais({
    super.key,
    required this.propriedadeId,
    this.notaParaEditar,
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
  bool _inicializando = true;

  // Variáveis para a lista de cultivos e o cultivo selecionado
  List<Map<String, dynamic>> _cultivos = [];
  int? _cultivoSelecionadoId;
  bool get _modoEdicao => widget.notaParaEditar != null;

  String get _apiUrlBase {
    if (kIsWeb) {
      return 'http://localhost/api';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2/api';
      } else {
        // Para iOS ou outros, você pode precisar de outro IP
        return 'http://localhost/api';
      }
    }
  }

  // URL da API (substitua pelas suas rotas reais)
  String get apiUrlListagemCultivos => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlCadastro => '$_apiUrlBase/cadastro_nf.php';
  String get apiUrlEdicao => '$_apiUrlBase/editar_nf.php';

  @override
  void initState() {
    super.initState();
    _listarCultivos();
    if (_modoEdicao) {
      final nota = widget.notaParaEditar!;
      _numeroNotaController.text = nota.numero;
      _valorController.text = nota.valor.replaceAll(',', '.');
      _dataSelecionada = DateFormat('dd/MM/yyyy').parse(nota.dataEmissao);
      _cultivoSelecionadoId = int.tryParse(nota.cultivoId);
    }
  }

  @override
  void dispose() {
    _numeroNotaController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _listarCultivos() async {
    setState(() {
      _inicializando = true;
    });
    try {
      // Faz a requisição POST para a API, passando o propriedadeId
      final response = await http.post(
        Uri.parse(apiUrlListagemCultivos),
        body: {'propriedade_id': widget.propriedadeId.toString()},
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _cultivos = List<Map<String, dynamic>>.from(data);
          });
        } else {
          // Se a resposta não for uma lista, limpa a lista de cultivos
          setState(() {
            _cultivos = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum cultivo cadastrado ou erro na API.'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar cultivos: $e')));
    } finally {
      setState(() {
        _inicializando = false;
      });
    }
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
    if (!_formKey.currentState!.validate() ||
        _dataSelecionada == null ||
        _cultivoSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos e selecione um cultivo e uma data.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    final String url = _modoEdicao
        ? '$_apiUrlBase/editar_nf.php'
        : '$_apiUrlBase/cadastro_nf.php';
    final Map<String, String> body = {
      'propriedade_id': widget.propriedadeId.toString(),
      'cultivo_id': _cultivoSelecionadoId.toString(),
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
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao conectar com a API: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _carregando = false;
        });
    }
  }

  void _navegarParaVisualizacao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TelaVisualizarNF(propriedadeId: widget.propriedadeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modoEdicao ? 'Editar Nota Fiscal' : 'Adicionar Nota Fiscal',
        ),
      ),
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
              if (_inicializando)
                const Center(child: CircularProgressIndicator())
              else if (_cultivos.isEmpty)
                const Center(child: Text('Nenhum cultivo cadastrado.'))
              else
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Cultivo'),
                  value: _cultivoSelecionadoId,
                  items: _cultivos.map<DropdownMenuItem<int>>((cultivo) {
                    return DropdownMenuItem<int>(
                      value: int.tryParse(cultivo['id'].toString()),
                      child: Text(cultivo['cultura']),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _cultivoSelecionadoId = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecione um cultivo' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Visualizar NFs Cadastradas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
