
import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../widgets/desktop_widgets.dart';
import '../widgets/persistent_edit_field.dart';

class MembersPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final member = selectedMember;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'PERSONNEL RECORDS',
            subtitle: 'Member data, manual add, edit and delete',
            accent: accent,
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 14),
          if (event == null)
            const Expanded(child: Center(child: Text('NO ACTIVE EVENT')))
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: onAddMember,
                            child: const Text('ADD MEMBER'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(0xCC101511),
                              border: Border.all(color: accent.withOpacity(0.35)),
                            ),
                            child: event!.members.isEmpty
                                ? const Center(child: Text('NO MEMBERS'))
                                : ListView.builder(
                                    itemCount: event!.members.length,
                                    itemBuilder: (context, index) {
                                      final row = event!.members[index];
                                      final active = index == selectedMemberIndex;
                                      return ListTile(
                                        selected: active,
                                        selectedTileColor: accent.withOpacity(0.16),
                                        title: Text(
                                          row.fullName.isEmpty ? 'Unnamed Member' : row.fullName,
                                        ),
                                        subtitle: Text(row.email),
                                        trailing: Text(
                                          row.membershipLevel,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        onTap: () => onSelectMember(index),
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
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: member == null
                          ? const Center(child: Text('SELECT A MEMBER'))
                          : ListView(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.fullName.isEmpty ? 'Unnamed Member' : member.fullName,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: onDeleteMember,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PersistentEditField(
                                  label: 'First Name',
                                  value: member.firstName,
                                  onChanged: (v) async {
                                    member.firstName = v;
                                    await onSave();
                                    onRefresh();
                                  },
                                ),
                                PersistentEditField(
                                  label: 'Last Name',
                                  value: member.lastName,
                                  onChanged: (v) async {
                                    member.lastName = v;
                                    await onSave();
                                    onRefresh();
                                  },
                                ),
                                PersistentEditField(
                                  label: 'Date of Birth',
                                  value: member.dateOfBirth,
                                  onChanged: (v) async {
                                    member.dateOfBirth = v;
                                    await onSave();
                                  },
                                ),
                                PersistentEditField(
                                  label: 'Gender',
                                  value: member.gender,
                                  onChanged: (v) async {
                                    member.gender = v;
                                    await onSave();
                                  },
                                ),
                                PersistentEditField(
                                  label: 'Telephone',
                                  value: member.telephone,
                                  onChanged: (v) async {
                                    member.telephone = v;
                                    await onSave();
                                  },
                                ),
                                PersistentEditField(
                                  label: 'Email',
                                  value: member.email,
                                  onChanged: (v) async {
                                    member.email = v;
                                    await onSave();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: DropdownButtonFormField<String>(
                                    value: membershipLevels.contains(member.membershipLevel)
                                        ? member.membershipLevel
                                        : membershipLevels.first,
                                    decoration: const InputDecoration(
                                      labelText: 'Membership Level',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: membershipLevels
                                        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      member.membershipLevel = v;
                                      await onSave();
                                      onRefresh();
                                    },
                                  ),
                                ),
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
}
