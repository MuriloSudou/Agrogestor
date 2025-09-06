import 'package:agrogestor/screens/tela_calendario.dart';
import 'package:agrogestor/screens/tela_cultivo.dart';
import 'package:agrogestor/screens/tela_saca.dart';
import 'package:flutter/material.dart';
import 'tela_login.dart';
import 'tela_notas_fiscais.dart';
import 'tela_custo.dart';

class TelaHome extends StatelessWidget {
  final int propriedadeId;

  const TelaHome({super.key, required this.propriedadeId});

  Widget _buildDrawerItem({
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D25),
      appBar: AppBar(
        title: const Text("AgroGestor"),
        backgroundColor: const Color.fromARGB(221, 255, 255, 255),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF004D25)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Gerencie sua Produção!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildDrawerItem(
              context: context,
              title: 'Notas Fiscais',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TelaNotasFiscais(propriedadeId: propriedadeId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              title: 'Cultivo',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TelaCultivo(propriedadeId: propriedadeId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              title: 'Custo',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TelaCusto(propriedadeId: propriedadeId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              title: 'Calendário',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TelaCalendario()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              title: 'Sacas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaSacas()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/img/img1/logogeral.png', height: 120.0),
            const SizedBox(height: 10),
            const Text(
              "Seu gerenciador agrícola!",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
