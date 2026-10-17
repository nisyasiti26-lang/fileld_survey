import 'package:flutter/material.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();

  // Tema pink
  static const Color primaryColor = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFBE185D);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color backgroundPink = Color(0xFFFFF7FB);
  static const Color textColor = Color(0xFF1F172A);

  final TextEditingController namaController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController usiaController = TextEditingController();

  String? kategori;
  String? jenisKelamin;

  @override
  void dispose() {
    namaController.dispose();
    lokasiController.dispose();
    usiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,

      // APP BAR
      appBar: AppBar(
        backgroundColor: lightPink,
        foregroundColor: darkPink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Data Survey',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field Survey',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Isi data responden dengan lengkap',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // JUDUL
              const Text(
                'Data Responden',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 15),

              // NAMA
              _inputField(
                controller: namaController,
                label: 'Nama Responden',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 15),

              // USIA
              _inputField(
                controller: usiaController,
                label: 'Usia',
                hint: 'Masukkan usia',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),

              // JENIS KELAMIN
              _dropdownField(
                value: jenisKelamin,
                label: 'Jenis Kelamin',
                hint: 'Pilih jenis kelamin',
                icon: Icons.wc_rounded,
                items: const [
                  'Laki-laki',
                  'Perempuan',
                ],
                onChanged: (value) {
                  setState(() {
                    jenisKelamin = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // KATEGORI SURVEY
              _dropdownField(
                value: kategori,
                label: 'Kategori Survey',
                hint: 'Pilih kategori',
                icon: Icons.category_outlined,
                items: const [
                  'Individu',
                  'Rumah Tangga',
                  'Lingkungan',
                  'Sosial',
                  'Kesehatan',
                ],
                onChanged: (value) {
                  setState(() {
                    kategori = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // LOKASI
              _inputField(
                controller: lokasiController,
                label: 'Lokasi Survey',
                hint: 'Masukkan lokasi survey',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 25),

              // INFORMASI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: darkPink,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pastikan seluruh data responden '
                        'sudah benar sebelum menyimpan survey.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _simpanSurvey,
                  icon: const Icon(
                    Icons.save_rounded,
                  ),
                  label: const Text(
                    'Simpan Survey',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(
          Icons.edit_outlined,
          color: primaryColor,
        ),
        // Ikon khusus tetap sesuai field
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFFBCFE8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ).copyWith(
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
      ),
    );
  }

  // DROPDOWN FIELD
  Widget _dropdownField({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label wajib dipilih';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFFBCFE8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
      dropdownColor: Colors.white,
      iconEnabledColor: primaryColor,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              color: textColor,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // SIMPAN SURVEY
  void _simpanSurvey() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data survey berhasil disimpan!',
        ),
        backgroundColor: primaryColor,
      ),
    );
  }
}
