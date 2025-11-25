import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_details_screen.dart';
import 'settings.dart';
import 'add_screen.dart';
import 'diario_screen.dart';
import 'metas_screen.dart';
import 'perfil_screen.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnail;
  final String publishedDate;
  final List<String> categories;
  final int pageCount;
  final String language;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnail,
    required this.publishedDate,
    required this.categories,
    required this.pageCount,
    required this.language,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Título não disponível',
      authors: (volumeInfo['authors'] as List?)
              ?.map((a) => a.toString())
              .toList() ??
          ['Autor não disponível'],
      description: volumeInfo['description'] ?? 'Descrição não disponível',
      thumbnail: (volumeInfo['imageLinks'] != null)
          ? volumeInfo['imageLinks']['thumbnail']
          : '',
      publishedDate: volumeInfo['publishedDate'] ?? 'Ano não disponível',
      categories: (volumeInfo['categories'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          ['Categoria não disponível'],
      pageCount: volumeInfo['pageCount'] ?? 0,
      language: volumeInfo['language'] ?? '',
    );
  }
}

Future<List<Book>> searchBooks(String query, {int maxResults = 40}) async {
  if (query.isEmpty) return [];
  final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=$maxResults');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final items = (data['items'] as List?) ?? [];
    return items.map((item) => Book.fromJson(item)).toList();
  } else {
    throw Exception('Erro ao buscar livros');
  }
}

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomTopBar({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 120);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topBarHeight = screenHeight * 0.13;
    final iconSize = screenWidth * 0.06;

    return PreferredSize(
      preferredSize: Size.fromHeight(topBarHeight),
      child: Container(
        height: topBarHeight,
        color: const Color(0xFF27273A),
        child: Stack(
          children: [
            if (showBackButton)
              Positioned(
                top: topBarHeight * 0.55,
                left: screenWidth * 0.04,
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
            Positioned(
              top: topBarHeight * 0.55,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
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
              right: screenWidth * 0.04,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.settings, color: Colors.white, size: iconSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomBarHeight = screenHeight * 0.11;

    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.add,
        'label': 'Adicionar',
        'color': const Color(0xFF4CB050)
      },
      {
        'icon': Icons.book,
        'label': 'Meu Diário',
        'color': const Color(0xFF12B7FF)
      },
      {
        'icon': Icons.home,
        'label': 'Explorar',
        'color': const Color(0xFFDD6E00)
      },
      {
        'icon': Icons.flag,
        'label': 'Metas',
        'color': const Color(0xFFF64136)
      },
      {
        'icon': Icons.person,
        'label': 'Perfil',
        'color': const Color(0xFFEA9E24)
      },
    ];

    return Container(
      height: bottomBarHeight,
      color: const Color(0xFF27273A),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool isActive = currentIndex == index;
          final Color color =
              isActive ? item['color'] : const Color(0xFF8B8B94);
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: SizedBox(
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'],
                        color: color, size: screenWidth * 0.065),
                    const SizedBox(height: 4),
                    Text(
                      item['label'],
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CategoryBooksScreen extends StatefulWidget {
  final String categoryName;
  final String query;
  const CategoryBooksScreen({
    super.key,
    required this.categoryName,
    required this.query,
  });

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryBooks();
  }

  Future<void> fetchCategoryBooks() async {
    try {
      final results = await searchBooks(widget.query, maxResults: 40);
      setState(() {
        books = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: CustomTopBar(title: widget.categoryName, showBackButton: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 10,
                childAspectRatio: 0.45,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: book.thumbnail.isNotEmpty
                            ? Image.network(
                                book.thumbnail,
                                width: double.infinity,
                                height: screenHeight * 0.18,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: screenHeight * 0.18,
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.authors.join(', '),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.03,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _currentIndex = 2;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = false;
  List<Book> searchResults = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    setState(() => isLoading = true);
    try {
      final results = await searchBooks(query);
      setState(() => searchResults = results);
    } catch (e) {
      debugPrint('Erro ao buscar livros: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      searchResults = [];
    });
  }

  Future<void> addBook(Map<String, dynamic> bookData) async {
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

    final payload = {
      ...bookData,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('diary')
          .add(payload);

      if (mounted) {
        setState(() {
          _currentIndex = 1;
        });
      }
    } catch (e, st) {
      debugPrint('Erro ao salvar livro no Firestore: $e');
      debugPrint(st.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o livro no servidor.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      AddScreen(
        onSaveBook: (bookData) {
          addBook(bookData);
        },
      ),
      const DiarioScreen(),
      buildExplorarScreen(context),
      const MetasScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget buildExplorarScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final Map<String, String> categories = {
      'Melhores livros brasileiros': 'literatura brasileira',
      'Religião': 'religiosos',
      'História': 'história',
      'Terror': 'terror',
      'Ficção': 'ficção',
      'Romance': 'romance',
      'Fantasia': 'fantasia',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Explorar'),
      body: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFF27273A),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white70),
                          onPressed: _clearSearch,
                        )
                      : null,
                  hintText: 'Buscar por título do livro',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  searchQuery = query;
                  _searchBooks(query);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: searchQuery.isNotEmpty
                ? isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : buildSearchResults(
                        screenWidth, screenHeight, searchResults)
                : ListView(
                    children: categories.entries
                        .map(
                          (entry) => buildCategoryCarousel(
                            context,
                            entry.key,
                            entry.value,
                            screenWidth,
                            screenHeight,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchResults(
      double screenWidth, double screenHeight, List<Book> searchResults) {
    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          'Nenhum resultado encontrado',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 10,
        childAspectRatio: 0.45,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final book = searchResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailsScreen(book: book),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.thumbnail.isNotEmpty
                    ? Image.network(
                        book.thumbnail,
                        width: double.infinity,
                        height: screenHeight * 0.18,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: screenHeight * 0.18,
                        color: Colors.grey,
                        child: const Icon(Icons.book,
                            color: Colors.white, size: 40),
                      ),
              ),
              const SizedBox(height: 5),
              Text(
                book.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                book.authors.join(', '),
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.03,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCategoryCarousel(
    BuildContext context,
    String categoryName,
    String query,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryBooksScreen(
                        categoryName: categoryName,
                        query: query,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Ver mais',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: screenWidth * 0.033,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: screenHeight * 0.28,
          child: FutureBuilder<List<Book>>(
            future: query.trim().isEmpty
                ? Future.value([])
                : searchBooks(query, maxResults: 6),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final books = snapshot.data!;
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum livro encontrado',
                    style:
                        GoogleFonts.poppins(color: Colors.white70),
                  ),
                );
              }
              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookDetailsScreen(book: book),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: book.thumbnail.isNotEmpty
                              ? Image.network(
                                  book.thumbnail,
                                  width: screenWidth * 0.3,
                                  height: screenHeight * 0.18,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: screenWidth * 0.3,
                                  height: screenHeight * 0.18,
                                  color: Colors.grey,
                                  child: const Icon(Icons.book,
                                      color: Colors.white,
                                      size: 40),
                                ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: screenWidth * 0.3,
                          child: Text(
                            book.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.032,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.3,
                          child: Text(
                            book.authors.join(', '),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.03,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
}
