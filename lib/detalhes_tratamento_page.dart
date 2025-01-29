import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetalhesTratamentoPage extends StatefulWidget {
  final String tratamentoId;

  const DetalhesTratamentoPage({super.key, required this.tratamentoId});

  @override
  _DetalhesTratamentoPageState createState() => _DetalhesTratamentoPageState();
}

class _DetalhesTratamentoPageState extends State<DetalhesTratamentoPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Função para marcar o medicamento como tomado
  void _marcarComoTomado(bool tomado, String horario, int quantidade,
      String medicamentoId, DateTime data) async {
    try {
      final tratamentoDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tratamentos')
          .doc(widget.tratamentoId);

      final tratamentoSnapshot = await tratamentoDoc.get();

      if (tratamentoSnapshot.exists) {
        final tratamentoData = tratamentoSnapshot.data();
        if (tratamentoData is! Map<String, dynamic>) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados do tratamento não encontrados.')),
          );
          return;
        }

        final List<dynamic> lembretes = tratamentoData['lembretes'] ?? [];

        // Encontrar o lembrete correspondente e atualizar o campo 'tomado'
        for (int i = 0; i < lembretes.length; i++) {
          final lembreteData = lembretes[i];
          final Timestamp lembreteDataTimestamp = lembreteData['data'];

          if (_formatDataHora(lembreteDataTimestamp) == horario) {
            lembretes[i]['tomado'] = tomado;

            await tratamentoDoc.update({
              'lembretes': lembretes,
            });

            break;
          }
        }

        // Se o medicamento foi tomado, atualiza o estoque
        if (tomado) {
          final medicamentoDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('medicamentos')
              .doc(medicamentoId);

          final medicamentoSnapshot = await medicamentoDoc.get();

          if (medicamentoSnapshot.exists) {
            final medicamentoData = medicamentoSnapshot.data();
            if (medicamentoData is! Map<String, dynamic>) {
              return;
            }

            int estoqueAtual =
                int.tryParse(medicamentoData['quantidadeEstoque']) ?? 0;

            if (estoqueAtual >= quantidade) {
              await medicamentoDoc.update({
                'quantidadeEstoque': (estoqueAtual - quantidade).toString(),
              });
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Horário $horario marcado como tomado!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: [
          TextButton(onPressed: () {
            Navigator.pushNamed(context, '/editar-tratamento',
                                arguments: widget.tratamentoId);
          }, child: const Text('Editar')),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir Tratamento'),
                  content: const Text(
                      'Tem certeza de que deseja excluir este tratamento?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );

              if (confirm) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('tratamentos')
                    .doc(widget.tratamentoId)
                    .delete();
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Medicamento excluído com sucesso!')),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tratamentos')
            .doc(widget.tratamentoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Tratamento não encontrado.'));
          }

          final tratamentoData = snapshot.data!.data();
          if (tratamentoData is! Map<String, dynamic>) {
            return const Center(
                child: Text('Erro ao carregar os dados do tratamento.'));
          }


          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('tratamentos')
                .doc(widget.tratamentoId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Tratamento não encontrado.'));
              }

              final tratamentoData = snapshot.data!.data();
              if (tratamentoData is! Map<String, dynamic>) {
                return const Center(
                    child: Text('Erro ao carregar os dados do tratamento.'));
              }

              final String medicamentoId =
                  tratamentoData['medicamentoId'] ?? '';
              final List<dynamic> lembretes = tratamentoData['lembretes'] ?? [];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('medicamentos')
                    .doc(medicamentoId)
                    .snapshots(),
                builder: (context, medicamentoSnapshot) {
                  if (medicamentoSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!medicamentoSnapshot.hasData ||
                      !medicamentoSnapshot.data!.exists) {
                    return const Center(
                        child: Text('Medicamento não encontrado.'));
                  }

                  final medicamentoData =
                      medicamentoSnapshot.data!.data() as Map<String, dynamic>?;

                  if (medicamentoData is! Map<String, dynamic>) {
                    return const Center(
                        child:
                            Text('Erro ao carregar os dados do medicamento.'));
                  }

                  final String medicamentoNome =
                      medicamentoData['nome'] ?? 'Nome não disponível';
                  final String quantidadeEstoque =
                      medicamentoData['quantidadeEstoque'] ?? '0';
                  final String dosagem =
                      medicamentoData['dosagem'] ?? 'Dosagem não especificada';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicamentoNome,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dosagem: $dosagem mg',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Quantidade de doses: ${lembretes.length}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: Text(
                                  '$quantidadeEstoque restantes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Lembretes:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: lembretes.length,
                            itemBuilder: (context, index) {
                              final lembreteData = lembretes[index];
                              final Timestamp dataTimestamp =
                                  lembreteData['data'] as Timestamp;
                              final String dataHoraFormatada = _formatDataHora(
                                  dataTimestamp); 
                              final int comprimidos =
                                  lembreteData['quantidade'] ?? 0;
                              final bool tomado =
                                  lembreteData['tomado'] ?? false;

                              return ListTile(
                                title: Row(
                                  children: [
                                    Checkbox(
                                      value: tomado,
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          lembretes[index]['tomado'] =
                                              value ?? false;
                                        });

                                        _marcarComoTomado(
                                          value ?? false,
                                          dataHoraFormatada,
                                          comprimidos,
                                          medicamentoId,
                                          dataTimestamp.toDate(),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          color: tomado
                                              ? Colors.grey
                                              : Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                          border: Border.all(
                                            color: tomado
                                                ? Colors.grey.shade600
                                                : Theme.of(context)
                                                    .primaryColor,
                                          ),
                                        ),
                                        child: Text(
                                          '$dataHoraFormatada - $comprimidos cp',
                                          style: TextStyle(
                                            color: tomado
                                                ? Colors.grey[600]
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration: tomado
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDataHora(Timestamp timestamp) {
    final DateTime dataHora = timestamp.toDate();

    final int dia = dataHora.day;
    final int mes = dataHora.month;
    final int ano = dataHora.year;
    final int hora = dataHora.hour;
    final int minuto = dataHora.minute;

    final String dataHoraFormatada =
        "$dia/${mes.toString().padLeft(2, '0')}/$ano às ${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}";

    return dataHoraFormatada;
  }
}
