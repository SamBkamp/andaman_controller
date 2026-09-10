import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device.dart';

class Ble_manager {
  final results = <DeviceIdentifier, ScanResult>{};
  var devices = <DoserDevice>[];

  Ble_manager();

  Future<List<DoserDevice>> scan_devices() async {
    print("Bluetooth state: ${await FlutterBluePlus.adapterState.first}");

    final state = await FlutterBluePlus.adapterState.firstWhere(
      (state) =>
      state == BluetoothAdapterState.on ||
      state == BluetoothAdapterState.off,
    );

    if(state == BluetoothAdapterState.off) throw Exception("Bluetooth turned off");

    final subscription = FlutterBluePlus.onScanResults.listen(
      (scan_results) {

        for (final result in scan_results) {
          results[result.device.remoteId] = result;
        }
      },
      onError: (error) {
        print("SCAN ERROR: $error");
      },
    );

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 3),
    );

    await FlutterBluePlus.isScanning
    .where((state) => state == false)
    .first;

    await subscription.cancel();

    for (final entry in results.values) {
      if(entry.advertisementData.advName.length > 1){
        print("UUID: ${entry.device.remoteId}");
        print("Name: ${entry.advertisementData.advName}");
        devices.add(DoserDevice(
            uuid: entry.device.remoteId.toString(),
            name: entry.advertisementData.advName,
          ),
        );
      }

    }
    print(results.length);

    return devices;
  }


  Future<bool> connect_to_device(DoserDevice ddev) async{
    final uuid = DeviceIdentifier(ddev.uuid);
    final scan_result = results[uuid];

    if (scan_result == null) {
      print("Connection failed: scan_result was NULL");
      return false;
    }

    try {
      await scan_result.device.connect();
    } catch (e) {
      print("Connection failed: $e");
      return false;
    }

    final services = await device.discoverServices();

    for (final service in services) {
      print("Service: ${service.uuid}");

      for (final characteristic in service.characteristics) {
        print("  Characteristic: ${characteristic.uuid}");
        print("  Read: ${characteristic.properties.read}");
        print("  Write: ${characteristic.properties.write}");
        print("  Notify: ${characteristic.properties.notify}");
      }
    }

    return true;
  }


}
