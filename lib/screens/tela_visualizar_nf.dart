import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'tela_notas_fiscais.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotaFiscal {
  final int id;
  final String numero;
  final String valor;
  final String dataEmissao;
  final int? cultivoId;
  final String? nomeCultivo;

  NotaFiscal({
    required this.id,
    required this.numero,
    required this.valor,
    required this.dataEmissao,
    this.cultivoId,
    this.nomeCultivo,
  });

  factory NotaFiscal.fromJson(Map<String, dynamic> json) {
    return NotaFiscal(
      id: int.parse(json['id'].toString()),
      numero: json['numero_nota'].toString(),
      valor: json['valor'].toString(),
      dataEmissao: json['data_emissao'].toString(),
      cultivoId: json['cultivo_id'] != null
          ? int.tryParse(json['cultivo_id'].toString())
          : null,
      nomeCultivo: json['nome_cultivo']?.toString(),
    );
  }
}

class TelaVisualizarNF extends StatefulWidget {
  final int propriedadeId;
  const TelaVisualizarNF({super.key, required this.propriedadeId});

  @override
  State<TelaVisualizarNF> createState() => _TelaVisualizarNFState();
}

class _TelaVisualizarNFState extends State<TelaVisualizarNF> {
  List<NotaFiscal> _notasFiscais = [];
  bool _carregando = true;

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://10.0.2.2/api';
    return 'http://localhost/api';
  }

  String get apiUrlListagem => '$_apiUrlBase/listar_nf.php';
  String get apiUrlExclusao => '$_apiUrlBase/excluir_nf.php';

  @override
  void initState() {
    super.initState();
    _listarNotasFiscais();
  }

  Future<void> _listarNotasFiscais() async {
    setState(() {
      _carregando = true;
    });
    try {
      final uri = Uri.parse(
        '$apiUrlListagem?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notasFiscais = data
              .map((json) => NotaFiscal.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      // Tratar erro
    } finally {
      if (mounted)
        setState(() {
          _carregando = false;
        });
    }
  }

  Future<void> _navegarParaFormulario({NotaFiscal? nota}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaNotasFiscais(
          propriedadeId: widget.propriedadeId,
          notaParaEditar: nota,
        ),
      ),
    );
    if (resultado == true) {
      _listarNotasFiscais();
    }
  }

  void _mostrarDialogoConfirmacao(int notaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
            'Tem certeza que deseja excluir esta nota fiscal?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () {
                Navigator.of(context).pop();
                _excluirNota(notaId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _excluirNota(int notaId) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrlExclusao),
        body: {'id': notaId.toString()},
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: data['status'] == 'success'
                ? Colors.green
                : Colors.red,
          ),
        );
        if (data['status'] == 'success') {
          _listarNotasFiscais();
        }
      }
    } catch (e) {
      // Tratar erro
    }
  }

  String _formatarDetalhes(NotaFiscal nota) {
    String dataFormatada;
    try {
      dataFormatada = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.parse(nota.dataEmissao));
    } catch (e) {
      dataFormatada = nota.dataEmissao;
    }

    String valorFormatado;
    try {
      valorFormatado = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(double.parse(nota.valor));
    } catch (e) {
      valorFormatado = 'R\$ ${nota.valor}';
    }

    final nomeCultivo = nota.nomeCultivo ?? 'Nenhum';
    return 'Cultivo: $nomeCultivo\nValor: $valorFormatado | Data: $dataFormatada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas Fiscais')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _listarNotasFiscais,
              child: _notasFiscais.isEmpty
                  ? const Center(child: Text('Nenhuma nota fiscal cadastrada.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _notasFiscais.length,
                      itemBuilder: (context, index) {
                        final nota = _notasFiscais[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                              'Nota Nº: ${nota.numero}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_formatarDetalhes(nota)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navegarParaFormulario(nota: nota),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _mostrarDialogoConfirmacao(nota.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
