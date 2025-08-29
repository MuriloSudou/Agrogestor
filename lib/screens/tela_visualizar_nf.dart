import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tela_notas_fiscais.dart'; 


class NotaFiscal {
  final int id;
  final String numero;
  final String valor;
  final String dataEmissao; 

  NotaFiscal({required this.id, required this.numero, required this.valor, required this.dataEmissao});

  factory NotaFiscal.fromJson(Map<String, dynamic> json) {
    return NotaFiscal(
      id: json['id'],
      numero: json['numero_nota'],
      valor: json['valor'],
      dataEmissao: json['data_emissao_formatada'],
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

  final String apiUrl = 'http://192.168.3.186/api/listar_nf.php';

  @override
  void initState() {
    super.initState();
    _buscarNotasFiscais();
  }

  Future<void> _buscarNotasFiscais() async {
    setState(() { _carregando = true; });
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'propriedade_id': widget.propriedadeId.toString()},
      );
      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success') {
        List<dynamic> nfJson = responseData['data'];
        setState(() {
          _notasFiscais = nfJson.map((json) => NotaFiscal.fromJson(json)).toList();
        });
      } else {
        // Tratar erro
      }
    } catch (e) {
      // Tratar erro
    } finally {
      if(mounted) setState(() { _carregando = false; });
    }
  }

  // Função para navegar para a tela de edição
  void _navegarParaEdicao(NotaFiscal nota) async {
    // Navega para a tela de formulário, passando a nota a ser editada
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaNotasFiscais(
          propriedadeId: widget.propriedadeId,
          notaParaEditar: nota, // Passa a nota fiscal existente
        ),
      ),
    );

    // Se a edição foi bem-sucedida, atualiza a lista
    if (resultado == true) {
      _buscarNotasFiscais();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Fiscais Cadastradas'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _notasFiscais.isEmpty
              ? const Center(child: Text('Nenhuma nota fiscal encontrada.'))
              : RefreshIndicator(
                  onRefresh: _buscarNotasFiscais,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _notasFiscais.length,
                    itemBuilder: (context, index) {
                      final nota = _notasFiscais[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text('NF Nº: ${nota.numero}'),
                          subtitle: Text('Data: ${nota.dataEmissao}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ ${nota.valor.replaceAll('.', ',')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              // Botão de editar
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _navegarParaEdicao(nota),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

