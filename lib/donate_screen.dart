// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _editDonationNotes(
    String docId,
    Map<String, dynamic> currentData,
  ) async {
    final currentNotes = currentData['notes'] ?? '';
    final controller = TextEditingController(text: currentNotes.toString());

    String selected = (currentData['condition'] ?? '').toString();
    if (selected.isEmpty) selected = 'Novo';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Editar Estado do Livro',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado do livro',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            StatefulBuilder(
              builder: (context, setStateSB) {
                return DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF27273A),
                  initialValue: selected,
                  items: ['Novo', 'Bom', 'Ruim']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      selected = v;
                      setStateSB(() {});
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    filled: true,
                    fillColor: const Color(0xFF1E1F2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Observações (opcional)',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
                filled: true,
                fillColor: const Color(0xFF1E1F2B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('donations')
                    .doc(docId)
                    .delete();
              }
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: Text(
              'Excluir',
              style: GoogleFonts.poppins(
                color: const Color(0xFFF64136),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('donations')
                    .doc(docId)
                    .update({
                  'condition': selected,
                  'notes': controller.text.trim(),
                });
              }
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: Text(
              'Salvar',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4CB050),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Doações', showBackButton: true),
      body: SafeArea(
        child: user == null
            ? Center(
                child: Text(
                  'Faça login para ver suas doações.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('donations')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar doações.',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum livro na lista de doações.',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final docId = doc.id;

                      final imagePath =
                          (data['image'] ?? '').toString().trim();
                      final title = (data['title'] ?? '').toString();
                      final author = (data['author'] ?? '').toString();
                      final genreRaw =
                          (data['genre'] ?? data['genero'] ?? '').toString();
                      final condition =
                          (data['condition'] ?? '').toString();
                      final notes =
                          (data['notes'] ?? '').toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF27273A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 92,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade800,
                                image: imagePath.isNotEmpty
                                    ? DecorationImage(
                                        image: (imagePath.startsWith('http')
                                            ? NetworkImage(imagePath)
                                            : FileImage(File(imagePath))) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imagePath.isEmpty
                                  ? const Icon(
                                      Icons.book,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    author.isNotEmpty
                                        ? 'por $author'
                                        : 'Autor desconhecido',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    genreRaw.isNotEmpty
                                        ? genreRaw
                                        : 'Sem gênero',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF12B7FF),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estado: ${condition.isNotEmpty ? condition : 'Não informado'}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Obs:',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notes.isNotEmpty
                                        ? notes
                                        : 'Sem observações',
                                    style: notes.isNotEmpty
                                        ? GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          )
                                        : GoogleFonts.poppins(
                                            color: Colors.white38,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _editDonationNotes(docId, data),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF12B7FF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF27273A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          title: Text(
                                            'Confirmar exclusão',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                          content: Text(
                                            'Deseja realmente remover esta doação?',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, false),
                                              child: Text(
                                                'Cancelar',
                                                style:
                                                    GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, true),
                                              child: Text(
                                                'Remover',
                                                style:
                                                    GoogleFonts.poppins(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final user = _auth.currentUser;
                                        if (user != null) {
                                          await _firestore
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('donations')
                                              .doc(docId)
                                              .delete();
                                        }
                                      }
                                    },
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}