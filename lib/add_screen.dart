import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart'; // Para CustomTopBar

class AddScreen extends StatefulWidget {
  final Map<String, dynamic>? bookToEdit;
  final Function(Map<String, dynamic>) onSaveBook;

  const AddScreen({super.key, required this.onSaveBook, this.bookToEdit});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> bookSuggestions = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController pagesController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String? selectedGenre;
  final List<String> genres = [
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
    'Outro',
  ];

  XFile? pickedImage;
  final ImagePicker picker = ImagePicker();
  int rating = 0;

  Future<void> _pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => pickedImage = image);
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      bookSuggestions = [];
    });
  }

  Future<void> fetchBookSuggestions(String query) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=intitle:$query&langRestrict=pt',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['items'] != null) {
        setState(() {
          bookSuggestions = (data['items'] as List)
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item['volumeInfo']),
              )
              .toList();
        });
      }
    }
  }

  void fillBookFields(Map<String, dynamic> book) {
    setState(() {
      titleController.text = book['title'] ?? '';
      authorController.text = book['authors'] != null
          ? (book['authors'] as List).join(', ')
          : '';
      yearController.text = book['publishedDate'] != null
          ? book['publishedDate'].toString().split('-')[0]
          : '';
      pagesController.text = book['pageCount'] != null
          ? book['pageCount'].toString()
          : '';
      summaryController.text = book['description'] ?? '';
      if (book['imageLinks'] != null &&
          book['imageLinks']['thumbnail'] != null) {
        _setNetworkImage(book['imageLinks']['thumbnail']);
      }
      bookSuggestions = [];
    });
  }

  void _setNetworkImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final tempDir = Directory.systemTemp;
      final file = await File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(bytes);
      setState(() => pickedImage = XFile(file.path));
    }
  }

  void _saveBook() {
    final bookData = {
      'image': pickedImage?.path,
      'title': titleController.text,
      'author': authorController.text,
      'genre': selectedGenre ?? '',
      'year': yearController.text,
      'pages': pagesController.text,
      'value': valueController.text,
      'startDate': startDateController.text,
      'endDate': endDateController.text,
      'summary': summaryController.text,
      'note': noteController.text,
      'rating': rating,
    };

    widget.onSaveBook(bookData);
    Navigator.maybePop(context);

    titleController.clear();
    authorController.clear();
    yearController.clear();
    pagesController.clear();
    valueController.clear();
    startDateController.clear();
    endDateController.clear();
    summaryController.clear();
    noteController.clear();
    selectedGenre = null;
    pickedImage = null;
    rating = 0;
    searchQuery = '';
    bookSuggestions = [];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Adicionar Livro'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Busca de livros
              TextField(
                controller: searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: _clearSearch,
                        )
                      : null,
                  hintText: 'Buscar por título do livro',
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
                onChanged: (query) {
                  setState(() => searchQuery = query);
                  if (query.length > 2) fetchBookSuggestions(query);
                },
              ),
              const SizedBox(height: 5),
              if (bookSuggestions.isNotEmpty)
                Container(
                  color: const Color(0xFF27273A),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: bookSuggestions.length,
                    itemBuilder: (context, index) {
                      final book = bookSuggestions[index];
                      return ListTile(
                        title: Text(
                          book['title'] ?? '',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        subtitle: Text(
                          book['authors'] != null
                              ? (book['authors'] as List).join(', ')
                              : '',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          searchController.text = book['title'] ?? '';
                          searchQuery = '';
                          fillBookFields(book);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 15),

              // Imagem e campos...
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27273A),
                    borderRadius: BorderRadius.circular(12),
                    image: pickedImage != null
                        ? DecorationImage(
                            image: FileImage(File(pickedImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Adicionar foto do livro',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Toque para tirar foto ou selecionar da galeria',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 15),

              // Campos do livro
              _buildTextField('Nome do Livro', Icons.book, titleController),
              const SizedBox(height: 15),
              _buildTextField('Nome do Autor', Icons.person, authorController),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedGenre,
                dropdownColor: const Color(0xFF141425),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category, color: Colors.white),
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
                items: genres
                    .map(
                      (genre) => DropdownMenuItem(
                        value: genre,
                        child: Text(
                          genre,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedGenre = val),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Ano',
                      Icons.calendar_today,
                      yearController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      'Páginas',
                      Icons.menu_book,
                      pagesController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildDateField('Data Início', startDateController),
                  const SizedBox(width: 15),
                  _buildDateField('Data Fim', endDateController),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField('Resumo', Icons.description, summaryController),
              const SizedBox(height: 15),
              _buildTextField(
                'Valor Pago (R\$)',
                Icons.attach_money,
                valueController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              _buildTextField('Anotações', Icons.edit, noteController),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Avaliação',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
              ),
              _buildStarRating(),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27273A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Adicionar Livro',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildDateField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white),
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.date_range, color: Colors.white),
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
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null)
            controller.text = '${picked.day}/${picked.month}/${picked.year}';
        },
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => rating = index + 1),
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}
