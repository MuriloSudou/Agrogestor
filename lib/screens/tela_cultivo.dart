import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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

  // Lista para armazenar os cultivos cadastrados
  List<Map<String, dynamic>> _cultivos = [];

  // Índice do cultivo que está sendo editado
  int? _indiceEdicao;

  // Controle de loading
  bool _carregando = false;
  bool _inicializando = true;

  String get _apiUrlBase {
    if (kIsWeb) {
      return 'http://localhost/api';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2/api';
      } else {
        // Para iOS ou outros, você pode precisar de outro IP
        return 'http://localhost/api';
      }
    }
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
      final response = await http.post(
        Uri.parse(apiUrlListar),
        body: {'propriedade_id': widget.propriedadeId.toString()},
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _cultivos = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao carregar cultivos: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao conectar ao servidor para carregar dados: $e',
            ),
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
    _cultivoController.clear();
    _areaController.clear();
    _inicioController.clear();
    setState(() {
      _dataSelecionada = null;
      _indiceEdicao = null;
    });
  }

  Future<void> _salvarOuAtualizarCultivo() async {
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

    final cultivoDados = {
      'cultura': _cultivoController.text,
      'propriedade_id': widget.propriedadeId.toString(),
      'area': _areaController.text,
      'inicio': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
    };

    try {
      final url = _indiceEdicao == null ? apiUrlCadastro : apiUrlEdicao;
      if (_indiceEdicao != null) {
        cultivoDados['id'] = _cultivos[_indiceEdicao!]['id'].toString();
      }
      final response = await http.post(Uri.parse(url), body: cultivoDados);
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
        _carregarCultivos(); // Recarrega a lista após a operação
        _limparCampos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar cultivo: $e'),
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

  void _editarCultivo(int index) {
    setState(() {
      _indiceEdicao = index;
      _cultivoController.text = _cultivos[index]['cultura'];
      _areaController.text = _cultivos[index]['area'].toString();
      _dataSelecionada = DateFormat(
        'dd/MM/yyyy',
      ).parse(_cultivos[index]['inicio']);
      _inicioController.text = _cultivos[index]['inicio'];
    });
  }

  Future<void> _excluirCultivo(int index) async {
    final cultivoId = _cultivos[index]['id'].toString();
    try {
      final response = await http.post(
        Uri.parse(apiUrlExclusao),
        body: {'id': cultivoId},
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
        _carregarCultivos(); // Recarrega a lista após a operação
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.red,
            ),
          );
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
    const Color accentColor = Color(0xFF327953); // Cor da barra superior
    const Color buttonColor = Color(0xFF333333);
    const Color formBackgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Cabeçalho AgroGestor ---
            Container(
              color: accentColor,
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
              'Cultivo',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "\"Cadastro de Cultivo AgroGestor: Organize sua plantação, colha eficiência.\"",
              style: TextStyle(
                color: Color.fromARGB(179, 37, 36, 36),
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
                                    const Text('Cultivo'),
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
                                    const Text('Área de Plantio'),
                                    TextFormField(
                                      controller: _areaController,
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
                                    const Text('Início'),
                                    TextFormField(
                                      controller: _inicioController,
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
                                    : _salvarOuAtualizarCultivo,
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
                              if (_indiceEdicao != null)
                                ElevatedButton(
                                  onPressed: _limparCampos,
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
                                  child: const Text('Cancelar Edição'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // --- Lista de Cultivos Cadastrados ---
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
                                      title: Text(cultivo['cultura']),
                                      subtitle: Text(
                                        'Propriedade: ${cultivo['propriedade_id'] ?? 'N/A'} | Área: ${cultivo['area'] ?? 'N/A'} | Início: ${cultivo['inicio'] ?? 'N/A'}',
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
                                                _editarCultivo(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _excluirCultivo(index),
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
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Voltar ao Perfil'),
        ),
      ),
    );
  }
}
