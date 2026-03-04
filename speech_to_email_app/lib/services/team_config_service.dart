import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/team_models.dart';

class TeamConfigService {
  static List<TeamInfo>? _cachedTeams;

  /// Load team configurations from JSON file
  static Future<List<TeamInfo>> loadTeams() async {
    if (_cachedTeams != null) {
      return _cachedTeams!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/config/teams.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final teamsJson = jsonData['teams'] as List<dynamic>;

      _cachedTeams = teamsJson
          .map((teamJson) => TeamInfo.fromJson(teamJson as Map<String, dynamic>))
          .toList();

      return _cachedTeams!;
    } catch (e) {
      print('Error loading teams: $e');
      return [];
    }
  }

  /// Get team info by team enum
  static Future<TeamInfo?> getTeamInfo(String teamId) async {
    final teams = await loadTeams();
    try {
      return teams.firstWhere((t) => t.id == teamId);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache (useful for testing or reloading)
  static void clearCache() {
    _cachedTeams = null;
  }
}
