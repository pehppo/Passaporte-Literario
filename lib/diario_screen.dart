import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_book_screen.dart';
import 'home_screen.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  String searchQuery = '';
  final Set<String> expandedBooks = {};

  double getTotalSpent(List<Map<String, dynamic>> books) {
    double total = 0;
    for (var book in books) {
      final value = book['value'];
      if (value != null && value.toString().isNotEmpty) {
        total += double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
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
        book['endDate'].toString().isEmpty) {
      return 0;
    }

    final pages = int.tryParse(book['pages'].toString()) ?? 0;

    final startSplit = book['startDate'].toString().split('/');
    final endSplit = book['endDate'].toString().split('/');

    if (startSplit.length != 3 || endSplit.length != 3) return 0;

    final startDate = DateTime(
      int.parse(startSplit[2]),
      int.parse(startSplit[1]),
      int.parse(startSplit[0]),
    );

    final endDate = DateTime(
      int.parse(endSplit[2]),
      int.parse(endSplit[1]),
      int.parse(endSplit[0]),
    );

    final days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) return 0;

    return pages / days;
  }

  double getAveragePagesPerDayAllBooks(List<Map<String, dynamic>> books) {
    if (books.isEmpty) return 0;

    double totalPagesPerDay = 0;
    int countedBooks = 0;

    for (var book in books) {
      final avg = getAveragePagesPerDay(book);
      if (avg > 0) {
        totalPagesPerDay += avg;
        countedBooks++;
      }
    }

    if (countedBooks == 0) return 0;
    return totalPagesPerDay / countedBooks;
  }

  Future<void> deleteBook(String docId) async {
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
          'Deseja realmente excluir este livro do diário?',
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diary')
          .doc(docId)
          .delete();
    }
  }

  Future<void> openEditScreen(String docId, Map<String, dynamic> book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookScreen(
          book: book,
          onSaveBook: (updatedData) async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('diary')
                .doc(docId)
                .update(updatedData);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF141425),
        appBar: const CustomTopBar(title: 'Meu Diário'),
        body: Center(
          child: Text(
            'Faça login para ver seu diário.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    final diaryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('diary')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Meu Diário'),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: diaryStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: screenHeight * 0.7,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar diário.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            final List<Map<String, dynamic>> allBooks = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();

            final List<Map<String, dynamic>> filteredBooks = searchQuery.isEmpty
                ? allBooks
                : allBooks
                    .where(
                      (book) => (book['title'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()),
                    )
                    .toList();

            final totalSpent = getTotalSpent(allBooks);
            final avgPagesAll = getAveragePagesPerDayAllBooks(allBooks);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBox(
                        icon: Icons.attach_money,
                        value: 'R\$ ${totalSpent.toStringAsFixed(2)}',
                        label: 'Total Gasto',
                        mainColor: const Color(0xFF4CB050),
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                    SizedBox(width: screenWidth * 0.07),
                      _buildStatBox(
                        icon: Icons.show_chart,
                        value: avgPagesAll.toStringAsFixed(0),
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
                  if (filteredBooks.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.1),
                      child: Text(
                        'Nenhum livro encontrado.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(filteredBooks.length, (index) {
                        final book = filteredBooks[index];
                        final docId = book['id'] as String;
                        final isExpanded = expandedBooks.contains(docId);

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
                                      child: (book['image'] != null &&
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
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
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
                                                    docId, book),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              GestureDetector(
                                                onTap: () async {
                                                  final bool? confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF27273A),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                      ),
                                                      title: Text(
                                                        'Adicionar à Doação',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        'Deseja adicionar este livro à lista de doação?',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color:
                                                              Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: Text(
                                                            'Cancelar',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color:
                                                                  Colors.white,
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
                                                                  true),
                                                          child: Text(
                                                            'Adicionar',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: Color(
                                                                  0xFF9E26B3),
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
                                                    final currentUser =
                                                        FirebaseAuth.instance
                                                            .currentUser;
                                                    if (currentUser == null) {
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Faça login para adicionar doações.',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    try {
                                                      final donation = {
                                                        'image': book['image'],
                                                        'title':
                                                            book['title'] ??
                                                                '',
                                                        'author':
                                                            book['author'] ??
                                                                '',
                                                        'genre':
                                                            book['genre'] ??
                                                                book['genero'] ??
                                                                '',
                                                        'condition': 'Bom',
                                                        'notes': '',
                                                        'sourceDiaryId': docId,
                                                        'createdAt': FieldValue
                                                            .serverTimestamp(),
                                                      };

                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(currentUser.uid)
                                                          .collection(
                                                              'donations')
                                                          .add(donation);

                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Livro adicionado para Doações',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Erro ao adicionar livro para doações',
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
                                                onTap: () => deleteBook(docId),
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
                                      book['year']?.toString() ?? '',
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
                                        expandedBooks.remove(docId);
                                      } else {
                                        expandedBooks.add(docId);
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
                      }),
                    ),
                ],
              ),
            );
          },
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
