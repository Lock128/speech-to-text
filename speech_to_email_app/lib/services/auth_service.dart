import 'package:shared_preferences/shared_preferences.dart';

enum Organization {
  hcVflHeppenheim('HC VfL Heppenheim', 'NibelungenhalleCoach'),
  demo('Demo', 'demo_key_2024');

  final String displayName;
  final String accessKey;

  const Organization(this.displayName, this.accessKey);

  static Organization? fromDisplayName(String name) {
    try {
      return Organization.values.firstWhere((org) => org.displayName == name);
    } catch (e) {
      return null;
    }
  }
}

class AuthService {
  static const String _orgKey = 'selected_organization';
  static const String _authKey = 'auth_key';
  static const String _isAuthenticatedKey = 'is_authenticated';

  Future<void> saveOrganization(Organization organization) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orgKey, organization.displayName);
  }

  Future<Organization?> getOrganization() async {
    final prefs = await SharedPreferences.getInstance();
    final orgName = prefs.getString(_orgKey);
    if (orgName == null) return null;
    return Organization.fromDisplayName(orgName);
  }

  Future<bool> authenticate(Organization organization, String key) async {
    if (key == organization.accessKey) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orgKey, organization.displayName);
      await prefs.setString(_authKey, key);
      await prefs.setBool(_isAuthenticatedKey, true);
      return true;
    }
    return false;
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_isAuthenticatedKey) ?? false;
    
    if (!isAuth) return false;

    // Verify the stored key matches the organization
    final orgName = prefs.getString(_orgKey);
    final storedKey = prefs.getString(_authKey);
    
    if (orgName == null || storedKey == null) return false;

    final org = Organization.fromDisplayName(orgName);
    if (org == null) return false;

    return storedKey == org.accessKey;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.setBool(_isAuthenticatedKey, false);
    // Keep organization selected but remove authentication
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orgKey);
    await prefs.remove(_authKey);
    await prefs.remove(_isAuthenticatedKey);
  }
}
