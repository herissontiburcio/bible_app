import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bible_year_plan.dart';

class BibleYearService {
  static Future<BibleYearPlan> loadPlan() async {
    final raw = await rootBundle.loadString('assets/plans/bible_year_plan.json');
    return BibleYearPlan.fromJson(jsonDecode(raw));
  }


  static int todayDayNumber() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final d = now.difference(start).inDays + 1;
    return d.clamp(1, 365);
  }
}


