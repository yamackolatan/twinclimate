import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../theme.dart';

/// Where the app's public pages live (GitHub Pages).
const String siteUrl = 'https://yamackolatan.github.io/twinclimate';
const String privacyUrl = '$siteUrl/privacy.html';
const String supportUrl = '$siteUrl/support.html';

/// About, privacy and data credits. Open-Meteo (CC BY 4.0) and
/// OpenStreetMap (ODbL) require visible attribution.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('About & privacy')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: pagePadding(context),
            children: [
              Text('TwinClimate', style: text.headlineSmall),
              Text('Version $appVersion', style: muted),
              const SizedBox(height: 12),
              Text(
                'Session weather and kit advice for runners, cyclists and '
                'swimmers: what it will feel like, and what to wear and '
                'bring.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text('Your privacy', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                'No account, no ads, no tracking. Your places, races, '
                'comfort profile and packing ticks stay on this device. To '
                'get the weather, the app sends the coordinates of the '
                'place you pick to Open-Meteo; place names come from '
                'OpenStreetMap. Your location is only used when you tap '
                '"Use my location".',
                style: muted,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(privacyUrl),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & feedback'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(supportUrl),
              ),
              const SizedBox(height: 16),
              Text('Data', style: text.titleMedium),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Weather data by Open-Meteo.com'),
                subtitle: const Text('Licensed under CC BY 4.0'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open('https://open-meteo.com/'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.map_outlined),
                title: const Text('Place names © OpenStreetMap contributors'),
                subtitle: const Text('Available under the ODbL'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open('https://www.openstreetmap.org/copyright'),
              ),
              if (shoppingDemo) ...[
                const SizedBox(height: 16),
                Text(
                  'Shop links go to decathlon.nl. Demo — not affiliated '
                  'with Decathlon.',
                  style: muted,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Advice is a guide based on forecasts and typical weather; '
                'always check conditions and stay safe.',
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
