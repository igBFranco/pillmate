import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String firstName = user?.displayName?.split(' ').first ?? 'Usuário';
    final String userEmail = user?.email ?? 'E-mail não disponível';

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logoHorizontal.png',
          height: 30,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, '/cadastro-tratamento'),
          ),
        ],
      ),
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                  child: Text('Erro ao carregar dados do usuário.'));
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final imageUrl = userData['photoURL'];

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userData['nome'] ?? 'Usuário'),
                  accountEmail: Text(userEmail),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl)
                        : const AssetImage('assets/images/user.png')
                            as ImageProvider,
                    child: imageUrl == null
                        ? const Icon(Icons.person,
                            size: 50, color: Colors.white)
                        : null,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, 
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Tratamentos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/lista-tratamentos');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Lista de Medicamentos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/lista-medicamentos');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text('Adicionar Medicamento'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/cadastro');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/configuracoes');
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Bem-vindo, $firstName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                buildOptionCard(context, 'Tratamentos', Colors.blue,
                    Icons.medical_services, '/lista-tratamentos'),
                buildOptionCard(context, 'Medicamentos', Colors.green,
                    Icons.local_hospital, '/lista-medicamentos'),
                buildOptionCard(context, 'Adicionar Medicamento', Colors.orange,
                    Icons.medication, '/cadastro'),
                buildOptionCard(context, 'Configurações', Colors.purple,
                    Icons.settings, '/configuracoes'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('tratamentos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Nenhum tratamento cadastrado.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String medicamentoId =
                        data['medicamentoId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('medicamentos')
                          .doc(medicamentoId)
                          .get(),
                      builder: (context, medicamentoSnapshot) {
                        if (medicamentoSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Carregando medicamento...'),
                          );
                        }
                        if (!medicamentoSnapshot.hasData ||
                            !medicamentoSnapshot.data!.exists) {
                          return const ListTile(
                            title: Text('Medicamento não encontrado'),
                          );
                        }
                        var medicamentoData = medicamentoSnapshot.data!.data()
                            as Map<String, dynamic>;
                        String medicamentoNome = medicamentoData['nome'] ??
                            'Medicamento desconhecido';

                        List<dynamic> lembretes = data['lembretes'] ?? [];
                        
                        // Verificar se dataInicial existe e é válida
                        Timestamp? dataInicialTimestamp = data['dataInicial'];
                        if (dataInicialTimestamp == null) {
                          return const ListTile(
                            title: Text('Data inicial não encontrada para este tratamento.'),
                          );
                        }
                        DateTime dataInicial = dataInicialTimestamp.toDate();

                        // Filtrar e ordenar os lembretes pela data e hora
                        List<String> proximosLembretes =
                            _calcularProximosLembretes(lembretes, dataInicial);

                        return ListTile(
                          title: Text(medicamentoNome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (proximosLembretes.isNotEmpty)
                                const Text('Próximos Lembretes:'),
                              Wrap(
                                spacing: 8.0,
                                children: proximosLembretes.map((horario) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: Text(
                                      horario,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/detalhes-tratamento',
                                arguments: doc.id);
                          },
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Função para calcular os próximos lembretes
  List<String> _calcularProximosLembretes(
    List<dynamic> lembretes, DateTime dataInicial) {
  List<String> proximosLembretes = [];
  DateTime agora = DateTime.now();

  bool tratamentoFinalizado =
      lembretes.every((lembrete) => lembrete['tomado'] == true);

  if (tratamentoFinalizado) {
    // Se o tratamento estiver finalizado, retornar somente a mensagem
    return ["Tratamento finalizado"];
  } else {
    // Filtrar e adicionar apenas os lembretes tomado == false
    for (var lembrete in lembretes) {
      if (lembrete['data'] is Timestamp && lembrete['tomado'] == false) {
        DateTime lembreteData = (lembrete['data'] as Timestamp).toDate();

        // Verificar se o lembrete é após a data e hora atual
        if (lembreteData.isAfter(agora)) {
          String horarioFormatado =
              "${lembreteData.hour}:${lembreteData.minute.toString().padLeft(2, '0')}";
          proximosLembretes.add(horarioFormatado);
        }
      }
    }

    // Caso não haja lembretes futuros, adicionar uma mensagem padrão
    if (proximosLembretes.isEmpty) {
      proximosLembretes.add("Não há lembretes futuros!");
    }
  }

  return proximosLembretes.take(3).toList();
}


  Widget buildOptionCard(BuildContext context, String title, Color color,
      IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 100,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
