import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart';
import 'home_screen.dart'; // CustomTopBar
import 'wishlist_screen.dart';
import 'donate_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class _PerfilScreenState extends State<PerfilScreen> with RouteAware {
  File? profileImage;
  String username = "Usuário";

  int livrosLidos = 0;
  int metasConcluidas = 0;
  int paginasLidas = 0;
  int avaliacoes = 0;
  int wishlistCount = 0;
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadProfileImage();
    loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    loadStats();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Atualiza estatísticas ao voltar para a tela
    loadStats();
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_email');
    if (email != null) {
      setState(() {
        username = prefs.getString('${email}_nome') ?? 'Usuário';
      });
    }
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_email');
    if (email != null) {
      final imagePath = prefs.getString('${email}_profile_image');
      if (imagePath != null) {
        setState(() {
          profileImage = File(imagePath);
        });
      }
    }
  }

  Future<void> removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedEmail = prefs.getString('logged_email');
    if (loggedEmail != null) {
      await prefs.remove('${loggedEmail}_profile_image');
    }
    setState(() {
      profileImage = null;
    });
    Navigator.pop(context, true);
  }

  Future<void> loadStats() async {
    setState(() => isLoadingStats = true);
    final prefs = await SharedPreferences.getInstance();

    // Carregar livros do Diário
    final diarioData = prefs.getString('books');
    if (diarioData != null) {
      final List<dynamic> livros = jsonDecode(diarioData);
      int totalPaginas = 0;
      int totalEstrelas = 0;

      for (var livro in livros) {
        totalPaginas += int.tryParse(livro['pages']?.toString() ?? '0') ?? 0;
        totalEstrelas += int.tryParse(livro['rating']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        livrosLidos = livros.length;
        paginasLidas = totalPaginas;
        avaliacoes = totalEstrelas;
      });
    } else {
      setState(() {
        livrosLidos = 0;
        paginasLidas = 0;
        avaliacoes = 0;
      });
    }

    // Carregar metas
    final metasData = prefs.getString('metas');
    if (metasData != null) {
      final List<dynamic> metasList = jsonDecode(metasData);
      int concluidas = metasList
          .where(
            (meta) => (meta['pagesRead'] ?? 0) >= (meta['totalPages'] ?? 1),
          )
          .length;
      setState(() {
        metasConcluidas = concluidas;
      });
    } else {
      setState(() {
        metasConcluidas = 0;
      });
    }
    // Carregar wishlist count
    final wishlistData = prefs.getString('wishlist');
    if (wishlistData != null) {
      try {
        final List<dynamic> list = jsonDecode(wishlistData);
        setState(() => wishlistCount = list.length);
      } catch (e) {
        setState(() => wishlistCount = 0);
      }
    } else {
      setState(() => wishlistCount = 0);
    }
    if (mounted) setState(() => isLoadingStats = false);
  }

  Widget buildStatBox({
    required double width,
    required double height,
    required Color color,
    required IconData icon,
    required String title,
    required int value,
    required String label,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: height * 0.35, color: Colors.white),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.white),
                children: [
                  TextSpan(
                    text: '$value ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
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
  }

  Widget buildQuickAccessBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF141425)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = (screenWidth - 60) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Perfil'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 15,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto + nome
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        image: profileImage != null
                            ? DecorationImage(
                                image: FileImage(profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profileImage == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Estatísticas com botão de refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estatísticas',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isLoadingStats
                          ? null
                          : () async {
                              await loadStats();
                            },
                      icon: isLoadingStats
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Atualizar estatísticas',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        buildStatBox(
                          width: boxWidth,
                          height: 110,
                          color: const Color(0xFF68D1FF),
                          icon: Icons.menu_book_rounded,
                          title: 'Livros Lidos',
                          value: livrosLidos,
                          label: livrosLidos == 1 ? 'livro' : 'livros',
                        ),
                        const SizedBox(height: 15),
                        buildStatBox(
                          width: boxWidth,
                          height: 190,
                          color: const Color(0xFF66C36A),
                          icon: Icons.show_chart_rounded,
                          title: 'Páginas Lidas',
                          value: paginasLidas,
                          label: paginasLidas == 1 ? 'página' : 'páginas',
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Column(
                      children: [
                        buildStatBox(
                          width: boxWidth,
                          height: 190,
                          color: const Color(0xFFFB9791),
                          icon: Icons.flag_rounded,
                          title: 'Metas Concluídas',
                          value: metasConcluidas,
                          label: metasConcluidas == 1 ? 'meta' : 'metas',
                        ),
                        const SizedBox(height: 15),
                        buildStatBox(
                          width: boxWidth,
                          height: 110,
                          color: const Color(0xFFF0BF70),
                          icon: Icons.star_rounded,
                          title: 'Lista de Desejos',
                          value: wishlistCount,
                          label: wishlistCount == 1
                              ? 'livro desejado'
                              : 'livros desejados',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Acesso Rápido
                Text(
                  'Acesso Rápido',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildQuickAccessBox(
                      icon: Icons.person,
                      label: 'Editar Perfil',
                      onTap: () async {
                        final atualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              onProfileImageChanged: (File? img) {
                                setState(() {
                                  profileImage = img;
                                });
                              },
                            ),
                          ),
                        );
                        if (atualizado == true) {
                          loadUsername();
                          loadProfileImage();
                        }
                      },
                    ),
                    buildQuickAccessBox(
                      icon: Icons.shopping_cart,
                      label: 'Lista de Desejos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistScreen(),
                          ),
                        );
                      },
                    ),
                    buildQuickAccessBox(
                      icon: Icons.favorite,
                      label: 'Doar Livros',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonateScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
