import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class TelaCusto extends StatefulWidget {
  final int propriedadeId;

  const TelaCusto({super.key, required this.propriedadeId});

  @override
  State<TelaCusto> createState() => _TelaCustoState();
}

class _TelaCustoState extends State<TelaCusto> {
  String? _cultivoSelecionado;
  String _areaCalculada = '';
  String _totalNotasFiscais = '';
  String _custoPorArea = '';
  bool _inicializando = true;

  List<Map<String, dynamic>> _cultivos = [];
  List<Map<String, dynamic>> _notasFiscais = [];

  String get _apiUrlBase {
    if (kIsWeb) {
      return 'http://localhost/api';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2/api';
      } else {
        return 'http://localhost/api';
      }
    }
  }

  String get apiUrlListarCultivos => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlListarNf => '$_apiUrlBase/listar_nf.php';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _inicializando = true;
    });

    try {
      final cultivosResponse = await http.post(
        Uri.parse(apiUrlListarCultivos),
        body: {'propriedade_id': widget.propriedadeId.toString()},
      );

      final notasResponse = await http.post(
        Uri.parse(apiUrlListarNf),
        body: {'propriedade_id': widget.propriedadeId.toString()},
      );

      if (cultivosResponse.statusCode == 200 &&
          notasResponse.statusCode == 200) {
        final dynamic cultivosData = jsonDecode(cultivosResponse.body);
        final dynamic notasData = jsonDecode(notasResponse.body);

        if (cultivosData is List && notasData is List) {
          setState(() {
            _cultivos = List<Map<String, dynamic>>.from(cultivosData);
            _notasFiscais = List<Map<String, dynamic>>.from(notasData);

            if (_cultivos.isNotEmpty) {
              // AJUSTE 1: Garante que o primeiro item a ser selecionado também venha da lista de nomes únicos
              final nomesUnicos = _cultivos
                  .map((c) => c['cultura'].toString())
                  .toSet()
                  .toList();
              _cultivoSelecionado = nomesUnicos.first;
              _gerarCusto(); // Calcula o custo inicial para o primeiro item
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _inicializando = false;
        });
      }
    }
  }

  void _gerarCusto() {
    if (_cultivoSelecionado == null || _cultivos.isEmpty) {
      setState(() {
        _areaCalculada = '0.00 ha';
        _totalNotasFiscais = 'R\$ 0.00';
        _custoPorArea = 'R\$ 0.00 / ha';
      });
      return;
    }

    // Filtra todos os registros daquele cultivo para somar a área total
    final List<Map<String, dynamic>> cultivosFiltrados = _cultivos
        .where((c) => c['cultura'] == _cultivoSelecionado)
        .toList();

    // Pega os IDs de todos os registros do cultivo selecionado
    final List<String> idsDosCultivosSelecionados = cultivosFiltrados
        .map((c) => c['id'].toString())
        .toList();

    // Filtra as notas fiscais que pertencem a qualquer um dos IDs do cultivo selecionado
    final List<Map<String, dynamic>> notasFiltradas = _notasFiscais.where((nf) {
      return idsDosCultivosSelecionados.contains(nf['cultivo_id'].toString());
    }).toList();

    double totalArea = 0.0;
    for (var cultivo in cultivosFiltrados) {
      totalArea += double.tryParse(cultivo['area']?.toString() ?? '0') ?? 0.0;
    }

    double totalNotas = 0.0;
    for (var nota in notasFiltradas) {
      totalNotas += double.tryParse(nota['valor']?.toString() ?? '0') ?? 0.0;
    }

    double custoCalculado = 0.0;
    if (totalArea > 0) {
      custoCalculado = totalNotas / totalArea;
    }

    setState(() {
      _areaCalculada = '${totalArea.toStringAsFixed(2)} ha';
      _totalNotasFiscais = 'R\$ ${totalNotas.toStringAsFixed(2)}';
      _custoPorArea = 'R\$ ${custoCalculado.toStringAsFixed(2)} / ha';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF327953);
    const Color formBackgroundColor = Colors.white;
    const Color primaryColor = Color(0xFF024222);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: _inicializando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
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
                  const Text(
                    'Custo da Safra',
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
                      color: Color.fromARGB(179, 37, 36, 36),
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
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
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Cultivo'),
                                        // AJUSTE 2: Cria uma lista de nomes de cultivos únicos para o Dropdown
                                        Builder(
                                          builder: (context) {
                                            final nomesUnicosCultivos = _cultivos
                                                .map(
                                                  (cultivo) =>
                                                      cultivo['cultura']
                                                          .toString(),
                                                )
                                                .toSet() // O Set remove automaticamente as duplicatas
                                                .toList(); // Converte de volta para uma lista

                                            return DropdownButtonFormField<
                                              String
                                            >(
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                              ),
                                              value: _cultivoSelecionado,
                                              hint: const Text(
                                                'Selecione um cultivo',
                                              ),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _cultivoSelecionado =
                                                      newValue;
                                                  // A chamada _gerarCusto() foi removida daqui
                                                });
                                              },
                                              items: nomesUnicosCultivos
                                                  .map<
                                                    DropdownMenuItem<String>
                                                  >(
                                                    (String nomeCultivo) =>
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: nomeCultivo,
                                                          child: Text(
                                                            nomeCultivo,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Área de Plantio'),
                                        TextFormField(
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          controller: TextEditingController(
                                            text: _areaCalculada,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Custo Total'),
                                        TextFormField(
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          controller: TextEditingController(
                                            text: _totalNotasFiscais,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                // AJUSTE 3: Este botão agora é o único que chama a função de cálculo
                                onPressed: _gerarCusto,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Gerar Custo'),
                              ),
                              const SizedBox(height: 40),
                              const Text(
                                'Custo da Safra por Hectare',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _custoPorArea,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
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
        color: Colors
            .white, // Alterado para branco para combinar com o fundo do form
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50), // Botão mais alto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}
