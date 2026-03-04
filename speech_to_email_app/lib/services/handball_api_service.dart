import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gameplay_models.dart';

class HandballApiService {
  // TODO: Replace with your actual API Gateway URL from CDK output
  static const String _baseUrl = 'https://YOUR_API_GATEWAY_URL/prod/handball';
  
  // TODO: Replace with your actual API Key from AWS Console
  // After deployment, go to AWS Console > API Gateway > API Keys > handball-app-key
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  // Organizations
  Future<List<Organization>> getOrganizations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Organization.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load organizations');
    }
  }

  Future<Organization> createOrganization(String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/organizations'),
      headers: _headers,
      body: json.encode({'name': name}),
    );
    
    if (response.statusCode == 201) {
      return Organization.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create organization');
    }
  }

  // Teams
  Future<List<TeamData>> getTeams({String? organizationId}) async {
    var url = '$_baseUrl/teams';
    if (organizationId != null) {
      url += '?organizationId=$organizationId';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => TeamData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<TeamData> getTeam(String teamId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/$teamId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return TeamData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load team');
    }
  }

  Future<TeamData> createTeam({
    required String name,
    required String coach,
    required List<String> players,
    required String organizationId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/teams'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'coach': coach,
        'players': players,
        'organizationId': organizationId,
      }),
    );
    
    if (response.statusCode == 201) {
      return TeamData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create team');
    }
  }

  Future<TeamData> updateTeam({
    required String teamId,
    String? name,
    String? coach,
    List<String>? players,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (coach != null) body['coach'] = coach;
    if (players != null) body['players'] = players;

    final response = await http.put(
      Uri.parse('$_baseUrl/teams/$teamId'),
      headers: _headers,
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return TeamData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update team');
    }
  }

  Future<void> deleteTeam(String teamId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/teams/$teamId'),
      headers: _headers,
    );
    
    if (response.statusCode != 204) {
      throw Exception('Failed to delete team');
    }
  }

  // Spielzüge
  Future<List<SpielzugData>> getSpielzuege({String? teamId}) async {
    var url = '$_baseUrl/spielzuege';
    if (teamId != null) {
      url += '?teamId=$teamId';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => SpielzugData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load spielzuege');
    }
  }

  Future<SpielzugData> getSpielzug(String spielzugId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/spielzuege/$spielzugId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return SpielzugData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load spielzug');
    }
  }

  Future<SpielzugData> createSpielzug({
    required String name,
    required String teamId,
    String? description,
    List<Map<String, dynamic>>? attackingPlayers,
    List<Map<String, dynamic>>? defendingPlayers,
    List<Map<String, dynamic>>? actions,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/spielzuege'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'teamId': teamId,
        'description': description,
        'attackingPlayers': attackingPlayers ?? [],
        'defendingPlayers': defendingPlayers ?? [],
        'actions': actions ?? [],
      }),
    );
    
    if (response.statusCode == 201) {
      return SpielzugData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create spielzug');
    }
  }

  Future<SpielzugData> updateSpielzug({
    required String spielzugId,
    String? name,
    String? description,
    List<Map<String, dynamic>>? attackingPlayers,
    List<Map<String, dynamic>>? defendingPlayers,
    List<Map<String, dynamic>>? actions,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (attackingPlayers != null) body['attackingPlayers'] = attackingPlayers;
    if (defendingPlayers != null) body['defendingPlayers'] = defendingPlayers;
    if (actions != null) body['actions'] = actions;

    final response = await http.put(
      Uri.parse('$_baseUrl/spielzuege/$spielzugId'),
      headers: _headers,
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return SpielzugData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update spielzug');
    }
  }

  Future<void> deleteSpielzug(String spielzugId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/spielzuege/$spielzugId'),
      headers: _headers,
    );
    
    if (response.statusCode != 204) {
      throw Exception('Failed to delete spielzug');
    }
  }
}

// Data models for API responses
class Organization {
  final String id;
  final String name;

  Organization({required this.id, required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class TeamData {
  final String id;
  final String name;
  final String coach;
  final List<String> players;
  final String organizationId;

  TeamData({
    required this.id,
    required this.name,
    required this.coach,
    required this.players,
    required this.organizationId,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      id: json['id'] as String,
      name: json['name'] as String,
      coach: json['coach'] as String,
      players: List<String>.from(json['players'] as List),
      organizationId: json['organizationId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coach': coach,
      'players': players,
      'organizationId': organizationId,
    };
  }
}

class SpielzugData {
  final String id;
  final String name;
  final String teamId;
  final String? description;
  final List<Map<String, dynamic>>? attackingPlayers;
  final List<Map<String, dynamic>>? defendingPlayers;
  final List<Map<String, dynamic>>? actions;

  SpielzugData({
    required this.id,
    required this.name,
    required this.teamId,
    this.description,
    this.attackingPlayers,
    this.defendingPlayers,
    this.actions,
  });

  factory SpielzugData.fromJson(Map<String, dynamic> json) {
    return SpielzugData(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      description: json['description'] as String?,
      attackingPlayers: json['attackingPlayers'] != null
          ? List<Map<String, dynamic>>.from(json['attackingPlayers'] as List)
          : null,
      defendingPlayers: json['defendingPlayers'] != null
          ? List<Map<String, dynamic>>.from(json['defendingPlayers'] as List)
          : null,
      actions: json['actions'] != null
          ? List<Map<String, dynamic>>.from(json['actions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'description': description,
      'attackingPlayers': attackingPlayers,
      'defendingPlayers': defendingPlayers,
      'actions': actions,
    };
  }
}
