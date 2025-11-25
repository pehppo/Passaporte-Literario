import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/cloudinary_service.dart';

import 'home_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ImagePicker picker = ImagePicker();

  final TextEditingController _addTitleController = TextEditingController();
  final TextEditingController _addAuthorController = TextEditingController();
  final TextEditingController _addGenreController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();
  String _addPriority = 'Média';

  @override
  void dispose() {
    _addTitleController.dispose();
    _addAuthorController.dispose();
    _addGenreController.dispose();
    _addPriceController.dispose();
    super.dispose();
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
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF232533)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF232533)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  double _totalEstimated(List<Map<String, dynamic>> wishlist) {
    double total = 0;
    for (var item in wishlist) {
      final pv = item['price'];
      if (pv == null) continue;
      try {
        final raw = pv is String ? pv : pv.toString();
        final normalized = raw.toString().replaceAll(',', '.');
        final d = pv is num ? pv.toDouble() : double.parse(normalized);
        total += d;
      } catch (_) {}
    }
    return total;
  }

  String _formatCurrencyDouble(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _pickImage(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salvando imagem...', style: GoogleFonts.poppins()),
          duration: const Duration(minutes: 1),
        ),
      );

      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        try {
          final url = await CloudinaryService.uploadImage(file);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('wishlist')
              .doc(docId)
              .update({'image': url});
        } catch (e) {
          debugPrint('Cloudinary upload failed for wishlist item: $e');
          rethrow;
        }
      }
    } catch (e, s) {
      debugPrint('Erro ao salvar imagem da wishlist: $e');
      debugPrint('$s');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar imagem: ${e.toString()}', style: GoogleFonts.poppins()),
        ),
      );
    } finally {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  Future<void> _addOrEditItem({
    Map<String, dynamic>? item,
    String? docId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final titleController = TextEditingController(text: item?['title'] ?? '');
    final authorController = TextEditingController(text: item?['author'] ?? '');
    final genreController = TextEditingController(text: item?['genre'] ?? '');
    final priceController = TextEditingController(
      text: item?['price']?.toString() ?? '',
    );
    String priority = item?['priority'] ?? 'Média';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Editar item',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authorController,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Autor',
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: genreController,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Gênero',
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))
                ],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Preço estimado',
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: priority,
                dropdownColor: const Color(0xFF27273A),
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                items: ['Alta', 'Média', 'Baixa']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => priority = v ?? 'Média',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newItem = {
                'title': titleController.text.trim(),
                'author': authorController.text.trim(),
                'genre': genreController.text.trim(),
                'price': (() {
                  final raw = priceController.text.trim();
                  if (raw.isEmpty) return null;
                  final normalized = raw.replaceAll(',', '.');
                  return double.tryParse(normalized);
                })(),
                'priority': priority,
                'image': item?['image'],
                'note': item?['note'] ?? '',
              };

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('wishlist')
                    .doc(docId)
                    .update(newItem);
              } catch (e) {
                debugPrint('Erro ao salvar item da wishlist: $e');
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Salvar',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Confirmar exclusão',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Deseja realmente excluir este item da lista de desejos?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Excluir',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(docId)
            .delete();
      } catch (e) {
        debugPrint('Erro ao excluir item da wishlist: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF141425),
        appBar: const CustomTopBar(
          title: 'Lista de Desejos',
          showBackButton: true,
        ),
        body: Center(
          child: Text(
            'Faça login para ver sua lista de desejos.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    final wishlistStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(
        title: 'Lista de Desejos',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<QuerySnapshot>(
            stream: wishlistStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: screenHeight * 0.6,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final List<Map<String, dynamic>> wishlist = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  ...data,
                };
              }).toList();

              final totalEst = _totalEstimated(wishlist);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27273A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Adicionar à Lista de Desejos',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _buildTextField(
                          'Nome do Livro',
                          Icons.book,
                          _addTitleController,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          'Nome do Autor',
                          Icons.person,
                          _addAuthorController,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _addGenreController.text.isNotEmpty
                              ? _addGenreController.text
                              : null,
                          dropdownColor: const Color(0xFF141425),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.category,
                              color: Colors.white,
                            ),
                            labelText: 'Gênero',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF232533)),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF232533)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          style: GoogleFonts.poppins(color: Colors.white),
                          items: <String>[
                            'Ação',
                            'Autoajuda',
                            'Aventura',
                            'Biografia',
                            'Ciência',
                            'Clássico',
                            'Comédia',
                            'Drama',
                            'Fantasia',
                            'Ficção Científica',
                            'História',
                            'Infantil',
                            'Mistério',
                            'Policial',
                            'Religião',
                            'Romance',
                            'Terror',
                            'Outro'
                          ]
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(
                                    g,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _addGenreController.text = val ?? ''),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _addPriceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]'),
                            )
                          ],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                            ),
                            labelText: 'Preço Estimado',
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DropdownButtonFormField<String>(
                            initialValue: _addPriority,
                            dropdownColor: const Color(0xFF141425),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.priority_high,
                                color: Colors.white,
                              ),
                              labelText: 'Prioridade',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              border: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFF232533)),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFF232533)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: Colors.white),
                            items: ['Alta', 'Média', 'Baixa']
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _addPriority = v ?? 'Média'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title =
                                  _addTitleController.text.trim();
                              if (title.isEmpty) return;

                              final newItem = {
                                'title': title,
                                'author':
                                    _addAuthorController.text.trim(),
                                'genre':
                                    _addGenreController.text.trim(),
                                'price': (() {
                                  final raw =
                                      _addPriceController.text.trim();
                                  if (raw.isEmpty) return null;
                                  final normalized =
                                      raw.replaceAll(',', '.');
                                  return double.tryParse(normalized);
                                })(),
                                'priority': _addPriority,
                                'image': null,
                                'note': '',
                                'createdAt': FieldValue.serverTimestamp(),
                              };

                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('wishlist')
                                    .add(newItem);
                              } catch (e) {
                                debugPrint(
                                    'Erro ao adicionar item na wishlist: $e');
                              }

                              _addTitleController.clear();
                              _addAuthorController.clear();
                              _addGenreController.clear();
                              _addPriceController.clear();
                              setState(() => _addPriority = 'Média');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Adicionar à Lista',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF141425),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27273A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total estimado',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'R\$ ${_formatCurrencyDouble(totalEst)}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4CB050),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  wishlist.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Center(
                            child: Text(
                              'Nenhum item na lista de desejos',
                              style:
                                  GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wishlist.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 15),
                          itemBuilder: (context, index) {
                            final w = wishlist[index];
                            final docId = w['id'] as String;

                            return Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27273A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(docId),
                                    child: Container(
                                      width: 64,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        color: Colors.grey[800],
                                        image: w['image'] != null
                                            ? DecorationImage(
                                                image: (w['image'] is String && (w['image'] as String).startsWith('http'))
                                                    ? NetworkImage(w['image']) as ImageProvider
                                                    : FileImage(File(w['image'])),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: w['image'] == null
                                          ? const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w['title'] ?? '',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          w['author'] ?? '',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${w['genre'] ?? '-'} • Prioridade: ${w['priority'] ?? '-'}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Preço: R\$' +
                                              (() {
                                                final pv = w['price'];
                                                if (pv == null) return '-';
                                                try {
                                                  final raw = pv is String
                                                      ? pv
                                                      : pv.toString();
                                                  final normalized = raw
                                                      .replaceAll(',', '.');
                                                  final d = pv is num
                                                      ? pv.toDouble()
                                                      : double.parse(
                                                          normalized);
                                                  return _formatCurrencyDouble(
                                                      d);
                                                } catch (e) {
                                                  final s = pv.toString();
                                                  return s.isEmpty ? '-' : s;
                                                }
                                              })(),
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF4CB050),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        iconSize: 20,
                                        onPressed: () => _addOrEditItem(
                                          item: w,
                                          docId: docId,
                                        ),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFF12B7FF),
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 20,
                                        onPressed: () => _deleteItem(docId),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
