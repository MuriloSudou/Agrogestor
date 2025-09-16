import 'package:agrogestor/screens/tela_calendario.dart';
import 'package:agrogestor/screens/tela_cultivo.dart';
import 'package:agrogestor/screens/tela_saca.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tela_login.dart';
import 'tela_notas_fiscais.dart';
import 'tela_custo.dart';

class TelaHome extends StatefulWidget {
  final String propriedadeId;
  final String nomeAgricultor;

  const TelaHome({
    super.key,
    required this.propriedadeId,
    required this.nomeAgricultor,
  });

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  Map<String, dynamic>? _dadosDashboard;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDadosDashboard();
  }

  Future<void> _carregarDadosDashboard() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // Busca os dados da propriedade no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('propriedades')
          .doc(widget.propriedadeId)
          .get();
      if (!doc.exists) {
        setState(() => _erro = 'Propriedade não encontrada.');
        return;
      }
      final data = doc.data() as Map<String, dynamic>;

      // Exemplo: buscar cultivos e sacas relacionados a esta propriedade
      final cultivosSnap = await FirebaseFirestore.instance
          .collection('cultivos')
          .where('propriedadeId', isEqualTo: widget.propriedadeId)
          .get();
      final totalCultivos = cultivosSnap.docs.length;

      final sacasSnap = await FirebaseFirestore.instance
          .collection('sacas')
          .where('propriedadeId', isEqualTo: widget.propriedadeId)
          .get();
      // Resumo de sacas por cultivo
      final Map<String, int> resumoSacas = {};
      for (var doc in sacasSnap.docs) {
        final nomeCultivo = doc['nome_cultivo'] ?? 'N/A';
        final total = int.tryParse(doc['total_sacas']?.toString() ?? '0') ?? 0;
        resumoSacas[nomeCultivo] = (resumoSacas[nomeCultivo] ?? 0) + total;
      }

      // Exemplo: buscar custo total (somando notas fiscais)
      final notasSnap = await FirebaseFirestore.instance
          .collection('notas_fiscais')
          .where('propriedadeId', isEqualTo: widget.propriedadeId)
          .get();
      double custoTotal = 0;
      for (var doc in notasSnap.docs) {
        custoTotal += double.tryParse(doc['valor']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        _dadosDashboard = {
          'nome_propriedade': data['nome'] ?? '',
          'total_cultivos': totalCultivos,
          'custo_total': custoTotal,
          'resumo_sacas': resumoSacas.entries
              .map((e) => {'nome_cultivo': e.key, 'total_sacas': e.value})
              .toList(),
        };
      });
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar dados: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_dadosDashboard?['nome_propriedade'] ?? "AgroGestor"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const TelaLogin()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Text(
                'Erro: $_erro',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarDadosDashboard,
              child: _buildDashboardBody(),
            ),
    );
  }

  Widget _buildDashboardBody() {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final custoTotal =
        double.tryParse(_dadosDashboard?['custo_total'].toString() ?? '0') ?? 0;

    // NOVO: Pega a lista de resumo de sacas
    final List resumoSacas = _dadosDashboard?['resumo_sacas'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo, ${widget.nomeAgricultor}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este é o resumo da sua propriedade.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInfoCard(
                icon: Icons.grass,
                label: 'Cultivos Ativos',
                value: _dadosDashboard?['total_cultivos']?.toString() ?? '0',
                color: Colors.green,
              ),
              _buildInfoCard(
                icon: Icons.request_quote,
                label: 'Custo Total',
                value: currencyFormat.format(custoTotal),
                color: Colors.orange,
              ),
            ],
          ),

          // NOVO: Seção para o resumo da colheita
          if (resumoSacas.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Resumo da Colheita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: resumoSacas.map<Widget>((saca) {
                  return ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.brown,
                    ),
                    title: Text(
                      saca['nome_cultivo'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${saca['total_sacas']} Sacas',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF004D25)),
            child: Text(
              'Olá, ${widget.nomeAgricultor}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Gerencie sua Produção!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _buildDrawerItem(
            context: context,
            title: 'Notas Fiscais',
            onTap: () async {
              // Navega para a tela e espera que ela seja fechada
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TelaNotasFiscais(propriedadeId: widget.propriedadeId),
                ),
              );

              // Quando o usuário voltar (pop), recarrega os dados do dashboard
              _carregarDadosDashboard();
            },
          ),
          _buildDrawerItem(
            context: context,
            title: 'Cultivo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TelaCultivo(propriedadeId: widget.propriedadeId),
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            title: 'Custo da Safra',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TelaCusto(propriedadeId: widget.propriedadeId),
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            title: 'Calendário',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TelaCalendario(propriedadeId: widget.propriedadeId),
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            title: 'Sacas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TelaSacas(propriedadeId: widget.propriedadeId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
