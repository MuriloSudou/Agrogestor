import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tela_notas_fiscais.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotaFiscal {
  final String id;
  final String numero;
  final String valor;
  final String dataEmissao;
  final String? cultivoId;
  final String? nomeCultivo;

  NotaFiscal({
    required this.id,
    required this.numero,
    required this.valor,
    required this.dataEmissao,
    this.cultivoId,
    this.nomeCultivo,
  });

  factory NotaFiscal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotaFiscal(
      id: doc.id,
      numero: data['numero'] ?? '',
      valor: data['valor'] ?? '',
      dataEmissao: data['dataEmissao'] ?? '',
      cultivoId: data['cultivoId'],
      nomeCultivo: data['nomeCultivo'],
    );
  }
}

class TelaVisualizarNF extends StatefulWidget {
  final String propriedadeId;
  const TelaVisualizarNF({super.key, required this.propriedadeId});

  @override
  State<TelaVisualizarNF> createState() => _TelaVisualizarNFState();
}

class _TelaVisualizarNFState extends State<TelaVisualizarNF> {
  List<NotaFiscal> _notasFiscais = [];
  bool _carregando = true;

  // Removed API URLs as they are no longer needed

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
      final query = await FirebaseFirestore.instance
          .collection('notas_fiscais')
          .where('propriedadeId', isEqualTo: widget.propriedadeId)
          .get();
      setState(() {
        _notasFiscais = query.docs
            .map((doc) => NotaFiscal.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      // Tratar erro
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
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

  void _mostrarDialogoConfirmacao(String notaId) {
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

  Future<void> _excluirNota(String notaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notas_fiscais')
          .doc(notaId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota fiscal excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _listarNotasFiscais();
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
