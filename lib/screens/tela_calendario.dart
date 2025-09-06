import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TelaCalendario extends StatefulWidget {
  const TelaCalendario({super.key});

  @override
  State<TelaCalendario> createState() => _TelaCalendarioState();
}

class _TelaCalendarioState extends State<TelaCalendario> {
  // Controladores para os campos de texto do formulário
  final _cultivoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Estado para controlar a data selecionada e o mês atual
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mapa para armazenar os eventos. A chave é a data e o valor é uma lista de eventos.
  Map<DateTime, List<Map<String, String>>> _events = {};
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _cultivoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // Função chamada ao selecionar um dia no calendário
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // Função para adicionar um novo evento
  Future<void> _adicionarEvento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      // Cria o novo evento com base nos dados do formulário
      final newEvent = {
        'cultivo': _cultivoController.text,
        'descricao': _descricaoController.text,
      };

      // Simula o salvamento em um banco de dados
      await Future.delayed(const Duration(milliseconds: 500));

      final day = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      if (_events[day] != null) {
        _events[day]!.add(newEvent);
      } else {
        _events[day] = [newEvent];
      }

      // Limpa os campos de texto e mostra uma mensagem de sucesso
      _cultivoController.clear();
      _descricaoController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar o evento.'),
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

  // Função para remover um evento
  void _removerEvento(DateTime day, int index) {
    setState(() {
      if (_events.containsKey(day) && _events[day]!.length > index) {
        _events[day]!.removeAt(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Helper function to get the number of days in a month
  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Helper function to get the day of the week for the first day of the month
  int firstDayWeekday(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF024222);
    const Color accentColor = Color.fromARGB(
      255,
      3,
      63,
      31,
    ); // Cor da barra superior
    const Color formBackgroundColor = Colors.white;
    const Color buttonColor = Color(0xFF333333);
    const Color selectedDayColor = Color(0xFF22578E); // Azul do design

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
    final int startDay = firstDayWeekday(year, month);
    final int gridItems = days + startDay - 1;

    final List<Map<String, String>> selectedDayEvents =
        _events[DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        )] ??
        [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Cor de fundo
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
            ), // Preto do design
          ),

          // Layout principal da tela
          SingleChildScrollView(
            child: Column(
              children: [
                // --- Cabeçalho AgroGestor ---
                Container(
                  color: const Color.fromARGB(255, 3, 63, 31),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'AgroGestor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Título e Slogan ---
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

                // --- Conteúdo Principal (Calendário e Formulário) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Seção do Calendário ---
                      Expanded(
                        child: Container(
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
                                          _focusedDay.day,
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
                                          _focusedDay.day,
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
                                      mainAxisSpacing: 4.0,
                                      crossAxisSpacing: 4.0,
                                    ),
                                itemCount: weekdays.length,
                                itemBuilder: (context, index) {
                                  return Center(
                                    child: Text(
                                      weekdays[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: buttonColor,
                                      ),
                                    ),
                                  );
                                },
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
                                itemCount: gridItems,
                                itemBuilder: (context, index) {
                                  if (index < startDay - 1) {
                                    return Container();
                                  }

                                  final dayNumber = index - (startDay - 2);
                                  final day = DateTime(year, month, dayNumber);
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
                                        border: Border.all(
                                          color: hasEvents
                                              ? Colors.orange
                                              : Colors.transparent,
                                          width: hasEvents ? 2.0 : 0.0,
                                        ),
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
                      // --- Seção do Formulário de Cadastro ---
                      Expanded(
                        child: Column(
                          children: [
                            Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cadastrar Atividades da Safra',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Cultura',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _cultivoController,
                                      decoration: const InputDecoration(
                                        hintText: 'Ex: Soja, Milho, Trigo',
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Insira o nome do cultivo'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Data',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _selectedDay != null
                                            ? '${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}'
                                            : 'DD/MM/AAAA',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Descrição',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _descricaoController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ex: Plantio, Irrigação, Colheita',
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      maxLines: 3,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Insira a descrição da atividade'
                                          : null,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _cultivoController.clear();
                                              _descricaoController.clear();
                                              setState(() {});
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey[300],
                                              foregroundColor: buttonColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16.0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            child: const Text('Cancelar'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _carregando
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : ElevatedButton(
                                                  onPressed: _adicionarEvento,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryColor,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16.0,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text('Salvar'),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // --- Seção de Visualização de Eventos ---
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
                                  Text(
                                    'Eventos em: ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Verifica se há eventos para o dia selecionado
                                  if (selectedDayEvents.isNotEmpty)
                                    ...selectedDayEvents.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final event = entry.value;
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            event['cultivo'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            event['descricao'] ?? '',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _removerEvento(
                                              DateTime(
                                                _selectedDay!.year,
                                                _selectedDay!.month,
                                                _selectedDay!.day,
                                              ),
                                              index,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList()
                                  else
                                    const Text(
                                      'Nenhum evento registrado para esta data.',
                                      style: TextStyle(color: buttonColor),
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
              ],
            ),
          ),

          // Botão Voltar
          Positioned(
            left: 24,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: primaryColor,
              label: const Text(
                'Voltar',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
