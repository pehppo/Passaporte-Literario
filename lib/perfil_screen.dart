import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'donate_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class _PerfilScreenState extends State<PerfilScreen> with RouteAware {
  String username = "Usuário";
  String? photoUrl;

  int livrosLidos = 0;
  int metasConcluidas = 0;
  int paginasLidas = 0;
  int avaliacoes = 0;
  int wishlistCount = 0;
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
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
    loadUserProfile();
    loadStats();
  }

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;
      setState(() {
        username = (data['name'] as String?) ??
            user.displayName ??
            username;
        photoUrl = data['photoUrl'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        username = user.displayName ?? username;
      });
    }
  }

  Future<void> loadStats() async {
    setState(() => isLoadingStats = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          livrosLidos = 0;
          paginasLidas = 0;
          avaliacoes = 0;
          metasConcluidas = 0;
          wishlistCount = 0;
          isLoadingStats = false;
        });
      }
      return;
    }

    try {
      final diarySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diary')
          .get();

      int totalPaginas = 0;
      int totalEstrelas = 0;

      for (final doc in diarySnap.docs) {
        final data = doc.data();
        final pagesVal = data['pages'];
        final ratingVal = data['rating'];

        totalPaginas += int.tryParse(pagesVal?.toString() ?? '0') ?? 0;
        totalEstrelas += int.tryParse(ratingVal?.toString() ?? '0') ?? 0;
      }

      final totalLivros = diarySnap.docs.length;

      int concluidas = 0;
      try {
        final metasSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .get();

        for (final doc in metasSnap.docs) {
          final data = doc.data();
          final pagesRead = data['pagesRead'] ?? 0;
          final totalPages = data['totalPages'] ?? 1;
          if (pagesRead >= totalPages) {
            concluidas++;
          }
        }
      } catch (_) {
        concluidas = 0;
      }

      int wlCount = 0;
      try {
        final wlSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .get();
        wlCount = wlSnap.docs.length;
      } catch (_) {
        wlCount = 0;
      }

      if (!mounted) return;
      setState(() {
        livrosLidos = totalLivros;
        paginasLidas = totalPaginas;
        avaliacoes = totalEstrelas;
        metasConcluidas = concluidas;
        wishlistCount = wlCount;
        isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      if (!mounted) return;
      setState(() {
        livrosLidos = 0;
        paginasLidas = 0;
        avaliacoes = 0;
        metasConcluidas = 0;
        wishlistCount = 0;
        isLoadingStats = false;
      });
    }
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        image: (photoUrl != null && photoUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl!.isEmpty)
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
                      onPressed:
                          isLoadingStats ? null : () async => loadStats(),
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
                              onProfileImageChanged: (String? url) {
                                setState(() {
                                  photoUrl = url;
                                });
                              },
                            ),
                          ),
                        );
                        if (atualizado == true) {
                          loadUserProfile();
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
