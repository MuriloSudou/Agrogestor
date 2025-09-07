import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'tela_visualizar_nf.dart';

class CultivoDropdown {
  final int id;
  final String cultura;
  CultivoDropdown({required this.id, required this.cultura});
  factory CultivoDropdown.fromJson(Map<String, dynamic> json) {
    return CultivoDropdown(
      id: int.parse(json['id'].toString()),
      cultura: json['cultura'].toString(),
    );
  }
}

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
  bool _carregandoCultivos = true;

  List<CultivoDropdown> _cultivos = [];
  int? _cultivoSelecionadoId;
  bool get _modoEdicao => widget.notaParaEditar != null;

  String get _apiUrlBase {
    return 'http://192.168.0.250/api';
  }

  String get apiUrlListagemCultivos => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlCadastro => '$_apiUrlBase/cadastro_nf.php';
  String get apiUrlEdicao => '$_apiUrlBase/editar_nf.php';
  String get apiUrlExclusao => '$_apiUrlBase/deletar_nf.php';

  @override
  void initState() {
    super.initState();
    if (_modoEdicao) {
      final nota = widget.notaParaEditar!;
      _numeroNotaController.text = nota.numero;
      _valorController.text = nota.valor.replaceAll(',', '.');
      _dataSelecionada = DateTime.parse(nota.dataEmissao);
      _cultivoSelecionadoId = nota.cultivoId;
    }
    _listarCultivos();
  }

  @override
  void dispose() {
    _numeroNotaController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _listarCultivos() async {
    setState(() {
      _carregandoCultivos = true;
    });
    try {
      final uri = Uri.parse(
        '$apiUrlListagemCultivos?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cultivos = data
              .map((json) => CultivoDropdown.fromJson(json))
              .toList();
          if (_modoEdicao && _cultivoSelecionadoId != null) {
            final idsDisponiveis = _cultivos.map((c) => c.id).toList();
            if (!idsDisponiveis.contains(_cultivoSelecionadoId)) {
              _cultivoSelecionadoId = null;
            }
          }
        });
      }
    } catch (e) {
      // Tratar erro
    } finally {
      if (mounted)
        setState(() {
          _carregandoCultivos = false;
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
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    final String url = _modoEdicao ? apiUrlEdicao : apiUrlCadastro;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor:
                (responseData['status'] == 'success' ||
                    responseData['status'] == 'info')
                ? Colors.green
                : Colors.red,
          ),
        );
        if (responseData['status'] == 'success') Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted)
        setState(() {
          _carregando = false;
        });
    }
  }

  Future<void> _excluirNota() async {
    if (!_modoEdicao) return;

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir esta Nota Fiscal? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      setState(() {
        _carregando = true;
      });

      try {
        final response = await http.post(
          Uri.parse(apiUrlExclusao),
          body: {'id': widget.notaParaEditar!.id.toString()},
        );
        final responseData = jsonDecode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: responseData['status'] == 'success'
                  ? Colors.green
                  : Colors.red,
            ),
          );
          if (responseData['status'] == 'success') {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _carregando = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modoEdicao ? 'Editar Nota Fiscal' : 'Adicionar Nota Fiscal',
        ),
        actions: [
          // ADICIONADO: Botão para navegar para a tela de visualização
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Ver todas as notas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TelaVisualizarNF(propriedadeId: widget.propriedadeId),
                ),
              );
            },
          ),
          // Botão de exclusão que só aparece no modo de edição
          if (_modoEdicao)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _excluirNota,
            ),
        ],
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
                decoration: const InputDecoration(
                  labelText: 'Número da Nota',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              _carregandoCultivos
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Associar ao Cultivo',
                        border: OutlineInputBorder(),
                      ),
                      value: _cultivoSelecionadoId,
                      items: _cultivos.map<DropdownMenuItem<int>>((cultivo) {
                        return DropdownMenuItem<int>(
                          value: cultivo.id,
                          child: Text(cultivo.cultura),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() => _cultivoSelecionadoId = newValue);
                      },
                      validator: (v) =>
                          v == null ? 'Selecione um cultivo' : null,
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dataSelecionada == null
                      ? 'Selecionar Data de Emissão'
                      : DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
                ),
                onPressed: () => _selecionarData(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _salvarOuAtualizar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_modoEdicao ? 'Atualizar' : 'Salvar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
