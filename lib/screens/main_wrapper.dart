import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/screens/ask_ai_chat.dart';
import 'package:lecturer_digest/screens/home_dashboard.dart';
import 'package:lecturer_digest/screens/my_courses.dart';
import 'package:lecturer_digest/screens/new_lecture_recording.dart';
import 'package:lecturer_digest/screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final List<Widget> _pages = [
    const HomeDashboard(),
    const MyCourses(),
    const AskAiChat(isTab: true),
    const ProfileScreen(isTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final currentIndex = provider.currentTabIndex;

        return Scaffold(
          extendBody: true,
          body: _pages[currentIndex],
          floatingActionButton: currentIndex == 0 ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewLectureRecording()));
            },
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.mic, color: Colors.white, size: 28),
              ),
            ),
          ) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  provider.setTabIndex(index);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: const Color(0xFF5C5F5F),
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildIcon(Icons.home_filled, 0, 'Home', currentIndex),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildIcon(Icons.library_books_rounded, 1, 'Kelas', currentIndex),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildIcon(Icons.auto_awesome_rounded, 2, 'DigestBot', currentIndex),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildIcon(Icons.person_rounded, 3, 'Profil', currentIndex),
                    label: '',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(IconData iconData, int index, String label, int currentIndex) {
    final isActive = currentIndex == index;
    return isActive
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
  }
}
