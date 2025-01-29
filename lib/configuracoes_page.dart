import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pillmate/login_page.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _nomeController = TextEditingController();
  final _senhaController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _nomeController.text = userData['nome'] ?? user.displayName ?? '';
        if (user.photoURL != null) {
          _imageFile = null;
        }
      });
    }
  }

  Future<void> _updateUserData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        String? imageUrl;

        await user.updateDisplayName(_nomeController.text);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'nome': _nomeController.text});

        if (_senhaController.text.isNotEmpty) {
          await user.updatePassword(_senhaController.text);
        }
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${user.uid}.jpg');

          final uploadTask = storageRef.putFile(_imageFile!);
          final snapshot = await uploadTask;

          imageUrl = await snapshot.ref.getDownloadURL();
          await user.updatePhotoURL(imageUrl);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoURL': imageUrl});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar dados: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      if (fileSize > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione uma imagem menor que 5 MB.')),
      );
      return;
    }
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    // Exibe o modal de confirmação
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza de que deseja sair da sua conta?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); 
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, 
              ),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); 
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor, 
              ),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    // Se o usuário confirmar (pressionar "Sim"), realizar o logout
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  },
),

        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _selectImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (FirebaseAuth.instance.currentUser?.photoURL !=
                                    null
                                ? NetworkImage(FirebaseAuth
                                    .instance.currentUser!.photoURL!)
                                : const AssetImage(
                                    'assets/images/logo.png')) as ImageProvider,
                        child: const Icon(Icons.camera_alt,
                            size: 32, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _senhaController,
                    decoration: InputDecoration(
                      labelText: 'Nova Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateUserData,
                      child: Text('Salvar Alterações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
