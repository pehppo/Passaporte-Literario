// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool _erroCadastro = false;
  String _mensagemErro = '';

  PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    bool fromRight = true,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final beginOffset = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final endOffset = Offset.zero;
        final tween = Tween(begin: beginOffset, end: endOffset).chain(
          CurveTween(curve: Curves.easeInOut),
        );
        return SlideTransition(position: animation.drive(tween), child: child);
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
                    child: Image.asset('assets/images/logo.png'),
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

                Text(
                  'Insira seu Nome de Usuário',
                  style: GoogleFonts.poppins(
                    fontSize: fonteTexto * 0.875,
                    color: const Color(0xFFA2A2A7),
                  ),
                ),
                SizedBox(height: espacamentoEntreCampos),
                Container(
                  height: campoHeight,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF232533)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: const Color(0xFFA2A2A7), size: screenWidth * 0.06),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: TextField(
                          controller: nomeController,
                          style: TextStyle(color: Colors.white, fontSize: fonteTexto),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: espacamentoEntreCampos),
                Text(
                  'Insira seu e-mail',
                  style: GoogleFonts.poppins(
                    fontSize: fonteTexto * 0.875,
                    color: const Color(0xFFA2A2A7),
                  ),
                ),
                SizedBox(height: espacamentoEntreCampos),
                Container(
                  height: campoHeight,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF232533)),
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

                SizedBox(height: espacamentoEntreCampos),
                Text(
                  'Senha',
                  style: GoogleFonts.poppins(
                    fontSize: fonteTexto * 0.875,
                    color: const Color(0xFFA2A2A7),
                  ),
                ),
                Container(
                  height: campoHeight,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF232533))),
                  ),
                  child: PasswordField(
                    controller: senhaController,
                    iconSize: screenWidth * 0.06,
                    fontSize: fonteTexto,
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                SizedBox(
                  width: double.infinity,
                  height: campoHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nome = nomeController.text.trim();
                      final email = emailController.text.trim();
                      final senha = senhaController.text.trim();
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                      setState(() {
                        _erroCadastro = false;
                        _mensagemErro = '';
                      });

                      if (nome.isEmpty || email.isEmpty || senha.isEmpty || !emailRegex.hasMatch(email)) {
                        setState(() {
                          _erroCadastro = true;
                          _mensagemErro = 'Preencha todos os campos corretamente';
                        });
                        return;
                      }

                      try {
                        final cred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(email: email, password: senha);

                        final user = cred.user;
                        if (user == null) throw Exception('Usuário nulo');

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'nome': nome,
                          'email': email,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!user.emailVerified) {
                          await user.sendEmailVerification();
                        }

                        await FirebaseAuth.instance.signOut();

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text(
                               'Conta criada com sucesso! Verifique seu e-mail para validar a conta antes de entrar.',
                               style: GoogleFonts.poppins(),
                             ),
                             backgroundColor: Colors.green,
                             duration: const Duration(seconds: 5),
                           ),
                        );

                        Navigator.pushReplacement(
                          context,
                          slidePageRoute(
                            page: const LoginScreen(),
                            fromRight: false,
                          ),
                        );
                        
                      } on FirebaseAuthException catch (e) {
                        String msg;
                        if (e.code == 'email-already-in-use') {msg = 'Este e-mail já está em uso.';}
                        else if (e.code == 'weak-password') {msg = 'A senha é muito fraca.';}
                        else if (e.code == 'invalid-email') {msg = 'E-mail inválido.';}
                        else {msg = 'Erro: ${e.code.replaceAll('-', ' ')}';}

                        setState(() {
                          _erroCadastro = true;
                          _mensagemErro = msg;
                        });
                      } catch (e) {
                        setState(() {
                          _erroCadastro = true;
                          _mensagemErro = 'Erro inesperado. Tente novamente.';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    child: Text(
                      'Cadastrar',
                      style: GoogleFonts.poppins(
                        fontSize: fonteBotao,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141425),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                if (_erroCadastro)
                  Text(
                    _mensagemErro,
                    style: GoogleFonts.poppins(
                      fontSize: fonteTexto * 0.8,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),

                SizedBox(height: screenHeight * 0.03),

                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Já tem uma conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: fonteTexto * 0.8,
                        color: const Color(0xFFA2A2A7),
                      ),
                      children: [
                        TextSpan(
                          text: 'Entrar',
                          style: GoogleFonts.poppins(
                            fontSize: fonteTexto * 0.8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0066FF),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                slidePageRoute(
                                  page: const LoginScreen(),
                                  fromRight: false,
                                ),
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

  const PasswordField({
    super.key,
    required this.controller,
    required this.iconSize,
    required this.fontSize,
  });

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
            decoration: const InputDecoration(border: InputBorder.none),
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