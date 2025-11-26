import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Português';
  String _selectedTheme = 'Escuro';

  final List<String> _languages = ['Português', 'English', 'Español'];
  final List<String> _themes = ['Escuro', 'Claro', 'Padrão do Sistema'];

  @override
  void initState() {
    super.initState();
    _loadPreferencesFromFirestore();
  }

  Future<void> _loadPreferencesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (data == null) return;

      final language = data['language'] as String?;
      final theme = data['theme'] as String?;

      setState(() {
        _selectedLanguage = language ?? 'Português';
        _selectedTheme = theme ?? 'Escuro';
      });
    } catch (e) {
      debugPrint('Erro ao carregar configurações do Firestore: $e');
    }
  }

  Future<void> _saveLanguage(String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'language': language,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Erro ao salvar idioma no Firestore: $e');
    }
  }

  Future<void> _saveTheme(String theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'theme': theme,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Erro ao salvar tema no Firestore: $e');
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.email == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível identificar o e-mail da conta.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF27273A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Alterar Senha',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Um link para redefinir sua senha foi enviado para:\n\n${user.email}\n\nVerifique sua caixa de entrada e a pasta de spam.',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4CB050),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erro ao enviar e-mail de redefinição: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao enviar e-mail. Tente novamente mais tarde.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEmail({required String subject}) async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'passap.literario@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': subject,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      }
    } on PlatformException catch (e) {
      debugPrint('Erro de plataforma: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro interno: Reinicie o aplicativo.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro genérico ao abrir email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir o aplicativo de e-mail.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27273A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Termos de Uso',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              '''
Bem-vindo ao nosso aplicativo de Diário de Leitura!

1. Aceitação dos Termos
Ao baixar e usar este aplicativo, você concorda com estes Termos de Uso. Se não concordar, por favor, não utilize o aplicativo.

2. Uso do Aplicativo
Este aplicativo destina-se ao registro pessoal de leituras, metas e listas de desejos. Você é responsável por manter a confidencialidade de sua conta e senha.

3. Conteúdo do Usuário
Você mantém a propriedade de qualquer conteúdo (comentários, anotações, fotos) que enviar. No entanto, você nos concede uma licença para armazenar e exibir esse conteúdo apenas para o seu uso pessoal dentro da plataforma.

4. Privacidade
Respeitamos sua privacidade. Seus dados são armazenados de forma segura e não são compartilhados com terceiros sem seu consentimento, exceto conforme exigido por lei.

5. Responsabilidades
Não nos responsabilizamos por quaisquer perdas ou danos resultantes do uso deste aplicativo. O serviço é fornecido "como está".

6. Alterações nos Termos
Podemos atualizar estes termos periodicamente. O uso continuado do aplicativo após as alterações constitui aceitação dos novos termos.

Contato: passap.literario@gmail.com
              ''', 
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String currentValue,
    required List<String> options,
    required Function(String) onChanged,
    required double fontSize14,
  }) {
    return Column(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF27273A),
            iconEnabledColor: const Color(0xFF7E848D),
            style: GoogleFonts.poppins(color: Colors.white),
            selectedItemBuilder: (context) {
              return options.map((_) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentValue,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize14,
                        color: const Color(0xFF7E848D),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize14,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
        Container(height: 1, color: const Color(0xFF232533)),
      ],
    );
  }

  Widget _buildSettingRow({
    required String title,
    required double fontSize14,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF7E848D),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF232533)),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('erro ao deslogar do Firebase: $e');
    }

    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('erro ao deslogar do Google: $e');
    }

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final topBarHeight = screenHeight * 0.13;
    final iconSize = screenWidth * 0.06;
    final horizontalPadding = screenWidth * 0.05;

    final fontSize14 = screenWidth * 0.038;
    final fontSize16 = screenWidth * 0.042;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(topBarHeight),
        child: Container(
          height: topBarHeight,
          color: const Color(0xFF27273A),
          child: Stack(
            children: [
              Positioned(
                top: topBarHeight * 0.55,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Configurações',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topBarHeight * 0.55,
                left: horizontalPadding * 0.76,
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
                right: screenWidth * 0.04,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _logout,
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Geral',
                style: GoogleFonts.poppins(
                  fontSize: fontSize14 * 1.1,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA2A2A7),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildDropdownSetting(
                title: 'Idioma (em breve)',
                currentValue: _selectedLanguage,
                options: _languages,
                onChanged: (val) {
                  setState(() => _selectedLanguage = val);
                  _saveLanguage(val);
                },
                fontSize14: fontSize14,
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildDropdownSetting(
                title: 'Temas (em breve)',
                currentValue: _selectedTheme,
                options: _themes,
                onChanged: (val) {
                  setState(() => _selectedTheme = val);
                  _saveTheme(val);
                },
                fontSize14: fontSize14,
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Fale Conosco',
                fontSize14: fontSize14,
                onTap: () {
                  _openEmail(subject: 'Fale Conosco - Passaporte Literário');
                },
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Segurança',
                style: GoogleFonts.poppins(
                  fontSize: fontSize14 * 1.1,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA2A2A7),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildSettingRow(
                title: 'Alterar Senha',
                fontSize14: fontSize14,
                onTap: _changePassword,
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Termos de Uso',
                fontSize14: fontSize14,
                onTap: _showTermsOfUse,
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Reportar Erro',
                fontSize14: fontSize14,
                onTap: () {
                  _openEmail(subject: 'Reportar Erro - Passaporte Literário');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}