import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditarTratamentoPage extends StatefulWidget {
  final String tratamentoId;

  const EditarTratamentoPage({super.key, required this.tratamentoId});

  @override
  State<EditarTratamentoPage> createState() => _EditarTratamentoPageState();
}

class _EditarTratamentoPageState extends State<EditarTratamentoPage> {
  final TextEditingController _duracaoController = TextEditingController();
  final List<Map<String, dynamic>> _horarios = [];
  String? _selectedMedicamentoId;
  String? _selectedMedicamentoNome;
  List<Map<String, dynamic>> _medicamentos = [];
  int _quantidadeLembretes = 1;
  DateTime? _dataInicial;

  @override
  void initState() {
    super.initState();
    _fetchMedicamentos();
    _carregarDadosTratamento();
  }

  Future<void> _fetchMedicamentos() async {
    final medicamentos = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('medicamentos')
        .get();

    setState(() {
      _medicamentos = medicamentos.docs.map((doc) {
        return {
          'id': doc.id,
          'nome': doc['nome'],
        };
      }).toList();
    });
  }

  Future<void> _carregarDadosTratamento() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final tratamentoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tratamentos')
        .doc(widget.tratamentoId)
        .get();

    if (tratamentoDoc.exists) {
      final tratamentoData = tratamentoDoc.data();
      if (tratamentoData != null) {
        setState(() {
          _selectedMedicamentoId = tratamentoData['medicamentoId'];
          _selectedMedicamentoNome = tratamentoData['medicamentoNome'];
          _duracaoController.text = tratamentoData['duracaoDias'].toString();
          _dataInicial = (tratamentoData['dataInicial'] as Timestamp).toDate();
          _quantidadeLembretes = tratamentoData['quantidadeLembretes'];
          _horarios.addAll((tratamentoData['lembretes'] as List<dynamic>).map(
            (lembrete) {
              final DateTime horario = (lembrete['data'] as Timestamp).toDate();
              return {
                'horario': horario,
                'quantidade': lembrete['quantidade'],
              };
            },
          ));
        });
      }
    }
  }

  Future<void> _editarTratamento() async {
    if (_selectedMedicamentoId == null || _dataInicial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final duracaoDias = int.tryParse(_duracaoController.text);
    if (duracaoDias == null || duracaoDias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira uma duração válida')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final tratamentoRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tratamentos')
        .doc(widget.tratamentoId);

    // Atualizar a lista de lembretes
    final lembretes = <Map<String, dynamic>>[];
    for (int dia = 0; dia < duracaoDias; dia++) {
      final dataDoDia = _dataInicial!.add(Duration(days: dia));
      for (var horario in _horarios) {
        final hora = horario['horario'];
        lembretes.add({
          'data': DateTime(
            dataDoDia.year,
            dataDoDia.month,
            dataDoDia.day,
            hora.hour,
            hora.minute,
          ),
          'quantidade': horario['quantidade'],
          'tomado': false,
        });
      }
    }

    await tratamentoRef.update({
      'medicamentoId': _selectedMedicamentoId,
      'medicamentoNome': _selectedMedicamentoNome,
      'duracaoDias': duracaoDias,
      'quantidadeLembretes': _quantidadeLembretes,
      'dataInicial': _dataInicial,
      'lembretes': lembretes,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tratamento editado com sucesso!')),
    );
    Navigator.pop(context);
  }

  Future<void> _selecionarDataInicial() async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataInicial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dataSelecionada != null) {
      setState(() {
        _dataInicial = dataSelecionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Tratamento')),
      body: _horarios.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o Medicamento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedMedicamentoId,
                      hint: const Text('Selecione um Medicamento'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMedicamentoId = newValue;
                          _selectedMedicamentoNome = _medicamentos.firstWhere(
                              (med) => med['id'] == newValue)['nome'];
                        });
                      },
                      items: _medicamentos
                          .map<DropdownMenuItem<String>>((medicamento) {
                        return DropdownMenuItem<String>(
                          value: medicamento['id'],
                          child: Text(medicamento['nome']),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Duração do Tratamento (dias)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _duracaoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Ex: 7 dias'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Data Inicial do Tratamento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _selecionarDataInicial,
                      child: Text(_dataInicial == null
                          ? 'Selecione a Data Inicial'
                          : '${_dataInicial!.day}/${_dataInicial!.month}/${_dataInicial!.year}'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quantidade de Lembretes por Dia',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _quantidadeLembretes,
                      onChanged: (int? newValue) {
                        setState(() {
                          _quantidadeLembretes = newValue!;
                          _horarios.clear();
                          for (int i = 0; i < _quantidadeLembretes; i++) {
                            _horarios.add({
                              'horario': DateTime.now(),
                              'quantidade': 1,
                            });
                          }
                        });
                      },
                      items: List.generate(10, (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1} Lembretes'),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(_quantidadeLembretes, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Horário ${index + 1}'),
                                ElevatedButton(
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _horarios[index]['horario'] = DateTime(
                                          2025,
                                          1,
                                          1,
                                          time.hour,
                                          time.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: Text(
                                    '${_horarios[index]['horario'].hour}:${_horarios[index]['horario'].minute}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade de Comprimidos',
                              ),
                              controller: TextEditingController(
                                text: _horarios[index]['quantidade'].toString(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    _horarios[index]['quantidade'] =
                                        int.parse(value);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _editarTratamento,
                        child: const Text('Editar Tratamento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
