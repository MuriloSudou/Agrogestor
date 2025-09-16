import 'package:flutter/material.dart';
// Removidos imports não utilizados
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaPropriedade extends StatefulWidget {
  final String agricultorId;
  final String nomeAgricultor;
  final String? propriedadeId;
  final String? nome;
  final String? area;

  const TelaPropriedade({
    super.key,
    required this.agricultorId,
    required this.nomeAgricultor,
    this.propriedadeId,
    this.nome,
    this.area,
  });

  @override
  State<TelaPropriedade> createState() => _TelaPropriedadeState();
}

class _TelaPropriedadeState extends State<TelaPropriedade> {
  final _propriedadeController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _areaController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.nome != null) _propriedadeController.text = widget.nome!;
    if (widget.area != null) _areaController.text = widget.area!;
    // Para matrícula e endereço, pode ser expandido se necessário
  }

  @override
  void dispose() {
    _propriedadeController.dispose();
    _matriculaController.dispose();
    _areaController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }
      if (widget.propriedadeId != null) {
        // Edição
        await FirebaseFirestore.instance
            .collection('propriedades')
            .doc(widget.propriedadeId)
            .update({
              'nome': _propriedadeController.text.trim(),
              'area_ha': _areaController.text.trim(),
              'matricula': _matriculaController.text.trim(),
              'endereco': _enderecoController.text.trim(),
            });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriedade atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Cadastro
        await FirebaseFirestore.instance.collection('propriedades').add({
          'uid': user.uid,
          'nome': _propriedadeController.text.trim(),
          'matricula': _matriculaController.text.trim(),
          'area_ha': _areaController.text.trim(),
          'endereco': _enderecoController.text.trim(),
          'dataCadastro': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriedade cadastrada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.propriedadeId != null
              ? 'Editar Propriedade'
              : 'Cadastrar Nova Propriedade',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Insira os dados da sua nova propriedade',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _propriedadeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Propriedade*',
                ),
                validator: (v) => v!.isEmpty ? 'Insira o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Área (ha)*'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Insira a área' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço (opcional)',
                ),
              ),
              const SizedBox(height: 32),
              _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _salvarPropriedade,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Salvar Propriedade'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
