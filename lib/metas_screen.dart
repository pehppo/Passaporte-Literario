import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  final TextEditingController bookController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController pagesController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> metas = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMetas();
  }

  @override
  void dispose() {
    bookController.dispose();
    authorController.dispose();
    pagesController.dispose();
    daysController.dispose();
    super.dispose();
  }

  Future<void> loadMetas() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        metas = [];
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'author': data['author'] ?? '',
          'totalPages': data['totalPages'] ?? 0,
          'daysToRead': data['daysToRead'] ?? 1,
          'pagesRead': data['pagesRead'] ?? 0,
          'coverImagePath': data['coverImageUrl'] ?? null,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        metas = loaded;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar metas: $e');
      if (!mounted) return;
      setState(() {
        metas = [];
        isLoading = false;
      });
    }
  }

  Future<void> createMeta() async {
    final title = bookController.text.trim();
    final author = authorController.text.trim();
    final totalPages = int.tryParse(pagesController.text.trim()) ?? 0;
    final daysToRead = int.tryParse(daysController.text.trim()) ?? 1;

    if (title.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuário não autenticado. Faça login novamente.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final data = {
        'title': title,
        'author': author,
        'totalPages': totalPages,
        'daysToRead': daysToRead <= 0 ? 1 : daysToRead,
        'pagesRead': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add(data);

      if (!mounted) return;

      setState(() {
        metas.insert(0, {
          'id': docRef.id,
          'title': title,
          'author': author,
          'totalPages': totalPages,
          'daysToRead': daysToRead <= 0 ? 1 : daysToRead,
          'pagesRead': 0,
          'coverImagePath': null,
        });

        bookController.clear();
        authorController.clear();
        pagesController.clear();
        daysController.clear();
      });
    } catch (e) {
      debugPrint('Erro ao criar meta: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao criar meta. Tente novamente.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updatePagesRead(int index, int newPagesRead) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final meta = metas[index];
    final docId = meta['id'] as String?;

    if (docId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(docId)
          .update({'pagesRead': newPagesRead});
    } catch (e) {
      debugPrint('Erro ao atualizar pagesRead: $e');
    }
  }

  Future<void> deleteMeta(int index) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final meta = metas[index];
    final docId = meta['id'] as String?;

    if (docId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Remover meta',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Deseja realmente remover esta meta?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remover',
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(docId)
          .delete();

      if (!mounted) return;
      setState(() {
        metas.removeAt(index);
      });
    } catch (e) {
      debugPrint('Erro ao remover meta: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao remover meta.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Metas de Leitura'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27273A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar Nova Meta',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'Nome do Livro',
                        Icons.book,
                        bookController,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        'Autor do Livro',
                        Icons.person,
                        authorController,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Total de Páginas',
                              Icons.menu_book,
                              pagesController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              'Dias para Ler',
                              Icons.calendar_today,
                              daysController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: createMeta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Criar Meta',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF141425),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...metas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meta = entry.value;

                  final totalPages = (meta['totalPages'] as int?) ?? 0;
                  final pagesRead = (meta['pagesRead'] as int?) ?? 0;
                  final daysToRead = (meta['daysToRead'] as int?) ?? 1;

                  final progress = totalPages == 0
                      ? 0.0
                      : pagesRead / totalPages.clamp(1, 999999);

                  final dailyPages = totalPages == 0
                      ? 0
                      : (totalPages / (daysToRead == 0 ? 1 : daysToRead)).ceil();

                  final coverPath = meta['coverImagePath'] as String?;

                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27273A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final user = _auth.currentUser;
                                  if (user == null) return;
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Selecionando imagem...', style: GoogleFonts.poppins()),
                                      duration: const Duration(minutes: 1),
                                    ),
                                  );

                                  final XFile? picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (picked != null) {
                                    final file = File(picked.path);

                                    final url = await CloudinaryService.uploadImage(file);
                                    final docId = meta['id'] as String?;
                                    if (docId != null) {
                                      await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('goals')
                                          .doc(docId)
                                          .update({'coverImageUrl': url});
                                    }
                                    if (!mounted) return;
                                    setState(() {
                                      metas[index]['coverImagePath'] = url;
                                    });
                                  }
                                } catch (e, s) {
                                  debugPrint('Erro ao selecionar imagem na Metas: $e');
                                  debugPrint('$s');
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao selecionar imagem: ${e.toString()}', style: GoogleFonts.poppins()),
                                    ),
                                  );
                                } finally {
                                  if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                }
                              },
                              child: Container(
                                width: 72,
                                height: 97,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[800],
                                  image: coverPath != null
                                      ? DecorationImage(
                                          image: (coverPath.startsWith('http'))
                                              ? NetworkImage(coverPath) as ImageProvider
                                              : FileImage(File(coverPath)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: coverPath == null
                                    ? const Icon(Icons.add, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta['title'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'por ${meta['author'] ?? ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.menu_book,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$dailyPages páginas/dia',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$daysToRead dias para ler',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          color: const Color(0xFF4CAF50),
                          minHeight: 12,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$pagesRead de $totalPages páginas (${(progress * 100).toInt()}%)',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final newPages =
                                        pagesRead + dailyPages > totalPages
                                            ? totalPages
                                            : pagesRead + dailyPages;
                                    setState(() {
                                      metas[index]['pagesRead'] = newPages;
                                    });
                                    await updatePagesRead(index, newPages);
                                  },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => deleteMeta(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
      ),
    );
  }
}
