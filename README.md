# CHARGEGRID Flutter App

Flutter discovery and booking client for the CHARGEGRID unified EV charging API.

Run:

1. cd App
2. flutter pub get
3. Download the Mappls configuration files for this Android/iOS package from the Mappls console and add them as directed by the `mappls_gl` package.
4. flutter run --dart-define=CHARGEGRID_API_URL=https://your-api.azurewebsites.net

The app uses `mappls_gl` for its embedded Mappls map. A Mappls key/configuration is required for maps and navigation; it is not committed to this repository.
