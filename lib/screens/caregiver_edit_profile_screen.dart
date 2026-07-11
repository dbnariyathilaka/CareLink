import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Edit Profile Screen
//  Figma node: 46-4624 (C-10 · Edit Profile (gap screen))
// ─────────────────────────────────────────────────────────────
class CaregiverEditProfileScreen extends StatefulWidget {
  const CaregiverEditProfileScreen({super.key});

  @override
  State<CaregiverEditProfileScreen> createState() =>
      _CaregiverEditProfileScreenState();
}

class _DayAvailability {
  bool available;
  String hours;
  _DayAvailability({required this.available, required this.hours});
}

class _CaregiverEditProfileScreenState
    extends State<CaregiverEditProfileScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);

  final List<String> _careTypes = ['Part-time', 'Full-time', 'Live-in'];
  final Set<String> _selectedCareTypes = {'Part-time', 'Full-time'};

  int _yearsExperience = 5;

  final List<String> _skills = [
    'Mobility assistance',
    'Medication mgmt',
    'Dementia care',
    'Wound care',
    'Physiotherapy',
  ];
  final Set<String> _selectedSkills = {
    'Mobility assistance',
    'Medication mgmt',
    'Dementia care',
  };

  final Map<String, _DayAvailability> _days = {
    'Mon': _DayAvailability(available: true, hours: '8-6'),
    'Tue': _DayAvailability(available: true, hours: '8-6'),
    'Wed': _DayAvailability(available: true, hours: '8-6'),
    'Thu': _DayAvailability(available: true, hours: '8-6'),
    'Fri': _DayAvailability(available: true, hours: '8-6'),
    'Sat': _DayAvailability(available: false, hours: '8-6'),
    'Sun': _DayAvailability(available: false, hours: '8-6'),
  };

  final _serviceAreaController = TextEditingController(text: 'Negombo');
  final _bioController = TextEditingController(
    text: 'Compassionate elder-care nurse with 5 years supporting families '
        'across the Western Province.',
  );

  static const List<String> _radiusOptions = [
    '5 km',
    '10 km',
    '15 km',
    '20 km',
    '25 km',
    '30 km',
  ];
  String _radius = '10 km';

  @override
  void dispose() {
    _serviceAreaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Care services offered'),
                    const SizedBox(height: 10),
                    Row(
                      children: _careTypes.map((type) {
                        final isSelected = _selectedCareTypes.contains(type);
                        final isLast = type == _careTypes.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 10),
                            child: _buildCareTypeChip(
                              label: type,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCareTypes.remove(type);
                                  } else {
                                    _selectedCareTypes.add(type);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Years of experience'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_yearsExperience > 0) {
                                    setState(() => _yearsExperience--);
                                  }
                                },
                                child: const Icon(Icons.remove_rounded, color: _indigo, size: 22),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () => setState(() => _yearsExperience++),
                                child: const Icon(Icons.add_rounded, color: _indigo, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Skills'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _skills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return _buildSkillChip(
                          label: skill,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSkills.remove(skill);
                              } else {
                                _selectedSkills.add(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Weekly availability'),
                    const SizedBox(height: 10),
                    Row(
                      children: _days.entries.map((entry) {
                        final isLast = entry.key == _days.keys.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 6),
                            child: _buildDayChip(entry.key, entry.value),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Service area'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.inputBackground,
                                  border: Border.all(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _serviceAreaController,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Radius'),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _showRadiusPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputBackground,
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _radius,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Short bio'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _bioController,
                        maxLines: 4,
                        minLines: 3,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: _indigo,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated!')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Save changes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _radiusOptions.map((option) {
            final selected = option == _radius;
            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  color: selected ? _indigo : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: _indigo) : null,
              onTap: () {
                setState(() => _radius = option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCareTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.15) : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _indigo : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? _indigoLight : const Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.15) : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _indigo : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _indigoLight : const Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String day, _DayAvailability data) {
    final available = data.available;
    return GestureDetector(
      onTap: () => setState(() => data.available = !data.available),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.inputBackground,
          border: Border.all(color: available ? _indigo : AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: TextStyle(
                color: available ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              available ? data.hours : '—',
              style: TextStyle(
                color: available ? _indigoLight : const Color(0xFF64748B),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
