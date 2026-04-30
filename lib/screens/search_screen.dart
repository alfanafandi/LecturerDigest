import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/lecture_summary_view.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery?.toLowerCase() ?? "";
    _searchController.text = widget.initialQuery ?? "";
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: isDesktop ? 80 : 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 700 : double.infinity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari materi, topik, atau kata kunci...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5), fontSize: 16),
                  icon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.outlineVariant),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = "";
                });
              },
            ),
          if (isDesktop) const SizedBox(width: 24),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (_searchQuery.isEmpty) {
            return _buildInitialState(isDesktop);
          }

          final results = provider.lectures.where((lecture) {
            final title = (lecture['title'] ?? "").toString().toLowerCase();
            final transcript = (lecture['raw_transcript'] ?? "").toString().toLowerCase();
            final date = (lecture['lecture_date'] ?? "").toString().toLowerCase();
            
            return title.contains(_searchQuery) || 
                   transcript.contains(_searchQuery) ||
                   date.contains(_searchQuery);
          }).toList();

          if (results.isEmpty) {
            return _buildEmptyState(isDesktop);
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
              child: isDesktop 
                ? GridView.builder(
                    padding: const EdgeInsets.all(48),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 100,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) => _buildSearchResultCard(context, results[index]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: results.length,
                    itemBuilder: (context, index) => _buildSearchResultCard(context, results[index]),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.manage_search_rounded, size: isDesktop ? 120 : 80, color: AppTheme.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 32),
          Text(
            'Cari Materi Kuliah',
            style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w900, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Temukan ringkasan, transkrip, atau tanggal kuliah.',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: isDesktop ? 16 : 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: isDesktop ? 120 : 80, color: AppTheme.outlineVariant),
          const SizedBox(height: 32),
          Text(
            'Tidak Ditemukan',
            style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w900, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hasil untuk "$_searchQuery"',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba gunakan kata kunci yang lebih umum.',
            style: TextStyle(color: AppTheme.outlineVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Map<String, dynamic> lecture) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LectureSummaryView(lectureId: lecture['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.description_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture['title'] ?? 'Tanpa Judul',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lecture['lecture_date'] ?? '-',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
