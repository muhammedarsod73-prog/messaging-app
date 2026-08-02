import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class WallpaperPickerScreen extends StatelessWidget {
  const WallpaperPickerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    final wallpapers = [
      {'style': ChatWallpaperStyle.whatsappDark, 'title': 'WhatsApp Dark'},
      {'style': ChatWallpaperStyle.whatsappEmerald, 'title': 'WhatsApp Emerald'},
      {'style': ChatWallpaperStyle.solidMidnight, 'title': 'Solid Midnight'},
      {'style': ChatWallpaperStyle.deepCharcoal, 'title': 'Deep Charcoal'},
      {'style': ChatWallpaperStyle.lightDoodle, 'title': 'Light Classic'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Wallpaper'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          final item = wallpapers[index];
          final style = item['style'] as ChatWallpaperStyle;
          final title = item['title'] as String;
          final isSelected = theme.wallpaperStyle == style;
          final previewColor = AppTheme.getWallpaperBackgroundColor(style, true);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.wallpaper_rounded, color: Colors.white70),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.whatsappAccent)
                  : null,
              onTap: () {
                theme.setWallpaperStyle(style);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
