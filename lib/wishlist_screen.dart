import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart'; // CustomTopBar

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> wishlist = [];
  final ImagePicker picker = ImagePicker();
  // Controllers for inline add form
  final TextEditingController _addTitleController = TextEditingController();
  final TextEditingController _addAuthorController = TextEditingController();
  final TextEditingController _addGenreController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();
  String _addPriority = 'Média';

  // Match AddScreen's _buildTextField signature and style
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

  @override
  void initState() {
    super.initState();
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('wishlist');
    setState(() {
      wishlist = data != null
          ? List<Map<String, dynamic>>.from(jsonDecode(data))
          : [];
    });
  }

  Future<void> saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', jsonEncode(wishlist));
  }

  Future<void> pickImage(int index) async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => wishlist[index]['image'] = file.path);
      await saveWishlist();
    }
  }

  double get totalEstimated {
    double total = 0;
    for (var item in wishlist) {
      final pv = item['price'];
      if (pv == null) continue;
      try {
        final d = pv is num ? pv.toDouble() : double.parse(pv.toString());
        total += d;
      } catch (e) {
        // ignore non-numeric
      }
    }
    return total;
  }

  Future<void> addOrEditItem({Map<String, dynamic>? item, int? index}) async {
    // This function is kept for compatibility with edit flow.
    // For editing, we'll open a simple dialog reusing the existing fields.
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
          item == null ? 'Editar item' : 'Editar item',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authorController,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Autor',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: genreController,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Gênero',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço estimado',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: priority,
                dropdownColor: const Color(0xFF27273A),
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.white70),
                ),
                items: ['Alta', 'Média', 'Baixa']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w400, color: Colors.white),
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
                'price': double.tryParse(priceController.text.trim()) ?? null,
                'priority': priority,
                'image': item?['image'] ?? null,
                'note': item?['note'] ?? '',
              };
              setState(() {
                if (index != null)
                  wishlist[index] = newItem;
                else
                  wishlist.add(newItem);
              });
              await saveWishlist();
              Navigator.pop(context);
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

  void deleteItem(int index) async {
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
      setState(() => wishlist.removeAt(index));
      await saveWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(
        title: 'Lista de Desejos',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Inline add box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  // Nome do Livro
                  _buildTextField('Nome do Livro', Icons.book, _addTitleController),
                  const SizedBox(height: 10),
                  // Autor
                  _buildTextField('Nome do Autor', Icons.person, _addAuthorController),
                  const SizedBox(height: 10),
                  // Gênero (use dropdown similar to AddScreen)
                  DropdownButtonFormField<String>(
                    value: _addGenreController.text.isNotEmpty ? _addGenreController.text : null,
                    dropdownColor: const Color(0xFF141425),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category, color: Colors.white),
                      labelText: 'Gênero',
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
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: <String>['Ação','Autoajuda','Aventura','Biografia','Ciência','Clássico','Comédia','Drama','Fantasia','Ficção Científica','História','Infantil','Mistério','Policial','Religião','Romance','Terror','Outro']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.poppins(color: Colors.white))))
                        .toList(),
                    onChanged: (val) => setState(() => _addGenreController.text = val ?? ''),
                  ),
                  const SizedBox(height: 10),
                  // Preço estimado
                  _buildTextField('Preço Estimado', Icons.attach_money, _addPriceController, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  // Prioridade (use underline style)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<String>(
                      value: _addPriority,
                      dropdownColor: const Color(0xFF141425),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.priority_high, color: Colors.white),
                        labelText: 'Prioridade',
                        labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
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
                      items: ['Alta', 'Média', 'Baixa']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => _addPriority = v ?? 'Média'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newItem = {
                          'title': _addTitleController.text.trim(),
                          'author': _addAuthorController.text.trim(),
                          'genre': _addGenreController.text.trim(),
                          'price': double.tryParse(_addPriceController.text.trim()) ?? null,
                          'priority': _addPriority,
                          'image': null,
                          'note': '',
                        };
                        setState(() => wishlist.add(newItem));
                        await saveWishlist();
                        // clear fields
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
            // Total estimado box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    'R\$ ${totalEstimated.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(color: const Color(0xFF4CB050), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: wishlist.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum item na lista de desejos',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: wishlist.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final w = wishlist[index];
                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27273A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => pickImage(index),
                                child: Container(
                                  width: 64,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[800],
                                    image: w['image'] != null
                                        ? DecorationImage(
                                            image: FileImage(File(w['image'])),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      w['title'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Author
                                    Text(
                                      w['author'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Genre • Priority
                                    Text(
                                      '${w['genre'] ?? '-'} • Prioridade: ${w['priority'] ?? '-'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Price (always show; display '-' when absent)
                                    Text(
                                      'Preço: R\$' + (() {
                                        final pv = w['price'];
                                        if (pv == null) return '-';
                                        try {
                                          final d = pv is num ? pv.toDouble() : double.parse(pv.toString());
                                          return d.toStringAsFixed(2);
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
                                    onPressed: () => addOrEditItem(item: w, index: index),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF12B7FF),
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 20,
                                    onPressed: () => deleteItem(index),
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
            ),
          ],
        ),
      ),
    );
  }
}
