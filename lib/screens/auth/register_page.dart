import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final noHpController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmasiPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String gender = 'P';

  // TEMA WARNA PINK
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFBE185D);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color backgroundPink = Color(0xFFFFF7FB);

  // REGISTER KE API
  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://sijala.biz.id/api/v1/register'),
      );

      request.fields['name'] = nameController.text.trim();
      request.fields['phone'] = noHpController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['gender'] = gender;
      request.fields['password'] = passwordController.text;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('RESPONSE: $responseBody');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Register berhasil'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) return;

        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Register gagal: $responseBody'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat terhubung ke server: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    noHpController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmasiPasswordController.dispose();
    super.dispose();
  }

  // STYLE INPUT PINK
  InputDecoration inputStyle({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: darkPink),
      prefixIcon: Icon(icon, color: primaryPink),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF9A8D4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF9A8D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryPink,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,

      // APP BAR
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: lightPink,
        foregroundColor: darkPink,
        elevation: 0,
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFCE7F3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // IKON REGISTER
                        Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF472B6),
                                Color(0xFFEC4899),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPink.withValues(
                                  alpha: 0.20,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            size: 55,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Buat Akun',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkPink,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Daftar akun Field Survey Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9D174D),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // NAMA
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: inputStyle(
                            label: 'Nama',
                            icon: Icons.person_outline,
                            hint: 'Masukkan nama lengkap',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // NOMOR HP
                        TextFormField(
                          controller: noHpController,
                          keyboardType: TextInputType.phone,
                          decoration: inputStyle(
                            label: 'Nomor HP',
                            icon: Icons.phone_outlined,
                            hint: '08xxxxxxxxxx',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor HP wajib diisi';
                            }

                            if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                              return 'Nomor HP hanya boleh angka';
                            }

                            if (value.trim().length < 10) {
                              return 'Nomor HP minimal 10 angka';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: inputStyle(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            hint: 'Masukkan email aktif',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // JENIS KELAMIN
                        DropdownButtonFormField<String>(
                          value: gender,
                          decoration: inputStyle(
                            label: 'Jenis Kelamin',
                            icon: Icons.wc_outlined,
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'L',
                              child: Text('Laki-laki'),
                            ),
                            DropdownMenuItem(
                              value: 'P',
                              child: Text('Perempuan'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                gender = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: inputStyle(
                            label: 'Password',
                            icon: Icons.lock_outline,
                            hint: 'Minimal 6 karakter',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryPink,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // KONFIRMASI PASSWORD
                        TextFormField(
                          controller: confirmasiPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: inputStyle(
                            label: 'Konfirmasi Password',
                            icon: Icons.lock_reset,
                            hint: 'Ulangi password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryPink,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password wajib diisi';
                            }

                            if (value != passwordController.text) {
                              return 'Password tidak sama';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 26),

                        // TOMBOL REGISTER
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPink,
                              disabledBackgroundColor: const Color(0xFFF9A8D4),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // LINK LOGIN
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.go('/login');
                                },
                          child: const Text.rich(
                            TextSpan(
                              text: 'Sudah punya akun? ',
                              style: TextStyle(
                                color: Color(0xFF9D174D),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: darkPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
