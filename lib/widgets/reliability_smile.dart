import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/station.dart';

/// Turns the station's operator quality and live connector state into a
/// booking-confidence signal. The API remains the source of connector status;
/// this presentation layer makes that status legible before a driver commits.
class StationReliability {
  final int score;
  final int available;
  final int total;
  final int operatorScore;

  const StationReliability(
      {required this.score,
      required this.available,
      required this.total,
      required this.operatorScore});

  factory StationReliability.fromStation(Station station) {
    final total = station.connectors.isNotEmpty
        ? station.connectors.length
        : math.max(station.availableConnectors, 1);
    final available = station.availableConnectors.clamp(0, total);
    final operatorScore = station.reliabilityScore.clamp(0, 100);
    final base = operatorScore == 0 ? 58 : operatorScore;
    final availabilitySignal = (available / total) * 100;
    final score =
        (base * 0.65 + availabilitySignal * 0.35).round().clamp(0, 100);
    return StationReliability(
        score: score,
        available: available,
        total: total,
        operatorScore: operatorScore);
  }

  bool get canBook => available > 0;
  bool get isExcellent => score >= 82 && canBook;
  bool get isGood => score >= 62 && canBook;

  String get headline => isExcellent
      ? 'Great time to book'
      : isGood
          ? 'Looking good'
          : canBook
              ? 'Book with a backup plan'
              : 'Not ready right now';

  String get shortLabel => isExcellent
      ? 'Reliable now'
      : isGood
          ? 'Available now'
          : canBook
              ? 'Limited availability'
              : 'Currently busy';

  String get emoji => isExcellent
      ? '😊'
      : isGood
          ? '🙂'
          : canBook
              ? '😐'
              : '😕';

  Color get color => isExcellent
      ? const Color(0xFF72DFA7)
      : isGood
          ? const Color(0xFF83CBF7)
          : canBook
              ? const Color(0xFFFFC46B)
              : const Color(0xFFFF8B85);

  List<String> get signals => [
        '$available of $total connectors ready',
        operatorScore == 0
            ? 'Operator score is still building'
            : 'Operator reliability $operatorScore%',
        canBook
            ? 'A connector can be reserved now'
            : 'No live connector is free yet',
      ];
}

class ReliabilitySmile extends StatelessWidget {
  final Station station;
  final bool compact;
  final bool showSignals;

  const ReliabilitySmile(
      {super.key,
      required this.station,
      this.compact = false,
      this.showSignals = false});

  @override
  Widget build(BuildContext context) {
    final reliability = StationReliability.fromStation(station);
    final faceSize = compact ? 54.0 : 78.0;
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 14),
      decoration: BoxDecoration(
        color: reliability.color.withValues(alpha: compact ? 0.08 : 0.11),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: reliability.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmileFace(
                  emoji: reliability.emoji,
                  color: reliability.color,
                  size: faceSize),
              SizedBox(width: compact ? 8 : 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reliability.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: reliability.color,
                            fontSize: compact ? 12 : 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${reliability.score}% booking confidence',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.77),
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (showSignals) ...[
            const SizedBox(height: 13),
            ...reliability.signals.map((signal) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: reliability.color),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(signal,
                            style: const TextStyle(
                                color: Color(0xFFC7D0DD), fontSize: 12))),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}

class _SmileFace extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  const _SmileFace(
      {required this.emoji, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.94),
            color.withValues(alpha: 0.60)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 20,
                spreadRadius: 1)
          ],
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.49)),
      );
}
