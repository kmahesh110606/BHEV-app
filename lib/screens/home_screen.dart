import 'package:flutter/material.dart';
// import 'dart:math';
import '../services/api_service.dart';
import '../main.dart';
import 'station_details.dart';
import '../widgets/glass_container.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

final apiService = ApiService(backendBase);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: apiService.fetchStations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final stations = snapshot.data ?? [];
            final featured = stations.isNotEmpty ? stations[0] : null;
            return Stack(children: [
              // map placeholder
              Positioned.fill(
                child: Container(color: const Color(0xFF081014)),
              ),
              // top search + filters
              Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(children: [
                    Expanded(
                        child: GlassContainer(
                            child: Row(children: [
                      const Icon(FluentIcons.search_24_regular,
                          color: Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Search station, area or route...',
                          style: TextStyle(color: Colors.white54))
                    ]))),
                    const SizedBox(width: 8),
                    GlassContainer(
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(FluentIcons.person_24_regular,
                                color: Colors.white60)))
                  ])),

              // featured bottom card
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      GlassContainer(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(featured?.name ?? 'No station',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                  '${featured?.waitTimeMin ?? 0} min • ${(featured?.tariff != null ? featured!.tariff!['power'] : '—')} kW',
                                  style: const TextStyle(color: Colors.white54))
                            ])),
                        Column(children: [
                          Text('${featured?.waitTimeMin ?? 0}',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF39FF96))),
                          const SizedBox(height: 8),
                          ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => StationDetailsScreen(
                                          stationId: featured?.id ?? ''))),
                              child: const Text('VIEW STATION'))
                        ])
                      ])),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(FluentIcons.map_24_regular,
                                    color: Colors.white70)),
                            Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF08C96A),
                                    shape: BoxShape.circle),
                                child: Icon(FluentIcons.flash_24_regular,
                                    color: Colors.white, size: 36)),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(FluentIcons.history_24_regular,
                                    color: Colors.white70)),
                          ])
                    ]),
                  ))
            ]);
          },
        ),
      ),
    );
  }
}
