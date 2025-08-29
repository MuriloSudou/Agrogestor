

import 'package:agrogestor/screens/tela_login.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const AgroGestorApp());
}

class AgroGestorApp extends StatelessWidget {
  const AgroGestorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroGestor',
      theme: ThemeData(
        // Define a cor primária do aplicativo
        primarySwatch: Colors.green,
        // Define um tema visual para os componentes
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define um tema para os campos de input
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        // Define um tema para os botões elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ),
      // A tela inicial do aplicativo será a TelaLogin
      home: const TelaLogin(),
      debugShowCheckedModeBanner: false, // Remove o banner de debug
    );
  }
}
