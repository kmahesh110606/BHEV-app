import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/station.dart';

class NavigationLauncher {
  static Uri googleMapsUri(Station station) => Uri.https(
        'www.google.com',
        '/maps/dir/',
        {
          'api': '1',
          'destination': '${station.lat},${station.lng}',
          'travelmode': 'driving',
        },
      );

  static Uri mapplsUri(Station station) => Uri.https(
        'www.mappls.com',
        '/direction',
        {
          'source': 'Current Location',
          'destination': '${station.lat},${station.lng}',
        },
      );

  static Future<void> openGoogle(BuildContext context, Station station) =>
      _open(context, googleMapsUri(station), 'Google Maps');

  static Future<void> openMappls(BuildContext context, Station station) =>
      _open(context, mapplsUri(station), 'Mappls');

  static Future<void> _open(
      BuildContext context, Uri uri, String provider) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$provider navigation could not be opened.')),
      );
    }
  }
}
