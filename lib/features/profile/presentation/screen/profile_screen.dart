import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'package:interviewer/features/profile/presentation/controller/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTab = 0;
  bool _saving = false;
  bool _populated = false;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _rolesCtrl = TextEditingController();
  final _industriesCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _newSkillCtrl = TextEditingController();
  String? _profileImage;
  String _jobType = '';
  String _expLevel = '';
  String _workLocation = '';
  List<String> _skills = [];
  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experienceList = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _certifications = [];
  List<Map<String, dynamic>> _languages = [];
  List<Map<String, dynamic>> _achievements = [];

  final ImagePicker _picker = ImagePicker(); // Add this

  static const _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  static final _years = List.generate(50, (i) => (DateTime.now().year - i).toString());
  static const _tabIcons = [Icons.person_outline, Icons.star_outline, Icons.code_outlined, Icons.work_outline, Icons.rocket_launch_outlined, Icons.school_outlined, Icons.verified_outlined, Icons.language_outlined, Icons.emoji_events_outlined];
  static const _tabLabels = ['Basic', 'Preferences', 'Skills', 'Experience', 'Projects', 'Education', 'Certs', 'Languages', 'Awards'];

  // Apple-like Minimalist Theme - Black & White
  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Colors.white;
  static const _surfaceAlt = Color(0xFFF5F5F7);
  static const _border = Color(0xFFE5E5EA);
  static const _accent = Color(0xFF000000);
  static const _accentSoft = Color(0xFFF5F5F7);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6E6E73);
  static const _textMuted = Color(0xFF86868B);
  static const _success = Color(0xFF34C759);
  static const _danger = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileControllerProvider.notifier).FetchUserProfile());
  }

  @override
  void dispose() {
    for (final c in [_fullNameCtrl,_emailCtrl,_phoneCtrl,_locationCtrl,_linkedinCtrl,_githubCtrl,_portfolioCtrl,_bioCtrl,_rolesCtrl,_industriesCtrl,_salaryCtrl,_newSkillCtrl]) c.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> d) {
    if (_populated) return;
    _populated = true;
    _fullNameCtrl.text = d['fullName'] ?? '';
    _emailCtrl.text = d['email'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    _locationCtrl.text = d['location'] ?? '';
    _linkedinCtrl.text = d['linkedin'] ?? '';
    _githubCtrl.text = d['github'] ?? '';
    _portfolioCtrl.text = d['portfolio'] ?? '';
    _bioCtrl.text = d['bio'] ?? '';
    _profileImage = d['profilePic'];
    final p = d['preferences'] ?? {};
    _rolesCtrl.text = (p['roles'] as List?)?.join(', ') ?? '';
    _industriesCtrl.text = (p['industries'] as List?)?.join(', ') ?? '';
    _jobType = p['jobType'] ?? '';
    _expLevel = p['experience'] ?? '';
    _salaryCtrl.text = p['expectedSalary'] ?? '';
    _workLocation = p['workLocationPreference'] ?? '';
    _skills = List<String>.from(d['skills'] ?? []);
    _education = _castList(d['education']) ?? [_emptyEdu()];
    _experienceList = _castList(d['experience']) ?? [_emptyExp()];
    _projects = _castList(d['projects']) ?? [_emptyProj()];
    _certifications = _castList(d['certifications']) ?? [_emptyCert()];
    _languages = _castList(d['languages']) ?? [_emptyLang()];
    _achievements = _castList(d['achievements']) ?? [_emptyAch()];
  }

  List<Map<String, dynamic>>? _castList(dynamic v) {
    if (v == null || (v as List).isEmpty) return null;
    return v.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> _emptyEdu() => {'id': DateTime.now().millisecondsSinceEpoch, 'institution': '', 'degree': '', 'field': '', 'location': '', 'startMonth': '', 'startYear': '', 'endMonth': '', 'endYear': '', 'cgpa': '', 'description': ''};
  Map<String, dynamic> _emptyExp() => {'id': DateTime.now().millisecondsSinceEpoch, 'company': '', 'role': '', 'location': '', 'startMonth': '', 'startYear': '', 'endMonth': '', 'endYear': '', 'current': false, 'description': '', 'skills': []};
  Map<String, dynamic> _emptyProj() => {'id': DateTime.now().millisecondsSinceEpoch, 'name': '', 'description': '', 'technologies': [], 'githubLink': '', 'liveLink': ''};
  Map<String, dynamic> _emptyCert() => {'id': DateTime.now().millisecondsSinceEpoch, 'name': '', 'organization': '', 'issueDate': '', 'credentialUrl': ''};
  Map<String, dynamic> _emptyLang() => {'id': DateTime.now().millisecondsSinceEpoch, 'language': '', 'proficiency': 'Beginner'};
  Map<String, dynamic> _emptyAch() => {'id': DateTime.now().millisecondsSinceEpoch, 'title': '', 'description': '', 'year': ''};

  // ✅ NEW: Image picker function
  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: _surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Choose Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                _imageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  onTap: () async {
                    Navigator.pop(context);
                    await _selectImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _imageSourceOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _selectImage(ImageSource.gallery);
                  },
                ),
                if (_profileImage != null) ...[
                  const SizedBox(height: 12),
                  _imageSourceOption(
                    icon: Icons.delete_outline,
                    title: 'Remove Photo',
                    color: _danger,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _profileImage = null);
                      _toast('Profile photo removed', success: true);
                    },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _toast('Failed to pick image', success: false);
    }
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color?.withOpacity(0.1) ?? _accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color ?? _accent),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color ?? _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: color ?? _textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _profileImage = base64Image;
        });

        _toast('Profile photo updated', success: true);
      }
    } catch (e) {
      _toast('Failed to select image', success: false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final profileData = {
        'fullName': _fullNameCtrl.text,
        'email': _emailCtrl.text,
        'phone': _phoneCtrl.text,
        'location': _locationCtrl.text,
        'linkedin': _linkedinCtrl.text,
        'github': _githubCtrl.text,
        'portfolio': _portfolioCtrl.text,
        'bio': _bioCtrl.text,
        'profilePic': _profileImage,
        'preferences': {
          'roles': _rolesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'industries': _industriesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'jobType': _jobType,
          'experience': _expLevel,
          'expectedSalary': _salaryCtrl.text,
          'workLocationPreference': _workLocation,
        },
        'skills': _skills,
        'education': _education,
        'experience': _experienceList,
        'projects': _projects,
        'certifications': _certifications,
        'languages': _languages,
        'achievements': _achievements,
      };

      await ref.read(profileControllerProvider.notifier).UpdateUserProfile(profileData);

      if (mounted) {
        _toast('Profile saved successfully!', success: true);
        setState(() => _populated = false);
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to save profile';

      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['error'] ?? e.response!.data['message'] ?? errorMessage;
        }
      }

      if (mounted) _toast(errorMessage, success: false);
    } catch (e) {
      if (mounted) _toast('Failed to save profile', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
      backgroundColor: success ? _success : _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(profileControllerProvider).profileState;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: ps.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        error: (e, _) => _buildError(e),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile data.', style: TextStyle(color: _textSecondary)));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_populated) setState(() => _populate(Map<String, dynamic>.from(user)));
          });
          return Column(children: [_buildTabBar(), Expanded(child: _buildTabContent())]);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    title: const Row(children: [
      Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5)),
    ]),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: TextButton(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
            ]),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 0.5, color: _border)),
  );

  Widget _buildError(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 0.5),
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: _textMuted)
        ),
        const SizedBox(height: 20),
        const Text('Failed to load profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(e.toString().contains('DioException') ? 'Network error occurred' : e.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _textSecondary)
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() => _populated = false);
            ref.read(profileControllerProvider.notifier).FetchUserProfile();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Retry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );

  Widget _buildTabBar() => Container(
    color: _surface,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final sel = i == _activeTab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _accent : _surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_tabIcons[i], size: 16, color: sel ? Colors.white : _textSecondary),
                const SizedBox(width: 6),
                Text(_tabLabels[i], style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : _textSecondary,
                  letterSpacing: -0.2,
                )),
              ]),
            ),
          );
        }),
      ),
    ),
  );

  Widget _buildTabContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: [
      _buildBasicTab(), _buildPreferencesTab(), _buildSkillsTab(),
      _buildExperienceTab(), _buildProjectsTab(), _buildEducationTab(),
      _buildCertificationsTab(), _buildLanguagesTab(), _buildAchievementsTab(),
    ][_activeTab],
  );

  // ── BASIC ─────────────────────────────────────────────────────────────────
  Widget _buildBasicTab() {
    ImageProvider? img;
    if (_profileImage != null && _profileImage!.contains(',')) {
      try { img = MemoryImage(base64Decode(_profileImage!.split(',')[1].trim())); } catch (_) {}
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Identity', Icons.person_outline),
      const SizedBox(height: 16),
      _card(Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: _surfaceAlt,
              backgroundImage: img,
              child: img == null ? Text(
                  _fullNameCtrl.text.isNotEmpty ? _fullNameCtrl.text[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: _textMuted)
              ) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surface, width: 2)
                ),
                child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              _fullNameCtrl.text.isEmpty ? 'Your Name' : _fullNameCtrl.text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.5)
          ),
          const SizedBox(height: 4),
          Text(
              _emailCtrl.text.isEmpty ? 'email@example.com' : _emailCtrl.text,
              style: const TextStyle(fontSize: 14, color: _textSecondary)
          ),
        ])),
      ])),
      const SizedBox(height: 24),
      _sectionTitle('Personal Details', Icons.edit_outlined),
      const SizedBox(height: 16),
      _card(Column(children: [
        _twoCol(_field('Full Name', _fullNameCtrl), _field('Email Address', _emailCtrl, type: TextInputType.emailAddress)),
        _twoCol(_field('Phone Number', _phoneCtrl, type: TextInputType.phone), _field('Location', _locationCtrl)),
        _twoCol(_field('LinkedIn URL', _linkedinCtrl), _field('GitHub URL', _githubCtrl)),
        _field('Portfolio Website', _portfolioCtrl),
        _field('Professional Bio', _bioCtrl, maxLines: 4, hint: 'Brief summary of your skills and experience...'),
      ])),
    ]);
  }

  // Rest of the code remains the same...
  // (Include all other methods: _buildPreferencesTab, _buildSkillsTab, etc.)

  Widget _buildPreferencesTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle('Job Preferences', Icons.tune_outlined),
    const SizedBox(height: 16),
    _card(Column(children: [
      _field('Target Roles', _rolesCtrl, hint: 'e.g. Software Engineer, Product Manager'),
      _field('Preferred Industries', _industriesCtrl, hint: 'e.g. Technology, Healthcare'),
      const SizedBox(height: 4),
      _fullDropdown('Job Type', _jobType, const {'': 'Select type', 'full-time': 'Full-time', 'part-time': 'Part-time', 'contract': 'Contract', 'freelance': 'Freelance', 'internship': 'Internship'}, (v) => setState(() => _jobType = v!)),
      const SizedBox(height: 4),
      _fullDropdown('Experience Level', _expLevel, const {'': 'Select level', 'entry': 'Entry Level (0–2 yrs)', 'mid': 'Mid Level (2–5 yrs)', 'senior': 'Senior Level (5–10 yrs)', 'lead': 'Lead / Principal (10+ yrs)'}, (v) => setState(() => _expLevel = v!)),
      const SizedBox(height: 4),
      _twoCol(
        _field('Expected Salary', _salaryCtrl, hint: 'e.g. \$80k – \$120k'),
        _fullDropdown('Work Mode', _workLocation, const {'': 'Select mode', 'remote': 'Remote', 'onsite': 'On-site', 'hybrid': 'Hybrid'}, (v) => setState(() => _workLocation = v!)),
      ),
    ])),
  ]);

  Widget _buildSkillsTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle('Skill Inventory', Icons.code_outlined),
    const SizedBox(height: 16),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _field('Add Skill', _newSkillCtrl, hint: 'e.g. Flutter, TypeScript, Docker')),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ElevatedButton(
            onPressed: _addSkill,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ]),
      if (_skills.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('${_skills.length} skills', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _skills.asMap().entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary, letterSpacing: -0.2)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _skills.removeAt(e.key)),
                child: const Icon(Icons.close, size: 16, color: _textMuted),
              ),
            ]),
          )).toList(),
        ),
      ],
    ])),
  ]);

  void _addSkill() {
    if (_newSkillCtrl.text.trim().isNotEmpty) {
      setState(() { _skills.add(_newSkillCtrl.text.trim()); _newSkillCtrl.clear(); });
    }
  }

  Widget _buildExperienceTab() => _dynamicSection('Experience', _experienceList, () => setState(() => _experienceList.add(_emptyExp())), (exp, i) => Column(children: [
    _twoCol(_mapField('Company', exp, 'company'), _mapField('Job Title', exp, 'role')),
    _mapField('Location', exp, 'location'),
    _twoCol(_monthYear('Start Date', exp, 'startMonth', 'startYear'), _monthYear('End Date', exp, 'endMonth', 'endYear', disabled: exp['current'] == true)),
    _checkRow('Currently working here', exp['current'] == true, (v) => setState(() => exp['current'] = v)),
    _mapField('Description & Achievements', exp, 'description', maxLines: 4, hint: 'Key responsibilities and accomplishments...'),
    _mapField('Technologies Used', exp, 'skills', isListField: true, hint: 'React, Node.js, AWS (comma separated)'),
  ]), (i) => setState(() => _experienceList.removeAt(i)));

  Widget _buildProjectsTab() => _dynamicSection('Project', _projects, () => setState(() => _projects.add(_emptyProj())), (proj, i) => Column(children: [
    _mapField('Project Name', proj, 'name'),
    _mapField('Description', proj, 'description', maxLines: 3, hint: 'What you built and why it matters...'),
    _mapField('Technologies', proj, 'technologies', isListField: true, hint: 'Next.js, Go, Redis (comma separated)'),
    _twoCol(_mapField('GitHub URL', proj, 'githubLink', hint: 'https://github.com/...'), _mapField('Live URL', proj, 'liveLink', hint: 'https://...')),
  ]), (i) => setState(() => _projects.removeAt(i)));

  Widget _buildEducationTab() => _dynamicSection('Education', _education, () => setState(() => _education.add(_emptyEdu())), (edu, i) => Column(children: [
    _twoCol(_mapField('Institution', edu, 'institution'), _mapField('Degree', edu, 'degree', hint: 'B.S. / M.S. / Ph.D.')),
    _twoCol(_mapField('Field of Study', edu, 'field'), _mapField('Location', edu, 'location')),
    _twoCol(_monthYear('Start Date', edu, 'startMonth', 'startYear'), _monthYear('End Date', edu, 'endMonth', 'endYear')),
    _mapField('CGPA / Grade', edu, 'cgpa', hint: 'e.g. 3.8 / 4.0'),
    _mapField('Notes', edu, 'description', maxLines: 3, hint: 'Relevant coursework, thesis, honors...'),
  ]), (i) => setState(() => _education.removeAt(i)));

  Widget _buildCertificationsTab() => _dynamicSection('Certification', _certifications, () => setState(() => _certifications.add(_emptyCert())), (cert, i) => Column(children: [
    _twoCol(_mapField('Certification Name', cert, 'name'), _mapField('Issuing Organization', cert, 'organization')),
    _twoCol(_mapField('Issue Date (YYYY-MM)', cert, 'issueDate'), _mapField('Credential URL', cert, 'credentialUrl', hint: 'https://...')),
  ]), (i) => setState(() => _certifications.removeAt(i)));

  Widget _buildLanguagesTab() => _dynamicSection('Language', _languages, () => setState(() => _languages.add(_emptyLang())), (lang, i) => _twoCol(
    _mapField('Language', lang, 'language', hint: 'e.g. English'),
    _fullDropdown('Proficiency', lang['proficiency'] ?? 'Beginner', const {'Beginner': 'Beginner', 'Intermediate': 'Intermediate', 'Advanced': 'Advanced', 'Fluent': 'Fluent', 'Native': 'Native'}, (v) => setState(() => lang['proficiency'] = v!)),
  ), (i) => setState(() => _languages.removeAt(i)));

  Widget _buildAchievementsTab() => _dynamicSection('Achievement', _achievements, () => setState(() => _achievements.add(_emptyAch())), (ach, i) => Column(children: [
    _mapField('Title', ach, 'title', hint: 'e.g. Hackathon First Place'),
    _mapField('Description', ach, 'description', maxLines: 3, hint: 'Context and significance...'),
    _fullDropdown('Year', ach['year']?.toString() ?? '', {
      '': 'Select Year', ..._years.asMap().map((_, y) => MapEntry(y, y)),
    }, (v) => setState(() => ach['year'] = v!)),
  ]), (i) => setState(() => _achievements.removeAt(i)));

  Widget _dynamicSection(String title, List<Map<String, dynamic>> list, VoidCallback onAdd, Widget Function(Map<String, dynamic>, int) builder, void Function(int) onRemove) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _sectionTitle(title, Icons.list_alt_outlined)),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16, color: _accent),
          label: Text('Add $title', style: const TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: _surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      ...list.asMap().entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _border, width: 0.5)),
            ),
            child: Row(children: [
              Text('$title ${e.key + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.3)),
              const Spacer(),
              if (list.length > 1)
                GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18, color: _danger),
                  ),
                ),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: builder(e.value, e.key)),
        ]),
      )),
    ]);
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 0.5),
    ),
    child: child,
  );

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, size: 20, color: _textPrimary),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.5)),
  ]);

  Widget _twoCol(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: a), const SizedBox(width: 12), Expanded(child: b),
  ]);

  Widget _field(String label, TextEditingController ctrl, {TextInputType? type, int maxLines = 1, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: -0.2)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: _textPrimary, letterSpacing: -0.2),
        decoration: _dec(hint ?? label),
        onChanged: (_) => setState(() {}),
      ),
    ]),
  );

  Widget _mapField(String label, Map<String, dynamic> map, String key, {int maxLines = 1, bool isListField = false, String? hint}) {
    final current = isListField ? (map[key] as List?)?.join(', ') ?? '' : map[key]?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: -0.2)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: current,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: _textPrimary, letterSpacing: -0.2),
          decoration: _dec(hint ?? label),
          onChanged: (v) => map[key] = isListField ? v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : v,
        ),
      ]),
    );
  }

  Widget _fullDropdown(String label, String value, Map<String, String> options, ValueChanged<String?> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: -0.2)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: options.containsKey(value) ? value : options.keys.first,
        isExpanded: true,
        dropdownColor: _surface,
        style: const TextStyle(fontSize: 15, color: _textPrimary, letterSpacing: -0.2),
        decoration: _dec(label),
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    ]),
  );

  Widget _monthYear(String label, Map<String, dynamic> map, String mKey, String yKey, {bool disabled = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: -0.2)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: DropdownButtonFormField<String>(
              value: _months.contains(map[mKey]) ? map[mKey] as String : null,
              isExpanded: true,
              dropdownColor: _surface,
              style: const TextStyle(fontSize: 14, color: _textPrimary, letterSpacing: -0.2),
              decoration: _dec('Month'),
              items: [const DropdownMenuItem(value: null, child: Text('Month', style: TextStyle(color: _textMuted))), ..._months.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))],
              onChanged: (v) => setState(() => map[mKey] = v ?? ''),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: DropdownButtonFormField<String>(
              value: _years.contains(map[yKey]?.toString()) ? map[yKey].toString() : null,
              isExpanded: true,
              dropdownColor: _surface,
              style: const TextStyle(fontSize: 14, color: _textPrimary, letterSpacing: -0.2),
              decoration: _dec('Year'),
              items: [const DropdownMenuItem(value: null, child: Text('Year', style: TextStyle(color: _textMuted))), ..._years.map((y) => DropdownMenuItem(value: y, child: Text(y)))],
              onChanged: (v) => setState(() => map[yKey] = v ?? ''),
            ),
          ),
        )),
      ]),
    ]),
  );

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
              color: value ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: value ? _accent : _border, width: value ? 0 : 1.5)
          ),
          child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: _textPrimary, letterSpacing: -0.2)),
      ]),
    ),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: _textMuted, letterSpacing: -0.2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    filled: true,
    fillColor: _surfaceAlt,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border, width: 0.5)
    ),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border, width: 0.5)
    ),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5)
    ),
  );
}