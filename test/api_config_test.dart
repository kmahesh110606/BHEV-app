import 'package:flutter_test/flutter_test.dart';
import 'package:uei_app/config/api_config.dart';

void main() {
  group('ApiConfig Tests', () {
    test('defaultBaseUrl points to Azure production backend', () {
      expect(
        ApiConfig.defaultBaseUrl,
        'https://bhev-api.wittybay-7a064b00.centralindia.azurecontainerapps.io',
      );
    });

    test('endpoint getters generate valid URI paths', () {
      expect(ApiConfig.login, contains('/api/v1/auth/login'));
      expect(ApiConfig.register, contains('/api/v1/auth/register'));
      expect(ApiConfig.stations, contains('/api/v1/stations'));
      expect(ApiConfig.nearbyStations, contains('/api/v1/stations/nearby'));
      expect(ApiConfig.createBooking, contains('/api/v1/bookings'));
      expect(ApiConfig.verifyArrivalQr, contains('/api/v1/arrivals/verify'));
      expect(ApiConfig.activeSession, contains('/api/v1/sessions/active'));
      expect(ApiConfig.operatorStations, contains('/api/v1/operator/stations'));
      expect(ApiConfig.operatorBookings, contains('/api/v1/operator/bookings'));
      expect(ApiConfig.operatorQueue, contains('/api/v1/operator/queue'));
      expect(ApiConfig.operatorReviews, contains('/api/v1/operator/reviews'));
    });
  });
}
