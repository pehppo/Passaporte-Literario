import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_book_screen.dart';
import 'home_screen.dart'; // Para CustomTopBar
import 'donate_screen.dart';

class DiarioScreen extends StatefulWidget {
  final List<Map<String, dynamic>> books;
  const DiarioScreen({super.key, required this.books});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  late List<Map<String, dynamic>> books = [];
  String searchQuery = '';
  Set<int> expandedBooks = {}; // controlando livros expandidos

  @override
  void initState() {
    super.initState();
    books = widget.books;
  }

  @override
  void didUpdateWidget(covariant DiarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.books != oldWidget.books) {
      setState(() {
        books = widget.books;
      });
    }
  }

  /// Salva os livros atuais no SharedPreferences
  Future<void> saveBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('books', jsonEncode(books));
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (searchQuery.isEmpty) return books;
    return books
        .where(
          (book) => (book['title'] ?? '').toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  double getTotalSpent() {
    double total = 0;
    for (var book in books) {
      if (book['value'] != null && book['value'].toString().isNotEmpty) {
        total +=
            double.tryParse(book['value'].toString().replaceAll(',', '.')) ?? 0;
      }
    }
    return total;
  }

  double getAveragePagesPerDay(Map<String, dynamic> book) {
    if (book['pages'] == null ||
        book['startDate'] == null ||
        book['endDate'] == null ||
        book['pages'].toString().isEmpty ||
        book['startDate'].toString().isEmpty ||
        book['endDate'].toString().isEmpty)
      return 0;

    int pages = int.tryParse(book['pages'].toString()) ?? 0;

    List<String> startSplit = book['startDate'].toString().split('/');
    List<String> endSplit = book['endDate'].toString().split('/');

    if (startSplit.length != 3 || endSplit.length != 3) return 0;

    DateTime startDate = DateTime(
      int.parse(startSplit[2]),
      int.parse(startSplit[1]),
      int.parse(startSplit[0]),
    );

    DateTime endDate = DateTime(
      int.parse(endSplit[2]),
      int.parse(endSplit[1]),
      int.parse(endSplit[0]),
    );

    int days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) return 0;

    return pages / days;
  }

  double getAveragePagesPerDayAllBooks() {
    if (books.isEmpty) return 0;

    double totalPagesPerDay = 0;
    int countedBooks = 0;

    for (var book in books) {
      double avg = getAveragePagesPerDay(book);
      if (avg > 0) {
        totalPagesPerDay += avg;
        countedBooks++;
      }
    }

    if (countedBooks == 0) return 0;

    return totalPagesPerDay / countedBooks;
  }

  void deleteBook(int index) async {
    bool? confirm = await showDialog(
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
          'Deseja realmente excluir este livro do diário?',
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
      setState(() {
        books.removeAt(index);
      });
      await saveBooks();
    }
  }

  void openEditScreen(Map<String, dynamic> book, int index) async {
    final updatedBook = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookScreen(
          book: book,
          onSaveBook: (data) => Navigator.pop(context, data),
        ),
      ),
    );

    if (updatedBook != null) {
      setState(() {
        books[index] = updatedBook;
      });
      await saveBooks();
    }
  }

  void addBook(Map<String, dynamic> newBook) async {
    setState(() {
      books.add(newBook);
    });
    await saveBooks();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Meu Diário'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatBox(
                    icon: Icons.attach_money,
                    value: 'R\$ ${getTotalSpent().toStringAsFixed(2)}',
                    label: 'Total Gasto',
                    mainColor: const Color(0xFF4CB050),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SizedBox(width: screenWidth * 0.07),
                  _buildStatBox(
                    icon: Icons.show_chart,
                    value: getAveragePagesPerDayAllBooks().toStringAsFixed(0),
                    label: 'Média Páginas/Dia',
                    mainColor: const Color(0xFFEA9E24),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  hintText: 'Pesquisar livros',
                  hintStyle: GoogleFonts.poppins(
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
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 20),
              filteredBooks.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum livro encontrado.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        final realIndex = books.indexOf(book);

                        bool isExpanded = expandedBooks.contains(realIndex);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF27273A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          (book['image'] != null &&
                                              book['image']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? Image.file(
                                              File(book['image']),
                                              width: 72,
                                              height: 97,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 72,
                                              height: 97,
                                              color: Colors.grey.shade800,
                                              child: const Icon(
                                                Icons.book,
                                                color: Colors.white70,
                                                size: 28,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book['title'] ??
                                                'Título não disponível',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'por ${book['author'] ?? 'Autor não disponível'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            book['genre'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                              color: const Color(0xFF12B7FF),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                i < (book['rating'] ?? 0)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 18,
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => openEditScreen(
                                                  book,
                                                  realIndex,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              GestureDetector(
                                                onTap: () async {
                                                  final bool?
                                                  confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF27273A,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                      ),
                                                      title: Text(
                                                        'Adicionar à Doação',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      content: Text(
                                                        'Deseja adicionar este livro à lista de doação?',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: Text(
                                                            'Cancelar',
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child: Text(
                                                            'Adicionar',
                                                            style: GoogleFonts.poppins(
                                                              color:
                                                                  const Color(
                                                                    0xFF9E26B3,
                                                                  ),
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    // Save the book into SharedPreferences 'donations' immediately
                                                    try {
                                                      final prefs =
                                                          await SharedPreferences.getInstance();
                                                      final donationsStr = prefs
                                                          .getString(
                                                            'donations',
                                                          );
                                                      List<Map<String, dynamic>>
                                                      donations = [];
                                                      if (donationsStr !=
                                                          null) {
                                                        donations =
                                                            List<
                                                              Map<
                                                                String,
                                                                dynamic
                                                              >
                                                            >.from(
                                                              jsonDecode(
                                                                donationsStr,
                                                              ),
                                                            );
                                                      }

                                                      // Map the book to donation fields
                            final donation = {
                            'image': book['image'],
                            'title': book['title'] ?? '',
                            'author': book['author'] ?? '',
                            'genre': book['genre'] ?? book['genero'] ?? '',
                            'genero': book['genre'] ?? book['genero'] ?? '',
                            'condition': book['condition'] ?? book['state'] ?? 'Bom',
                            // start notes empty so user can type Observações
                            'notes': '',
                            'createdAt': DateTime.now().toIso8601String(),
                            };

                                                      // Prevent duplicates: compare title+author (case-insensitive)
                                                      bool exists = donations.any((d) {
                                                        final dTitle = (d['title'] ?? '').toString().trim().toLowerCase();
                                                        final dAuthor = (d['author'] ?? '').toString().trim().toLowerCase();
                                                        final bTitle = (donation['title'] ?? '').toString().trim().toLowerCase();
                                                        final bAuthor = (donation['author'] ?? '').toString().trim().toLowerCase();
                                                        if (dTitle.isNotEmpty && bTitle.isNotEmpty && dAuthor.isNotEmpty && bAuthor.isNotEmpty) {
                                                          return dTitle == bTitle && dAuthor == bAuthor;
                                                        }
                                                        // fallback: compare image path if titles/authors missing
                                                        final dImage = (d['image'] ?? '').toString();
                                                        final bImage = (donation['image'] ?? '').toString();
                                                        if (dImage.isNotEmpty && bImage.isNotEmpty) return dImage == bImage;
                                                        return false;
                                                      });

                                                      if (exists) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Livro já está na lista de Doações', style: GoogleFonts.poppins()),
                                                          ),
                                                        );
                                                      } else {
                                                        donations.add(donation);
                                                        await prefs.setString('donations', jsonEncode(donations));
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Livro copiado para Doações',
                                                              style: GoogleFonts.poppins(),
                                                            ),
                                                          ),
                                                        );

                                                        // Open the DonateScreen so user sees the list
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => const DonateScreen(),
                                                          ),
                                                        );
                                                      }
                                                      // Open the DonateScreen so user sees the list
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const DonateScreen(),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      // If something fails, show an error
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Erro ao mover para doações',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: const Icon(
                                                  Icons.favorite,
                                                  color: Colors.purple,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              GestureDetector(
                                                onTap: () =>
                                                    deleteBook(realIndex),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
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
                                Row(
                                  children: [
                                    _buildInfoBox(
                                      Icons.calendar_today,
                                      book['year'] ?? '',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoBox(
                                      Icons.menu_book,
                                      '${book['pages'] ?? ''} pág.',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoBox(
                                      Icons.attach_money,
                                      book['value'] != null
                                          ? 'R\$ ${book['value']}'
                                          : '',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Lido de ${book['startDate'] ?? ''} a ${book['endDate'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Média de ${getAveragePagesPerDay(book).toStringAsFixed(0)} pág./dia',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFEA9E24),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        expandedBooks.remove(realIndex);
                                      } else {
                                        expandedBooks.add(realIndex);
                                      }
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resumo:',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        book['summary'] ?? '',
                                        maxLines: isExpanded ? null : 3,
                                        overflow: isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Anotações:',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        book['note'] ?? '',
                                        maxLines: isExpanded ? null : 3,
                                        overflow: isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String value,
    required String label,
    required Color mainColor,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      height: screenHeight * 0.15,
      width: screenWidth * 0.40,
      decoration: BoxDecoration(
        color: const Color(0xFF27273A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: mainColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: mainColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF141425)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF141425), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
