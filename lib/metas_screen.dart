import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // CustomTopBar
import 'dart:convert';

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

  List<Map<String, dynamic>> metas = [];

  @override
  void initState() {
    super.initState();
    loadMetas();
  }

  // Carrega metas do SharedPreferences
  Future<void> loadMetas() async {
    final prefs = await SharedPreferences.getInstance();
    final metasData = prefs.getString('metas');
    if (metasData != null) {
      setState(() {
        metas = List<Map<String, dynamic>>.from(jsonDecode(metasData));
      });
    }
  }

  // Salva metas no SharedPreferences
  Future<void> saveMetas() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('metas', jsonEncode(metas));
  }

  void createMeta() {
    if (bookController.text.isEmpty) return;

    setState(() {
      metas.add({
        'title': bookController.text,
        'author': authorController.text,
        'totalPages': int.tryParse(pagesController.text) ?? 0,
        'daysToRead': int.tryParse(daysController.text) ?? 1,
        'coverImage': null,
        'pagesRead': 0,
      });
      bookController.clear();
      authorController.clear();
      pagesController.clear();
      daysController.clear();
    });

  saveMetas();
  Navigator.maybePop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Metas de Leitura'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Box criar nova meta
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
                _buildTextField('Nome do Livro', Icons.book, bookController),
                const SizedBox(height: 10),
                _buildTextField('Autor do Livro', Icons.person, authorController),
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
          // Lista de metas
          ...metas.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> meta = entry.value;

            final progress = meta['totalPages'] == 0
                ? 0.0
                : meta['pagesRead'] / meta['totalPages'];

            final dailyPages = (meta['totalPages'] / (meta['daysToRead'] == 0 ? 1 : meta['daysToRead'])).ceil();

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
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setState(() {
                              metas[index]['coverImage'] = File(image.path);
                            });
                            saveMetas();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 97,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                            image: meta['coverImage'] != null
                                ? DecorationImage(
                                    image: FileImage(meta['coverImage']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: meta['coverImage'] == null
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
                              meta['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'por ${meta['author']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.menu_book, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '$dailyPages páginas/dia',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${meta['daysToRead']} dias restantes',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
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
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFF4CAF50),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${meta['pagesRead']} de ${meta['totalPages']} páginas (${(progress * 100).toInt()}%)',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          // marcar como lido (conta apenas dailyPages)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                int pagesRead = meta['pagesRead'];
                                int totalPages = meta['totalPages'];
                                metas[index]['pagesRead'] = (pagesRead + dailyPages) > totalPages
                                    ? totalPages
                                    : pagesRead + dailyPages;
                              });
                              saveMetas();
                            },
                            icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => metas.removeAt(index));
                              saveMetas();
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
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
