import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/handball_models.dart';

class HandballCourt extends StatefulWidget {
  final HandballPlay play;
  final bool isAnimating;
  final double animationSpeed;
  final VoidCallback? onAnimationComplete;

  const HandballCourt({
    super.key,
    required this.play,
    this.isAnimating = false,
    this.animationSpeed = 1.0,
    this.onAnimationComplete,
  });

  @override
  State<HandballCourt> createState() => _HandballCourtState();
}

class _HandballCourtState extends State<HandballCourt> with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentActionIndex = 0;
  Map<String, Offset> _playerPositions = {};
  String? _ballHolderId;
  List<Offset> _ballPath = [];
  static const double _playerRadius = 15.0; // Player circle radius
  static const double _minDistance = 35.0; // Minimum distance between players

  @override
  void initState() {
    super.initState();
    _initializePositions();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (800 / widget.animationSpeed).round()),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentActionIndex < widget.play.actions.length - 1) {
          setState(() {
            _currentActionIndex++;
          });
          _executeAction(widget.play.actions[_currentActionIndex]);
        } else {
          widget.onAnimationComplete?.call();
        }
      }
    });
  }

  void _initializePositions() {
    _playerPositions.clear();
    _ballPath.clear();
    
    // Set initial positions for attacking players
    for (var player in widget.play.attackingPlayers) {
      _playerPositions[player.id] = player.initialPosition;
    }
    
    // Set initial positions for defending players with collision avoidance
    for (var player in widget.play.defendingPlayers) {
      Offset position = player.initialPosition;
      position = _adjustPositionForCollision(player.id, position);
      _playerPositions[player.id] = position;
    }

    // Ball starts with first attacking player
    if (widget.play.attackingPlayers.isNotEmpty) {
      _ballHolderId = widget.play.attackingPlayers.first.id;
    }
  }

  Offset _adjustPositionForCollision(String playerId, Offset targetPosition) {
    // Check for collisions with existing players
    for (var entry in _playerPositions.entries) {
      if (entry.key == playerId) continue;
      
      final distance = _calculateDistance(targetPosition, entry.value);
      if (distance < _minDistance / 1000.0) { // Convert to normalized coordinates
        // Calculate offset direction
        final dx = targetPosition.dx - entry.value.dx;
        final dy = targetPosition.dy - entry.value.dy;
        final angle = dx == 0 && dy == 0 ? 0.0 : (dx.abs() > dy.abs() ? 1.0 : 0.0);
        
        // Offset the position slightly
        if (angle > 0.5) {
          // Horizontal offset
          targetPosition = Offset(
            targetPosition.dx + (dx > 0 ? 0.04 : -0.04),
            targetPosition.dy,
          );
        } else {
          // Vertical offset
          targetPosition = Offset(
            targetPosition.dx,
            targetPosition.dy + (dy > 0 ? 0.03 : -0.03),
          );
        }
      }
    }
    
    return targetPosition;
  }

  double _calculateDistance(Offset pos1, Offset pos2) {
    final dx = pos1.dx - pos2.dx;
    final dy = pos1.dy - pos2.dy;
    return (dx * dx + dy * dy);
  }

  @override
  void didUpdateWidget(HandballCourt oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation duration if speed changed
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      _animationController.duration = Duration(
        milliseconds: (800 / widget.animationSpeed).round(),
      );
    }
    
    // Reinitialize positions if play changed (e.g., defensive formation changed)
    if (widget.play != oldWidget.play) {
      _initializePositions();
    }
    
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _resetAnimation();
    }
  }

  void _startAnimation() {
    setState(() {
      _currentActionIndex = 0;
      _initializePositions();
    });
    
    if (widget.play.actions.isNotEmpty) {
      _executeAction(widget.play.actions[0]);
    }
  }

  void _resetAnimation() {
    _animationController.reset();
    setState(() {
      _currentActionIndex = 0;
      _initializePositions();
      _ballPath.clear();
    });
  }

  void _executeAction(PlayAction action) {
    _animationController.reset();
    
    switch (action.type) {
      case ActionType.pass:
        if (action.targetPlayerId != null) {
          final fromPos = _playerPositions[action.playerId];
          final toPos = _playerPositions[action.targetPlayerId];
          if (fromPos != null && toPos != null) {
            setState(() {
              _ballPath = [fromPos, toPos];
              _ballHolderId = action.targetPlayerId;
            });
          }
        }
        break;
        
      case ActionType.move:
        if (action.targetPosition != null) {
          setState(() {
            // Apply collision avoidance to the target position
            final adjustedPosition = _adjustPositionForCollision(
              action.playerId,
              action.targetPosition!,
            );
            _playerPositions[action.playerId] = adjustedPosition;
          });
        }
        break;
        
      case ActionType.shoot:
        // Animate shot towards goal
        final fromPos = _playerPositions[action.playerId];
        if (fromPos != null) {
          setState(() {
            _ballPath = [fromPos, const Offset(0.5, 0.05)]; // Towards goal
            _ballHolderId = null;
          });
        }
        break;
        
      case ActionType.screen:
      case ActionType.cut:
        if (action.targetPosition != null) {
          setState(() {
            // Apply collision avoidance to the target position
            final adjustedPosition = _adjustPositionForCollision(
              action.playerId,
              action.targetPosition!,
            );
            _playerPositions[action.playerId] = adjustedPosition;
          });
        }
        break;
    }
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: AspectRatio(
          aspectRatio: 20 / 40, // Handball court proportions (half court)
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5B7), // Court color
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: HandballCourtPainter(
                attackingPlayers: widget.play.attackingPlayers,
                defendingPlayers: widget.play.defendingPlayers,
                playerPositions: _playerPositions,
                ballHolderId: _ballHolderId,
                ballPath: _ballPath,
                animationProgress: _animationController.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HandballCourtPainter extends CustomPainter {
  final List<Player> attackingPlayers;
  final List<Player> defendingPlayers;
  final Map<String, Offset> playerPositions;
  final String? ballHolderId;
  final List<Offset> ballPath;
  final double animationProgress;

  HandballCourtPainter({
    required this.attackingPlayers,
    required this.defendingPlayers,
    required this.playerPositions,
    this.ballHolderId,
    required this.ballPath,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCourtLines(canvas, size);
    _drawPlayers(canvas, size);
    _drawBall(canvas, size);
  }

  void _drawCourtLines(Canvas canvas, Size size) {
    final solidPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dottedPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Goal area (6m line - solid)
    final goalAreaRect = Rect.fromLTWH(
      size.width * 0.15,
      0,
      size.width * 0.7,
      size.height * 0.15, // 6m = 15% of half court (40m)
    );
    canvas.drawRect(goalAreaRect, solidPaint);

    // 9m line (free throw line - dotted)
    final nineMLinesY = size.height * 0.225; // 9m = 22.5% of half court
    _drawDottedArc(
      canvas,
      size,
      nineMLinesY,
      dottedPaint,
    );

    // Center line
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      solidPaint,
    );

    // Goal
    final goalPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        0,
        size.width * 0.3,
        size.height * 0.05,
      ),
      goalPaint,
    );
  }

  void _drawDottedArc(Canvas canvas, Size size, double y, Paint paint) {
    final path = Path();
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    
    // Create the arc path
    final startX = size.width * 0.1;
    final endX = size.width * 0.9;
    final controlY = y + size.height * 0.025;
    
    // Draw dotted line manually
    for (double x = startX; x < endX; x += dashWidth + dashSpace) {
      final t1 = (x - startX) / (endX - startX);
      final t2 = ((x + dashWidth) - startX) / (endX - startX);
      
      if (t2 > 1.0) break;
      
      // Calculate points on the quadratic curve
      final x1 = startX + t1 * (endX - startX);
      final y1 = y + t1 * (1 - t1) * 4 * (controlY - y);
      
      final x2 = startX + t2 * (endX - startX);
      final y2 = y + t2 * (1 - t2) * 4 * (controlY - y);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawPlayers(Canvas canvas, Size size) {
    // Draw defending players
    for (var player in defendingPlayers) {
      final position = playerPositions[player.id];
      if (position != null) {
        _drawPlayer(
          canvas,
          size,
          position,
          player,
          Colors.red.shade700,
        );
      }
    }

    // Draw attacking players
    for (var player in attackingPlayers) {
      final position = playerPositions[player.id];
      if (position != null) {
        _drawPlayer(
          canvas,
          size,
          position,
          player,
          Colors.blue.shade700,
        );
      }
    }
  }

  void _drawPlayer(Canvas canvas, Size size, Offset position, Player player, Color color) {
    final center = Offset(
      position.dx * size.width,
      position.dy * size.height,
    );

    // Player circle
    final playerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, playerPaint);

    // Player border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 15, borderPaint);

    // Player position label
    final textPainter = TextPainter(
      text: TextSpan(
        text: player.position.abbreviation,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawBall(Canvas canvas, Size size) {
    if (ballPath.length == 2 && animationProgress > 0) {
      // Animate ball along path
      final start = Offset(
        ballPath[0].dx * size.width,
        ballPath[0].dy * size.height,
      );
      final end = Offset(
        ballPath[1].dx * size.width,
        ballPath[1].dy * size.height,
      );

      final currentPos = Offset.lerp(start, end, animationProgress)!;

      // Draw ball path
      final pathPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, pathPaint);

      // Draw ball
      final ballPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPos, 8, ballPaint);

      final ballBorderPaint = Paint()
        ..color = Colors.orange.shade900
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(currentPos, 8, ballBorderPaint);
    } else if (ballHolderId != null) {
      // Draw ball with player
      final playerPos = playerPositions[ballHolderId];
      if (playerPos != null) {
        final center = Offset(
          playerPos.dx * size.width,
          playerPos.dy * size.height,
        );

        final ballPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center + const Offset(12, -12), 6, ballPaint);

        final ballBorderPaint = Paint()
          ..color = Colors.orange.shade900
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center + const Offset(12, -12), 6, ballBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HandballCourtPainter oldDelegate) {
    return oldDelegate.playerPositions != playerPositions ||
        oldDelegate.ballHolderId != ballHolderId ||
        oldDelegate.ballPath != ballPath ||
        oldDelegate.animationProgress != animationProgress;
  }
}
