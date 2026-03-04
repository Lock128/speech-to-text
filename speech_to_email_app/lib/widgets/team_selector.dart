import 'package:flutter/material.dart';
import '../models/team_models.dart';
import '../services/team_config_service.dart';

class TeamSelector extends StatefulWidget {
  final TeamInfo? selectedTeam;
  final ValueChanged<TeamInfo?> onTeamSelected;
  final ValueChanged<String>? onCoachChanged;
  final ValueChanged<List<String>>? onPlayersChanged;

  const TeamSelector({
    super.key,
    required this.selectedTeam,
    required this.onTeamSelected,
    this.onCoachChanged,
    this.onPlayersChanged,
  });

  @override
  State<TeamSelector> createState() => _TeamSelectorState();
}

class _TeamSelectorState extends State<TeamSelector> {
  List<TeamInfo> _teams = [];
  bool _isLoading = true;
  final TextEditingController _coachController = TextEditingController();
  final TextEditingController _playerController = TextEditingController();
  List<String> _additionalPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _updateCoachController();
  }

  @override
  void didUpdateWidget(TeamSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTeam != widget.selectedTeam) {
      _updateCoachController();
      _additionalPlayers.clear();
    }
  }

  void _updateCoachController() {
    _coachController.text = widget.selectedTeam?.coach ?? '';
  }

  @override
  void dispose() {
    _coachController.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final teams = await TeamConfigService.loadTeams();
    if (mounted) {
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    }
  }

  void _addPlayer() {
    final playerName = _playerController.text.trim();
    if (playerName.isNotEmpty) {
      setState(() {
        _additionalPlayers.add(playerName);
        _playerController.clear();
      });
      _notifyPlayersChanged();
    }
  }

  void _removePlayer(String player) {
    setState(() {
      _additionalPlayers.remove(player);
    });
    _notifyPlayersChanged();
  }

  void _notifyPlayersChanged() {
    if (widget.onPlayersChanged != null && widget.selectedTeam != null) {
      final allPlayers = [
        ...widget.selectedTeam!.players,
        ..._additionalPlayers,
      ];
      widget.onPlayersChanged!(allPlayers);
    }
  }

  List<String> _getAllPlayers() {
    if (widget.selectedTeam == null) return [];
    return [
      ...widget.selectedTeam!.players,
      ..._additionalPlayers,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Team Selection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TeamInfo>(
              value: widget.selectedTeam,
              decoration: const InputDecoration(
                labelText: 'Select Team',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<TeamInfo>(
                  value: null,
                  child: Text('-- No Team Selected --'),
                ),
                ..._teams.map((team) {
                  return DropdownMenuItem(
                    value: team,
                    child: Text('${team.displayName} (Coach: ${team.coach})'),
                  );
                }).toList(),
              ],
              onChanged: widget.onTeamSelected,
            ),
            if (widget.selectedTeam != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Editable Coach Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _coachController,
                      decoration: InputDecoration(
                        labelText: 'Coach',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          onPressed: () {
                            if (widget.onCoachChanged != null) {
                              widget.onCoachChanged!(_coachController.text.trim());
                            }
                          },
                          tooltip: 'Update Coach',
                        ),
                      ),
                      onSubmitted: (value) {
                        if (widget.onCoachChanged != null) {
                          widget.onCoachChanged!(value.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Players Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Players (${_getAllPlayers().length}):',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddPlayerDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Player', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Roster Players (from config)
              if (widget.selectedTeam!.players.isNotEmpty) ...[
                Text(
                  'Roster:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.selectedTeam!.players.map((player) {
                    return Chip(
                      label: Text(
                        player,
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blue.shade50,
                    );
                  }).toList(),
                ),
              ],
              
              // Additional Players
              if (_additionalPlayers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Additional Players:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _additionalPlayers.map((player) {
                    return Chip(
                      label: Text(
                        player,
                        style: const TextStyle(fontSize: 11),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removePlayer(player),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.green.shade50,
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: TextField(
          controller: _playerController,
          decoration: const InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
            hintText: 'Enter player name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) {
            _addPlayer();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _playerController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addPlayer();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
