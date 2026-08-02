import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'wallpaper_picker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showPairCodeDialog(BuildContext context, AuthProvider auth) {
    final pairController = TextEditingController(text: auth.pairCode);
    final partnerController = TextEditingController(text: auth.partnerName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('2-Person Pair Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pairController,
                decoration: const InputDecoration(
                  labelText: 'Secret Pair Key / Code',
                  hintText: 'e.g. DUO2026',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partnerController,
                decoration: const InputDecoration(
                  labelText: 'Partner Name',
                  hintText: 'e.g. My Favorite Person',
                  prefixIcon: Icon(Icons.favorite_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                auth.updatePairing(
                  pairController.text.trim(),
                  partnerController.text.trim(),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.whatsappAccent,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Current Profile Header Card
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.whatsappAccent,
              child: Text(
                auth.currentUser.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              auth.currentUser.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Pair Key: ${auth.pairCode} • ${auth.isUserA ? 'User A' : 'User B'}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.whatsappAccent),
              onPressed: () => _showPairCodeDialog(context, auth),
            ),
          ),
          const Divider(),

          // Section 1: Pair Role Switcher (1-tap dual testing)
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: AppTheme.whatsappAccent),
            title: const Text('Dual-Role Mode Switcher'),
            subtitle: Text('Currently active as: ${auth.currentUser.name}'),
            trailing: Switch(
              value: auth.isUserA,
              onChanged: (_) => auth.switchRole(),
              activeColor: AppTheme.whatsappAccent,
            ),
          ),

          // Section 2: Wallpaper
          ListTile(
            leading: const Icon(Icons.wallpaper_rounded, color: Colors.blueAccent),
            title: const Text('Chat Wallpaper'),
            subtitle: const Text('Change chat background color & style'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const WallpaperPickerScreen()),
              );
            },
          ),

          // Section 3: Privacy Passcode Lock
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded, color: Colors.amber),
            title: const Text('Passcode Privacy Lock'),
            subtitle: Text(theme.isPasscodeEnabled ? 'Lock enabled (PIN: ${theme.passcode})' : 'Disabled'),
            trailing: Switch(
              value: theme.isPasscodeEnabled,
              onChanged: (val) => theme.setPasscodeEnabled(val),
              activeColor: AppTheme.whatsappAccent,
            ),
          ),

          // Section 4: Theme Dark/Light Mode
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded, color: Colors.purpleAccent),
            title: const Text('Dark Mode Theme'),
            subtitle: const Text('WhatsApp Dark Emerald palette'),
            trailing: Switch(
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggleTheme(),
              activeColor: AppTheme.whatsappAccent,
            ),
          ),

          // Section 5: System Notification Privacy Mode
          ListTile(
            leading: const Icon(Icons.notifications_active_rounded, color: Colors.amber),
            title: const Text('System Notification Privacy'),
            subtitle: Text(
              theme.notificationMode == 0
                  ? 'Discrete Privacy (Safe from Notification Loggers)'
                  : (theme.notificationMode == 1 ? 'Full Text Preview' : 'Off (In-App Only)'),
            ),
            trailing: DropdownButton<int>(
              value: theme.notificationMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Discrete Privacy')),
                DropdownMenuItem(value: 1, child: Text('Full Preview')),
                DropdownMenuItem(value: 2, child: Text('Off')),
              ],
              onChanged: (val) {
                if (val != null) theme.setNotificationMode(val);
              },
            ),
          ),

          const Divider(),

          // Section 6: Clear Chat History for Both Sides
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            title: const Text('Clear Chat for Both Sides', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Permanently delete all messages for both users'),
            onTap: () {
              final chat = Provider.of<ChatProvider>(context, listen: false);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat for Both Sides?'),
                  content: const Text(
                    'This will permanently delete all text messages in this 2-person room for both you and your partner. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        chat.clearAllMessagesForBoth();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All messages deleted for both sides'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                      label: const Text('Clear for Both'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              'DuoChat v1.0 • Private 2-Person WhatsApp Clone',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
