import 'package:flutter/material.dart';
import 'tela_login.dart';
import 'tela_notas_fiscais.dart';

class TelaHome extends StatelessWidget {
  
  final int propriedadeId;

  const TelaHome({super.key, required this.propriedadeId});


  Widget _buildDrawerItem({required String title, required VoidCallback onTap, required BuildContext context}) {
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
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Gerencie sua Produção!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            _buildDrawerItem(
              context: context,
              title: 'Nota Fiscais',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaNotasFiscais(propriedadeId: propriedadeId),
                  ),
                );
              },
            ),
            _buildDrawerItem(context: context, title: 'Cultivo', onTap: () {}),
            _buildDrawerItem(context: context, title: 'Custo', onTap: () {}),
            _buildDrawerItem(context: context, title: 'Calendário', onTap: () {}),
            _buildDrawerItem(context: context, title: 'Sacas', onTap: () {}),
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
