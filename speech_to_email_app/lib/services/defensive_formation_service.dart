import 'package:flutter/material.dart';
import '../models/handball_models.dart';

class DefensiveFormationService {
  // Court reference points (as percentage of half court height)
  static const double sixMLine = 0.15;    // 6m line
  static const double eightMLine = 0.20;  // ~8m line
  static const double nineMLine = 0.225;  // 9m line
  static const double tenMLine = 0.25;    // 10m line

  static List<Player> getDefendersForFormation(DefensiveFormation formation) {
    switch (formation) {
      case DefensiveFormation.sixZero:
        return _getSixZeroDefenders();
      case DefensiveFormation.fiveOne:
        return _getFiveOneDefenders();
      case DefensiveFormation.oneFive:
        return _getOneFiveDefenders();
      case DefensiveFormation.threeTwoOne:
        return _getThreeTwoOneDefenders();
    }
  }

  // 6-0: All six defenders on the 6m line
  static List<Player> _getSixZeroDefenders() {
    return [
      const Player(
        id: 'd1',
        name: 'LW',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, sixMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'LR',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, sixMLine + 0.01),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'DCL',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, sixMLine + 0.015),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'DCR',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, sixMLine + 0.015),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'RR',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, sixMLine + 0.01),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'RW',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, sixMLine),
        color: Colors.red,
      ),
    ];
  }

  // 5-1: Five defenders on 6m line, one in center on 9m line
  static List<Player> _getFiveOneDefenders() {
    return [
      const Player(
        id: 'd1',
        name: 'LW',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, sixMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'LR',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, sixMLine + 0.01),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'DCL',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.45, sixMLine + 0.015),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'DCR',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.55, sixMLine + 0.015),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'RW',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, sixMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'RR',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.5, nineMLine), // One advanced in center
        color: Colors.red,
      ),
    ];
  }

  // 1-5: One defender on 6m line (center), five on 9m line
  static List<Player> _getOneFiveDefenders() {
    return [
      const Player(
        id: 'd1',
        name: 'DCL',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.5, sixMLine + 0.015), // One on 6m line
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'LW',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.15, nineMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'LR',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.3, nineMLine + 0.005),
        color: Colors.red,
      ),
      const Player(
        id: 'd4',
        name: 'RR',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.7, nineMLine + 0.005),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'RW',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.85, nineMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd6',
        name: 'DCR',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.5, nineMLine + 0.02), // Back
        color: Colors.red,
      ),
    ];
  }

  // 3-2-1: Three on 6m line (LW, RW, one DC), two on ~8m (LR, RR), one DC on 10m
  static List<Player> _getThreeTwoOneDefenders() {
    return [
      // Front line - 6m
      const Player(
        id: 'd1',
        name: 'LW',
        position: PlayerPosition.defLeftWing,
        initialPosition: Offset(0.2, sixMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd2',
        name: 'DCL',
        position: PlayerPosition.defCenterLeft,
        initialPosition: Offset(0.5, sixMLine + 0.015), // Center front
        color: Colors.red,
      ),
      const Player(
        id: 'd3',
        name: 'RW',
        position: PlayerPosition.defRightWing,
        initialPosition: Offset(0.8, sixMLine),
        color: Colors.red,
      ),
      // Mid line - ~8m
      const Player(
        id: 'd4',
        name: 'LR',
        position: PlayerPosition.defLeftBack,
        initialPosition: Offset(0.35, eightMLine),
        color: Colors.red,
      ),
      const Player(
        id: 'd5',
        name: 'RR',
        position: PlayerPosition.defRightBack,
        initialPosition: Offset(0.65, eightMLine),
        color: Colors.red,
      ),
      // Back - 10m
      const Player(
        id: 'd6',
        name: 'DCR',
        position: PlayerPosition.defCenterRight,
        initialPosition: Offset(0.5, tenMLine),
        color: Colors.red,
      ),
    ];
  }
}
