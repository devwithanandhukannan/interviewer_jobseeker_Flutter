import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:interviewer/features/company/presentation/controller/companyProfile_controller.dart';
class CompanyProfileScreen extends ConsumerStatefulWidget {
  final String companyId;
  const CompanyProfileScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  int _activeTab = 0;
  static const _tabLabels = ['Overview', 'Offices', 'Jobs & Team'];
  static const _tabIcons = [Icons.business_outlined, Icons.map_outlined, Icons.people_outline];

  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Colors.white;
  static const _surfaceAlt = Color(0xFFF5F5F7);
  static const _border = Color(0xFFE5E5EA);
  static const _accent = Color(0xFF000000);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6E6E73);
  static const _textMuted = Color(0xFF86868B);
  static const _verifiedColor = Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(companyProfileControllerProvider.notifier)
        .fetchCompanyData(widget.companyId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyProfileControllerProvider).companyData;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Company Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: _border),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        error: (e, _) => _buildErrorState(e),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text('No information available for this company.', style: TextStyle(color: _textSecondary)),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(data),
                      _buildTabBar(),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildSelectedTabContent(data),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    ImageProvider? logoImage;
    final logoUrl = data['logoUrl']?.toString() ?? '';

    if (logoUrl.startsWith('data:image') && logoUrl.contains(',')) {
      try {
        logoImage = MemoryImage(base64Decode(logoUrl.split(',')[1].trim()));
      } catch (_) {}
    } else if (logoUrl.startsWith('http')) {
      logoImage = NetworkImage(logoUrl);
    }

    final isVerified = data['isVerified'] == true || data['verificationBadge'] == 'verified';

    return Container(
      color: _surface,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: logoImage != null
                ? Image(image: logoImage, fit: BoxFit.contain) // FIXED syntax error here
                : Center(
              child: Text(
                (data['name'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textMuted),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['name'] ?? 'Unknown Company',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 20, color: _verifiedColor),
              ]
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data['tagline'] ?? 'No tagline provided',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: data['tagline'] != null ? _textSecondary : _textMuted,
                fontStyle: data['tagline'] != null ? FontStyle.normal : FontStyle.italic
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetricBadge(Icons.layers_outlined, data['industry'] ?? 'Corporate'),
              const SizedBox(width: 8),
              _buildMetricBadge(Icons.pie_chart_outline, data['size'] ?? 'Scale N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _surface,
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabLabels.length, (i) {
              final isSelected = i == _activeTab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent : _surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_tabIcons[i], size: 16, color: isSelected ? Colors.white : _textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _tabLabels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(Map<String, dynamic> data) {
    switch (_activeTab) {
      case 0:
        return _buildOverviewTab(data);
      case 1:
        return _buildOfficesTab(data);
      case 2:
        return _buildJobsAndTeamTab(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final services = data['services'] as List? ?? [];
    final products = data['products'] as List? ?? [];
    final keywords = data['seoKeywords'] as List? ?? [];
    final coreValues = data['coreValues'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Corporate Identity', Icons.assignment_ind_outlined),
        _buildCard(
          Column(
            children: [
              _buildInfoRow('Industry Focus', data['industry'] ?? 'Not Specified'),
              _buildDivider(),
              _buildInfoRow('Company Size', data['size'] ?? 'Not Specified'),
              if (data['corporateLink'] != null) ...[
                _buildDivider(),
                _buildInfoRow('Official URL', data['corporateLink'], isLink: true),
              ]
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (coreValues.isNotEmpty) ...[
          _buildSectionHeader('Core Values', Icons.favorite_border),
          _buildCard(Wrap(
            spacing: 8, runSpacing: 8,
            children: coreValues.map((v) => _buildTag(v.toString())).toList(),
          )),
          const SizedBox(height: 24),
        ],

        _buildSectionHeader('Offerings & Portfolio', Icons.grid_view_outlined),
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Services Provided', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
              const SizedBox(height: 8),
              services.isEmpty
                  ? const Text('No explicit services cataloged yet.', style: TextStyle(fontSize: 13, color: _textMuted, fontStyle: FontStyle.italic))
                  : Wrap(spacing: 6, children: services.map((s) => _buildTag(s.toString())).toList()),

              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Container(height: 0.5, color: _border)),

              const Text('Products Ecosystem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
              const SizedBox(height: 8),
              products.isEmpty
                  ? const Text('No standalone specialized product arrays listed.', style: TextStyle(fontSize: 13, color: _textMuted, fontStyle: FontStyle.italic))
                  : Wrap(spacing: 6, children: products.map((p) => _buildTag(p.toString())).toList()),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (keywords.isNotEmpty) ...[
          _buildSectionHeader('Search Keywords', Icons.search),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: keywords.map((k) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(8)),
              child: Text('#$k', style: const TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildOfficesTab(Map<String, dynamic> data) {
    final offices = data['officeLocations'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('HQ & Branch Offices', Icons.location_on_outlined), // FIXED property typo here
        offices.isEmpty
            ? _buildCard(
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No listed geographic office operational parameters mapped.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMuted, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final office = offices[idx];
            return _buildCard(
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.storefront, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      office.toString(),
                      style: const TextStyle(fontSize: 15, color: _textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobsAndTeamTab(Map<String, dynamic> data) {
    final counts = data['_count'] ?? {};
    final activeJobs = data['activeJobsCount'] ?? counts['jobPostings'] ?? 0;
    final teamSize = data['teamSize'] ?? counts['teamMembers'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Operational Summary', Icons.analytics_outlined),
        Row(
          children: [
            Expanded(child: _buildMetricBlock('Active Job Openings', activeJobs.toString(), Icons.work_outline, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricBlock('Internal App Team', teamSize.toString(), Icons.people_outline, Colors.purple)),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Social Networks Connections', Icons.public_outlined),
        _buildCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSocialRow('YouTube Feed', data['youtubeLink']),
              _buildDivider(),
              _buildSocialRow('Corporate Domain', data['corporateLink']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBlock(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textPrimary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _textSecondary)),
          Flexible(
            child: Text(
              value?.toString() ?? 'N/A',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isLink ? _verifiedColor : _textPrimary,
                decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String channel, dynamic link) {
    final hasLink = link != null && link.toString().isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(channel, style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w500)),
        Text(
          hasLink ? 'Linked' : 'Not Connected',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasLink ? Colors.green : _textMuted
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(height: 0.5, color: _border),
  );

  Widget _buildErrorState(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _surfaceAlt, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: _textMuted),
          ),
          const SizedBox(height: 20),
          const Text('Failed to load company details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 8),
          Text(e.toString().contains('DioException') ? 'Network connection breakdown.' : e.toString(),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(companyProfileControllerProvider.notifier).fetchCompanyData(widget.companyId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Retry Execution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}