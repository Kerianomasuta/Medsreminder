import 'package:flutter/material.dart';

class PatientProfileItem {
  final String code;
  final String name;
  final int age;
  final String relation;
  final String condition;
  final Color avatarBg;
  final IconData avatarIcon;

  const PatientProfileItem({
    required this.code,
    required this.name,
    required this.age,
    required this.relation,
    required this.condition,
    this.avatarBg = const Color(0xFFFFD9C6),
    this.avatarIcon = Icons.face_3_rounded,
  });
}
