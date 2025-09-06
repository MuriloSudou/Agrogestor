import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class NotaFiscal {
  final int id;
  final String numero;
  final String valor;
  final String dataEmissao;
  final String cultivoId;

  NotaFiscal({
    required this.id,
    required this.numero,
    required this.valor,
    required this.dataEmissao,
    required this.cultivoId,
  });

  factory NotaFiscal.fromJson(Map<String, dynamic> json) {
    return NotaFiscal(
      id: int.parse(json['id'].toString()),
      numero: json['numero_nota'],
      valor: json['valor_nf'],
      dataEmissao: json['data_emissao'],
      cultivoId: json['cultivo_id'],
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

  final String apiUrlListagem = 'http://10.0.0.78/api/listar_nf.php';
  final String apiUrlExclusao = 'http://10.0.0.78/api/excluir_nf.php';

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
      final response = await http.get(
        Uri.parse('$apiUrlListagem?propriedade_id=${widget.propriedadeId}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notasFiscais = data
              .map((json) => NotaFiscal.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar notas fiscais: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar Notas Fiscais')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _notasFiscais.isEmpty
          ? const Center(child: Text('Nenhuma nota fiscal cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _notasFiscais.length,
              itemBuilder: (context, index) {
                final nota = _notasFiscais[index];
                return Card(
                  child: ListTile(
                    title: Text('Número: ${nota.numero}'),
                    subtitle: Text(
                      'Valor: R\$${nota.valor}\nData: ${nota.dataEmissao}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
