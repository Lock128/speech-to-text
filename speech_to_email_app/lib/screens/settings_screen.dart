import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/gameplay_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _isKeyVisible = false;
  bool _useBackendApi = false;
  final GameplayService _gameplayService = GameplayService();

  @override
  void initState() {
    super.initState();
    _loadBackendSetting();
  }

  Future<void> _loadBackendSetting() async {
    final useBackend = await _gameplayService.shouldUseBackend();
    setState(() {
      _useBackendApi = useBackend;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader(context, 'Authentication'),
                _buildOrganizationSelector(context, authProvider),
                const SizedBox(height: 8),
                _buildAuthenticationCard(context, authProvider),
                const Divider(height: 32),
                
                _buildSectionHeader(context, 'Data Source'),
                _buildBackendApiToggle(context),
                const Divider(height: 32),
                
                _buildSectionHeader(context, 'General'),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {
                // TODO: Implement notifications settings
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () {
                // TODO: Implement language selection
              },
            ),
            const Divider(height: 32),
            
            _buildSectionHeader(context, 'Audio'),
            _buildSettingsTile(
              context,
              icon: Icons.mic,
              title: 'Microphone',
              subtitle: 'Configure microphone settings',
              onTap: () {
                // TODO: Implement microphone settings
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.high_quality,
              title: 'Audio Quality',
              subtitle: 'High',
              onTap: () {
                // TODO: Implement audio quality settings
              },
            ),
            const Divider(height: 32),
            
            _buildSectionHeader(context, 'Account'),
            _buildSettingsTile(
              context,
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Manage your profile',
              onTap: () {
                // TODO: Implement profile settings
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.email_outlined,
              title: 'Email Preferences',
              subtitle: 'Configure email delivery',
              onTap: () {
                // TODO: Implement email preferences
              },
            ),
            const Divider(height: 32),
            
            _buildSectionHeader(context, 'About'),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'View privacy policy',
              onTap: () {
                // TODO: Show privacy policy
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'View terms of service',
              onTap: () {
                // TODO: Show terms of service
              },
            ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackendApiToggle(BuildContext context) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        secondary: Icon(
          _useBackendApi ? Icons.cloud : Icons.storage,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Use Backend API'),
        subtitle: Text(
          _useBackendApi 
              ? 'Spielzüge werden vom Backend geladen' 
              : 'Spielzüge werden lokal gespeichert',
        ),
        value: _useBackendApi,
        onChanged: (bool value) async {
          await _gameplayService.setUseBackend(value);
          setState(() {
            _useBackendApi = value;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value 
                      ? 'Backend API aktiviert - Spielzüge werden vom Server geladen'
                      : 'Backend API deaktiviert - Spielzüge werden lokal gespeichert',
                ),
                backgroundColor: value ? Colors.blue : Colors.grey,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOrganizationSelector(BuildContext context, AuthProvider authProvider) {
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
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Organization',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Organization>(
              value: authProvider.selectedOrganization,
              decoration: const InputDecoration(
                labelText: 'Select Organization',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: Organization.values.map((org) {
                return DropdownMenuItem(
                  value: org,
                  child: Text(org.displayName),
                );
              }).toList(),
              onChanged: (Organization? value) async {
                if (value != null && value != authProvider.selectedOrganization) {
                  // If user is authenticated, show confirmation dialog
                  if (authProvider.isAuthenticated) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Organization'),
                        content: const Text(
                          'Changing organization will log you out. You will need to authenticate again with the new organization\'s access key.\n\nDo you want to continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm != true) return;
                  }
                  
                  await authProvider.selectOrganization(value);
                  _keyController.clear();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Organization changed to ${value.displayName}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationCard(BuildContext context, AuthProvider authProvider) {
    final isAuthenticated = authProvider.isAuthenticated;
    final hasOrganization = authProvider.selectedOrganization != null;

    return Card(
      elevation: 2,
      color: isAuthenticated 
          ? Colors.green.shade50 
          : (hasOrganization ? null : Colors.grey.shade100),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.lock_open : Icons.lock_outline,
                  color: isAuthenticated 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Access Key',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isAuthenticated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Authenticated',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!hasOrganization) ...[
              Text(
                'Please select an organization first',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else if (isAuthenticated) ...[
              Text(
                'You are authenticated and can use the Upload feature.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && mounted) {
                    await authProvider.logout();
                    _keyController.clear();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ] else ...[
              TextField(
                controller: _keyController,
                obscureText: !_isKeyVisible,
                decoration: InputDecoration(
                  labelText: 'Enter Access Key',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isKeyVisible = !_isKeyVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final key = _keyController.text.trim();
                    if (key.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an access key'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final success = await authProvider.authenticate(key);
                    
                    if (mounted) {
                      if (success) {
                        _keyController.clear();
                        setState(() {
                          _isKeyVisible = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid access key. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Authenticate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
