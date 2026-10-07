import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device.dart';
import 'schedule.dart';

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
  DateTime? last_scan;
  bool scanning = false;
  BluetoothDevice? connected_device;

  Ble_manager();

  Future<List<DoserDevice>> scan_devices() async {

    while(scanning){
      await Future.delayed(const Duration(milliseconds: 100));
    }

    //keep a scan cache
    if(last_scan != null
      && DateTime.now().difference(last_scan!) < const Duration(seconds: 20)){
      return devices;
    }

    scanning = true;

    try {
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
      last_scan = DateTime.now();
      return devices;

    } finally {
      scanning = false;
    }

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

    //enumerating the endpoints into a list for later recall
    for (final service in services) {
      print("Service: ${service.uuid}");

      for (final characteristic in service.characteristics) {
        switch(characteristic.uuid.str){
          case dosing_characteristic_uuid:
          ddev.characteristics[DoserEndpoint.dose.index] = characteristic;
          break;

          case schedule_characteristic_uuid:
          ddev.characteristics[DoserEndpoint.schedule.index] = characteristic;
          break;

          case device_info_uuid:
          ddev.characteristics[DoserEndpoint.deviceInfo.index] = characteristic;
          break;

          case calibration_uuid:
          break;

          case write_direction_uuid:
          ddev.characteristics[DoserEndpoint.direction.index] = characteristic;
          break;

          case auto_cal_uuid:
          ddev.characteristics[DoserEndpoint.autocal.index] = characteristic;
          break;

          default:
          break;
        }
        print("    ${characteristic.uuid}");
      }
    }

    return true;
  }

  Future<void> disconnect_from_device(DoserDevice ddev) async {
    if(connected_device == null) return;
    await connected_device!.disconnect();
    connected_device = null;

  }

  Future<bool> manual_dose(DoserDevice ddev, String mls) async{

    print("manually dosing ${mls} mls");

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

  Future<Schedule> getSchedule(DoserDevice ddev) async {
    Schedule retval = Schedule(ScheduleType.periodic, "2.5");
    final characteristic = ddev.characteristics[DoserEndpoint.schedule.index];
    if (characteristic == null) {
      return retval;
    }

    final val = await characteristic.read();
    String valString = String.fromCharCodes(val);
    print(valString);

    if(valString[0] == 'c' || valString.substring(valString.length - 6) == "ml/min"){

      retval.type = ScheduleType.continuous;
      retval.ml = valString.substring(0, 4); //skip first character
    }else {
      List<String> parts = valString.split(",");
      retval.ml = parts[0];
      retval.period = parts[1];
    }

    return retval;
  }

  Future<bool> setSchedule(DoserDevice ddev, Schedule sched) async {
    final characteristic = ddev.characteristics[DoserEndpoint.schedule.index];
    String sendVal = "";
    if (characteristic == null) {
      return false;
    }
    if(sched.type == ScheduleType.continuous){
      String mls = sched.ml;
      sendVal = "c$mls";
    }else{
      String mls = sched.ml;
      String period = sched.period;
      sendVal = "$mls,$period";
    }

    await characteristic.write(sendVal.codeUnits);

    return true;
  }
}
