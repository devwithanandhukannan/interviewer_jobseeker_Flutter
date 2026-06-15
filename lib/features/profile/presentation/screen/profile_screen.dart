import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interviewer/features/profile/presentation/controller/profile_controller.dart';
import 'package:interviewer/features/settings/presentations/screen/settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
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

  final ImagePicker _picker = ImagePicker();

  static const _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  static final _years = List.generate(50, (i) => (DateTime.now().year - i).toString());

  // ── Apple Premium Light Design Tokens ─────────────────────────────────────
  static const _bg         = Color(0xFFF2F2F7); // Apple standard systemic background
  static const _surface    = Color(0xFFFFFFFF); // Pure canvas white
  static const _surfaceAlt = Color(0xFFF2F2F7);
  static const _border     = Color(0xFFE5E5EA); // Ultra-fine crisp split line
  static const _accent     = Color(0xFF007AFF); // Classic Apple iOS Blue
  static const _accentLight= Color(0xFFE5F1FF);
  static const _textPrimary   = Color(0xFF000000);
  static const _textSecondary = Color(0xFF3A3A3C);
  static const _textMuted     = Color(0xFF8E8E93); // iOS monochrome caption text
  static const _success    = Color(0xFF34C759); // iOS System Green
  static const _danger     = Color(0xFFFF3B30); // iOS System Red

  static const _navItems = [
    {'icon': Icons.person_outline_rounded,      'activeIcon': Icons.person_rounded,         'label': 'About'},
    {'icon': Icons.tune_outlined,               'activeIcon': Icons.tune_rounded,            'label': 'Prefs'},
    {'icon': Icons.code_outlined,               'activeIcon': Icons.code_rounded,            'label': 'Skills'},
    {'icon': Icons.work_outline_rounded,        'activeIcon': Icons.work_rounded,            'label': 'Work'},
    {'icon': Icons.rocket_launch_outlined,      'activeIcon': Icons.rocket_launch_rounded,   'label': 'Projects'},
    {'icon': Icons.school_outlined,              'activeIcon': Icons.school_rounded,          'label': 'Education'},
    {'icon': Icons.verified_outlined,           'activeIcon': Icons.verified_rounded,        'label': 'Certs'},
    {'icon': Icons.language_outlined,           'activeIcon': Icons.language_rounded,        'label': 'Lang'},
    {'icon': Icons.emoji_events_outlined,       'activeIcon': Icons.emoji_events_rounded,    'label': 'Awards'},
  ];

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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(10))),
            const Text('Profile Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 20),
            _sheetOption(Icons.camera_alt_outlined, 'Take Photo', () async { Navigator.pop(ctx); await _selectImage(ImageSource.camera); }),
            const SizedBox(height: 10),
            _sheetOption(Icons.photo_library_outlined, 'Choose from Gallery', () async { Navigator.pop(ctx); await _selectImage(ImageSource.gallery); }),
            if (_profileImage != null) ...[
              const SizedBox(height: 10),
              _sheetOption(Icons.delete_outline_rounded, 'Remove Photo', () { Navigator.pop(ctx); setState(() => _profileImage = null); _toast('Photo removed', success: true); }, danger: true),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _sheetOption(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? _danger : _accent;
    final bg = danger ? _danger.withOpacity(0.08) : _accentLight;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2)),
          ]),
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        setState(() => _profileImage = 'data:image/jpeg;base64,${base64Encode(bytes)}');
        _toast('Profile photo updated', success: true);
      }
    } catch (_) {
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
        _toast('Profile saved!', success: true);
        setState(() => _populated = false);
      }
    } on DioException catch (e) {
      String msg = 'Failed to save profile';
      if (e.response?.data is Map) msg = e.response!.data['error'] ?? e.response!.data['message'] ?? msg;
      if (mounted) _toast(msg, success: false);
    } catch (_) {
      if (mounted) _toast('Failed to save profile', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white))),
      ]),
      backgroundColor: success ? _success : _danger,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(profileControllerProvider).profileState;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          ps.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
            error: (e, _) => _buildError(e),
            data: (user) {
              if (user == null) return const Center(child: Text('No profile data.', style: TextStyle(color: _textMuted)));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_populated) setState(() => _populate(Map<String, dynamic>.from(user)));
              });
              return Column(children: [
                Expanded(child: _buildTabContent()),
                _buildBottomNav(),
              ]);
            },
          ),
          if (!_saving && ps.hasValue && ps.value != null)
            Positioned(
              right: 16,
              bottom: 92,
              child: FloatingActionButton.extended(
                onPressed: _save,
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 16,
    title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.6)),
    actions: [
      IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.settings_outlined, size: 18, color: _textSecondary),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        tooltip: 'Settings',
      ),
      const SizedBox(width: 12),
    ],
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 0.5, color: _border)),
  );

  Widget _buildError(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 44, color: _textMuted),
        const SizedBox(height: 16),
        const Text('Couldn\'t load profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        const Text('Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _textMuted)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () { setState(() => _populated = false); ref.read(profileControllerProvider.notifier).FetchUserProfile(); },
          style: FilledButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );

  Widget _buildBottomNav() => Container(
    decoration: const BoxDecoration(
      color: _surface,
      border: Border(top: BorderSide(color: _border, width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _navItems.length,
            itemBuilder: (_, i) {
              final sel = i == _activeTab;
              final item = _navItems[i];
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? _accentLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sel ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                        size: 19,
                        color: sel ? _accent : _textSecondary,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: sel ? 6 : 0,
                      ),
                      if (sel)
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                            letterSpacing: -0.1,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _buildTabContent() => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
    child: [
      _buildBasicTab(), _buildPreferencesTab(), _buildSkillsTab(),
      _buildExperienceTab(), _buildProjectsTab(), _buildEducationTab(),
      _buildCertificationsTab(), _buildLanguagesTab(), _buildAchievementsTab(),
    ][_activeTab],
  );

  Widget _buildBasicTab() {
    ImageProvider? img;
    if (_profileImage != null && _profileImage!.contains(',')) {
      try { img = MemoryImage(base64Decode(_profileImage!.split(',')[1].trim())); } catch (_) {}
    }
    final initial = _fullNameCtrl.text.isNotEmpty ? _fullNameCtrl.text[0].toUpperCase() : 'U';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _card(Column(children: [
        Row(children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _accentLight),
                child: img != null
                    ? ClipOval(child: Image(image: img, fit: BoxFit.cover))
                    : Center(child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _accent))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: _surface, shape: BoxShape.circle, border: Border.all(color: _border, width: 0.5)),
                  child: const Icon(Icons.camera_alt_rounded, size: 11, color: _textSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_fullNameCtrl.text.isEmpty ? 'Your Name' : _fullNameCtrl.text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(_emailCtrl.text.isEmpty ? 'email@example.com' : _emailCtrl.text,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
            if (_locationCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 13, color: _textMuted),
                const SizedBox(width: 2),
                Text(_locationCtrl.text, style: const TextStyle(fontSize: 12, color: _textMuted)),
              ]),
            ],
          ])),
          TextButton(
            onPressed: _pickImage,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), backgroundColor: _surfaceAlt, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
          ),
        ]),
      ])),
      const SizedBox(height: 20),
      _sectionLabel('Personal Info'),
      _card(Column(children: [
        _twoCol(_field('Full Name', _fullNameCtrl), _field('Email', _emailCtrl, type: TextInputType.emailAddress)),
        _twoCol(_field('Phone', _phoneCtrl, type: TextInputType.phone), _field('Location', _locationCtrl)),
      ])),
      const SizedBox(height: 20),
      _sectionLabel('Online Presence'),
      _card(Column(children: [
        _field('LinkedIn URL', _linkedinCtrl, prefix: Icons.link_rounded),
        _field('GitHub URL', _githubCtrl, prefix: Icons.code_rounded),
        _field('Portfolio', _portfolioCtrl, prefix: Icons.open_in_new_rounded),
      ])),
      const SizedBox(height: 20),
      _sectionLabel('Bio'),
      _card(_field('Professional Summary', _bioCtrl, maxLines: 4, hint: 'Tell recruiters who you are and what you bring to the table…')),
    ]);
  }

  Widget _buildPreferencesTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel('Job Preferences'),
    _card(Column(children: [
      _field('Target Roles', _rolesCtrl, hint: 'Software Engineer…'),
      _field('Preferred Industries', _industriesCtrl, hint: 'Technology, Finance…'),
      _fullDropdown('Job Type', _jobType, const {'': 'Select type','full-time':'Full-time','part-time':'Part-time','contract':'Contract','freelance':'Freelance','internship':'Internship'}, (v) => setState(() => _jobType = v!)),
      _fullDropdown('Experience Level', _expLevel, const {'':'Select level','entry':'Entry (0–2 yrs)','mid':'Mid (2–5 yrs)','senior':'Senior (5–10 yrs)','lead':'Lead / Principal (10+ yrs)'}, (v) => setState(() => _expLevel = v!)),
      _twoCol(
        _field('Expected Salary', _salaryCtrl, hint: '\$80k – \$120k'),
        _fullDropdown('Work Mode', _workLocation, const {'':'Select mode','remote':'Remote','onsite':'On-site','hybrid':'Hybrid'}, (v) => setState(() => _workLocation = v!)),
      ),
    ])),
  ]);

  Widget _buildSkillsTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionLabel('Skills (${_skills.length})'),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _field('Add Skill', _newSkillCtrl, hint: 'Flutter, React, Go…')),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton(
            onPressed: _addSkill,
            style: FilledButton.styleFrom(backgroundColor: _accent, minimumSize: const Size(44, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          ),
        ),
      ]),
      if (_skills.isNotEmpty) Wrap(
        spacing: 6, runSpacing: 6,
        children: _skills.asMap().entries.map((e) => Chip(
          label: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary)),
          deleteIcon: const Icon(Icons.close_rounded, size: 13, color: _textMuted),
          onDeleted: () => setState(() => _skills.removeAt(e.key)),
          backgroundColor: _surfaceAlt,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        )).toList(),
      ),
    ])),
  ]);

  void _addSkill() {
    if (_newSkillCtrl.text.trim().isNotEmpty) {
      setState(() { _skills.add(_newSkillCtrl.text.trim()); _newSkillCtrl.clear(); });
    }
  }

  Widget _buildExperienceTab() => _dynamicSection('Experience', _experienceList, () => setState(() => _experienceList.add(_emptyExp())),
          (exp, i) => Column(children: [
        _twoCol(_mapField('Company', exp, 'company'), _mapField('Job Title', exp, 'role')),
        _mapField('Location', exp, 'location'),
        _twoCol(_monthYear('Start', exp, 'startMonth', 'startYear'), _monthYear('End', exp, 'endMonth', 'endYear', disabled: exp['current'] == true)),
        _checkRow('Currently working here', exp['current'] == true, (v) => setState(() => exp['current'] = v)),
        const SizedBox(height: 10),
        _mapField('Description', exp, 'description', maxLines: 3, hint: 'Key responsibilities…'),
        _mapField('Technologies', exp, 'skills', isListField: true, hint: 'React, Node.js'),
      ]),
          (i) => setState(() => _experienceList.removeAt(i)));

  Widget _buildProjectsTab() => _dynamicSection('Project', _projects, () => setState(() => _projects.add(_emptyProj())),
          (proj, i) => Column(children: [
        _mapField('Project Name', proj, 'name'),
        _mapField('Description', proj, 'description', maxLines: 3, hint: 'What you built…'),
        _mapField('Technologies', proj, 'technologies', isListField: true, hint: 'Next.js, Tailwind'),
        _twoCol(_mapField('GitHub URL', proj, 'githubLink'), _mapField('Live URL', proj, 'liveLink')),
      ]),
          (i) => setState(() => _projects.removeAt(i)));

  Widget _buildEducationTab() => _dynamicSection('Education', _education, () => setState(() => _education.add(_emptyEdu())),
          (edu, i) => Column(children: [
        _twoCol(_mapField('Institution', edu, 'institution'), _mapField('Degree', edu, 'degree')),
        _twoCol(_mapField('Field of Study', edu, 'field'), _mapField('Location', edu, 'location')),
        _twoCol(_monthYear('Start', edu, 'startMonth', 'startYear'), _monthYear('End', edu, 'endMonth', 'endYear')),
        _mapField('GPA / Grade', edu, 'cgpa'),
        _mapField('Notes', edu, 'description', maxLines: 2),
      ]),
          (i) => setState(() => _education.removeAt(i)));

  Widget _buildCertificationsTab() => _dynamicSection('Certification', _certifications, () => setState(() => _certifications.add(_emptyCert())),
          (cert, i) => Column(children: [
        _twoCol(_mapField('Certification Name', cert, 'name'), _mapField('Organization', cert, 'organization')),
        _twoCol(_mapField('Issue Date', cert, 'issueDate', hint: 'YYYY-MM'), _mapField('Credential URL', cert, 'credentialUrl')),
      ]),
          (i) => setState(() => _certifications.removeAt(i)));

  Widget _buildLanguagesTab() => _dynamicSection('Language', _languages, () => setState(() => _languages.add(_emptyLang())),
          (lang, i) => _twoCol(
        _mapField('Language', lang, 'language'),
        _fullDropdown('Proficiency', lang['proficiency'] ?? 'Beginner', const {'Beginner':'Beginner','Intermediate':'Intermediate','Advanced':'Advanced','Fluent':'Fluent','Native':'Native'}, (v) => setState(() => lang['proficiency'] = v!)),
      ),
          (i) => setState(() => _languages.removeAt(i)));

  Widget _buildAchievementsTab() => _dynamicSection('Achievement', _achievements, () => setState(() => _achievements.add(_emptyAch())),
          (ach, i) => Column(children: [
        _mapField('Title', ach, 'title'),
        _mapField('Description', ach, 'description', maxLines: 2),
        _fullDropdown('Year', ach['year']?.toString() ?? '', {'': 'Select Year', ..._years.asMap().map((_, y) => MapEntry(y, y))}, (v) => setState(() => ach['year'] = v!)),
      ]),
          (i) => setState(() => _achievements.removeAt(i)));

  Widget _dynamicSection(String title, List<Map<String, dynamic>> list, VoidCallback onAdd, Widget Function(Map<String, dynamic>, int) builder, void Function(int) onRemove) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _sectionLabel('$title (${list.length})')),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 14, color: _accent),
          label: Text('Add New', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _accent)),
          style: TextButton.styleFrom(
            backgroundColor: _accentLight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      ...list.asMap().entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13.5)),
            ),
            child: Row(children: [
              Text('$title #${e.key + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary)),
              const Spacer(),
              if (list.length > 1)
                GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: _danger),
                ),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(14), child: builder(e.value, e.key)),
        ]),
      )),
    ]);
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border, width: 0.5),
    ),
    child: child,
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 0.5)),
  );

  Widget _twoCol(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: a), const SizedBox(width: 12), Expanded(child: b),
  ]);

  Widget _field(String label, TextEditingController ctrl, {TextInputType? type, int maxLines = 1, String? hint, IconData? prefix}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: _textPrimary),
        decoration: _dec(hint ?? label, prefixIcon: prefix),
        onChanged: (_) => setState(() {}),
      ),
    ]),
  );

  Widget _mapField(String label, Map<String, dynamic> map, String key, {int maxLines = 1, bool isListField = false, String? hint}) {
    final current = isListField ? (map[key] as List?)?.join(', ') ?? '' : map[key]?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: current,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: _dec(hint ?? label),
          onChanged: (v) => map[key] = isListField ? v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : v,
        ),
      ]),
    );
  }

  Widget _fullDropdown(String label, String value, Map<String, String> options, ValueChanged<String?> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: options.containsKey(value) ? value : options.keys.first,
        isExpanded: true,
        dropdownColor: _surface,
        style: const TextStyle(fontSize: 14, color: _textPrimary),
        decoration: _dec(label),
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    ]),
  );

  Widget _monthYear(String label, Map<String, dynamic> map, String mKey, String yKey, {bool disabled = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.3 : 1,
            child: DropdownButtonFormField<String>(
              value: _months.contains(map[mKey]) ? map[mKey] as String : null,
              isExpanded: true, dropdownColor: _surface,
              style: const TextStyle(fontSize: 13, color: _textPrimary),
              decoration: _dec('Month'),
              items: [const DropdownMenuItem(value: null, child: Text('Month', style: TextStyle(color: _textMuted))), ..._months.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))],
              onChanged: (v) => setState(() => map[mKey] = v ?? ''),
            ),
          ),
        )),
        const SizedBox(width: 6),
        Expanded(child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.3 : 1,
            child: DropdownButtonFormField<String>(
              value: _years.contains(map[yKey]?.toString()) ? map[yKey].toString() : null,
              isExpanded: true, dropdownColor: _surface,
              style: const TextStyle(fontSize: 13, color: _textPrimary),
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
    padding: const EdgeInsets.only(top: 2, bottom: 6),
    child: GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: value ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: value ? _accent : _border, width: 1),
          ),
          child: value ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: _textPrimary)),
      ]),
    ),
  );

  InputDecoration _dec(String hint, {IconData? prefixIcon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _textMuted),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: _textMuted) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: _surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1)),
  );
}