import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Organization? _selectedOrganization;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  Organization? get selectedOrganization => _selectedOrganization;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    _selectedOrganization = await _authService.getOrganization();
    _isAuthenticated = await _authService.isAuthenticated();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectOrganization(Organization organization) async {
    // If changing organization, logout first
    if (_selectedOrganization != null && _selectedOrganization != organization) {
      await logout();
    }
    
    _selectedOrganization = organization;
    await _authService.saveOrganization(organization);
    notifyListeners();
  }

  Future<bool> authenticate(String key) async {
    if (_selectedOrganization == null) return false;

    final success = await _authService.authenticate(_selectedOrganization!, key);
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _authService.clearAll();
    _selectedOrganization = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
