import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Function(String?)? onProfileImageChanged;

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

  String? photoUrl;
  File? localPhotoFile;

  final ImagePicker picker = ImagePicker();

  static const String _cloudinaryCloudName = 'dtottvkil';
  static const String _cloudinaryUploadPreset = 'pass-liter';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      setState(() {
        email = data['email'] ?? user.email ?? '';
        username = data['name'] ?? user.displayName ?? '';
        sobreMim = data['about'] ?? '';
        celular = data['phone'] ?? '';
        dia = data['birthDay'] ?? '';
        mes = data['birthMonth'] ?? '';
        ano = data['birthYear'] ?? '';
        photoUrl = data['photoUrl'];
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
    }
  }

  Future<void> pickProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    setState(() {
      localPhotoFile = file;
    });

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enviando foto de perfil...',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(minutes: 1),
        ),
      );

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Cloudinary upload failed: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = (data['secure_url'] ?? data['url']) as String?;
      if (url == null) throw Exception('Cloudinary did not return a URL');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));

      if (username.isNotEmpty) {
        await user.updateDisplayName(username);
      }

      setState(() {
        photoUrl = url;
      });

      widget.onProfileImageChanged?.call(photoUrl);
    } catch (e, s) {
      debugPrint('Erro ao enviar imagem para o Storage: $e');
      debugPrint('$s');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao enviar foto: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  Future<void> removeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': FieldValue.delete()}, SetOptions(merge: true));

      setState(() {
        localPhotoFile = null;
        photoUrl = null;
      });

      widget.onProfileImageChanged?.call(null);
    } catch (e) {
      debugPrint('Erro ao remover foto de perfil: $e');
    }
  }

  Widget buildTextField({
    required String label,
    required String value,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        keyboardType: keyboardType,
        controller: controller,
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

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': username,
        'email': email.isNotEmpty ? email : user.email,
        'about': sobreMim,
        'phone': celular,
        'birthDay': dia,
        'birthMonth': mes,
        'birthYear': ano,
      }, SetOptions(merge: true));

      if (username.isNotEmpty) {
        await user.updateDisplayName(username);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar seu perfil.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
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
                  image: (() {
                    if (localPhotoFile != null) {
                      return DecorationImage(
                        image: FileImage(localPhotoFile!),
                        fit: BoxFit.cover,
                      );
                    }
                    if (photoUrl != null && photoUrl!.isNotEmpty) {
                      return DecorationImage(
                        image: NetworkImage(photoUrl!),
                        fit: BoxFit.cover,
                      );
                    }
                    return null;
                  })(),
                ),
                child: (localPhotoFile == null &&
                        (photoUrl == null || photoUrl!.isEmpty))
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            if (localPhotoFile != null || (photoUrl != null && photoUrl!.isNotEmpty))
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

            buildTextField(
              label: 'Nome',
              value: username,
              onChanged: (v) => username = v,
            ),
            buildTextField(
              label: 'Sobre mim',
              value: sobreMim,
              onChanged: (v) => sobreMim = v,
            ),
            buildTextField(
              label: 'E-mail',
              value: email,
              onChanged: (v) => email = v,
              keyboardType: TextInputType.emailAddress,
            ),
            buildTextField(
              label: 'Celular',
              value: celular,
              onChanged: (v) => celular = v,
              keyboardType: TextInputType.phone,
            ),
            buildDateField(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
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
