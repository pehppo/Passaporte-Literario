import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  final Function(String?)? onProfileImageChanged;
  final String? currentName; 

  const EditProfileScreen({
    super.key, 
    this.onProfileImageChanged,
    this.currentName,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _aboutController;
  late TextEditingController _phoneController;
  
  late TextEditingController _dayController;
  late TextEditingController _monthController;
  late TextEditingController _yearController;

  String? photoUrl;
  File? localPhotoFile;
  bool _isLoading = false;

  final ImagePicker picker = ImagePicker();

  static const String _cloudinaryCloudName = 'CLOUDINARY_CLOUD_NAME';
  static const String _cloudinaryUploadPreset = 'CLOUDINARY_PRESET';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName ?? '');
    _emailController = TextEditingController();
    _aboutController = TextEditingController();
    _phoneController = TextEditingController();
    _dayController = TextEditingController();
    _monthController = TextEditingController();
    _yearController = TextEditingController();

    loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
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
        _nameController.text = data['nome'] ?? user.displayName ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _aboutController.text = data['about'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        
        _dayController.text = data['birthDay'] ?? '';
        _monthController.text = data['birthMonth'] ?? '';
        _yearController.text = data['birthYear'] ?? '';

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
          content: Text('Enviando foto de perfil...', style: GoogleFonts.poppins()),
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
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = (data['secure_url'] ?? data['url']) as String?;
      if (url == null) throw Exception('Cloudinary did not return a URL');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));

      setState(() {
        photoUrl = url;
      });
      
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      widget.onProfileImageChanged?.call(photoUrl);

    } catch (e) {
      debugPrint('Erro upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto.', style: GoogleFonts.poppins())),
        );
      }
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
      debugPrint('Erro ao remover foto: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final newName = _nameController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'nome': newName,
        'email': _emailController.text.isNotEmpty ? _emailController.text : user.email,
        'about': _aboutController.text,
        'phone': _phoneController.text,
        'birthDay': _dayController.text,
        'birthMonth': _monthController.text,
        'birthYear': _yearController.text,
      }, SetOptions(merge: true));

      if (newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil atualizado com sucesso!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar alterações.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        keyboardType: keyboardType,
        controller: controller,
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
                controller: _dayController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 27),
            SizedBox(
              width: 110,
              child: buildTextField(
                label: 'MM',
                controller: _monthController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 27),
            SizedBox(
              width: 70,
              child: buildTextField(
                label: 'AAAA',
                controller: _yearController,
                keyboardType: TextInputType.number,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF141425),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.poppins(
            color: Colors.white, 
            fontWeight: FontWeight.w600
          ),
        ),
        centerTitle: true,
      ),
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
              controller: _nameController,
            ),
            buildTextField(
              label: 'Sobre mim',
              controller: _aboutController,
            ),
            buildTextField(
              label: 'E-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            buildTextField(
              label: 'Celular',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            
            buildDateField(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFF141425))
                  : Text(
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