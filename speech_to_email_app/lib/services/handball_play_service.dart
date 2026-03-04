import 'package:flutter/material.dart';
import '../models/handball_models.dart';

class HandballPlayService {
  // Sample plays for demonstration
  static HandballPlay getDefaultPlay(String playName) {
    switch (playName) {
      case 'Angriff Links':
        return _createAngriffLinks();
      case 'Angriff Rechts':
        return _createAngriffRechts();
      case 'Konter Mitte':
        return _createKonterMitte();
      case 'Tempogegenstoß':
        return _createTempogegenstoss();
      case 'Kreis Anspiel':
        return _createKreisAnspiel();
      default:
        return _createDefaultPlay(playName);
    }
  }

  static HandballPlay _createAngriffLinks() {
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
        playerId: 'a3',
        targetPlayerId: 'a2',
        sequenceNumber: 1,
        description: 'Pass von RM zu LR',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.move,
        playerId: 'a1',
        targetPosition: Offset(0.15, 0.25),
        sequenceNumber: 2,
        description: 'LW schneidet nach innen',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.pass,
        playerId: 'a2',
        targetPlayerId: 'a1',
        sequenceNumber: 3,
        description: 'Pass zu LW',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.shoot,
        playerId: 'a1',
        sequenceNumber: 4,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_angriff_links',
      name: 'Angriff Links',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Angriff über die linke Seite mit Schnittbewegung',
    );
  }

  static HandballPlay _createAngriffRechts() {
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
        playerId: 'a3',
        targetPlayerId: 'a4',
        sequenceNumber: 1,
        description: 'Pass von RM zu RR',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.move,
        playerId: 'a5',
        targetPosition: Offset(0.85, 0.25),
        sequenceNumber: 2,
        description: 'RW schneidet nach innen',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.pass,
        playerId: 'a4',
        targetPlayerId: 'a5',
        sequenceNumber: 3,
        description: 'Pass zu RW',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.shoot,
        playerId: 'a5',
        sequenceNumber: 4,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_angriff_rechts',
      name: 'Angriff Rechts',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Angriff über die rechte Seite',
    );
  }

  static HandballPlay _createKonterMitte() {
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.1, 0.6),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.7),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.9, 0.6),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd3',
        name: 'D3',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, 0.4),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'D4',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, 0.4),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.move,
        playerId: 'a3',
        targetPosition: Offset(0.5, 0.4),
        sequenceNumber: 1,
        description: 'RM läuft nach vorne',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.move,
        playerId: 'a3',
        targetPosition: Offset(0.5, 0.25),
        sequenceNumber: 2,
        description: 'RM durchbricht Abwehr',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.shoot,
        playerId: 'a3',
        sequenceNumber: 3,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_konter_mitte',
      name: 'Konter Mitte',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Schneller Konter durch die Mitte',
    );
  }

  static HandballPlay _createTempogegenstoss() {
    final attackingPlayers = [
      const Player(
        id: 'a1',
        name: 'LW',
        position: PlayerPosition.leftWing,
        initialPosition: Offset(0.2, 0.8),
        color: Colors.blue,
      ),
      const Player(
        id: 'a3',
        name: 'RM',
        position: PlayerPosition.centerBack,
        initialPosition: Offset(0.5, 0.9),
        color: Colors.blue,
      ),
      const Player(
        id: 'a5',
        name: 'RW',
        position: PlayerPosition.rightWing,
        initialPosition: Offset(0.8, 0.8),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
      const Player(
        id: 'd1',
        name: 'D1',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.3, 0.5),
        color: Colors.red,
      ),
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.move,
        playerId: 'a1',
        targetPosition: Offset(0.15, 0.4),
        sequenceNumber: 1,
        description: 'LW sprintet nach vorne',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a1',
        sequenceNumber: 2,
        description: 'Langer Pass zu LW',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.move,
        playerId: 'a1',
        targetPosition: Offset(0.2, 0.15),
        sequenceNumber: 3,
        description: 'LW läuft aufs Tor',
      ),
      const PlayAction(
        id: 'act4',
        type: ActionType.shoot,
        playerId: 'a1',
        sequenceNumber: 4,
        description: 'Wurf aufs Tor',
      ),
    ];

    return HandballPlay(
      id: 'play_tempogegenstoss',
      name: 'Tempogegenstoß',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Schneller Gegenstoß mit langem Pass',
    );
  }

  static HandballPlay _createKreisAnspiel() {
    final attackingPlayers = [
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
        id: 'a6',
        name: 'KM',
        position: PlayerPosition.pivot,
        initialPosition: Offset(0.5, 0.2),
        color: Colors.blue,
      ),
    ];

    final defendingPlayers = [
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
    ];

    final actions = [
      const PlayAction(
        id: 'act1',
        type: ActionType.move,
        playerId: 'a6',
        targetPosition: Offset(0.4, 0.18),
        sequenceNumber: 1,
        description: 'KM bewegt sich nach links',
      ),
      const PlayAction(
        id: 'act2',
        type: ActionType.pass,
        playerId: 'a3',
        targetPlayerId: 'a6',
        sequenceNumber: 2,
        description: 'Pass zu KM',
      ),
      const PlayAction(
        id: 'act3',
        type: ActionType.shoot,
        playerId: 'a6',
        sequenceNumber: 3,
        description: 'Wurf vom Kreis',
      ),
    ];

    return HandballPlay(
      id: 'play_kreis_anspiel',
      name: 'Kreis Anspiel',
      attackingPlayers: attackingPlayers,
      defendingPlayers: defendingPlayers,
      actions: actions,
      description: 'Anspiel zum Kreisläufer',
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
