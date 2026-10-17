import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_nisya/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // API
  static const String baseUrl = 'https://sijala.biz.id/api/v1';
  static const String profileEndpoint = '$baseUrl/profile';
  static const String imageEndpoint = 'https://sijala.biz.id/api/image';

  // Tema pink
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFBE185D);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color backgroundPink = Color(0xFFFFF7FB);

  Map<String, dynamic>? profile;
  Future<Uint8List?>? profileImageFuture;

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  String? selectedGender;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    phoneController = TextEditingController();

    getProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Mengambil data profil
  Future<void> getProfile() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final profileData = Map<String, dynamic>.from(data['data'] as Map);

        final photo = profileData['photo']?.toString();
        final genderValue = profileData['gender']?.toString();

        if (!mounted) return;

        setState(() {
          profile = profileData;

          nameController.text = profileData['name']?.toString() ?? '';
          phoneController.text = profileData['phone']?.toString() ?? '';

          // Pastikan value gender valid ('Laki-laki' atau 'Perempuan') jika ada di database
          if (genderValue == 'Laki-laki' || genderValue == 'Perempuan') {
            selectedGender = genderValue;
          } else {
            selectedGender = null;
          }

          profileImageFuture = photo != null && photo.isNotEmpty
              ? fetchProfileImage(photo)
              : null;

          isLoading = false;
        });
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mengambil data profil.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: darkPink,
        ),
      );
    }
  }

  // Memperbarui profil
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Silakan login kembali.');
      }

      final response = await http.post(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'gender': selectedGender ?? '',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        if (!mounted) return;

        setState(() {
          isEditing = false;
          isSaving = false;
        });

        await getProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui 💗'),
            backgroundColor: primaryPink,
          ),
        );
      } else {
        throw Exception(
          data['message'] ?? 'Gagal memperbarui profil.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: darkPink,
        ),
      );
    }
  }

  // Mengambil foto profil
  Future<Uint8List?> fetchProfileImage(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$imageEndpoint/$fileName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: darkPink),
            SizedBox(width: 10),
            Expanded(child: Text('Konfirmasi Logout')),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;
        context.go(AppRoutes.login);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: primaryPink,
          ),
        );

        context.go(AppRoutes.login);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout gagal. Silakan coba lagi.'),
            backgroundColor: darkPink,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server.'),
          backgroundColor: darkPink,
        ),
      );
    }
  }

  // Kartu putih
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: primaryPink.withValues(alpha: 0.07),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // Ikon kecil pada informasi profil
  Widget infoIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: darkPink,
        size: 21,
      ),
    );
  }

  // Baris informasi seperti pada gambar
  Widget infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: cardDecoration(),
      child: Row(
        children: [
          infoIcon(icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Foto profil
  Widget profileAvatar() {
    final photo = profile?['photo']?.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: primaryPink.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPink.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 47,
            backgroundColor: lightPink,
            child: photo != null && photo.isNotEmpty
                ? FutureBuilder<Uint8List?>(
                    future: profileImageFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryPink,
                          ),
                        );
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        return ClipOval(
                          child: Image.memory(
                            snapshot.data!,
                            width: 94,
                            height: 94,
                            fit: BoxFit.cover,
                          ),
                        );
                      }

                      return const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: primaryPink,
                      );
                    },
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: primaryPink,
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 1,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: primaryPink,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Header profil
  Widget profileHeader() {
    final name = profile?['name']?.toString() ?? 'Pengguna';
    final email = profile?['email']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      child: Column(
        children: [
          profileAvatar(),
          const SizedBox(height: 17),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252536),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Tombol aksi lebar
  Widget actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: darkPink,
                side: const BorderSide(
                  color: Color(0xFFE8A0C4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // Tampilan profil
  Widget profileCard() {
    if (profile == null) {
      return const Center(
        child: Text('Data profil tidak ditemukan.'),
      );
    }

    return Column(
      children: [
        profileHeader(),
        infoRow(
          icon: Icons.person_outline_rounded,
          label: 'Nama',
          value: profile!['name']?.toString() ?? '-',
        ),
        infoRow(
          icon: Icons.alternate_email_rounded,
          label: 'Username',
          value: profile!['username']?.toString() ?? '-',
        ),
        infoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile!['email']?.toString() ?? '-',
        ),
        infoRow(
          icon: Icons.phone_outlined,
          label: 'Nomor HP',
          value: profile!['phone']?.toString() ?? '-',
        ),
        infoRow(
          icon: Icons.wc_rounded,
          label: 'Jenis Kelamin',
          value: profile!['gender']?.toString() ?? '-',
        ),
        const SizedBox(height: 7),
        actionButton(
          icon: Icons.edit_rounded,
          title: 'Edit Profil',
          onPressed: () {
            setState(() => isEditing = true);
          },
        ),
        const SizedBox(height: 10),
        actionButton(
          icon: Icons.logout_rounded,
          title: 'Logout',
          outlined: true,
          onPressed: logout,
        ),
      ],
    );
  }

  // Input form pink
  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryPink),
      filled: true,
      fillColor: const Color(0xFFFFF9FC),
      labelStyle: const TextStyle(color: darkPink),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFF3C5DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFF3C5DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryPink,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // Form edit profil
  Widget editProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.manage_accounts_rounded,
                  color: primaryPink,
                  size: 27,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit Informasi Profil',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252536),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Perbarui informasi diri kamu di bawah ini.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 23),
            TextFormField(
              controller: nameController,
              decoration: inputDecoration(
                'Nama Lengkap',
                Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: inputDecoration(
                'Nomor HP',
                Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: inputDecoration(
                'Jenis Kelamin',
                Icons.wc_rounded,
              ),
              dropdownColor: const Color(0xFFFFF9FC),
              items: const [
                DropdownMenuItem(
                  value: 'Laki-laki',
                  child: Text('Laki-laki'),
                ),
                DropdownMenuItem(
                  value: 'Perempuan',
                  child: Text('Perempuan'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pilih jenis kelamin terlebih dahulu';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            setState(() => isEditing = false);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkPink,
                      side: const BorderSide(color: primaryPink),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Profil' : 'Profil',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: isSaving
                    ? null
                    : () {
                        setState(() => isEditing = false);
                      },
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryPink,
          onRefresh: getProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 25),
            child: isLoading
                ? const SizedBox(
                    height: 350,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryPink,
                      ),
                    ),
                  )
                : isEditing
                    ? editProfileCard()
                    : profileCard(),
          ),
        ),
      ),
    );
  }
}
  