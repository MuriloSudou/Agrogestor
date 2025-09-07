import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tela_home.dart';
import 'tela_propriedade.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Propriedade {
  final int id;
  final String nome;
  final String area;

  Propriedade({required this.id, required this.nome, required this.area});

  // CORRIGIDO: Nomes das chaves para corresponder ao JSON da API
  factory Propriedade.fromJson(Map<String, dynamic> json) {
    return Propriedade(
      id: int.parse(json['id'].toString()),
      nome: json['nome_propriedade'].toString(),
      area: json['area_ha'].toString(),
    );
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

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://10.0.2.2/api';
    return 'http://localhost/api';
  }

  String get apiUrl => '$_apiUrlBase/listar_propriedades.php';

  @override
  void initState() {
    super.initState();
    _buscarPropriedades();
  }

  Future<void> _buscarPropriedades() async {
    setState(() {
      _carregando = true;
    });
    try {
      // CORRIGIDO: Usa http.get e passa o ID na URL
      final uri = Uri.parse('$apiUrl?agricultor_id=${widget.agricultorId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // CORRIGIDO: A API agora retorna uma lista JSON diretamente
        final List<dynamic> propriedadesJson = jsonDecode(response.body);
        setState(() {
          _listaPropriedades = propriedadesJson
              .map((json) => Propriedade.fromJson(json))
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

  void _navegarParaHome() {
    if (_propriedadeSelecionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma propriedade.')),
      );
      return;
    }
    Navigator.push(
      // Usa push em vez de pushReplacement para poder voltar
      context,
      MaterialPageRoute(
        builder: (context) => TelaHome(
          propriedadeId: _propriedadeSelecionadaId!,
          // Passando também o nome do agricultor para a TelaHome
          nomeAgricultor: widget.nomeAgricultor,
        ),
      ),
    );
  }

  void _navegarParaCadastroPropriedade() async {
    // CORRIGIDO: Espera o resultado da tela de cadastro
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPropriedade(
          agricultorId: widget.agricultorId,
          nomeAgricultor: widget.nomeAgricultor,
        ),
      ),
    );
    // Se o resultado for 'true', significa que um cadastro foi salvo com sucesso
    if (resultado == true) {
      _buscarPropriedades(); // Atualiza a lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${widget.nomeAgricultor}'),
        automaticallyImplyLeading: false, // Remove a seta de voltar
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _listaPropriedades.isEmpty
                          ? const Center(
                              child: Text('Nenhuma propriedade cadastrada.'),
                            )
                          : ListView.builder(
                              itemCount: _listaPropriedades.length,
                              itemBuilder: (context, index) {
                                final propriedade = _listaPropriedades[index];
                                return Card(
                                  child: RadioListTile<int>(
                                    title: Text(propriedade.nome),
                                    subtitle: Text('${propriedade.area} ha'),
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
                      onPressed: _propriedadeSelecionadaId != null
                          ? _navegarParaHome
                          : null, // Desabilita se nada estiver selecionado
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
