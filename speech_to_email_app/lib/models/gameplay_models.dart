import '../services/handball_api_service.dart' as api;

enum Team {
  maennerI('Männer I'),
  maennerII('Männer II'),
  damen('Damen'),
  mC1('mC1'),
  mC2('mC2');

  final String displayName;
  const Team(this.displayName);
}

class Spielzug {
  final String id;
  final String name;
  final Team team;
  final api.SpielzugData? backendData; // Store backend data for visualization

  const Spielzug({
    required this.id,
    required this.name,
    required this.team,
    this.backendData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'team': team.name,
  };

  factory Spielzug.fromJson(Map<String, dynamic> json) => Spielzug(
    id: json['id'] as String,
    name: json['name'] as String,
    team: Team.values.firstWhere((t) => t.name == json['team']),
  );
}
