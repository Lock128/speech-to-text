import 'package:flutter/material.dart';
import '../models/handball_models.dart';
import 'handball_api_service.dart' as api;

class HandballPlayService {
  // Get play from backend data or fallback to default
  static HandballPlay getPlay(String playName, {api.SpielzugData? backendData}) {
    if (backendData != null && _hasCompletePlayData(backendData)) {
      return _createFromBackendData(backendData);
    }
    return getDefaultPlay(playName);
  }

  // Check if backend data has complete play information
  static bool _hasCompletePlayData(api.SpielzugData data) {
    return data.attackingPlayers != null &&
        data.attackingPlayers!.isNotEmpty &&
        data.actions != null &&
        data.actions!.isNotEmpty;
  }

  // Convert backend data to HandballPlay
  static HandballPlay _createFromBackendData(api.SpielzugData data) {
    final attackingPlayers = (data.attackingPlayers ?? []).map((p) {
      return Player(
        id: p['id'] as String,
        name: p['name'] as String,
        position: _parsePosition(p['position'] as String),
        initialPosition: Offset(
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        ),
        color: Colors.blue,
      );
    }).toList();

    final defendingPlayers = (data.defendingPlayers ?? []).map((p) {
      return Player(
        id: p['id'] as String,
        name: p['name'] as String,
        position: _parsePosition(p['position'] as String),
        initialPosition: Offset(
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        ),
        color: Colors.red,
      );
    }).toList();

    final actions = (data.actions ?? []).map((a) {
      return PlayAction(
        id: a['id'] as String,
        type: _parseActionType(a['type'] as String),
        playerId: a['playerId'] as String,
        targetPlayerId: a['targetPlayerId'] as String?,
        targetPosition: a['targetX'] != null && a['targetY'] != null
            ? Offset(
                (a['targetX'] as num).toDouble(),
                (a['targetY'] as num).toDouble(),
              )
            : null,
        sequenceNumber: a['sequenceNumber'] as int,
        delay: Duration(milliseconds: a['delayMs'] as int? ?? 500),
        description: a['description'] as String?,
      );
    }).toList();

    return HandballPlay(
      id: data.id,
      name: data.name,
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: data.description,
      defensiveFormation: _parseDefensiveFormation(data.defensiveFormation),
    );
  }

  static PlayerPosition _parsePosition(String position) {
    return PlayerPosition.values.firstWhere(
      (p) => p.name == position,
      orElse: () => PlayerPosition.centerBack,
    );
  }

