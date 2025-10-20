import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; // Para o modelo Book

class BookDetailsScreen extends StatelessWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  // Função para formatar a data
  String formatDate(String dateString) {
    try {
      DateTime date;
      if (dateString.length == 4) {
        // Apenas ano
        date = DateTime(int.parse(dateString), 1, 1);
      } else if (dateString.length == 7) {
        // Ano-mês
        final parts = dateString.split('-');
        date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      } else {
        // Ano-mês-dia
        date = DateTime.parse(dateString);
      }
      return '${date.day.toString().padLeft(2, '0')}-'
             '${date.month.toString().padLeft(2, '0')}-'
             '${date.year}';
    } catch (e) {
      return dateString; // retorna como está se der erro
    }
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: screenHeight * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capa centralizada e maior
              Center(
                child: book.thumbnail.isNotEmpty
                    ? Image.network(
                        book.thumbnail,
                        width: screenWidth * 0.6,
                        height: screenHeight * 0.4,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: screenWidth * 0.6,
                        height: screenHeight * 0.4,
                        color: Colors.grey,
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Título
              Text(
                book.title,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              // Autor
              Text(
                'Autor: ${book.authors.join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // Gênero
              Text(
                'Gênero: ${book.categories.join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // Ano no formato dd-MM-yyyy
              Text(
                'Ano: ${formatDate(book.publishedDate)}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // Páginas
              Text(
                'Páginas: ${book.pageCount}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Resumo
              Text(
                'Resumo:',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                book.description,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
