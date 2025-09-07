import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Modelo de dados para os eventos
class EventoCalendario {
  final int id;
  final DateTime data;
  final String titulo;
  final String descricao;

  EventoCalendario({
    required this.id,
    required this.data,
    required this.titulo,
    required this.descricao,
  });

  factory EventoCalendario.fromJson(Map<String, dynamic> json) {
    return EventoCalendario(
      id: int.parse(json['id'].toString()),
      data: DateTime.parse(json['data_evento'].toString()),
      titulo: json['titulo_evento'].toString(),
      descricao: json['descricao_evento'].toString(),
    );
  }
}

class TelaCalendario extends StatefulWidget {
  final int propriedadeId;

  const TelaCalendario({super.key, required this.propriedadeId});

  @override
  State<TelaCalendario> createState() => _TelaCalendarioState();
}

class _TelaCalendarioState extends State<TelaCalendario> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ATUALIZADO: A fonte dos eventos agora é a API
  Map<DateTime, List<EventoCalendario>> _events = {};
  bool _carregando = true;

  String get _apiUrlBase {
    if (kIsWeb) return 'http://localhost/api';
    if (Platform.isAndroid) return 'http://192.168.0.250/api';
    return 'http://localhost/api';
  }

  String get apiUrlListar => '$_apiUrlBase/listar_eventos.php';
  String get apiUrlCadastrar => '$_apiUrlBase/cadastrar_evento.php';
  String get apiUrlExcluir => '$_apiUrlBase/excluir_evento.php';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _carregarEventos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _carregando = true;
    });
    try {
      final uri = Uri.parse(
        '$apiUrlListar?propriedade_id=${widget.propriedadeId}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<EventoCalendario> eventosCarregados = data
            .map((json) => EventoCalendario.fromJson(json))
            .toList();

        final Map<DateTime, List<EventoCalendario>> eventosMapeados = {};
        for (var evento in eventosCarregados) {
          final dia = DateTime.utc(
            evento.data.year,
            evento.data.month,
            evento.data.day,
          );
          if (eventosMapeados[dia] == null) {
            eventosMapeados[dia] = [];
          }
          eventosMapeados[dia]!.add(evento);
        }

        setState(() {
          _events = eventosMapeados;
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _adicionarEvento() async {
    if (!_formKey.currentState!.validate() || _selectedDay == null) {
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

    try {
      final response = await http.post(
        Uri.parse(apiUrlCadastrar),
        body: {
          'propriedade_id': widget.propriedadeId.toString(),
          'data_evento': DateFormat('yyyy-MM-dd').format(_selectedDay!),
          'titulo_evento': _tituloController.text,
          'descricao_evento': _descricaoController.text,
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
          _tituloController.clear();
          _descricaoController.clear();
          _carregarEventos();
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

  Future<void> _removerEvento(int eventoId) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrlExcluir),
        body: {'id': eventoId.toString()},
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
          _carregarEventos();
        }
      }
    } catch (e) {
      // Tratar erro
    }
  }

  // Funções auxiliares do seu layout original
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
  int firstDayWeekday(int year, int month) => DateTime(year, month, 1).weekday;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color formBackgroundColor = Colors.white;
    const Color buttonColor = Color(0xFF333333);
    const Color selectedDayColor = Color(0xFF22578E);

    final List<String> weekdays = [
      'DOM',
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SAB',
    ];
    final List<String> months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    final int year = _focusedDay.year;
    final int month = _focusedDay.month;
    final int days = daysInMonth(year, month);
    // Ajuste para o índice do weekday (domingo = 7, mas queremos que seja 0 para o cálculo)
    final int startDayIndex = firstDayWeekday(year, month) % 7;
    final int totalGridSlots = (days + startDayIndex).ceilToDouble().toInt();

    // ATUALIZADO: Lê a lista de eventos para o dia selecionado
    final List<EventoCalendario> selectedDayEvents =
        _events[DateTime.utc(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        )] ??
        [];

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // Fundo escuro como no seu design
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color.fromARGB(255, 3, 63, 31),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: const Row(
                children: [
                  Text(
                    'AgroGestor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Calendário',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "\"Planeje sua colheita, otimize seu tempo\"",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Seção do Calendário ---
                  Expanded(
                    flex: 2, // Dando mais espaço para o calendário
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: formBackgroundColor,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: () {
                                        setState(() {
                                          _focusedDay = DateTime(
                                            _focusedDay.year,
                                            _focusedDay.month - 1,
                                            1,
                                          );
                                        });
                                      },
                                    ),
                                    Text(
                                      '${months[_focusedDay.month - 1]} ${_focusedDay.year}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () {
                                        setState(() {
                                          _focusedDay = DateTime(
                                            _focusedDay.year,
                                            _focusedDay.month + 1,
                                            1,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                      ),
                                  itemCount: weekdays.length,
                                  itemBuilder: (context, index) => Center(
                                    child: Text(
                                      weekdays[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: buttonColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 4.0,
                                        crossAxisSpacing: 4.0,
                                      ),
                                  itemCount: totalGridSlots,
                                  itemBuilder: (context, index) {
                                    if (index < startDayIndex) {
                                      return Container(); // Células vazias antes do dia 1
                                    }
                                    final dayNumber = index - startDayIndex + 1;
                                    if (dayNumber > days) {
                                      return Container(); // Células vazias depois do último dia
                                    }

                                    final day = DateTime.utc(
                                      year,
                                      month,
                                      dayNumber,
                                    );
                                    final isSelected = isSameDay(
                                      _selectedDay,
                                      day,
                                    );
                                    final hasEvents = _events.containsKey(day);

                                    return GestureDetector(
                                      onTap: () =>
                                          _onDaySelected(day, _focusedDay),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? selectedDayColor
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: hasEvents
                                              ? Border.all(
                                                  color: Colors.orange,
                                                  width: 2.0,
                                                )
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$dayNumber',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  // --- Seção do Formulário e Eventos ---
                  Expanded(
                    flex: 1, // Menos espaço para esta seção
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: formBackgroundColor,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cadastrar Atividade',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Para: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _tituloController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título (ex: Soja)',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Insira um título' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descricaoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descrição (ex: Irrigação)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                  validator: (v) => v!.isEmpty
                                      ? 'Insira uma descrição'
                                      : null,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _adicionarEvento,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                    ),
                                    child: const Text('Salvar'),
                                  ),
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
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eventos em: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              if (selectedDayEvents.isNotEmpty)
                                ...selectedDayEvents.map((event) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      title: Text(
                                        event.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(event.descricao),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removerEvento(event.id),
                                      ),
                                    ),
                                  );
                                }).toList()
                              else
                                const Text('Nenhum evento para esta data.'),
                            ],
                          ),
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
        padding: const EdgeInsets.all(16),
        color: const Color.fromARGB(255, 255, 255, 255),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar'),
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
