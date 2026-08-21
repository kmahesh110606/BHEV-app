import 'dart:async';

// This is a minimal scaffold for BLE interaction. On a real device use flutter_blue_plus
class BluetoothService {
  bool simulate = true;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get onData => _controller.stream;

  void startSimulation() {
    simulate = true;
    Timer.periodic(Duration(seconds: 2), (t) {
      if (!simulate) {
        t.cancel();
        return;
      }
      _controller.add({'power_kw': 7.2, 'voltage': 400, 'current': 18});
    });
  }

  void stopSimulation() {
    simulate = false;
  }
}

final bluetoothService = BluetoothService();
