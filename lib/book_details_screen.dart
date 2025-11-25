import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isSaving = false;

  final List<String> _validGenres = [
    'Ação', 'Autoajuda', 'Aventura', 'Biografia', 'Ciência', 'Clássico',
    'Comédia', 'Drama', 'Fantasia', 'Ficção Científica', 'História',
    'Infantil', 'Mistério', 'Policial', 'Religião', 'Romance', 'Terror', 'Outro'
  ];

  String formatDate(String dateString) {
    try {
      DateTime date;
      if (dateString.length == 4) {
        date = DateTime(int.parse(dateString), 1, 1);
      } else if (dateString.length == 7) {
        final parts = dateString.split('-');
        date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      } else {
        date = DateTime.parse(dateString);
      }
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<String?> _downloadCoverImage(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('Erro ao baixar capa: $e');
    }
    return null;
  }

  Future<void> _addToWishlist() async {
    setState(() => _isSaving = true);

     final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');

    final existing = await wishlistRef
        .where('title', isEqualTo: widget.book.title)
        .where('author', isEqualTo: widget.book.authors.join(', '))
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este livro já está na sua lista de desejos!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? localImagePath;
    if (widget.book.thumbnail.isNotEmpty) {
      localImagePath = await _downloadCoverImage(widget.book.thumbnail);
    }

    String apiCategory = widget.book.categories.isNotEmpty ? widget.book.categories[0] : 'Outro';
    String finalGenre = 'Outro';

    for (var g in _validGenres) {
      if (g.toLowerCase() == apiCategory.toLowerCase()) {
        finalGenre = g;
        break;
      }
    }

    if (finalGenre == 'Outro') {
      final catLower = apiCategory.toLowerCase();
      if (catLower.contains('fiction') && !catLower.contains('non')) finalGenre = 'Ficção Científica';
      if (catLower.contains('history')) finalGenre = 'História';
      if (catLower.contains('biography')) finalGenre = 'Biografia';
      if (catLower.contains('romance')) finalGenre = 'Romance';
      if (catLower.contains('thriller') || catLower.contains('mystery')) finalGenre = 'Mistério';
      if (catLower.contains('fantasy')) finalGenre = 'Fantasia';
      if (catLower.contains('horror')) finalGenre = 'Terror';
      if (catLower.contains('religion')) finalGenre = 'Religião';
    }

    final newItem = {
      'title': widget.book.title,
      'author': widget.book.authors.join(', '),
      'genre': finalGenre,
      'price': null,
      'priority': 'Média',
      'image': localImagePath,
      'note': widget.book.description.length > 100
          ? '${widget.book.description.substring(0, 100)}...'
          : widget.book.description,
      'createdAt': Timestamp.now(),
    };

    await wishlistRef.add(newItem);

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Livro adicionado à Lista de Desejos!', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4CB050),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final topBarHeight = screenHeight * 0.13;
    final iconSize = screenWidth * 0.06;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(topBarHeight),
        child: Container(
          height: topBarHeight,
          color: const Color(0xFF27273A),
          child: Stack(
            children: [
              Positioned(
                top: topBarHeight * 0.55,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Detalhes do Livro',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topBarHeight * 0.55,
                left: horizontalPadding * 0.76,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: screenHeight * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: widget.book.thumbnail.isNotEmpty
                            ? Image.network(
                                widget.book.thumbnail,
                                width: screenWidth * 0.5,
                                height: screenHeight * 0.35,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: screenWidth * 0.5,
                                  height: screenHeight * 0.35,
                                  color: Colors.grey,
                                  child: const Icon(Icons.book, color: Colors.white, size: 60),
                                ),
                              )
                            : Container(
                                width: screenWidth * 0.5,
                                height: screenHeight * 0.35,
                                color: Colors.grey,
                                child: const Icon(Icons.book, color: Colors.white, size: 60),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(widget.book.title,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center),
                    SizedBox(height: screenHeight * 0.015),
                    _buildInfoRow('Autor:', widget.book.authors.join(', '), screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    _buildInfoRow('Gênero:', widget.book.categories.join(', '), screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    _buildInfoRow('Ano:', formatDate(widget.book.publishedDate), screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    _buildInfoRow('Páginas:', widget.book.pageCount.toString(), screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    Text('Resumo:',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    SizedBox(height: screenHeight * 0.01),
                    Text(widget.book.description,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white70,
                          height: 1.5,
                        )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _addToWishlist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Color(0xFF141425), strokeWidth: 2),
                        )
                      : Text(
                          'Adicionar à Lista de Desejos',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF141425),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.038,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.038,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
