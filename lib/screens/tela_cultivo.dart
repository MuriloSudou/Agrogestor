import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// NOVO: Modelo de dados para segurança e clareza
class Cultivo {
  final int id;
  final String cultura;
  final String area;
  final String inicio;

  Cultivo({
    required this.id,
    required this.cultura,
    required this.area,
    required this.inicio,
  });

  factory Cultivo.fromJson(Map<String, dynamic> json) {
    return Cultivo(
      id: int.parse(json['id'].toString()),
      cultura: json['cultura'].toString(),
      area: json['area'].toString(),
      inicio: json['inicio'].toString(),
    );
  }
}

class TelaCultivo extends StatefulWidget {
  final int propriedadeId;
  const TelaCultivo({super.key, required this.propriedadeId});

  @override
  State<TelaCultivo> createState() => _TelaCultivoState();
}

class _TelaCultivoState extends State<TelaCultivo> {
  final _formKey = GlobalKey<FormState>();
  final _cultivoController = TextEditingController();
  final _areaController = TextEditingController();
  final _inicioController = TextEditingController();
  DateTime? _dataSelecionada;

  List<Cultivo> _cultivos = []; // Usa o modelo de dados
  int? _idEdicao; // Guarda o ID em vez do índice

  bool _carregando = false;
  bool _inicializando = true;

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://10.0.2.2/api';
    return 'http://localhost/api';
  }

  String get apiUrlListar => '$_apiUrlBase/listar_cultivos.php';
  String get apiUrlCadastro => '$_apiUrlBase/cadastro_cultivos.php';
  String get apiUrlEdicao => '$_apiUrlBase/editar_cultivo.php';
  String get apiUrlExclusao => '$_apiUrlBase/excluir_cultivo.php';

  @override
  void initState() {
    super.initState();
    _carregarCultivos();
  }

  @override
  void dispose() {
    _cultivoController.dispose();
    _areaController.dispose();
    _inicioController.dispose();
    super.dispose();
  }

  Future<void> _carregarCultivos() async {
    setState(() {
      _inicializando = true;
    });
    try {
      // CORRIGIDO: Usa http.get para listar
      final uri = Uri.parse(
        '$apiUrlListar?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cultivos = data.map((json) => Cultivo.fromJson(json)).toList();
        });
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
      if (mounted)
        setState(() {
          _inicializando = false;
        });
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
        _inicioController.text = DateFormat('dd/MM/yyyy').format(data);
      });
    }
  }

  void _limparCampos() {
    _formKey.currentState?.reset();
    _cultivoController.clear();
    _areaController.clear();
    _inicioController.clear();
    setState(() {
      _dataSelecionada = null;
      _idEdicao = null;
    });
  }

  Future<void> _salvarOuAtualizarCultivo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    final url = _idEdicao == null ? apiUrlCadastro : apiUrlEdicao;
    final body = {
      'propriedade_id': widget.propriedadeId.toString(),
      'cultura': _cultivoController.text,
      'area': _areaController.text.replaceAll(',', '.'),
      'inicio': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
    };

    if (_idEdicao != null) {
      body['id'] = _idEdicao.toString();
    }

    try {
      final response = await http.post(Uri.parse(url), body: body);
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Operação concluída.'),
            backgroundColor:
                (data['status'] == 'success' || data['status'] == 'info')
                ? Colors.green
                : Colors.red,
          ),
        );
        if (data['status'] == 'success') {
          _carregarCultivos();
          _limparCampos();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _carregando = false;
        });
    }
  }

  void _iniciarEdicao(Cultivo cultivo) {
    setState(() {
      _idEdicao = cultivo.id;
      _cultivoController.text = cultivo.cultura;
      _areaController.text = cultivo.area;
      // CORRIGIDO: Formato da data para corresponder à API
      _dataSelecionada = DateTime.parse(cultivo.inicio);
      _inicioController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_dataSelecionada!);
    });
  }

  void _mostrarDialogoConfirmacao(int cultivoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este cultivo?'),
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
                _excluirCultivo(cultivoId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _excluirCultivo(int cultivoId) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrlExclusao),
        body: {'id': cultivoId.toString()},
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
          _carregarCultivos();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color buttonColor = Color(0xFF333333);
    const Color formBackgroundColor = Colors.white;

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
              'Cultivo',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "\"Organize sua plantação, colha eficiência.\"",
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
                                    const Text('Cultivo'),
                                    TextFormField(
                                      controller: _cultivoController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
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
                                    const Text('Área (ha)'),
                                    TextFormField(
                                      controller: _areaController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
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
                                    const Text('Início do Plantio'),
                                    TextFormField(
                                      controller: _inicioController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'dd/mm/aaaa',
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
                                    : _salvarOuAtualizarCultivo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
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
                                        _idEdicao == null
                                            ? 'Salvar'
                                            : 'Atualizar',
                                      ),
                              ),
                              if (_idEdicao != null) ...[
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _limparCampos,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Cancelar Edição'),
                                ),
                              ],
                            ],
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
                          'Cultivos cadastrados:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _inicializando
                            ? const Center(child: CircularProgressIndicator())
                            : _cultivos.isEmpty
                            ? const Center(
                                child: Text('Nenhum cultivo cadastrado.'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _cultivos.length,
                                itemBuilder: (context, index) {
                                  final cultivo = _cultivos[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        cultivo.cultura,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Área: ${cultivo.area} ha | Início: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(cultivo.inicio))}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _iniciarEdicao(cultivo),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _mostrarDialogoConfirmacao(
                                                  cultivo.id,
                                                ),
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
