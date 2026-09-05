import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device.dart';

class Ble_manager {

  const Ble_manager();

  Future<int> scan_devices() async {
    final results = <DeviceIdentifier, ScanResult>{};

    print("Bluetooth state: ${await FlutterBluePlus.adapterState.first}");

    final subscription = FlutterBluePlus.onScanResults.listen(
      (scan_results) {
        print("Got ${scan_results.length} scan results");

        for (final result in scan_results) {
          results[result.device.remoteId] = result;
        }
      },
      onError: (error) {
        print("SCAN ERROR: $error");
      },
    );

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    await FlutterBluePlus.isScanning
    .where((state) => state == false)
    .first;

    await subscription.cancel();

    for (final entry in results.values) {
      print("UUID: ${entry.device.remoteId}");
      print("Name: ${entry.advertisementData.advName}");
    }

    print("HEEEEELP");
    print(results.length);

    return 0;
  }

}
