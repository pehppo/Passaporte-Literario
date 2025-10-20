import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pass_liter/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Para usar o temaNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Português';
  String _selectedTheme = 'Escuro';

  final List<String> _languages = ['Português', 'English', 'Español'];
  final List<String> _themes = ['Escuro', 'Claro', 'Sistema'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'Português';
      _selectedTheme = prefs.getString('selectedTheme') ?? 'Escuro';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
    temaNotifier.value = theme; // Atualiza tema em tempo real
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF7E848D),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF232533)),
        ],
      ),
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
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
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
              // --- Sessão Geral ---
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
                title: 'Idioma',
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
                title: 'Temas',
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
                  // ação fale conosco
                },
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Notificações',
                fontSize14: fontSize14,
                onTap: () {
                  // ação notificações
                },
              ),

              // --- Sessão Segurança ---
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
                onTap: () {
                  // ação alterar senha
                },
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Termos de Uso',
                fontSize14: fontSize14,
                onTap: () {
                  // ação termos de uso
                },
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildSettingRow(
                title: 'Reportar Erro',
                fontSize14: fontSize14,
                onTap: () {
                  // ação reportar erro
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
