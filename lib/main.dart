import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pillmate/cadastro_medicamentos_page.dart';
import 'package:pillmate/cadastro_tratamento_page.dart';
import 'package:pillmate/configuracoes_page.dart';
import 'package:pillmate/detalhes_tratamento_page.dart';
import 'package:pillmate/editar_tratamento_page.dart';
import 'package:pillmate/home_page.dart';
import 'package:pillmate/lista_medicamentos_page.dart';
import 'package:pillmate/lista_tratamentos_page.dart';
import 'package:pillmate/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerenciador de Medicamentos',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/cadastro': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return CadastroMedicamentoPage(medicamentoId: args?['medicamentoId']);
        },
        '/configuracoes': (context) => const ConfiguracoesPage(),
        '/lista-medicamentos': (context) => ListaMedicamentosPage(),
        '/lista-tratamentos': (context) => ListaTratamentosPage(),
        '/cadastro-tratamento': (context) => const CadastroTratamentoPage(),
        '/detalhes-tratamento': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return DetalhesTratamentoPage(tratamentoId: args);
        },
        '/editar-tratamento': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return EditarTratamentoPage(tratamentoId: args);
        },
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 83, 0, 255),
          primary: const Color.fromARGB(255, 83, 0, 255),
        ),
        useMaterial3: true,
      ),
    );
  }
}
