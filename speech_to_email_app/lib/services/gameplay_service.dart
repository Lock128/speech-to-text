import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gameplay_models.dart';
import 'auth_service.dart';

class GameplayService {
  static const String _spielzuegeKey = 'spielzuege_data';

  // Default Spielzüge for HC VfL Heppenheim
  static final Map<Team, List<Spielzug>> _hcVflSpielzuege = {
    Team.maennerI: [
      Spielzug(id: 'm1_1', name: 'Angriff Links', team: Team.maennerI),
      Spielzug(id: 'm1_2', name: 'Angriff Rechts', team: Team.maennerI),
      Spielzug(id: 'm1_3', name: 'Konter Mitte', team: Team.maennerI),
      Spielzug(id: 'm1_4', name: 'Tempogegenstoß', team: Team.maennerI),
      Spielzug(id: 'm1_5', name: 'Kreis Anspiel', team: Team.maennerI),
    ],
    Team.maennerII: [
      Spielzug(id: 'm2_1', name: 'Angriff Links', team: Team.maennerII),
      Spielzug(id: 'm2_2', name: 'Angriff Rechts', team: Team.maennerII),
      Spielzug(id: 'm2_3', name: 'Konter Mitte', team: Team.maennerII),
      Spielzug(id: 'm2_4', name: 'Kreis Anspiel', team: Team.maennerII),
    ],
    Team.damen: [
      Spielzug(id: 'd_1', name: 'Angriff Links', team: Team.damen),
      Spielzug(id: 'd_2', name: 'Angriff Rechts', team: Team.damen),
      Spielzug(id: 'd_3', name: 'Konter Mitte', team: Team.damen),
      Spielzug(id: 'd_4', name: 'Tempogegenstoß', team: Team.damen),
      Spielzug(id: 'd_5', name: 'Kreis Anspiel', team: Team.damen),
    ],
    Team.mC1: [
      Spielzug(id: 'mc1_1', name: 'Angriff Links', team: Team.mC1),
      Spielzug(id: 'mc1_2', name: 'Angriff Rechts', team: Team.mC1),
      Spielzug(id: 'mc1_3', name: 'Konter Mitte', team: Team.mC1),
    ],
    Team.mC2: [
      Spielzug(id: 'mc2_1', name: 'Angriff Links', team: Team.mC2),
      Spielzug(id: 'mc2_2', name: 'Angriff Rechts', team: Team.mC2),
      Spielzug(id: 'mc2_3', name: 'Konter Mitte', team: Team.mC2),
    ],
  };

  // Default Spielzüge for Demo organization
  static final Map<Team, List<Spielzug>> _demoSpielzuege = {
    Team.maennerI: [
      Spielzug(id: 'demo_m1_1', name: 'Demo Play 1', team: Team.maennerI),
      Spielzug(id: 'demo_m1_2', name: 'Demo Play 2', team: Team.maennerI),
      Spielzug(id: 'demo_m1_3', name: 'Demo Play 3', team: Team.maennerI),
    ],
    Team.maennerII: [
      Spielzug(id: 'demo_m2_1', name: 'Demo Play A', team: Team.maennerII),
      Spielzug(id: 'demo_m2_2', name: 'Demo Play B', team: Team.maennerII),
    ],
    Team.damen: [
      Spielzug(id: 'demo_d_1', name: 'Demo Play X', team: Team.damen),
      Spielzug(id: 'demo_d_2', name: 'Demo Play Y', team: Team.damen),
      Spielzug(id: 'demo_d_3', name: 'Demo Play Z', team: Team.damen),
    ],
    Team.mC1: [
      Spielzug(id: 'demo_mc1_1', name: 'Demo Youth Play 1', team: Team.mC1),
      Spielzug(id: 'demo_mc1_2', name: 'Demo Youth Play 2', team: Team.mC1),
    ],
    Team.mC2: [
      Spielzug(id: 'demo_mc2_1', name: 'Demo Youth Play A', team: Team.mC2),
      Spielzug(id: 'demo_mc2_2', name: 'Demo Youth Play B', team: Team.mC2),
    ],
  };

  String _getStorageKey(Organization organization) {
    return '${_spielzuegeKey}_${organization.name}';
  }

  Map<Team, List<Spielzug>> _getDefaultsForOrganization(Organization organization) {
    switch (organization) {
      case Organization.hcVflHeppenheim:
        return _hcVflSpielzuege;
      case Organization.demo:
        return _demoSpielzuege;
    }
  }

  Future<List<Spielzug>> getSpielzuegeForTeam(Team team, Organization organization) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey(organization);
    final jsonString = prefs.getString(storageKey);

    if (jsonString == null) {
      // Return default Spielzüge if none are saved
      final defaults = _getDefaultsForOrganization(organization);
      return defaults[team] ?? [];
    }

    try {
      final Map<String, dynamic> allData = json.decode(jsonString);
      final List<dynamic>? teamData = allData[team.name];

      if (teamData == null) {
        final defaults = _getDefaultsForOrganization(organization);
        return defaults[team] ?? [];
      }

      return teamData.map((item) => Spielzug.fromJson(item)).toList();
    } catch (e) {
      // If parsing fails, return defaults
      final defaults = _getDefaultsForOrganization(organization);
      return defaults[team] ?? [];
    }
  }

  Future<void> saveSpielzuegeForTeam(Team team, List<Spielzug> spielzuege, Organization organization) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey(organization);
    final jsonString = prefs.getString(storageKey);

    Map<String, dynamic> allData = {};
    if (jsonString != null) {
      try {
        allData = json.decode(jsonString);
      } catch (e) {
        // If parsing fails, start fresh
        allData = {};
      }
    }

    allData[team.name] = spielzuege.map((s) => s.toJson()).toList();
    await prefs.setString(storageKey, json.encode(allData));
  }

  Future<void> addSpielzug(Team team, String name, Organization organization) async {
    final spielzuege = await getSpielzuegeForTeam(team, organization);
    final newId = '${organization.name}_${team.name}_${DateTime.now().millisecondsSinceEpoch}';
    spielzuege.add(Spielzug(id: newId, name: name, team: team));
    await saveSpielzuegeForTeam(team, spielzuege, organization);
  }

  Future<void> removeSpielzug(Team team, String id, Organization organization) async {
    final spielzuege = await getSpielzuegeForTeam(team, organization);
    spielzuege.removeWhere((s) => s.id == id);
    await saveSpielzuegeForTeam(team, spielzuege, organization);
  }

  Future<void> updateSpielzug(Team team, String id, String newName, Organization organization) async {
    final spielzuege = await getSpielzuegeForTeam(team, organization);
    final index = spielzuege.indexWhere((s) => s.id == id);
    if (index != -1) {
      spielzuege[index] = Spielzug(id: id, name: newName, team: team);
      await saveSpielzuegeForTeam(team, spielzuege, organization);
    }
  }

  Future<void> resetToDefaults(Team team, Organization organization) async {
    final defaults = _getDefaultsForOrganization(organization);
    final defaultSpielzuege = defaults[team] ?? [];
    await saveSpielzuegeForTeam(team, defaultSpielzuege, organization);
  }
}
