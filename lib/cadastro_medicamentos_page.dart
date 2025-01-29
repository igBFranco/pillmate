import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CadastroMedicamentoPage extends StatefulWidget {
  final String? medicamentoId;

  const CadastroMedicamentoPage({super.key, this.medicamentoId});

  @override
  _CadastroMedicamentoPageState createState() =>
      _CadastroMedicamentoPageState();
}

class _CadastroMedicamentoPageState extends State<CadastroMedicamentoPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController dosagemController = TextEditingController();
  final TextEditingController quantidadeEstoqueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.medicamentoId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('medicamentos')
          .doc(widget.medicamentoId)
          .get()
          .then((doc) {
        var data = doc.data()!;
        nomeController.text = data['nome'];
        dosagemController.text = data['dosagem'];
        quantidadeEstoqueController.text = data['quantidadeEstoque'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Medicamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Medicamento'),
            ),
            TextField(
              controller: dosagemController,
              decoration: const InputDecoration(labelText: 'Dosagem'),
            ),
            TextField(
              controller: quantidadeEstoqueController,
              decoration: const InputDecoration(labelText: 'Quantidade em Estoque'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                var medicamento = {
                  'nome': nomeController.text,
                  'dosagem': dosagemController.text,
                  'quantidadeEstoque': quantidadeEstoqueController.text,
                };
                if (widget.medicamentoId == null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('medicamentos')
                      .add(medicamento);
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth
                          .instance.currentUser!.uid) 
                      .collection('medicamentos')
                      .doc(widget.medicamentoId)
                      .update(medicamento);
                }
                Navigator.pop(context);
              },
              child: Text(widget.medicamentoId == null
                  ? 'Cadastrar Medicamento'
                  : 'Atualizar Medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
