import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Modelo de dados para os registos de sacas
class SacaColhida {
  final int id;
  final String nomeCultivo;
  final int quantidade;
  final String pesoMedio;
  final String dataColheita;

  SacaColhida({
    required this.id,
    required this.nomeCultivo,
    required this.quantidade,
    required this.pesoMedio,
    required this.dataColheita,
  });

  factory SacaColhida.fromJson(Map<String, dynamic> json) {
    return SacaColhida(
      id: int.parse(json['id'].toString()),
      nomeCultivo: json['nome_cultivo'].toString(),
      quantidade: int.parse(json['quantidade'].toString()),
      pesoMedio: json['peso_medio_kg'].toString(),
      dataColheita: json['data_colheita'].toString(),
    );
  }
}

// Modelo de dados para os cultivos no menu de seleção
class CultivoParaSaca {
  final int id;
  final String cultura;
  CultivoParaSaca({required this.id, required this.cultura});

  factory CultivoParaSaca.fromJson(Map<String, dynamic> json) {
    return CultivoParaSaca(
      id: int.parse(json['id'].toString()),
      cultura: json['cultura'].toString(),
    );
  }
}

class TelaSacas extends StatefulWidget {
  final int propriedadeId;
  const TelaSacas({super.key, required this.propriedadeId});

  @override
  State<TelaSacas> createState() => _TelaSacasState();
}

class _TelaSacasState extends State<TelaSacas> {
  final _formKey = GlobalKey<FormState>();
  final _sacksController = TextEditingController();
  final _pesoController = TextEditingController();
  final _dataController = TextEditingController();
  DateTime? _dataSelecionada;
  int? _cultivoSelecionadoId;

  List<SacaColhida> _sacas = [];
  List<CultivoParaSaca> _cultivosDisponiveis = [];

  bool _carregando = true;

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://10.0.2.2/api';
    return 'http://localhost/api';
  }

  String get apiUrlListarSacas => '$_apiUrlBase/listar_sacas.php';
  String get apiUrlListarCultivos => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlCadastro => '$_apiUrlBase/cadastrar_saca.php';
  String get apiUrlExclusao => '$_apiUrlBase/excluir_saca.php';

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _sacksController.dispose();
    _pesoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _carregando = true;
    });
    await Future.wait([_carregarSacas(), _carregarCultivos()]);
    if (mounted)
      setState(() {
        _carregando = false;
      });
  }

  Future<void> _carregarSacas() async {
    try {
      final uri = Uri.parse(
        '$apiUrlListarSacas?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sacas = data.map((json) => SacaColhida.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Tratar erro
    }
  }

  Future<void> _carregarCultivos() async {
    try {
      final uri = Uri.parse(
        '$apiUrlListarCultivos?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cultivosDisponiveis = data
              .map((json) => CultivoParaSaca.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      // Tratar erro
    }
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
    _formKey.currentState?.reset();
    _sacksController.clear();
    _pesoController.clear();
    _dataController.clear();
    setState(() {
      _dataSelecionada = null;
      _cultivoSelecionadoId = null;
    });
  }

  Future<void> _salvarSaca() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrlCadastro),
        body: {
          'cultivo_id': _cultivoSelecionadoId.toString(),
          'quantidade': _sacksController.text,
          'peso_medio_kg': _pesoController.text.replaceAll(',', '.'),
          'data_colheita': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
        },
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
          _limparCampos();
          _carregarDadosIniciais();
        }
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

  Future<void> _excluirSaca(int sacaId) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrlExclusao),
        body: {'id': sacaId.toString()},
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
          _carregarDadosIniciais();
        }
      }
    } catch (e) {
      // Tratar erro
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color buttonColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/img/img1/logogeral.png', height: 60),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gestão da Colheita',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "\"Registe a sua colheita para um campo mais rentável!\"",
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          DropdownButtonFormField<int>(
                            value: _cultivoSelecionadoId,
                            decoration: const InputDecoration(
                              labelText: 'Cultivo*',
                              border: OutlineInputBorder(),
                            ),
                            items: _cultivosDisponiveis.map((cultivo) {
                              return DropdownMenuItem<int>(
                                value: cultivo.id,
                                child: Text(cultivo.cultura),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _cultivoSelecionadoId = value),
                            validator: (v) =>
                                v == null ? 'Selecione um cultivo' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sacksController,
                            decoration: const InputDecoration(
                              labelText: 'Nº de Sacas*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pesoController,
                            decoration: const InputDecoration(
                              labelText: 'Peso Médio por Saca (kg)*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dataController,
                            decoration: const InputDecoration(
                              labelText: 'Data da Colheita*',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () => _selecionarData(context),
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 20),
                          _carregando
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _salvarSaca,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Salvar Registo'),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          'Colheitas Registadas:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _carregando
                            ? const Center(child: CircularProgressIndicator())
                            : _sacas.isEmpty
                            ? const Center(
                                child: Text('Nenhum registo de colheita.'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sacas.length,
                                itemBuilder: (context, index) {
                                  final saca = _sacas[index];
                                  final dataFormatada = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.parse(saca.dataColheita));
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        saca.nomeCultivo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${saca.quantidade} sacas | ${saca.pesoMedio} kg/saca | Colhido em: $dataFormatada',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _excluirSaca(saca.id),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}
