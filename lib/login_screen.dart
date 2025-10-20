import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cadastro_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool _erroLogin = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: -10, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<bool> verificarLogin(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_email', email);
    String? savedSenha = prefs.getString(email);
    return savedSenha != null && savedSenha == senha;
  }

  Future<void> _triggerError() async {
    setState(() => _erroLogin = true);
    _shakeController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 750));
    if (mounted) {
      setState(() => _erroLogin = false);
    }
  }

  PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    bool fromRight = true,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final beginOffset = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final endOffset = Offset.zero;
        final tween = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final paddingHorizontal = screenWidth * 0.05;
    final logoSize = screenWidth * 0.4;
    final campoHeight = screenHeight * 0.07;
    final espacamentoTopo = screenHeight * 0.08;
    final espacamentoEntreCampos = screenHeight * 0.01;
    final fonteTexto = screenWidth * 0.04;
    final fonteBotao = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: espacamentoTopo),
                Center(
                  child: SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Center(
                  child: Text(
                    'Seu Diário de Leituras',
                    style: GoogleFonts.poppins(
                      fontSize: fonteTexto,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // E-mail
                Text(
                  'Insira seu e-mail',
                  style: GoogleFonts.poppins(
                    fontSize: fonteTexto * 0.875,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFA2A2A7),
                  ),
                ),
                SizedBox(height: espacamentoEntreCampos),

                // Campo de e-mail com shake
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    double offset = _erroLogin ? _shakeAnimation.value : 0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    height: campoHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _erroLogin ? Colors.red.shade400 : const Color(0xFF232533),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: const Color(0xFFA2A2A7), size: screenWidth * 0.06),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            style: TextStyle(color: Colors.white, fontSize: fonteTexto),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: espacamentoEntreCampos),

                // Senha
                Text(
                  'Senha',
                  style: GoogleFonts.poppins(
                    fontSize: fonteTexto * 0.875,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFA2A2A7),
                  ),
                ),
                SizedBox(height: 0),

                // Campo de senha com shake
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    double offset = _erroLogin ? _shakeAnimation.value : 0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    height: campoHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _erroLogin ? Colors.red.shade400 : const Color(0xFF232533),
                          width: 1,
                        ),
                      ),
                    ),
                    child: PasswordField(
                      controller: senhaController,
                      iconSize: screenWidth * 0.06,
                      fontSize: fonteTexto,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Botão Entrar
                SizedBox(
                  width: double.infinity,
                  height: campoHeight * 1.0,
                  child: ElevatedButton(
                    onPressed: () async {
                      String email = emailController.text.trim();
                      String senha = senhaController.text.trim();
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                      setState(() => _erroLogin = false);

                      if (email.isEmpty || !emailRegex.hasMatch(email) || senha.isEmpty) {
                        await _triggerError();
                        return;
                      }

                      bool sucesso = await verificarLogin(email, senha);
                      if (!sucesso) {
                        await _triggerError();
                        return;
                      }

                      // SALVA LOGIN
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    child: Text(
                      'Entrar',
                      style: GoogleFonts.poppins(
                        fontSize: fonteBotao,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141425),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                if (_erroLogin)
                  Text(
                    'E-mail ou senha incorretos',
                    style: GoogleFonts.poppins(
                      fontSize: fonteTexto * 0.8,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),

                SizedBox(height: screenHeight * 0.03),

                // Link de cadastro
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Não tem uma conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: fonteTexto * 0.8,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFA2A2A7),
                      ),
                      children: [
                        TextSpan(
                          text: 'Cadastre-se!',
                          style: GoogleFonts.poppins(
                            fontSize: fonteTexto * 0.8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0066FF),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                slidePageRoute(page: const CadastroScreen(), fromRight: true),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final double iconSize;
  final double fontSize;
  const PasswordField({super.key, required this.controller, required this.iconSize, required this.fontSize});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock, color: const Color(0xFFA2A2A7), size: widget.iconSize),
        SizedBox(width: widget.iconSize * 0.3),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            style: TextStyle(color: Colors.white, fontSize: widget.fontSize),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFA2A2A7),
            size: widget.iconSize,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ],
    );
  }
}
