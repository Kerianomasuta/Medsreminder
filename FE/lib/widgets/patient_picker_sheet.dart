import 'package:flutter/material.dart';

import '../models/care_network.dart';

/// Asks which linked patient an action applies to.
/// Returns null when the caregiver dismisses the sheet.
Future<LinkedUserSummary?> pickLinkedPatient(
  BuildContext context, {
  required List<LinkedUserSummary> patients,
  String? selectedId,
  required String title,
}) {
  if (patients.isEmpty) return Future<LinkedUserSummary?>.value();
  return showModalBottomSheet<LinkedUserSummary>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Chọn một bệnh nhân, rồi tiếp tục.',
              style: TextStyle(color: Color(0xFF687195)),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                final selected = patient.id == selectedId;
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE5D0),
                    child: Icon(Icons.person_rounded, color: Color(0xFFAD6047)),
                  ),
                  title: Text(
                    patient.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Color(0xFF249D76))
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, patient),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
