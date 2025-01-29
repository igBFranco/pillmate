import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pillmate/login_page.dart';

class ListaTratamentosPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Tratamentos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                        data['medicamentoId']; // Pega o ID do medicamento

                    // Buscar o nome do medicamento usando o ID
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
                        
                        // Verificar se 'dataInicial' existe e é válida
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
                          title: Text('$medicamentoNome'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (proximosLembretes.isNotEmpty)
                                Text('Próximos Lembretes:'),
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

    for (var lembrete in lembretes) {
      // Verificar se o campo 'data' existe e é um Timestamp
      if (lembrete['data'] is Timestamp) {
        DateTime lembreteData = (lembrete['data'] as Timestamp).toDate();

        // Verificar se o lembrete é após a data e hora atual
        if (lembreteData.isAfter(agora)) {
          // Formatar o horário para exibição
          String horarioFormatado =
              "${lembreteData.hour}:${lembreteData.minute.toString().padLeft(2, '0')}";
          proximosLembretes.add(horarioFormatado);
        }
      }
    }

    return proximosLembretes.take(3).toList();
  }
}
