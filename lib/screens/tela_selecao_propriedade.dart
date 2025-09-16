import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tela_home.dart';
import 'tela_propriedade.dart';

class Propriedade {
  final String id;
  final String nome;
  final String area;

  Propriedade({required this.id, required this.nome, required this.area});

  factory Propriedade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Propriedade(
      id: doc.id,
      nome: data['nome'] ?? '',
      area: data['area_ha'] ?? '',
    );
  }
}

class TelaSelecaoPropriedade extends StatefulWidget {
  final String agricultorId;
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
  String? _propriedadeSelecionadaId;
  bool _carregando = true;

  Future<void> _removerPropriedade(String propriedadeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Propriedade'),
        content: const Text('Tem certeza que deseja remover esta propriedade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('propriedades')
          .doc(propriedadeId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propriedade removida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _buscarPropriedades();
      }
    }
  }

  void _editarPropriedade(Propriedade propriedade) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPropriedade(
          agricultorId: widget.agricultorId,
          nomeAgricultor: widget.nomeAgricultor,
          propriedadeId: propriedade.id,
          nome: propriedade.nome,
          area: propriedade.area,
        ),
      ),
    );
    if (resultado == true) {
      _buscarPropriedades();
    }
  }

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }
      final query = await FirebaseFirestore.instance
          .collection('propriedades')
          .where('uid', isEqualTo: user.uid)
          .get();
      setState(() {
        _listaPropriedades = query.docs
            .map((doc) => Propriedade.fromFirestore(doc))
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text(propriedade.nome),
                                          subtitle: Text(
                                            '${propriedade.area} ha',
                                          ),
                                          value: propriedade.id,
                                          groupValue: _propriedadeSelecionadaId,
                                          onChanged: (value) {
                                            setState(() {
                                              _propriedadeSelecionadaId = value;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Editar',
                                        onPressed: () =>
                                            _editarPropriedade(propriedade),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remover',
                                        onPressed: () =>
                                            _removerPropriedade(propriedade.id),
                                      ),
                                    ],
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
