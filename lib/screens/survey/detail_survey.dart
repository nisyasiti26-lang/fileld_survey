import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_nisya/screens/auth/login_page.dart';
import 'package:flutter_application_nisya/screens/survey/tambah_edit.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  // WEMA WARNA PINK SESUAI DASHBOARD / DAFTAR SURVEY
  static const Color primaryColor = Color(0xFFF06292); // Pink Utama
  static const Color darkPink = Color(0xFF880E4F); // Teks & Ikon Pink Gelap
  static const Color lightPink = Color(0xFFF8BBD0); // Soft Pink Badge / Border
  static const Color backgroundPink = Color(0xFFFCE4EC); // Soft Pink Background
  static const Color textColor = Color(0xFF880E4F); // Warna Teks

  static const String apiBaseUrl = 'https://sijala.biz.id/api/v1';

  Map<String, dynamic>? survey;
  bool isLoading = true;
  bool isLoadingImage = false;
  bool isDeleting = false;

  String? errorMessage;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return token == null || token.isEmpty ? null : token;
  }

  Future<void> goToLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> fetchDetail() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      imageBytes = null;
    });

    try {
      final token = await getToken();

      if (token == null) {
        await goToLogin();
        return;
      }

      final url = Uri.parse('$apiBaseUrl/surveys/${widget.surveyId}');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await goToLogin();
        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result is Map &&
            result['status'] == true &&
            result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);

          if (!mounted) return;

          setState(() {
            survey = data;
            isLoading = false;
          });

          final photo = data['photo']?.toString();

          if (photo != null && photo.isNotEmpty && photo != 'placeholder.jpg') {
            await fetchImage(photo, token);
          }

          return;
        }
      }

      throw Exception('Gagal mengambil data survey.');
    } catch (e) {
      debugPrint('GET DETAIL ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Gagal memuat detail survey.\n'
            'Periksa koneksi internet Anda.';
      });
    }
  }

  Future<void> fetchImage(String photoName, String token) async {
    if (!mounted) return;

    setState(() {
      isLoadingImage = true;
    });

    try {
      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final url = Uri.parse('https://sijala.biz.id/api/image/$fileName');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          imageBytes = response.bodyBytes;
          isLoadingImage = false;
        });

        return;
      }
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      isLoadingImage = false;
    });
  }

  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Survey'),
        content: const Text('Apakah Anda yakin ingin menghapus survey ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: darkPink)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => isDeleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$apiBaseUrl/surveys/${widget.surveyId}/delete'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      setState(() => isDeleting = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey berhasil dihapus'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus survey '
              '(Kode: ${response.statusCode})',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      debugPrint('DELETE SURVEY ERROR: $e');

      if (!mounted) return;

      setState(() => isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menghapus survey.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> editSurvey() async {
    if (survey == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyFormPage(survey: survey)),
    );

    if (result == true && mounted) {
      await fetchDetail();
    }
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    } catch (e) {
      debugPrint('GOOGLE MAPS ERROR: $e');
    }
  }

  void copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Koordinat berhasil disalin!')),
    );
  }

  void showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: lightPink),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: cardDecoration(),
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: const Text(
          'Detail Survey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (survey != null) ...[
            IconButton(
              onPressed: isDeleting ? null : editSurvey,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Survey',
            ),
            IconButton(
              onPressed: isDeleting ? null : deleteSurvey,
              icon: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Hapus Survey',
            ),
          ],
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat detail survey...',
              style: TextStyle(color: darkPink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null || survey == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Survey tidak ditemukan',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final title = survey!['title']?.toString() ?? '';
    final description = survey!['description']?.toString() ?? '';

    final category =
        survey!['category_name']?.toString() ??
        (survey!['category'] is Map
            ? survey!['category']['name']?.toString()
            : null) ??
        'Tanpa Kategori';

    final date = survey!['created_at']?.toString() ?? '';

    final lat = double.tryParse(survey!['latitude']?.toString() ?? '');

    final lng = double.tryParse(survey!['longitude']?.toString() ?? '');

    final hasValidCoords = lat != null && lng != null;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KARTU INFORMASI SURVEY
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Waktu: $date',
                        style: const TextStyle(fontSize: 12, color: darkPink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // KARTU FOTO SURVEY
          sectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Foto Survey',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (isLoadingImage)
                  const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                else if (imageBytes != null)
                  GestureDetector(
                    onTap: () {
                      showFullImageDialog(imageBytes!);
                    },
                    child: Image.memory(
                      imageBytes!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 130,
                    width: double.infinity,
                    color: lightPink.withValues(alpha: 0.3),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 34,
                          color: primaryColor,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tidak ada foto survey',
                          style: TextStyle(color: darkPink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          // KARTU DESKRIPSI
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description.isEmpty ? 'Tidak ada deskripsi.' : description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: darkPink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // KARTU LOKASI SURVEY
          sectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Survey',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasValidCoords
                            ? 'Koordinat: $lat, $lng'
                            : 'Koordinat tidak tersedia',
                        style: const TextStyle(fontSize: 12, color: darkPink),
                      ),
                    ],
                  ),
                ),
                if (hasValidCoords) ...[
                  // PETA
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.flutter_appl_latihan',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_on,
                                color: primaryColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // TOMBOL KOORDINAT DAN GOOGLE MAPS
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              copyCoordinates(lat, lng);
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Salin Koordinat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: darkPink,
                              side: const BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              openGoogleMaps(lat, lng);
                            },
                            icon: const Icon(Icons.map_outlined, size: 16),
                            label: const Text('Buka Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: lightPink.withValues(alpha: 0.3),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 36,
                              color: primaryColor,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Peta tidak tersedia '
                              '(koordinat kosong)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: darkPink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
