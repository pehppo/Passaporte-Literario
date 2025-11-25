import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';

class EditBookScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final Function(Map<String, dynamic>) onSaveBook;

  const EditBookScreen({
    super.key,
    required this.book,
    required this.onSaveBook,
  });

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController yearController;
  late TextEditingController pagesController;
  late TextEditingController valueController;
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  late TextEditingController summaryController;
  late TextEditingController noteController;

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

  @override
  void initState() {
    super.initState();
    _fillFieldsForEditing(widget.book);
  }

  void _fillFieldsForEditing(Map<String, dynamic> book) {
    titleController = TextEditingController(text: book['title'] ?? '');
    authorController = TextEditingController(text: book['author'] ?? '');
    selectedGenre = genres.contains(book['genre']) ? book['genre'] : null;
    yearController = TextEditingController(text: book['year'] ?? '');
    pagesController = TextEditingController(
      text: book['pages']?.toString() ?? '',
    );
    valueController = TextEditingController(
      text: book['value']?.toString() ?? '',
    );
    startDateController = TextEditingController(text: book['startDate'] ?? '');
    endDateController = TextEditingController(text: book['endDate'] ?? '');
    summaryController = TextEditingController(text: book['summary'] ?? '');
    noteController = TextEditingController(text: book['note'] ?? '');
    rating = book['rating'] ?? 0;

    if (book['image'] != null && book['image'].toString().isNotEmpty) {
      pickedImage = XFile(book['image']);
    }
  }

  Future<void> _pickImageFrom(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) setState(() => pickedImage = image);
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível acessar a câmera/galeria')),
        );
      }
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF27273A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Tirar foto', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text('Selecionar da galeria', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFrom(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveBook() {
    final updatedBook = {
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

    widget.onSaveBook(updatedBook);
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Editar Livro', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showPickOptions,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final desiredHeight = (screenHeight * 0.25).clamp(120.0, 360.0);

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: double.infinity,
                        maxHeight: desiredHeight,
                        minHeight: 120,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: desiredHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27273A),
                          ),
                          child: pickedImage != null
                              ? Image.file(
                                  File(pickedImage!.path),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: desiredHeight,
                                )
                              : Column(
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
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField('Nome do Livro', Icons.book, titleController),
              const SizedBox(height: 15),
              _buildTextField('Nome do Autor', Icons.person, authorController),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedGenre,
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
                    'Salvar Alterações',
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
          if (picked != null) {
            controller.text = '${picked.day}/${picked.month}/${picked.year}';
          }
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
