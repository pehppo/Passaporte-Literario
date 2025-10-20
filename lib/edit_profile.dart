import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart'; // CustomTopBar

class EditProfileScreen extends StatefulWidget {
  final Function(File?)? onProfileImageChanged;

  const EditProfileScreen({super.key, this.onProfileImageChanged});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String username = '';
  String email = '';
  String sobreMim = '';
  String celular = '';
  String dia = '';
  String mes = '';
  String ano = '';
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedEmail = prefs.getString('logged_email');
    if (loggedEmail != null) {
      setState(() {
        email = loggedEmail;
        username = prefs.getString('${loggedEmail}_nome') ?? '';
        sobreMim = prefs.getString('${loggedEmail}_sobre_mim') ?? '';
        celular = prefs.getString('${loggedEmail}_celular') ?? '';
        dia = prefs.getString('${loggedEmail}_dia') ?? '';
        mes = prefs.getString('${loggedEmail}_mes') ?? '';
        ano = prefs.getString('${loggedEmail}_ano') ?? '';
        final imagePath = prefs.getString('${loggedEmail}_profile_image');
        if (imagePath != null) profileImage = File(imagePath);
      });
    }
  }

  Future<void> pickProfileImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      final loggedEmail = prefs.getString('logged_email');
      if (loggedEmail != null) {
        await prefs.setString('${loggedEmail}_profile_image', image.path);
      }
      setState(() => profileImage = File(image.path));
      widget.onProfileImageChanged?.call(profileImage);
    }
  }

  Future<void> removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedEmail = prefs.getString('logged_email');
    if (loggedEmail != null) {
      await prefs.remove('${loggedEmail}_profile_image');
    }
    setState(() => profileImage = null);
    widget.onProfileImageChanged?.call(null);
  }

  Widget buildTextField({
    required String label,
    required String value,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        keyboardType: keyboardType,
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF232533)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data de Nascimento',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: buildTextField(
                label: 'DD',
                value: dia,
                keyboardType: TextInputType.number,
                onChanged: (v) => dia = v,
              ),
            ),
            const SizedBox(width: 27),
            SizedBox(
              width: 110,
              child: buildTextField(
                label: 'MM',
                value: mes,
                keyboardType: TextInputType.number,
                onChanged: (v) => mes = v,
              ),
            ),
            const SizedBox(width: 27),
            SizedBox(
              width: 70,
              child: buildTextField(
                label: 'AAAA',
                value: ano,
                keyboardType: TextInputType.number,
                onChanged: (v) => ano = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      appBar: const CustomTopBar(title: 'Editar Perfil', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                  image: profileImage != null
                      ? DecorationImage(image: FileImage(profileImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: profileImage == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: removeProfileImage,
              child: Text(
                'Remover Foto de Perfil',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 25),

            buildTextField(label: 'Nome', value: username, onChanged: (v) => username = v),
            buildTextField(label: 'Sobre mim', value: sobreMim, onChanged: (v) => sobreMim = v),
            buildTextField(label: 'E-mail', value: email, onChanged: (v) => email = v),
            buildTextField(label: 'Celular', value: celular, onChanged: (v) => celular = v),
            buildDateField(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final loggedEmail = prefs.getString('logged_email');
                  if (loggedEmail != null) {
                    await prefs.setString('${loggedEmail}_nome', username);
                    await prefs.setString('${loggedEmail}_sobre_mim', sobreMim);
                    await prefs.setString('${loggedEmail}_celular', celular);
                    await prefs.setString('${loggedEmail}_dia', dia);
                    await prefs.setString('${loggedEmail}_mes', mes);
                    await prefs.setString('${loggedEmail}_ano', ano);
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text(
                  'Salvar alterações',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF141425),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
