import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TelaSacas extends StatefulWidget {
  const TelaSacas({super.key});

  @override
  State<TelaSacas> createState() => _TelaSacasState();
}

class _TelaSacasState extends State<TelaSacas> {
  final _formKey = GlobalKey<FormState>();
  final _cultivoController = TextEditingController();
  final _sacksController = TextEditingController();
  final _dataController = TextEditingController();
  DateTime? _dataSelecionada;

  // Lista para armazenar as sacas cadastradas
  List<Map<String, dynamic>> _sacks = [];

  // Índice da saca que está sendo editada
  int? _indiceEdicao;

  // Controle de loading
  bool _carregando = false;

  // URL da API (substitua pelas suas rotas reais)
  final String apiUrlCadastro = 'http://10.0.0.78/api/cadastro_sacas.php';
  final String apiUrlEdicao = 'http://10.0.0.78/api/editar_saca.php';
  final String apiUrlExclusao = 'http://10.0.0.78/api/excluir_saca.php';

  @override
  void dispose() {
    _cultivoController.dispose();
    _sacksController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _dataController.text = DateFormat('dd/MM/yyyy').format(data);
      });
    }
  }

  void _limparCampos() {
    _cultivoController.clear();
    _sacksController.clear();
    _dataController.clear();
    setState(() {
      _dataSelecionada = null;
      _indiceEdicao = null;
    });
  }

  Future<void> _salvarOuAtualizarSaca() async {
    if (!_formKey.currentState!.validate() || _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos e selecione uma data.'),
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    final sacaDados = {
      'cultivo': _cultivoController.text,
      'sacks': _sacksController.text,
      'data': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
    };

    try {
      // Fallback local (funciona sem API)
      final dadosParaLista = {
        ...sacaDados,
        'data': DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
      };

      if (_indiceEdicao == null) {
        _sacks.add(dadosParaLista);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saca salva com sucesso!')),
        );
      } else {
        _sacks[_indiceEdicao!] = dadosParaLista;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saca editada com sucesso!')),
        );
      }

      _limparCampos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar saca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _editarSaca(int index) {
    setState(() {
      _indiceEdicao = index;
      _cultivoController.text = _sacks[index]['cultivo'];
      _sacksController.text = _sacks[index]['sacks'];
      _dataSelecionada = DateFormat('dd/MM/yyyy').parse(_sacks[index]['data']);
      _dataController.text = _sacks[index]['data'];
    });
  }

  Future<void> _excluirSaca(int index) async {
    setState(() {
      _sacks.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saca excluída com sucesso!')));
  }

  double _calcularTotalSacas() {
    return _sacks.fold(0.0, (sum, saca) {
      return sum + (double.tryParse(saca['sacks'] ?? '0') ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color accentColor = Color.fromARGB(255, 5, 67, 34);
    const Color buttonColor = Color(0xFF333333);
    const Color formBackgroundColor = Colors.white;

    final Map<String, double> sacasPorCultivo = {};
    for (var saca in _sacks) {
      final String cultivo = saca['cultivo'];
      final double quantidade = double.tryParse(saca['sacks'] ?? '0') ?? 0;
      sacasPorCultivo.update(
        cultivo,
        (value) => value + quantidade,
        ifAbsent: () => quantidade,
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Cabeçalho AgroGestor ---
            Container(
              color: const Color.fromARGB(255, 5, 67, 34),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'AgroGestor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Título e Slogan ---
            const Text(
              'Gestão da Colheita',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "\"Gestão precisa da colheita para um campo mais rentável!\"",
              style: TextStyle(
                color: Color.fromARGB(179, 26, 25, 25),
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- Conteúdo Principal (Formulário e Lista) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: formBackgroundColor,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cultura'),
                                    TextFormField(
                                      controller: _cultivoController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Número de Sacas'),
                                    TextFormField(
                                      controller: _sacksController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) => value!.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Data'),
                                    TextFormField(
                                      controller: _dataController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      readOnly: true,
                                      onTap: () => _selecionarData(context),
                                      validator: (value) => value!.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _carregando
                                    ? null
                                    : _salvarOuAtualizarSaca,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _carregando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _indiceEdicao == null
                                            ? 'Salvar'
                                            : 'Atualizar',
                                      ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // --- Lista de Sacas Cadastradas ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: formBackgroundColor,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes das Sacas:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _sacks.isEmpty
                            ? const Center(
                                child: Text('Nenhuma saca cadastrada.'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sacks.length,
                                itemBuilder: (context, index) {
                                  final saca = _sacks[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(saca['cultivo']),
                                      subtitle: Text(
                                        'Número de Sacas: ${saca['sacks'] ?? 'N/A'} | Data: ${saca['data'] ?? 'N/A'}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _editarSaca(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _excluirSaca(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: const Color.fromARGB(255, 255, 255, 255),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Voltar ao Inicio'),
        ),
      ),
    );
  }
}
