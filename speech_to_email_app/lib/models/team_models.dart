import 'gameplay_models.dart';

class TeamInfo {
  final Team team;
  final String coach;
  final List<String> players;

  const TeamInfo({
    required this.team,
    required this.coach,
    required this.players,
  });

  Map<String, dynamic> toJson() => {
    'team': team.name,
    'teamDisplayName': team.displayName,
    'coach': coach,
    'players': players,
  };

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    final teamId = json['id'] as String;
    final team = Team.values.firstWhere(
      (t) => t.name == teamId,
      orElse: () => Team.maennerI,
    );

    return TeamInfo(
      team: team,
      coach: json['coach'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  String get displayName => team.displayName;
  String get id => team.name;
}
