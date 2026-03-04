import 'package:flutter/material.dart';

enum DefensiveFormation {
  sixZero('6-0', '6-0 Formation'),
  fiveOne('5-1', '5-1 Formation'),
  oneFive('1-5', '1-5 Formation'),
  threeTwoOne('3-2-1', '3-2-1 Formation');

  final String code;
  final String displayName;
  const DefensiveFormation(this.code, this.displayName);
}

enum PlayerPosition {
  // Attacking positions
  leftWing('LW', 'Linksaußen'),
  leftBack('LR', 'Rückraum Links'),
  centerBack('RM', 'Rückraum Mitte'),
  rightBack('RR', 'Rückraum Rechts'),
  rightWing('RW', 'Rechtsaußen'),
  pivot('KM', 'Kreisläufer'),
  
  // Defending positions
  defLeftWing('DLW', 'Verteidiger Links Außen'),
  defLeftBack('DLR', 'Verteidiger Links'),
  defCenterLeft('DCL', 'Verteidiger Mitte Links'),
  defCenterRight('DCR', 'Verteidiger Mitte Rechts'),
  defRightBack('DRR', 'Verteidiger Rechts'),
  defRightWing('DRW', 'Verteidiger Rechts Außen');

  final String abbreviation;
  final String displayName;
  const PlayerPosition(this.abbreviation, this.displayName);

  bool get isAttacking => index < 6;
  bool get isDefending => index >= 6;
}

class Player {
  final String id;
  final String name;
  final PlayerPosition position;
  final Offset initialPosition;
  final Color color;

  const Player({
    required this.id,
    required this.name,
    required this.position,
    required this.initialPosition,
    required this.color,
  });

  Player copyWith({
    String? id,
    String? name,
    PlayerPosition? position,
    Offset? initialPosition,
    Color? color,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      initialPosition: initialPosition ?? this.initialPosition,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position.name,
    'x': initialPosition.dx,
    'y': initialPosition.dy,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      position: PlayerPosition.values.firstWhere((p) => p.name == json['position']),
      initialPosition: Offset(json['x'] as double, json['y'] as double),
      color: Colors.blue, // Default color, will be set based on team
    );
  }
}

enum ActionType {
  pass('Pass'),
  move('Bewegung'),
  shoot('Wurf'),
  screen('Block'),
  cut('Schnitt');

  final String displayName;
  const ActionType(this.displayName);
}

class PlayAction {
  final String id;
  final ActionType type;
  final String playerId;
  final String? targetPlayerId; // For passes
  final Offset? targetPosition; // For movements
  final int sequenceNumber;
  final Duration delay;
  final String? description;

  const PlayAction({
    required this.id,
    required this.type,
    required this.playerId,
    this.targetPlayerId,
    this.targetPosition,
    required this.sequenceNumber,
    this.delay = const Duration(milliseconds: 500),
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'playerId': playerId,
    'targetPlayerId': targetPlayerId,
    'targetX': targetPosition?.dx,
    'targetY': targetPosition?.dy,
    'sequenceNumber': sequenceNumber,
    'delayMs': delay.inMilliseconds,
    'description': description,
  };

  factory PlayAction.fromJson(Map<String, dynamic> json) {
    return PlayAction(
      id: json['id'] as String,
      type: ActionType.values.firstWhere((t) => t.name == json['type']),
      playerId: json['playerId'] as String,
      targetPlayerId: json['targetPlayerId'] as String?,
      targetPosition: json['targetX'] != null && json['targetY'] != null
          ? Offset(json['targetX'] as double, json['targetY'] as double)
          : null,
      sequenceNumber: json['sequenceNumber'] as int,
      delay: Duration(milliseconds: json['delayMs'] as int? ?? 500),
      description: json['description'] as String?,
    );
  }
}

class HandballPlay {
  final String id;
  final String name;
  final List<Player> attackingPlayers;
  final List<Player> defendingPlayers;
  final List<PlayAction> actions;
  final String? description;
  final DefensiveFormation defensiveFormation;

  const HandballPlay({
    required this.id,
    required this.name,
    required this.attackingPlayers,
    required this.defendingPlayers,
    required this.actions,
    this.description,
    this.defensiveFormation = DefensiveFormation.sixZero,
  });

  HandballPlay copyWith({
    String? id,
    String? name,
    List<Player>? attackingPlayers,
    List<Player>? defendingPlayers,
    List<PlayAction>? actions,
    String? description,
    DefensiveFormation? defensiveFormation,
  }) {
    return HandballPlay(
      id: id ?? this.id,
      name: name ?? this.name,
      attackingPlayers: attackingPlayers ?? this.attackingPlayers,
      defendingPlayers: defendingPlayers ?? this.defendingPlayers,
      actions: actions ?? this.actions,
      description: description ?? this.description,
      defensiveFormation: defensiveFormation ?? this.defensiveFormation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'attackingPlayers': attackingPlayers.map((p) => p.toJson()).toList(),
    'defendingPlayers': defendingPlayers.map((p) => p.toJson()).toList(),
    'actions': actions.map((a) => a.toJson()).toList(),
    'description': description,
    'defensiveFormation': defensiveFormation.name,
  };

  factory HandballPlay.fromJson(Map<String, dynamic> json) {
    return HandballPlay(
      id: json['id'] as String,
      name: json['name'] as String,
      attackingPlayers: (json['attackingPlayers'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      defendingPlayers: (json['defendingPlayers'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      actions: (json['actions'] as List)
          .map((a) => PlayAction.fromJson(a))
          .toList(),
      description: json['description'] as String?,
      defensiveFormation: json['defensiveFormation'] != null
          ? DefensiveFormation.values.firstWhere(
              (f) => f.name == json['defensiveFormation'],
              orElse: () => DefensiveFormation.sixZero,
            )
          : DefensiveFormation.sixZero,
    );
  }
}
