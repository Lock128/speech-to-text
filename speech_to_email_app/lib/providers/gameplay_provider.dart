import 'package:flutter/foundation.dart';
import '../models/gameplay_models.dart';
import '../services/gameplay_service.dart';
import '../services/auth_service.dart';

class GameplayProvider extends ChangeNotifier {
  final GameplayService _gameplayService = GameplayService();

  Team? _selectedTeam;
  Spielzug? _selectedSpielzug;
  List<Spielzug> _availableSpielzuege = [];
  bool _isLoading = false;
  Organization? _currentOrganization;

  Team? get selectedTeam => _selectedTeam;
  Spielzug? get selectedSpielzug => _selectedSpielzug;
  List<Spielzug> get availableSpielzuege => _availableSpielzuege;
  bool get isLoading => _isLoading;
  Organization? get currentOrganization => _currentOrganization;

  void setOrganization(Organization? organization) {
    if (_currentOrganization != organization) {
      _currentOrganization = organization;
      // Reset selections when organization changes
      _selectedTeam = null;
      _selectedSpielzug = null;
      _availableSpielzuege = [];
      notifyListeners();
    }
  }

  Future<void> selectTeam(Team team) async {
    if (_currentOrganization == null) return;

    _selectedTeam = team;
    _selectedSpielzug = null;
    _isLoading = true;
    notifyListeners();

    _availableSpielzuege = await _gameplayService.getSpielzuegeForTeam(team, _currentOrganization!);
    _isLoading = false;
    notifyListeners();
  }

  void selectSpielzug(Spielzug? spielzug) {
    _selectedSpielzug = spielzug;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSpielzug = null;
    notifyListeners();
  }

  Future<void> addSpielzug(String name) async {
    if (_selectedTeam == null || _currentOrganization == null) return;

    await _gameplayService.addSpielzug(_selectedTeam!, name, _currentOrganization!);
    await _refreshSpielzuege();
  }

  Future<void> removeSpielzug(String id) async {
    if (_selectedTeam == null || _currentOrganization == null) return;

    await _gameplayService.removeSpielzug(_selectedTeam!, id, _currentOrganization!);
    
    // Clear selection if the removed Spielzug was selected
    if (_selectedSpielzug?.id == id) {
      _selectedSpielzug = null;
    }
    
    await _refreshSpielzuege();
  }

  Future<void> updateSpielzug(String id, String newName) async {
    if (_selectedTeam == null || _currentOrganization == null) return;

    await _gameplayService.updateSpielzug(_selectedTeam!, id, newName, _currentOrganization!);
    
    // Update selection if the updated Spielzug was selected
    if (_selectedSpielzug?.id == id) {
      _selectedSpielzug = Spielzug(id: id, name: newName, team: _selectedTeam!);
    }
    
    await _refreshSpielzuege();
  }

  Future<void> resetToDefaults() async {
    if (_selectedTeam == null || _currentOrganization == null) return;

    await _gameplayService.resetToDefaults(_selectedTeam!, _currentOrganization!);
    _selectedSpielzug = null;
    await _refreshSpielzuege();
  }

  Future<void> _refreshSpielzuege() async {
    if (_selectedTeam == null || _currentOrganization == null) return;

    _isLoading = true;
    notifyListeners();

    _availableSpielzuege = await _gameplayService.getSpielzuegeForTeam(_selectedTeam!, _currentOrganization!);
    _isLoading = false;
    notifyListeners();
  }
}
