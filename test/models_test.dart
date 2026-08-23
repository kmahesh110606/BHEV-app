import 'package:flutter_test/flutter_test.dart';
import 'package:uei_app/models/user_model.dart';
import 'package:uei_app/models/station_model.dart';
import 'package:uei_app/models/booking_model.dart';
import 'package:uei_app/models/session_model.dart';
import 'package:uei_app/models/operator_models.dart';

void main() {
  group('Models Serialization & Logic Tests', () {
    test('UserModel parse and role checks', () {
      final user = UserModel.fromJson({
        'id': 'u123',
        'email': 'driver@test.com',
        'name': 'Test Driver',
        'role': 'customer',
      });
      expect(user.id, 'u123');
      expect(user.isOperator, isFalse);

      final opUser = UserModel.fromJson({
        'id': 'op123',
        'email': 'operator@chargegrid.in',
        'role': 'operator',
      });
      expect(opUser.isOperator, isTrue);
    });

    test('StationModel parse and fast DC detection', () {
      final station = StationModel.fromJson({
        'id': 'st_01',
        'name': 'Koramangala DC Fast Hub',
        'address': '80 Feet Road',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'latitude': 12.9352,
        'longitude': 77.6245,
        'rating': 4.9,
        'connectors': [
          {
            'id': 'c1',
            'standard': 'CCS2',
            'powerType': 'DC',
            'maxPowerKw': 60.0,
            'status': 'AVAILABLE',
            'tariff': {'pricePerKwh': 14.5, 'flatFee': 20.0},
          }
        ],
      });

      expect(station.isFastDc, isTrue);
      expect(station.maxPowerKw, 60);
      expect(station.baseTariffPerKwh, 14.5);
      expect(station.availableConnectors, 1);
    });

    test('BookingModel parse and lifecycle', () {
      final booking = BookingModel.fromJson({
        'id': 'bk_123',
        'slotStart': '2026-08-23T10:00:00.000Z',
        'slotEnd': '2026-08-23T10:30:00.000Z',
        'status': 'CONFIRMED',
        'totalCost': 320.0,
      });

      expect(booking.isActive, isTrue);
      expect(booking.totalCost, 320.0);
    });

    test('SessionModel parse and telemetry calculation', () {
      final session = SessionModel.fromJson({
        'id': 'sess_123',
        'stationName': 'Indiranagar Fast Hub',
        'energyWh': 24500,
        'liveCost': 355.25,
        'status': 'ACTIVE',
        'powerKw': 58.4,
        'socPercent': 68.0,
      });

      expect(session.energyKwh, 24.5);
      expect(session.isActive, isTrue);
      expect(session.socPercent, 68.0);
    });

    test('OperatorKpis parse', () {
      final kpis = OperatorKpis.fromJson({
        'totalRevenue': 95000.0,
        'activeSessions': 6,
        'totalEnergyDeliveredKwh': 7200.5,
        'fleetUtilizationPercent': 82.4,
      });

      expect(kpis.totalRevenue, 95000.0);
      expect(kpis.activeSessions, 6);
      expect(kpis.fleetUtilizationPercent, 82.4);
    });
  });
}
