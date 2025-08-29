import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tela_home.dart';
import 'tela_propriedade.dart';


class Propriedade {
  final int id;
  final String nome;
  Propriedade({required this.id, required this.nome});
  factory Propriedade.fromJson(Map<String, dynamic> json) {
    return Propriedade(id: json['id'], nome: json['nome']);
  }
}

class TelaSelecaoPropriedade extends StatefulWidget {
  final int agricultorId;
  final String nomeAgricultor;

  const TelaSelecaoPropriedade({
    super.key,
    required this.agricultorId,
    required this.nomeAgricultor,
  });

  @override
  State<TelaSelecaoPropriedade> createState() => _TelaSelecaoPropriedadeState();
}

class _TelaSelecaoPropriedadeState extends State<TelaSelecaoPropriedade> {
  List<Propriedade> _listaPropriedades = [];
  int? _propriedadeSelecionadaId;
  bool _carregando = true;

  final String apiUrl = 'http://192.168.3.186/api/listar_propriedades.php';

  @override
  void initState() {
    super.initState();
    _buscarPropriedades();
  }

  Future<void> _buscarPropriedades() async {
    setState(() { _carregando = true; });
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'agricultor_id': widget.agricultorId.toString()},
      );
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        List<dynamic> propriedadesJson = responseData['data'];
        setState(() {
          _listaPropriedades = propriedadesJson.map((json) => Propriedade.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Tratar erro
    } finally {
      setState(() { _carregando = false; });
    }
  }

  void _navegarParaHome() {
    if (_propriedadeSelecionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma propriedade.')),
      );
      return;
    }
    // Passa o ID da propriedade selecionada para a TelaHome.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TelaHome(propriedadeId: _propriedadeSelecionadaId!)),
    );
  }

  void _navegarParaCadastroPropriedade() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPropriedade(
          agricultorId: widget.agricultorId,
          nomeAgricultor: widget.nomeAgricultor,
        ),
      ),
    );
    _buscarPropriedades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${widget.nomeAgricultor}'),
        automaticallyImplyLeading: false,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _buscarPropriedades,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Selecione uma propriedade para gerenciar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _listaPropriedades.isEmpty
                          ? const Center(child: Text('Nenhuma propriedade cadastrada.'))
                          : ListView.builder(
                              itemCount: _listaPropriedades.length,
                              itemBuilder: (context, index) {
                                final propriedade = _listaPropriedades[index];
                                return Card(
                                  child: RadioListTile<int>(
                                    title: Text(propriedade.nome),
                                    value: propriedade.id,
                                    groupValue: _propriedadeSelecionadaId,
                                    onChanged: (value) {
                                      setState(() {
                                        _propriedadeSelecionadaId = value;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Nova Propriedade'),
                      onPressed: _navegarParaCadastroPropriedade,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _navegarParaHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Acessar Propriedade'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
