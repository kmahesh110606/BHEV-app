/// URJAA Unified Open EV Network — API Configuration
class ApiConfig {
  // Live Azure Production Endpoint
  static const String defaultBaseUrl =
      'https://bhev-api.wittybay-7a064b00.centralindia.azurecontainerapps.io';

  // Local fallback endpoints
  static const String localAndroidUrl = 'http://10.0.2.2:3000';
  static const String localIosUrl = 'http://localhost:3000';

  static String baseUrl = defaultBaseUrl;

  // ── Authentication & User Endpoints ──
  static String get register => '$baseUrl/api/v1/auth/register';
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get profile => '$baseUrl/api/v1/users/me';
  static String get updateRole => '$baseUrl/api/v1/users/me/role';

  // ── Public Stations & Discovery ──
  static String get stations => '$baseUrl/api/v1/stations';
  static String get nearbyStations => '$baseUrl/api/v1/stations/nearby';
  static String stationDetails(String id) => '$baseUrl/api/v1/stations/$id';
  static String get availability => '$baseUrl/api/v1/availability';

  // ── Bookings & Slot Reservations ──
  static String get createBooking => '$baseUrl/api/v1/bookings';
  static String get myBookings => '$baseUrl/api/v1/bookings/me';
  static String bookingDetails(String id) => '$baseUrl/api/v1/bookings/$id';

  // ── Physical Proof-of-Presence & Dynamic QR ──
  static String get verifyArrivalQr => '$baseUrl/api/v1/arrivals/verify';
  static String stationDynamicQr(String stationId) =>
      '$baseUrl/api/v1/operator/mock-stations/$stationId/dynamic-qr';

  // ── Live Charging Sessions & Payments ──
  static String get activeSession => '$baseUrl/api/v1/sessions/active';
  static String get sessionHistory => '$baseUrl/api/v1/sessions/me';
  static String sessionDetails(String id) => '$baseUrl/api/v1/sessions/$id';
  static String stopSession(String id) => '$baseUrl/api/v1/sessions/$id/stop';
  static String paySession(String id) => '$baseUrl/api/v1/sessions/$id/pay';

  // ── Kiosk Hardware & Telemetry ──
  static String kioskState(String stationId) =>
      '$baseUrl/api/v1/kiosk/$stationId/state';
  static String kioskTelemetry(String stationId) =>
      '$baseUrl/api/v1/kiosk/$stationId/telemetry';
  static String kioskStart(String stationId) =>
      '$baseUrl/api/v1/kiosk/$stationId/start-session';
  static String kioskStop(String stationId) =>
      '$baseUrl/api/v1/kiosk/$stationId/stop-session';

  // ── URJAA CPO Operator Enterprise Suite ──
  static String get operatorProfile => '$baseUrl/api/v1/operator/profile';
  static String get operatorStations => '$baseUrl/api/v1/operator/stations';
  static String operatorStationDetails(String id) =>
      '$baseUrl/api/v1/operator/stations/$id';
  static String operatorAddCharger(String stationId) =>
      '$baseUrl/api/v1/operator/stations/$stationId/chargers';
  static String operatorUpdateCharger(String chargerId) =>
      '$baseUrl/api/v1/operator/chargers/$chargerId';
  static String operatorChargerMaintenance(String chargerId) =>
      '$baseUrl/api/v1/operator/chargers/$chargerId/maintenance';
  static String operatorChargerMaintenanceEnd(String chargerId) =>
      '$baseUrl/api/v1/operator/chargers/$chargerId/maintenance/end';

  static String get operatorBookings => '$baseUrl/api/v1/operator/bookings';
  static String get operatorQueue => '$baseUrl/api/v1/operator/queue';
  static String get operatorNoShowCheck =>
      '$baseUrl/api/v1/operator/no-show/check';
  static String get operatorSessions => '$baseUrl/api/v1/operator/sessions';

  static String get operatorReviews => '$baseUrl/api/v1/operator/reviews';
  static String operatorReviewResponse(String reviewId) =>
      '$baseUrl/api/v1/operator/reviews/$reviewId/response';

  static String get operatorIssues => '$baseUrl/api/v1/operator/issues';
  static String operatorResolveIssue(String issueId) =>
      '$baseUrl/api/v1/operator/issues/$issueId/resolve';

  static String get operatorPricingRules =>
      '$baseUrl/api/v1/operator/pricing-rules';
  static String get operatorRevenueAnalytics =>
      '$baseUrl/api/v1/operator/analytics/revenue';
  static String get operatorNotifications =>
      '$baseUrl/api/v1/operator/notifications';
  static String get operatorReadNotifications =>
      '$baseUrl/api/v1/operator/notifications/read-all';

  static String get operatorSyncMockStations =>
      '$baseUrl/api/v1/operator/mock-stations/sync';
}
