import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:intl/intl.dart';

class TelaCusto extends StatefulWidget {
  final int propriedadeId;

  const TelaCusto({super.key, required this.propriedadeId});

  @override
  State<TelaCusto> createState() => _TelaCustoState();
}

class _TelaCustoState extends State<TelaCusto> {
  String? _cultivoSelecionado;
  String _areaCalculada = '0.00 ha';
  String _totalNotasFiscais = 'R\$ 0.00';
  String _custoPorArea = 'R\$ 0.00 / ha';
  bool _inicializando = true;

  List<Map<String, dynamic>> _cultivos = [];
  List<Map<String, dynamic>> _notasFiscais = [];

  // ATUALIZADO: Usando 10.0.2.2 para o emulador Android
  String get _apiUrlBase {
    if (kIsWeb) {
      return 'http://localhost/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2/api';
    } else {
      return 'http://localhost/api';
    }
  }

  String get apiUrlListarCultivos => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlListarNf => '$_apiUrlBase/listar_nf.php';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ATUALIZADO: Usando http.get para compatibilidade com a API
  Future<void> _carregarDados() async {
    setState(() {
      _inicializando = true;
    });

    try {
      final uriCultivos = Uri.parse(
        '$apiUrlListarCultivos?propriedade_id=${widget.propriedadeId}',
      );
      final uriNotas = Uri.parse(
        '$apiUrlListarNf?propriedade_id=${widget.propriedadeId}',
      );

      final cultivosResponse = await http.get(uriCultivos);
      final notasResponse = await http.get(uriNotas);

      if (cultivosResponse.statusCode == 200 &&
          notasResponse.statusCode == 200) {
        final dynamic cultivosData = jsonDecode(cultivosResponse.body);
        final dynamic notasData = jsonDecode(notasResponse.body);

        if (cultivosData is List && notasData is List) {
          setState(() {
            _cultivos = List<Map<String, dynamic>>.from(cultivosData);
            _notasFiscais = List<Map<String, dynamic>>.from(notasData);

            if (_cultivos.isNotEmpty) {
              final nomesUnicos = _cultivos
                  .map((c) => c['cultura'].toString())
                  .toSet()
                  .toList();
              // Não pré-seleciona mais, deixa o usuário escolher
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

    final List<Map<String, dynamic>> cultivosFiltrados = _cultivos
        .where((c) => c['cultura'] == _cultivoSelecionado)
        .toList();
    final List<String> idsDosCultivosSelecionados = cultivosFiltrados
        .map((c) => c['id'].toString())
        .toList();
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

    double custoCalculado = totalArea > 0 ? totalNotas / totalArea : 0.0;

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    setState(() {
      _areaCalculada =
          '${totalArea.toStringAsFixed(2).replaceAll('.', ',')} ha';
      _totalNotasFiscais = currencyFormat.format(totalNotas);
      _custoPorArea = '${currencyFormat.format(custoCalculado)} / ha';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color accentColor = Color(0xFF327953);

    final nomesUnicosCultivos = _cultivos
        .map((cultivo) => cultivo['cultura'].toString())
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _inicializando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('lib/img/img1/logogeral.png', height: 60),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Custo da Safra',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Selecione um cultivo para ver os custos detalhados.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Cultivo',
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                ),
                                value: _cultivoSelecionado,
                                hint: const Text('Selecione um cultivo'),
                                // ATUALIZADO: A lógica de cálculo agora está aqui
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _cultivoSelecionado = newValue;
                                    _gerarCusto(); // Calcula o custo assim que o usuário seleciona
                                  });
                                },
                                items: nomesUnicosCultivos
                                    .map<DropdownMenuItem<String>>(
                                      (String nomeCultivo) =>
                                          DropdownMenuItem<String>(
                                            value: nomeCultivo,
                                            child: Text(nomeCultivo),
                                          ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                'Área Total Cultivada:',
                                _areaCalculada,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                'Custo Total (NF-e):',
                                _totalNotasFiscais,
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                'Custo por Hectare:',
                                _custoPorArea,
                                isTotal: true,
                                color: accentColor,
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
        color: Colors.grey[100],
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Voltar'),
        ),
      ),
    );
  }

  // Widget auxiliar para criar as linhas de informação
  Widget _buildInfoRow(
    String label,
    String value, {
    bool isTotal = false,
    Color color = Colors.black87,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
