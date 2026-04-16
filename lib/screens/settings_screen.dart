import 'package:flutter/material.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.background.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('LectureDigest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Profile Header
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAL6O0ziGcisVOnxvZHWOV94lv5TjrTx45VUk4IuWFJbIL6s703jWvUvjk1blpFmExrtQNkPCv9252clUcJNJG7xYtwJ4LRzPvwWHXDGhvrr655EFoRKXoxpqwDkvo1ujymTlSgHvNY6Z7Md3i-pqjHhhJN7GRbtr70q8aff8Ux8YG1Hn5RS_WqYnAITJAG0bwf72DGxy7Q1iZ7N8GxFW_mknCzd-R5lUyTJughS7R9VlGigu9cfS7VIKmxwLwoeJV0J9H-Kx_PUIfR'), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PREMIUM MEMBER', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text('Andi Pratama', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.school, size: 14, color: AppTheme.onSurfaceVariant),
                          SizedBox(width: 4),
                          Text('Informatics Major, Year 3', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16)]),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                )
              ],
            ),
            const SizedBox(height: 32),



            // Settings Items
            _buildSettingsItem(Icons.person_outline, 'Account', 'Security, Email, and Subscription', AppTheme.secondary),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_suggest, color: AppTheme.tertiary)),
                      const SizedBox(width: 12),
                      const Text('App Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Toggle system-wide dark theme', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
                        ],
                      ),
                      Switch(value: false, onChanged: (v){}, activeColor: AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Current: English (US)', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
                        ],
                      ),
                      const Text('Change', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSmallSettingItem(Icons.notifications, 'Notifications')),
                const SizedBox(width: 12),
                Expanded(child: _buildSmallSettingItem(Icons.help, 'Help & Support')),
              ],
            ),
            const SizedBox(height: 32),

            // Logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Logout Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildSmallSettingItem(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }
}
