import '../models/station.dart';

/// Clearly labelled preview data keeps the consumer journey reviewable before
/// a production operator feed has been connected to the hosted API.
const demoStations = <Station>[
  Station(
    id: 'demo-koramangala',
    name: 'Koramangala Fast Hub',
    lat: 12.9352,
    lng: 77.6245,
    address: '80 Feet Road, Koramangala',
    city: 'Bengaluru',
    operatorName: 'CHARGEGRID Demo Network',
    isMock: true,
    isDemo: true,
    rating: 4.8,
    reliabilityScore: 92,
    availableConnectors: 3,
    connectors: [
      Connector(
          id: 'demo-kora-ccs',
          standard: 'CCS2',
          powerType: 'DC Fast',
          maxPowerKw: 60,
          status: 'AVAILABLE'),
      Connector(
          id: 'demo-kora-type2',
          standard: 'Type 2',
          powerType: 'AC',
          maxPowerKw: 22,
          status: 'AVAILABLE'),
      Connector(
          id: 'demo-kora-busy',
          standard: 'CCS2',
          powerType: 'DC Fast',
          maxPowerKw: 60,
          status: 'OCCUPIED'),
    ],
  ),
  Station(
    id: 'demo-indiranagar',
    name: 'Indiranagar Mobility Point',
    lat: 12.9784,
    lng: 77.6408,
    address: '100 Feet Road, Indiranagar',
    city: 'Bengaluru',
    operatorName: 'CHARGEGRID Demo Network',
    isMock: true,
    isDemo: true,
    rating: 4.6,
    reliabilityScore: 81,
    availableConnectors: 1,
    connectors: [
      Connector(
          id: 'demo-indira-ccs',
          standard: 'CCS2',
          powerType: 'DC Fast',
          maxPowerKw: 50,
          status: 'AVAILABLE'),
      Connector(
          id: 'demo-indira-type2',
          standard: 'Type 2',
          powerType: 'AC',
          maxPowerKw: 22,
          status: 'OCCUPIED'),
    ],
  ),
  Station(
    id: 'demo-electronic-city',
    name: 'Electronic City EV Plaza',
    lat: 12.8456,
    lng: 77.6603,
    address: 'Phase 1, Electronic City',
    city: 'Bengaluru',
    operatorName: 'CHARGEGRID Demo Network',
    isMock: true,
    isDemo: true,
    rating: 4.3,
    reliabilityScore: 70,
    availableConnectors: 1,
    connectors: [
      Connector(
          id: 'demo-ecity-ccs',
          standard: 'CCS2',
          powerType: 'DC Fast',
          maxPowerKw: 120,
          status: 'AVAILABLE'),
      Connector(
          id: 'demo-ecity-gbt',
          standard: 'GBT DC',
          powerType: 'DC Fast',
          maxPowerKw: 60,
          status: 'UNAVAILABLE'),
    ],
  ),
];
