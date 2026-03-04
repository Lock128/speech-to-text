import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gameplay_models.dart';
import '../models/handball_models.dart';
import '../providers/gameplay_provider.dart';
import '../providers/auth_provider.dart';
import '../services/handball_play_service.dart';
import '../services/defensive_formation_service.dart';
import '../widgets/handball_court.dart';
import 'home_screen.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  @override
  void initState() {
    super.initState();
    // Sync organization on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOrganization();
    });
  }

  void _syncOrganization() {
    final authProvider = context.read<AuthProvider>();
    final gameplayProvider = context.read<GameplayProvider>();
    gameplayProvider.setOrganization(authProvider.selectedOrganization);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gameplay'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<GameplayProvider>(
            builder: (context, provider, _) {
              if (provider.selectedTeam == null || provider.currentOrganization == null) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Manage Spielzüge',
                onPressed: () => _showManageDialog(context, provider),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<GameplayProvider, AuthProvider>(
          builder: (context, gameplayProvider, authProvider, _) {
            // Check if user is authenticated
            if (!authProvider.isAuthenticated) {
              return _buildUnauthenticatedView(context, authProvider);
            }

            // Sync organization if it changed
            if (gameplayProvider.currentOrganization != authProvider.selectedOrganization) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                gameplayProvider.setOrganization(authProvider.selectedOrganization);
              });
            }

            // Check if organization is selected
            if (authProvider.selectedOrganization == null) {
              return _buildNoOrganizationView(context);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team Selection
                  _buildTeamSelector(context, gameplayProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Spielzug Dropdown
                  if (gameplayProvider.selectedTeam != null) ...[
                    _buildSpielzugDropdown(context, gameplayProvider),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Selected Spielzug Display
                  if (gameplayProvider.selectedSpielzug != null) ...[
                    _buildSelectedSpielzugCard(context, gameplayProvider),
                    const SizedBox(height: 24),
                    _buildHandballVisualization(context, gameplayProvider),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Authentifizierung erforderlich',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.selectedOrganization == null
                  ? 'Bitte wählen Sie eine Organisation aus und geben Sie Ihren Zugangscode in den Einstellungen ein, um die Gameplay-Funktion zu nutzen.'
                  : 'Bitte geben Sie Ihren Zugangscode in den Einstellungen ein, um die Gameplay-Funktion zu nutzen.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to settings tab
                final homeScreenState = context.findAncestorStateOfType<HomeScreenState>();
                homeScreenState?.navigateToSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Zu den Einstellungen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrganizationView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Organisation ausgewählt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Bitte wählen Sie eine Organisation in den Einstellungen aus.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector(BuildContext context, GameplayProvider provider) {
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
                  'Mannschaft',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Team>(
              value: provider.selectedTeam,
              decoration: const InputDecoration(
                labelText: 'Team auswählen',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: Team.values.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team.displayName),
                );
              }).toList(),
              onChanged: (Team? value) {
                if (value != null) {
                  provider.selectTeam(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpielzugDropdown(BuildContext context, GameplayProvider provider) {
    if (provider.isLoading) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (provider.availableSpielzuege.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.sports_handball,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Spielzüge verfügbar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fügen Sie Spielzüge über das Einstellungsmenü hinzu',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                  Icons.sports_handball,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Spielzug',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Spielzug>(
              value: provider.selectedSpielzug,
              decoration: const InputDecoration(
                labelText: 'Spielzug auswählen',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<Spielzug>(
                  value: null,
                  child: Text('-- Bitte wählen --'),
                ),
                ...provider.availableSpielzuege.map((spielzug) {
                  return DropdownMenuItem(
                    value: spielzug,
                    child: Text(spielzug.name),
                  );
                }).toList(),
              ],
              onChanged: (Spielzug? value) {
                provider.selectSpielzug(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSpielzugCard(BuildContext context, GameplayProvider provider) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.sports_handball,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ausgewählter Spielzug',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.selectedSpielzug!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => provider.clearSelection(),
              icon: const Icon(Icons.clear),
              label: const Text('Auswahl aufheben'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandballVisualization(BuildContext context, GameplayProvider provider) {
    final selectedSpielzug = provider.selectedSpielzug!;
    final play = HandballPlayService.getPlay(
      selectedSpielzug.name,
      backendData: selectedSpielzug.backendData,
    );
    
    return _HandballPlayVisualization(play: play);
  }

  void _showManageDialog(BuildContext context, GameplayProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ManageSpielzuegeDialog(provider: provider),
    );
  }
}

class _HandballPlayVisualization extends StatefulWidget {
  final HandballPlay play;

  const _HandballPlayVisualization({required this.play});

  @override
  State<_HandballPlayVisualization> createState() => _HandballPlayVisualizationState();
}

class _HandballPlayVisualizationState extends State<_HandballPlayVisualization> {
  bool _isAnimating = false;
  double _animationSpeed = 1.0; // 1.0 = normal speed
  DefensiveFormation _selectedFormation = DefensiveFormation.sixZero;
  late HandballPlay _currentPlay;
  int _currentActionIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPlay = widget.play;
  }

  void _updateFormation(DefensiveFormation formation) {
    setState(() {
      _selectedFormation = formation;
      // Don't stop animation, just update the formation
      
      // Update play with new defensive formation
      final newDefenders = DefensiveFormationService.getDefendersForFormation(formation);
      _currentPlay = _currentPlay.copyWith(
        defendingPlayers: newDefenders,
        defensiveFormation: formation,
      );
    });
  }

  void _onAnimationProgress(int actionIndex) {
    if (mounted && _currentActionIndex != actionIndex) {
      setState(() {
        _currentActionIndex = actionIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spielzug Visualisierung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isAnimating ? Icons.stop : Icons.play_arrow),
                      onPressed: () {
                        setState(() {
                          _isAnimating = !_isAnimating;
                        });
                      },
                      tooltip: _isAnimating ? 'Stop' : 'Play',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {
                          _isAnimating = false;
                          _currentActionIndex = 0;
                        });
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            setState(() {
                              _isAnimating = true;
                            });
                          }
                        });
                      },
                      tooltip: 'Restart',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFormationSelector(context),
            const SizedBox(height: 16),
            HandballCourt(
              play: _currentPlay,
              isAnimating: _isAnimating,
              animationSpeed: _animationSpeed,
              onAnimationProgress: _onAnimationProgress,
              onAnimationComplete: () {
                if (mounted) {
                  setState(() {
                    _isAnimating = false;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_currentPlay.description != null) ...[
              Text(
                _currentPlay.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            _buildActionSteps(context),
            const SizedBox(height: 16),
            _buildLegend(context),
            const SizedBox(height: 16),
            _buildSpeedControl(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationSelector(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.shield,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Abwehr:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: DefensiveFormation.values.map((formation) {
              final isSelected = _selectedFormation == formation;
              return ChoiceChip(
                label: Text(formation.code),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _updateFormation(formation);
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControl(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.speed,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Geschwindigkeit:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Slider(
            value: _animationSpeed,
            min: 0.25,
            max: 2.0,
            divisions: 7,
            label: '${_animationSpeed.toStringAsFixed(2)}x',
            onChanged: (value) {
              setState(() {
                _animationSpeed = value;
              });
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${_animationSpeed.toStringAsFixed(2)}x',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSteps(BuildContext context) {
    if (_currentPlay.actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Spielzug-Schritte',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_currentPlay.actions.length, (index) {
          final action = _currentPlay.actions[index];
          final isActive = _isAnimating && index == _currentActionIndex;
          final isCompleted = _isAnimating && index < _currentActionIndex;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getActionIcon(action.type),
                          const SizedBox(width: 4),
                          Text(
                            _getActionTypeLabel(action.type),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (action.description != null)
                        Text(
                          action.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Icon _getActionIcon(ActionType type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case ActionType.pass:
        iconData = Icons.arrow_forward;
        color = Colors.blue;
        break;
      case ActionType.move:
        iconData = Icons.directions_run;
        color = Colors.green;
        break;
      case ActionType.shoot:
        iconData = Icons.sports_handball;
        color = Colors.orange;
        break;
      case ActionType.screen:
        iconData = Icons.block;
        color = Colors.purple;
        break;
      case ActionType.cut:
        iconData = Icons.call_split;
        color = Colors.teal;
        break;
    }
    
    return Icon(iconData, size: 14, color: color);
  }

  String _getActionTypeLabel(ActionType type) {
    switch (type) {
      case ActionType.pass:
        return 'Pass';
      case ActionType.move:
        return 'Bewegung';
      case ActionType.shoot:
        return 'Wurf';
      case ActionType.screen:
        return 'Block';
      case ActionType.cut:
        return 'Schnitt';
    }
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(context, Colors.blue.shade700, 'Angriff'),
        _buildLegendItem(context, Colors.red.shade700, 'Verteidigung'),
        _buildLegendItem(context, Colors.orange, 'Ball'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ManageSpielzuegeDialog extends StatefulWidget {
  final GameplayProvider provider;

  const _ManageSpielzuegeDialog({required this.provider});

  @override
  State<_ManageSpielzuegeDialog> createState() => _ManageSpielzuegeDialogState();
}

class _ManageSpielzuegeDialogState extends State<_ManageSpielzuegeDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Spielzüge verwalten - ${widget.provider.selectedTeam?.displayName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add new Spielzug
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Neuer Spielzug',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      await widget.provider.addSpielzug(name);
                      _nameController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // List of existing Spielzüge
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.provider.availableSpielzuege.length,
                itemBuilder: (context, index) {
                  final spielzug = widget.provider.availableSpielzuege[index];
                  return ListTile(
                    title: Text(spielzug.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(spielzug),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          onPressed: () => _confirmDelete(spielzug),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Zurücksetzen'),
                content: const Text('Alle Spielzüge auf Standardwerte zurücksetzen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Zurücksetzen'),
                  ),
                ],
              ),
            );
            
            if (confirm == true && mounted) {
              await widget.provider.resetToDefaults();
            }
          },
          child: const Text('Zurücksetzen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  void _showEditDialog(Spielzug spielzug) {
    final editController = TextEditingController(text: spielzug.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spielzug bearbeiten'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                await widget.provider.updateSpielzug(spielzug.id, newName);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Spielzug spielzug) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen'),
        content: Text('Spielzug "${spielzug.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await widget.provider.removeSpielzug(spielzug.id);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
