import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/persistent_edit_field.dart';

class MembersPanel extends StatefulWidget {
  final Color accent;
  final EventRecord? event;
  final MemberRecord? selectedMember;
  final int? selectedMemberIndex;
  final List<String> membershipLevels;
  final VoidCallback onAddMember;
  final VoidCallback onDeleteMember;
  final ValueChanged<int> onSelectMember;
  final Future<void> Function() onSave;
  final VoidCallback onRefresh;

  const MembersPanel({
    super.key,
    required this.accent,
    required this.event,
    required this.selectedMember,
    required this.selectedMemberIndex,
    required this.membershipLevels,
    required this.onAddMember,
    required this.onDeleteMember,
    required this.onSelectMember,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  State<MembersPanel> createState() => _MembersPanelState();
}

class _MembersPanelState extends State<MembersPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String _sortMode = 'name_az';
  bool _isEditing = false;

  @override
  void didUpdateWidget(covariant MembersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMemberIndex != widget.selectedMemberIndex) {
      _isEditing = false;
    }

    if (oldWidget.event?.id != widget.event?.id) {
      _isEditing = false;
      _search = '';
      _searchController.text = '';
      _sortMode = 'name_az';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MemberRecord> _filteredMembers() {
    final event = widget.event;
    if (event == null) return [];

    final members = List<MemberRecord>.from(event.members);

    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      members.retainWhere((member) {
        final fullName = member.fullName.toLowerCase();
        final email = member.email.toLowerCase();
        final username = _getUsername(member).toLowerCase();
        final telephone = member.telephone.toLowerCase();

        return fullName.contains(query) ||
            email.contains(query) ||
            username.contains(query) ||
            telephone.contains(query);
      });
    }

    members.sort((a, b) {
      switch (_sortMode) {
        case 'name_za':
          return b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase());
        case 'level':
          final levelCompare =
              a.membershipLevel.toLowerCase().compareTo(b.membershipLevel.toLowerCase());
          if (levelCompare != 0) return levelCompare;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        case 'rating_high':
          final ratingCompare = _getRating(b).compareTo(_getRating(a));
          if (ratingCompare != 0) return ratingCompare;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        case 'rating_low':
          final ratingCompare = _getRating(a).compareTo(_getRating(b));
          if (ratingCompare != 0) return ratingCompare;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        case 'name_az':
        default:
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      }
    });

    return members;
  }

  int? _resolvedSelectedFilteredIndex(List<MemberRecord> filtered) {
    final selected = widget.selectedMember;
    if (selected == null) return null;

    for (int i = 0; i < filtered.length; i++) {
      if (filtered[i].id == selected.id) return i;
    }
    return null;
  }

