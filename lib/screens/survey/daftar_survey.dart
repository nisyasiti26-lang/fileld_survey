import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_nisya/screens/auth/login_page.dart';
import 'package:flutter_application_nisya/screens/survey/detail_survey.dart';
import 'package:flutter_application_nisya/screens/survey/tambah_edit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  List<Map<String, dynamic>> surveys = [];

  bool isLoading = true;

  String? errorMessage;

  final String apiUrl = 'https://sijala.biz.id/api/v1/surveys';

  // WARNA SESUAI GAMBAR DASHBOARD
  static const Color primaryColor = Color(0xFFF06292); // Pink Utama
  static const Color backgroundColor = Color(
    0xFFFCE4EC,
  ); // Soft Pink Background
  static const Color softPinkBadge = Color(
    0xFFF8BBD0,
  ); // Soft Pink untuk Badge/Card

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // =========================================================
  // AMBIL DATA SURVEY
  // =========================================================

  Future<void> fetchSurveys() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // TOKEN SUDAH TIDAK VALID
      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      // BERHASIL
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List rawList = data['data'];

          setState(() {
            surveys = rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            isLoading = false;
          });

          return;
        }
      }

      throw Exception(
        'Gagal memuat data '
        '(Kode: ${response.statusCode})',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Tidak dapat terhubung ke server. '
            'Periksa koneksi Anda.';
      });
    }
  }

  // =========================================================
  // DETAIL SURVEY
  // =========================================================

  Future<void> openDetail(int surveyId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyDetailPage(surveyId: surveyId),
      ),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // =========================================================
  // TAMBAH SURVEY
  // =========================================================

  Future<void> openAddSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SurveyFormPage()),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // =========================================================
  // NAMA KATEGORI
  // =========================================================

  String getCategoryName(Map<String, dynamic> survey) {
    if (survey['category_name'] != null &&
        survey['category_name'].toString().isNotEmpty) {
      return survey['category_name'].toString();
    }

    if (survey['category'] is Map && survey['category']['name'] != null) {
      return survey['category']['name'].toString();
    }

    return 'Tanpa Kategori';
  }

  // =========================================================
  // FORMAT TANGGAL
  // =========================================================

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Soft Pink Background
      appBar: AppBar(
        title: const Text('Daftar Survey'),
        backgroundColor: primaryColor, // Pink Utama Header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchSurveys,
        child: buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddSurvey,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Survey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget buildBody() {
    // LOADING
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat data survey...',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ERROR
    if (errorMessage != null && surveys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: fetchSurveys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // DATA KOSONG
    if (surveys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Data Survey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tekan tombol di bawah untuk '
                'menambah survey baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF880E4F)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: openAddSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Survey Baru'),
              ),
            ],
          ),
        ),
      );
    }

    // =========================================================
    // DAFTAR SURVEY
    // =========================================================

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        final survey = surveys[index];

        final id = int.tryParse(survey['id']?.toString() ?? '') ?? 0;

        final title = survey['title']?.toString() ?? '';

        final description = survey['description']?.toString() ?? '';

        final category = getCategoryName(survey);

        final date = formatDate(survey['created_at']?.toString());

        final lat = survey['latitude']?.toString() ?? '';

        final lng = survey['longitude']?.toString() ?? '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: softPinkBadge),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openDetail(id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JUDUL DAN KATEGORI
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF880E4F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: softPinkBadge, // Soft Pink Badge
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: primaryColor),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // DESKRIPSI
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: softPinkBadge, height: 1),
                  const SizedBox(height: 10),

                  // LOKASI DAN TANGGAL
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lat.isNotEmpty && lng.isNotEmpty
                              ? '$lat, $lng'
                              : 'Lokasi tidak tersedia',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF880E4F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF880E4F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
