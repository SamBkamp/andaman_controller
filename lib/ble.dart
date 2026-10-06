import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device.dart';

class Ble_manager {

  static const doser_service_uuid           = "8b7668b1-2fa9-40ac-5208-1aa51d1ee896";
  static const dosing_characteristic_uuid   = "8b7668b1-2fa9-5ed0-5208-1aa51d1ee896";
  static const schedule_characteristic_uuid = "8b7668b1-2fa9-ed5c-5208-1aa51d1ee896";
  static const device_info_uuid             = "8b7668b1-2fa9-f013-5208-1aa51d1ee896";
  static const calibration_uuid             = "8b7668b1-2fa9-1bca-5208-1aa51d1ee896";
  static const write_direction_uuid         = "8b7668b1-2fa9-4ed1-5208-1aa51d1ee896";
  static const devname_uuid                 = "8b7668b1-2fa9-9e4a-5208-1aa51d1ee896";
  static const auto_cal_uuid                = "8b7668b1-2fa9-5110-5208-1aa51d1ee896";


  final results = <DeviceIdentifier, ScanResult>{};
  var devices = <DoserDevice>[];

  Ble_manager();

  Future<List<DoserDevice>> scan_devices() async {
    devices.clear();
    print("Bluetooth state: ${await FlutterBluePlus.adapterState.first}");

    //weird ass hack where first query returns "unknown"
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
      await scan_devices();
      //return false;
    }

    //try a second time just in case there was no init first time around
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

    final services = await scan_result.device.discoverServices();

    for (final service in services) {
      print("Service: ${service.uuid}");

      for (final characteristic in service.characteristics) {
        switch(characteristic.uuid.str){
          case dosing_characteristic_uuid:
          ddev.characteristics[DoserEndpoint.dose.index] = characteristic;
          print("dosing characteristic:");
          break;

          case schedule_characteristic_uuid:
          ddev.characteristics[DoserEndpoint.schedule.index] = characteristic;
          print("schedule characteristic:");
          break;

          case device_info_uuid:
          ddev.characteristics[DoserEndpoint.deviceInfo.index] = characteristic;
          print("device info characteristic:");
          final value = await characteristic.read();
          print("Device info: $value");
          break;

          case calibration_uuid:
          print("calibration characteristic:");
          break;

          case write_direction_uuid:
          ddev.characteristics[DoserEndpoint.direction.index] = characteristic;
          print("dev info characteristic:");
          break;

          case auto_cal_uuid:
          ddev.characteristics[DoserEndpoint.autocal.index] = characteristic;
          print("autocal characteristic:");
          break;

          default:
          print("unknown characteristic:");
          break;
        }
        print("    ${characteristic.uuid}");
      }
    }

    return true;
  }

  Future<bool> manual_dose(DoserDevice ddev, String mls) async{

    print("manually dosing ${mls} mls");
    print("in code units: ${mls.codeUnits}");

    final characteristic = ddev.characteristics[DoserEndpoint.dose.index];


    if (characteristic == null) {
      return false;
    }

    await characteristic.write(mls.codeUnits);

    return true;
  }

  Future<bool> getDirection(DoserDevice ddev) async{
    final characteristic = ddev.characteristics[DoserEndpoint.direction.index];
    if (characteristic == null) {
      return false;
    }

    final val = await characteristic.read();

    return String.fromCharCodes(val) == "CW";
  }

  Future<bool> setDirection(DoserDevice ddev, bool direction) async {
    final characteristic = ddev.characteristics[DoserEndpoint.direction.index];
    if (characteristic == null) {
      return false;
    }

    await characteristic.write([
        direction ? 0x00 : 0x01,
    ]);

    return true;
  }

}