  Future<void> _saveAndRefresh() async {
    await widget.onSave();
    widget.onRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  String _getUsername(MemberRecord member) {
    try {
      final dynamic dynamicMember = member;
      final value = dynamicMember.username;
      if (value == null) return '';
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  int _getRating(MemberRecord member) {
    try {
      final dynamic dynamicMember = member;
      final value = dynamicMember.rating;
      if (value is int) return value.clamp(0, 5);
      if (value is num) return value.toInt().clamp(0, 5);
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setRating(MemberRecord member, int rating) async {
    try {
      final dynamic dynamicMember = member;
      dynamicMember.rating = rating.clamp(0, 5);
      await _saveAndRefresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add "rating" to MemberRecord to enable saved ratings.'),
        ),
      );
    }
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          color: const Color(0x66121813),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(MemberRecord member) {
    final rating = _getRating(member);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          color: const Color(0x66121813),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RATING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  onPressed: _isEditing ? () => _setRating(member, starValue) : null,
                  icon: Icon(
                    starValue <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: widget.accent,
                    size: 24,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.selectedMember;
    final filteredMembers = _filteredMembers();
    final filteredSelectedIndex = _resolvedSelectedFilteredIndex(filteredMembers);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'PERSONNEL RECORDS',
            subtitle: 'Member records, search, sort and controlled editing',
            accent: widget.accent,
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 14),
          if (widget.event == null)
            const Expanded(
              child: Center(
                child: Text('NO ACTIVE EVENT'),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search name, email, username, phone',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _search = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 170,
                              child: DropdownButtonFormField<String>(
                                value: _sortMode,
                                decoration: const InputDecoration(
                                  labelText: 'Sort',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'name_az',
                                    child: Text('Name A-Z'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name_za',
                                    child: Text('Name Z-A'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'level',
                                    child: Text('Membership'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rating_high',
                                    child: Text('Rating High-Low'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rating_low',
                                    child: Text('Rating Low-High'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _sortMode = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: widget.onAddMember,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('ADD MEMBER'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(0xCC101511),
                              border: Border.all(color: widget.accent.withOpacity(0.35)),
                            ),
                            child: filteredMembers.isEmpty
                                ? const Center(child: Text('NO MEMBERS FOUND'))
                                : ListView.builder(
                                    itemCount: filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      final row = filteredMembers[index];
                                      final active = index == filteredSelectedIndex;

                                      return ListTile(
                                        selected: active,
                                        selectedTileColor: widget.accent.withOpacity(0.16),
                                        title: Text(
                                          row.fullName.isEmpty ? 'Unnamed Member' : row.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          row.membershipLevel.isEmpty
                                              ? 'No membership level'
                                              : row.membershipLevel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_getRating(row) > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: Text(
                                                  '${_getRating(row)}/5',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            Icon(
                                              Icons.person_outline,
                                              size: 18,
                                              color: widget.accent,
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          final realIndex = widget.event!.members
                                              .indexWhere((m) => m.id == row.id);
                                          if (realIndex == -1) return;
                                          widget.onSelectMember(realIndex);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xCC101511),
                        border: Border.all(color: widget.accent.withOpacity(0.35)),
                      ),
                      child: member == null
                          ? const Center(child: Text('SELECT A MEMBER'))
                          : ListView(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.fullName.isEmpty
                                                ? 'Unnamed Member'
                                                : member.fullName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            member.membershipLevel.isEmpty
                                                ? 'No membership level'
                                                : member.membershipLevel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: widget.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _isEditing ? 'Finish editing' : 'Edit member',
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = !_isEditing;
                                        });
                                      },
                                      icon: Icon(
                                        _isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                                        color: widget.accent,
                                      ),
                                    ),
                                    if (_isEditing)
                                      const SizedBox(width: 4),
                                    if (_isEditing)
                                      OutlinedButton.icon(
                                        onPressed: widget.onDeleteMember,
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('DELETE'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildRatingRow(member),
                                if (_isEditing) ...[
                                  PersistentEditField(
                                    label: 'First Name',
                                    value: member.firstName,
                                    onChanged: (v) async {
                                      member.firstName = v;
                                      await _saveAndRefresh();
                                    },
                                  ),
                                  PersistentEditField(
                                    label: 'Last Name',
                                    value: member.lastName,
                                    onChanged: (v) async {
                                      member.lastName = v;
                                      await _saveAndRefresh();
                                    },
                                  ),
                                  PersistentEditField(
                                    label: 'Date of Birth',
                                    value: member.dateOfBirth,
                                    onChanged: (v) async {
                                      member.dateOfBirth = v;
                                      await _saveAndRefresh();
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: DropdownButtonFormField<String>(
                                      value: _normalizedGenderValue(member.gender),
                                      decoration: const InputDecoration(
                                        labelText: 'Gender',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: '', child: Text('Not Set')),
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (v) async {
                                        member.gender = v ?? '';
                                        await _saveAndRefresh();
                                      },
                                    ),
                                  ),
                                  PersistentEditField(
                                    label: 'Telephone',
                                    value: member.telephone,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (v) async {
                                      member.telephone = v;
                                      await _saveAndRefresh();
                                    },
                                  ),
                                  PersistentEditField(
                                    label: 'Email',
                                    value: member.email,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (v) async {
                                      member.email = v;
                                      await _saveAndRefresh();
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: DropdownButtonFormField<String>(
                                      value: widget.membershipLevels.contains(member.membershipLevel)
                                          ? member.membershipLevel
                                          : widget.membershipLevels.first,
                                      decoration: const InputDecoration(
                                        labelText: 'Membership Level',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: widget.membershipLevels
                                          .map(
                                            (e) => DropdownMenuItem<String>(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        member.membershipLevel = v;
                                        await _saveAndRefresh();
                                      },
                                    ),
                                  ),
                                ] else ...[
                                  _buildReadOnlyRow(
                                    label: 'First Name',
                                    value: member.firstName,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Last Name',
                                    value: member.lastName,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Date of Birth',
                                    value: member.dateOfBirth,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Gender',
                                    value: member.gender,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Telephone',
                                    value: member.telephone,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Email',
                                    value: member.email,
                                  ),
                                  _buildReadOnlyRow(
                                    label: 'Membership Level',
                                    value: member.membershipLevel,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _normalizedGenderValue(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed == 'male') return 'Male';
    if (trimmed == 'female') return 'Female';
    if (trimmed == 'other') return 'Other';
    return '';
  }
}
