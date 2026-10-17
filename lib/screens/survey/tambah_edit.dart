import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_nisya/screens/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const SurveyFormPage({
    super.key,
    this.survey,
  });

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  static const Color primaryColor = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFBE185D);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color backgroundPink = Color(0xFFFFF7FB);
  static const Color textColor = Color(0xFF1F172A);
  static const Color secondaryText = Color(0xFF64748B);

  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  int? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  bool isSubmitting = false;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? existingImageBytes;

  bool get isEdit => widget.survey != null;

  String? get surveyId {
    final data = widget.survey;
    if (data == null) return null;

    final value = data['id'] ?? data['survey_id'] ?? data['surveyId'];

    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return value.toString();
  }

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final s = widget.survey!;

      titleController.text = s['title']?.toString() ?? '';

      final description = s['description']?.toString() ?? '';
      descriptionController.text = description == '-' ? '' : description;

      latitudeController.text = s['latitude']?.toString() ?? '';

      longitudeController.text = s['longitude']?.toString() ?? '';

      selectedCategoryId = int.tryParse(
        (s['category_id'] ?? s['category']?['id'])?.toString() ?? '',
      );

      final photo = s['photo']?.toString();

      if (photo != null && photo.isNotEmpty && photo != 'placeholder.jpg') {
        fetchExistingImage(photo);
      }
    }

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> fetchCategories() async {
    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/categories'),
        headers: {
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['data'] is List) {
          final List rawList = decoded['data'];

          final loadedCategories = rawList
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          if (!mounted) return;

          setState(() {
            categories = loadedCategories;
            isLoadingCategories = false;
          });

          return;
        }
      }

      debugPrint('CATEGORY RESPONSE: ${response.body}');
    } catch (e) {
      debugPrint('FETCH CATEGORIES ERROR: $e');
    }

    if (mounted) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> fetchExistingImage(String photoName) async {
    try {
      final token = await getToken();

      final fileName =
          photoName.contains('/') ? photoName.split('/').last : photoName;

      final response = await http.get(
        Uri.parse(
          'https://sijala.biz.id/api/image/$fileName',
        ),
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty &&
          mounted) {
        setState(() {
          existingImageBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      debugPrint('FETCH IMAGE ERROR: $e');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = pickedFile;
        selectedImageBytes = bytes;
      });
    } catch (e) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      existingImageBytes = null;
    });
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: backgroundPink,
                  leading: const CircleAvatar(
                    backgroundColor: lightPink,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: darkPink,
                    ),
                  ),
                  title: const Text('Galeri'),
                  subtitle: const Text('Pilih foto dari galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: backgroundPink,
                  leading: const CircleAvatar(
                    backgroundColor: lightPink,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: darkPink,
                    ),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil foto langsung'),
                  onTap: () {
                    Navigator.pop(ctx);
                    pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Future<void> saveSurvey() async {
    if (isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi.');
      return;
    }

    if (selectedCategoryId == null || selectedCategoryId == 0) {
      showErrorSnackBar('Kategori survey wajib dipilih.');
      return;
    }

    if (isEdit && surveyId == null) {
      showErrorSnackBar(
        'ID survey tidak ditemukan. Periksa data survey.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final token = await getToken();

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      final uri = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/save',
      );

      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['title'] = titleController.text.trim();

      request.fields['category_id'] = selectedCategoryId.toString();

      request.fields['description'] = descriptionController.text.trim();

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      if (isEdit) {
        request.fields['id'] = surveyId!;
        request.fields['_method'] = 'PUT';
      }

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('SAVE STATUS: ${response.statusCode}');
      debugPrint('SAVE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil disimpan!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      String message = 'Gagal menyimpan survey (${response.statusCode}).';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    } catch (e) {
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFFBCFE8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFFBCFE8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.8,
        ),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget formCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFBCFE8),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: darkPink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Survey' : 'Tambah Survey',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: lightPink,
        foregroundColor: darkPink,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF472B6),
                        Color(0xFFEC4899),
                        Color(0xFFBE185D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.22),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Perbarui Survey' : 'Field Survey',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isEdit
                                  ? 'Periksa dan ubah data survey'
                                  : 'Lengkapi informasi survey kamu',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                formCard(
                  title: 'Data Utama Survey',
                  icon: Icons.description_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldLabel('Judul Survey *'),
                      TextFormField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: fieldDecoration(
                          label: 'Judul Survey',
                          hint: 'Masukkan judul survey',
                          icon: Icons.title_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 17),
                      fieldLabel('Kategori Survey *'),
                      if (isLoadingCategories)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        )
                      else if (categories.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori gagal dimuat.',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  isLoadingCategories = true;
                                });
                                fetchCategories();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: categories.any((cat) =>
                                  int.tryParse(
                                    cat['id']?.toString() ?? '',
                                  ) ==
                                  selectedCategoryId)
                              ? selectedCategoryId
                              : null,
                          isExpanded: true,
                          decoration: fieldDecoration(
                            label: 'Kategori Survey',
                            hint: 'Pilih kategori survey',
                            icon: Icons.category_outlined,
                          ),
                          items: categories.map((cat) {
                            final id = int.tryParse(
                                  cat['id']?.toString() ?? '',
                                ) ??
                                0;

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                cat['name']?.toString() ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return 'Kategori wajib dipilih';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 17),
                      fieldLabel('Deskripsi Survey'),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: fieldDecoration(
                          label: 'Deskripsi',
                          hint: 'Keterangan atau catatan survey...',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                formCard(
                  title: 'Foto Survey',
                  icon: Icons.photo_camera_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambahkan foto sebagai dokumentasi survey.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (selectedImageBytes != null ||
                          existingImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            selectedImageBytes ?? existingImageBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        InkWell(
                          onTap: showImageSourceDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 155,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: backgroundPink,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF9A8D4),
                                width: 1.3,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: lightPink,
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    color: darkPink,
                                    size: 27,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Ketuk untuk memilih foto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: darkPink,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pilih dari galeri atau kamera',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: showImageSourceDialog,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                              ),
                              label: Text(
                                selectedImageBytes != null ||
                                        existingImageBytes != null
                                    ? 'Ganti Foto'
                                    : 'Pilih Foto',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: darkPink,
                                side: const BorderSide(
                                  color: primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (selectedImageBytes != null ||
                              existingImageBytes != null) ...[
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: removeSelectedImage,
                              tooltip: 'Hapus foto',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF2F2),
                                foregroundColor: const Color(0xFFEF4444),
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                formCard(
                  title: 'Lokasi Survey',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masukkan koordinat lokasi jika tersedia.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Latitude'),
                                TextFormField(
                                  controller: latitudeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: fieldDecoration(
                                    label: 'Latitude',
                                    hint: '-7.3274000',
                                    icon: Icons.my_location_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Longitude'),
                                TextFormField(
                                  controller: longitudeController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: fieldDecoration(
                                    label: 'Longitude',
                                    hint: '108.2207000',
                                    icon: Icons.explore_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : saveSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: const Color(0xFFF9A8D4),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.save_as_rounded
                                    : Icons.save_rounded,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isEdit ? 'Simpan Perubahan' : 'Simpan Survey',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
