import 'package:url_launcher/url_launcher.dart';

/// Navigation launcher opening native Google Maps / Apple Maps directions
class NavigationLauncher {
  static Future<bool> openMapDirections(double latitude, double longitude, String label) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$label',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
