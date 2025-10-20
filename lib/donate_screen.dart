import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // CustomTopBar

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  List<Map<String, dynamic>> donations = [];

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('donations');
    if (dataStr == null) {
      donations = [];
    } else {
      try {
        donations = List<Map<String, dynamic>>.from(jsonDecode(dataStr));
      } catch (_) {
        donations = [];
      }
    }
    setState(() {});
  }

  Future<void> _saveDonations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('donations', jsonEncode(donations));
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _editDonationNotes(int index) async {
    final current = donations[index]['notes'] ?? '';
    final controller = TextEditingController(text: current);
    String selected = (donations[index]['condition'] ?? '').toString();
    if (selected.isEmpty) selected = 'Novo';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Editar Estado do Livro', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Estado dropdown
                Text('Estado do livro', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                StatefulBuilder(builder: (context, setStateSB) {
                  return DropdownButtonFormField<String>(
                    value: selected,
                    items: ['Novo', 'Bom', 'Usado', 'Ruim']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 12))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        selected = v;
                        setStateSB(() {});
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      filled: true,
                      fillColor: const Color(0xFF1E1F2B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  );
                }),
            const SizedBox(height: 12),
            Text('Observações (opcional)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
                filled: true,
                fillColor: const Color(0xFF1E1F2B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // delete this donation and close
              donations.removeAt(index);
              await _saveDonations();
              Navigator.pop(context, true);
            },
            child: Text('Excluir', style: GoogleFonts.poppins(color: const Color(0xFFF64136), fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              // save estado and notes
              donations[index]['condition'] = selected;
              donations[index]['notes'] = controller.text;
              _saveDonations();
              Navigator.pop(context, true);
            },
            child: Text('Salvar', style: GoogleFonts.poppins(color: const Color(0xFF4CB050), fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Doações', showBackButton: true),
      body: SafeArea(
        child: donations.isEmpty
            ? Center(
                child: Text(
                  'Nenhuma doação',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: donations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final item = donations[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF27273A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover
                        Container(
                          width: 92,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade800,
                            image:
                                item['image'] != null &&
                                    item['image'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(item['image'])),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (item['image'] == null ||
                                  item['image'].toString().isEmpty)
                              ? const Icon(Icons.book, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Text block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'por ${item['author'] ?? ''}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (item['genre'] ?? item['genero'] ?? '').toString().isNotEmpty ? (item['genre'] ?? item['genero']) : 'Sem gênero',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF12B7FF),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estado: ${item['condition'] ?? ''}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Obs:',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Builder(builder: (context) {
                                final notes = (item['notes'] ?? '').toString();
                                return Text(
                                  notes.isNotEmpty ? notes : 'Sem observações',
                                  style: notes.isNotEmpty
                                      ? GoogleFonts.poppins(color: Colors.white70, fontSize: 12)
                                      : GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Right icons container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _editDonationNotes(index),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF12B7FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF27273A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      title: Text(
                                        'Confirmar exclusão',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Text(
                                        'Deseja realmente remover esta doação?',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
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
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(
                                            'Remover',
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
                                    donations.removeAt(index);
                                    await _saveDonations();
                                    setState(() {});
                                  }
                                },
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
