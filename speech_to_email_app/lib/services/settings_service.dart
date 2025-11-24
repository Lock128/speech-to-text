import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _coachNameKey = 'coach_name';
  
  static Future<String?> getCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_coachNameKey);
  }
  
  static Future<void> setCoachName(String coachName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachNameKey, coachName);
  }
  
  static Future<void> clearCoachName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coachNameKey);
  }
}