import 'package:agrogestor/screens/tela_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ),
      // Adiciona o suporte para localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      // A tela inicial do aplicativo será a TelaLogin
      home: const TelaLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}
