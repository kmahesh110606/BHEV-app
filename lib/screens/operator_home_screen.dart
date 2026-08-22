import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/auth_service.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});
  @override State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  String message = 'Load the labelled mock CPO station display.';
  bool loading = false;
  Future<void> _sync() async {
    setState(() => loading = true);
    try {
      final response = await http.post(Uri.parse('$backendBase/api/v1/operator/mock-stations/sync'), headers: {if (AuthService.currentToken != null) 'Authorization': 'Bearer ${AuthService.currentToken}'});
      if (response.statusCode != 200) throw Exception(response.body);
      final result = Map<String, dynamic>.from((json.decode(response.body) as Map)['data']);
      setState(() => message = 'Normalized ${result['locations']} stations and ${result['connectors']} connectors from the prototype feed.');
    } catch (error) { setState(() => message = '$error'); } finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('CHARGEGRID operator')), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('CPO prototype console', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
    const Text('Only mock data is supported until a CPO authorizes an OCPI or REST adapter.'), const SizedBox(height: 24),
    ElevatedButton(onPressed: loading ? null : _sync, child: Text(loading ? 'Syncing…' : 'Sync mock CPO feed')), const SizedBox(height: 20), Text(message),
  ])));
}
