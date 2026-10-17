import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String userName = 'Pengguna';

  // Variabel data ringkasan survey
  int totalSurvey = 0;
  int selesaiSurvey = 0;
  int pendingSurvey = 0;
  bool isLoadingSummary = true;
  Map<String, dynamic>? latestSurvey;

  // PALET WARNA PINK
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);
  static const Color lightPink = Color(0xFFF8BBD0);
  static const Color backgroundPink = Color(0xFFFCE4EC);

  static const String apiUrl = 'https://sijala.biz.id/api/v1/surveys';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSurveySummary();
  }

  // MENGAMBIL NAMA USER DARI SHAREDPREFERENCES
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null && userString.isNotEmpty) {
        final userData = jsonDecode(userString);
        if (userData is Map && userData['name'] != null) {
          setState(() {
            userName = userData['name'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // MENGAMBIL RINGKASAN DATA SURVEY DARI API
  Future<void> _fetchSurveySummary() async {
    setState(() {
      isLoadingSummary = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          isLoadingSummary = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List rawList = data['data'];

          final surveyList = rawList
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          setState(() {
            totalSurvey = surveyList.length;
            pendingSurvey =
                surveyList.length; // Mengikuti jumlah survey yang ada
            selesaiSurvey = 0;
            latestSurvey = surveyList.isNotEmpty ? surveyList.first : null;
            isLoadingSummary = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching survey summary: $e');
    }

    if (mounted) {
      setState(() {
        isLoadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () {
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      // KONTEN DASHBOARD
      body: RefreshIndicator(
        color: primaryPink,
        onRefresh: _fetchSurveySummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TEKS SAMBUTAN DINAMIS
              Text(
                'Halo, $userName 👋',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 14),

              // BANNER KELOLA SURVEY
              InkWell(
                onTap: () async {
                  await context.push(AppRoutes.survey);
                  _fetchSurveySummary();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF48FB1),
                        Color(0xFFEC4899),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelola Survey',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pantau dan kelola data survey kamu dengan mudah.',
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
              ),

              const SizedBox(height: 24),

              // JUDUL RINGKASAN SURVEY
              const Text(
                'Ringkasan Survey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),
              const SizedBox(height: 12),

              // KARTU RINGKASAN (TOTAL, SELESAI, PENDING)
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.assignment,
                      title: isLoadingSummary ? '...' : '$totalSurvey',
                      subtitle: 'Total',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.check_circle,
                      title: isLoadingSummary ? '...' : '$selesaiSurvey',
                      subtitle: 'Selesai',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.pending_actions,
                      title: isLoadingSummary ? '...' : '$pendingSurvey',
                      subtitle: 'Pending',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // BAGIAN SURVEY TERBARU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Survey Terbaru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkPink,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await context.push(AppRoutes.survey);
                      _fetchSurveySummary();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: primaryPink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // KARTU PREVIEW SURVEY TERBARU
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lightPink),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, color: primaryPink, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        latestSurvey != null
                            ? '${latestSurvey!['title'] ?? 'Survey Baru'}\nCatatan: Terdata $totalSurvey survey.'
                            : 'Belum ada data survey terbaru.',
                        style: const TextStyle(
                          color: darkPink,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // NAVIGASI BAWAH
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryPink,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        onTap: (index) {
          if (index == _selectedIndex) {
            if (index == 0) {
              context.go(AppRoutes.dashboard);
            }
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            context.go(AppRoutes.dashboard);
          } else if (index == 1) {
            context.push(AppRoutes.survey);
          } else if (index == 2) {
            context.push(AppRoutes.profile);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Survey',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // WIDGET KARTU RINGKASAN
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightPink),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: backgroundPink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryPink, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkPink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