  static ActionType _parseActionType(String type) {
    return ActionType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => ActionType.move,
    );
  }

  static DefensiveFormation _parseDefensiveFormation(String? formation) {
    if (formation == null) return DefensiveFormation.sixZero;
    return DefensiveFormation.values.firstWhere(
      (f) => f.name == formation,
      orElse: () => DefensiveFormation.sixZero,
    );
  }

  static HandballPlay getDefaultPlay(String playName) {
    switch (playName) {
      case 'Leer 1':
        return _createLeer1();
      case 'Leer 2':
        return _createLeer2();
      case '10-1':
        return _create10_1();
      case '10-2':
        return _create10_2();
      default:
        return _createDefaultPlay(playName);
    }
  }

  static HandballPlay _create10_1() {
    // 10-1 - Spielzug über links mit Kreissperre
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.1, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a2',
        name: 'LR',
        position: PlayerPosition.leftBack,
        initialPosition: Offset(0.25, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.5),
        color: Colors.blue,
      ),
      const Player(
        id: 'a4',
        name: 'RR',
        position: PlayerPosition.rightBack,
        initialPosition: Offset(0.75, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.9, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a6',
        name: 'KM',
        position: PlayerPosition.pivot,
        initialPosition: Offset(0.5, 0.2),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd1',
        name: 'D1',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, 0.25),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'D2',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'D4',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'D5',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'D6',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, 0.25),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.pass,
        playerId: 'a5',
        targetPlayerId: 'a4',
        sequenceNumber: 1,
        description: 'Pass von RW zu RR',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a3',
        sequenceNumber: 2,
        description: 'Pass von RR zu RM',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a2',
        sequenceNumber: 3,
        description: 'Pass von RM zu LR',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a1',
        sequenceNumber: 4,
        description: 'Pass von LR zu LW',
      ),
      const PlayAction(
        id: 'act5',
        type: ActionType.pass,
        playerId: 'a1',
        targetPlayerId: 'a2',
        sequenceNumber: 5,
        description: 'Pass von LW zurück zu LR',
      ),
      const PlayAction(
        id: 'act6',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a3',
        sequenceNumber: 6,
        description: 'Pass von LR zu RM',
      ),
      const PlayAction(
        id: 'act7',
        type: ActionType.screen,
        playerId: 'a6',
        targetPosition: Offset(0.35, 0.28),
        sequenceNumber: 7,
        description: 'KM stellt Sperre für LR',
      ),
      const PlayAction(
        id: 'act8',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a2',
        sequenceNumber: 8,
        description: 'Pass von RM zurück zu LR',
      ),
      const PlayAction(
        id: 'act9',
        type: ActionType.move,
        playerId: 'a2',
        targetPosition: Offset(0.3, 0.25),
        sequenceNumber: 9,
        description: 'LR nutzt Sperre und stößt durch',
      ),
      const PlayAction(
        id: 'act10',
        type: ActionType.shoot,
        playerId: 'a2',
        sequenceNumber: 10,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_10_1',
      name: '10-1',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Spielzug über links mit Kreissperre',
    );
  }

  static HandballPlay _create10_2() {
    // 10-2 - Spielzug über rechts mit Kreissperre (Spiegelbild)
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.1, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a2',
        name: 'LR',
        position: PlayerPosition.leftBack,
        initialPosition: Offset(0.25, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.5),
        color: Colors.blue,
      ),
      const Player(
        id: 'a4',
        name: 'RR',
        position: PlayerPosition.rightBack,
        initialPosition: Offset(0.75, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.9, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a6',
        name: 'KM',
        position: PlayerPosition.pivot,
        initialPosition: Offset(0.5, 0.2),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd1',
        name: 'D1',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, 0.25),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'D2',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'D4',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'D5',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'D6',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, 0.25),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.pass,
        playerId: 'a1',
        targetPlayerId: 'a2',
        sequenceNumber: 1,
        description: 'Pass von LW zu LR',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a3',
        sequenceNumber: 2,
        description: 'Pass von LR zu RM',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a4',
        sequenceNumber: 3,
        description: 'Pass von RM zu RR',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a5',
        sequenceNumber: 4,
        description: 'Pass von RR zu RW',
      ),
      const PlayAction(
        id: 'act5',
        type: ActionType.pass,
        playerId: 'a5',
        targetPlayerId: 'a4',
        sequenceNumber: 5,
        description: 'Pass von RW zurück zu RR',
      ),
      const PlayAction(
        id: 'act6',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a3',
        sequenceNumber: 6,
        description: 'Pass von RR zu RM',
      ),
      const PlayAction(
        id: 'act7',
        type: ActionType.screen,
        playerId: 'a6',
        targetPosition: Offset(0.65, 0.28),
        sequenceNumber: 7,
        description: 'KM stellt Sperre für RR',
      ),
      const PlayAction(
        id: 'act8',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a4',
        sequenceNumber: 8,
        description: 'Pass von RM zurück zu RR',
      ),
      const PlayAction(
        id: 'act9',
        type: ActionType.move,
        playerId: 'a4',
        targetPosition: Offset(0.7, 0.25),
        sequenceNumber: 9,
        description: 'RR nutzt Sperre und stößt durch',
      ),
      const PlayAction(
        id: 'act10',
        type: ActionType.shoot,
        playerId: 'a4',
        sequenceNumber: 10,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_10_2',
      name: '10-2',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Spielzug über rechts mit Kreissperre',
    );
  }

  static HandballPlay _createLeer1() {
    // Leer 1 - Kreuztausch auf der linken Seite
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.1, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a2',
        name: 'LR',
        position: PlayerPosition.leftBack,
        initialPosition: Offset(0.25, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.5),
        color: Colors.blue,
      ),
      const Player(
        id: 'a4',
        name: 'RR',
        position: PlayerPosition.rightBack,
        initialPosition: Offset(0.75, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.9, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a6',
        name: 'KM',
        position: PlayerPosition.pivot,
        initialPosition: Offset(0.5, 0.2),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd1',
        name: 'D1',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, 0.25),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'D2',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'D4',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'D5',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'D6',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, 0.25),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a3',
        sequenceNumber: 1,
        description: 'Pass von LR zu RM',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a2',
        sequenceNumber: 2,
        description: 'Pass zurück von RM zu LR',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.move,
        playerId: 'a3',
        targetPosition: Offset(0.75, 0.48),
        sequenceNumber: 3,
        description: 'RM läuft nach halb rechts',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.move,
        playerId: 'a4',
        targetPosition: Offset(0.5, 0.5),
        sequenceNumber: 4,
        description: 'RR läuft zur Mitte (Kreuztausch)',
      ),
      const PlayAction(
        id: 'act5',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a4',
        sequenceNumber: 5,
        description: 'Pass von LR zum neuen RM (ehemals RR)',
      ),
      const PlayAction(
        id: 'act6',
        type: ActionType.move,
        playerId: 'a4',
        targetPosition: Offset(0.5, 0.35),
        sequenceNumber: 6,
        description: 'Neuer RM durchstößt nach vorne',
      ),
      const PlayAction(
        id: 'act7',
        type: ActionType.shoot,
        playerId: 'a4',
        sequenceNumber: 7,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_leer_1',
      name: 'Leer 1',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Kreuztausch über links mit Durchstoß',
    );
  }

  static HandballPlay _createLeer2() {
    // Leer 2 - Kreuztausch auf der rechten Seite
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.1, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a2',
        name: 'LR',
        position: PlayerPosition.leftBack,
        initialPosition: Offset(0.25, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.5),
        color: Colors.blue,
      ),
      const Player(
        id: 'a4',
        name: 'RR',
        position: PlayerPosition.rightBack,
        initialPosition: Offset(0.75, 0.45),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.9, 0.35),
        color: Colors.blue,
      ),
      const Player(
        id: 'a6',
        name: 'KM',
        position: PlayerPosition.pivot,
        initialPosition: Offset(0.5, 0.2),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd1',
        name: 'D1',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, 0.25),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'D2',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'D4',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, 0.3),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'D5',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, 0.28),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'D6',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, 0.25),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a3',
        sequenceNumber: 1,
        description: 'Pass von RR zu RM',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a4',
        sequenceNumber: 2,
        description: 'Pass zurück von RM zu RR',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.move,
        playerId: 'a3',
        targetPosition: Offset(0.25, 0.48),
        sequenceNumber: 3,
        description: 'RM läuft nach halb links',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.move,
        playerId: 'a2',
        targetPosition: Offset(0.5, 0.5),
        sequenceNumber: 4,
        description: 'LR läuft zur Mitte (Kreuztausch)',
      ),
      const PlayAction(
        id: 'act5',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a2',
        sequenceNumber: 5,
        description: 'Pass von RR zum neuen RM (ehemals LR)',
      ),
      const PlayAction(
        id: 'act6',
        type: ActionType.move,
        playerId: 'a2',
        targetPosition: Offset(0.5, 0.35),
        sequenceNumber: 6,
        description: 'Neuer RM durchstößt nach vorne',
      ),
      const PlayAction(
        id: 'act7',
        type: ActionType.shoot,
        playerId: 'a2',
        sequenceNumber: 7,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_leer_2',
      name: 'Leer 2',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Kreuztausch über rechts mit Durchstoß',
    );
  }

  static HandballPlay _createDefaultPlay(String name) {
    // Generic play for demo or unknown plays
    final attackingPlayers = [
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.5),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.3),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.move,
        playerId: 'a3',
        targetPosition: Offset(0.5, 0.3),
        sequenceNumber: 1,
        description: 'Bewegung nach vorne',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.shoot,
        playerId: 'a3',
        sequenceNumber: 2,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_default',
      name: name,
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Einfacher Spielzug',
    );
  }
}
