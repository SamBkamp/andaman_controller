import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device.dart';
import 'schedule.dart';
import 'dart:async';
import 'dart:typed_data';

class Ble_manager {

  static const doser_service_uuid           = "8b7668b1-2fa9-40ac-5208-1aa51d1ee896";
  static const dosing_characteristic_uuid   = "8b7668b1-2fa9-5ed0-5208-1aa51d1ee896";
  static const schedule_characteristic_uuid = "8b7668b1-2fa9-ed5c-5208-1aa51d1ee896";
  static const device_info_uuid             = "8b7668b1-2fa9-f013-5208-1aa51d1ee896";
  static const calibration_uuid             = "8b7668b1-2fa9-1bca-5208-1aa51d1ee896";
  static const write_direction_uuid         = "8b7668b1-2fa9-4ed1-5208-1aa51d1ee896";
  static const devname_uuid                 = "8b7668b1-2fa9-9e4a-5208-1aa51d1ee896";
  static const auto_cal_uuid                = "8b7668b1-2fa9-5110-5208-1aa51d1ee896";
  static const timed_sched_uuid             = "8b7668b1-2fa9-ed71-5208-1aa51d1ee896";


  final results = <DeviceIdentifier, ScanResult>{};
  var devices = <DoserDevice>[];
  DateTime? last_scan;
  bool scanning = false;
  BluetoothDevice? connected_device;
  final _connection_state_controller = StreamController<bool>.broadcast();
  Stream<bool> get connection_state =>_connection_state_controller.stream;
  StreamSubscription<BluetoothConnectionState>? _connection_sub;

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
    var scan_result = results[uuid];

    //return early if we are already connected
    if(connected_device != null && connected_device!.remoteId.toString() == ddev.uuid){
      return true;
    }

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

    //only connect to one device at a time
    if(connected_device != null){
      await connected_device!.disconnect();
      connected_device = null;
    }

    try {
      await scan_result.device.connect();
    } catch (e) {
      print("Connection failed: $e");
      return false;
    }

    connected_device = scan_result.device;
    listen_to_device();

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

          case devname_uuid:
          ddev.characteristics[DoserEndpoint.devname.index] = characteristic;
          break;

          case timed_sched_uuid:
          ddev.characteristics[DoserEndpoint.timedsched.index] = characteristic;

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

    //get periodic schedule
    var characteristic = ddev.characteristics[DoserEndpoint.schedule.index];
    if (characteristic == null) {
      return retval;
    }

    List<int> val = await characteristic.read();
    String valString = String.fromCharCodes(val);
    print(valString);

    if(valString[0] == 't'){ //if the result starts with t, the active dose type is timed.
      retval.type = ScheduleType.timed;
      valString = valString.substring(1); //skip first character
    }

    List<String> parts = valString.split(",");
    retval.ml = parts[0];
    retval.period = parts[1];
    print(retval.period);

    //get timed schedule

    characteristic = ddev.characteristics[DoserEndpoint.timedsched.index];
    if (characteristic == null) {
      return retval;
    }
    val = await characteristic.read();

    for (int i = 0; i < val.length; i += 4) {
      int amount_raw = (val[i + 2]>>8) | val[i + 3];

      retval.entries.add(TimedScheduleEntry(
          hours: val[i],
          minutes: val[i + 1],
          amount: amount_raw / 100.0,
      ));
    }

    return retval;
  }

  Future<bool> setSchedule(DoserDevice ddev, Schedule sched) async {
    final characteristic = sched.type == ScheduleType.timed ? ddev.characteristics[DoserEndpoint.timedsched.index] : ddev.characteristics[DoserEndpoint.schedule.index];
    List<int> data = [];
    String sendVal = "";

    if (characteristic == null) {
      return false;
    }
    if(sched.type == ScheduleType.continuous){
      String mls = sched.ml;
      sendVal = "c$mls";
      data = sendVal.codeUnits;
    }else if(sched.type == ScheduleType.timed){
      for(int i = 0; i < sched.entries.length; i ++){
        data.add(sched.entries[i].hours);
        data.add(sched.entries[i].minutes);

        int amount = (sched.entries[i].amount *100).round();
        // uint16 little-endian
        data.add(amount & 0xFF);
        data.add((amount >> 8) & 0xFF);

      }

    }else{
      String mls = sched.ml;
      String period = sched.period;
      sendVal = "$mls,$period";
      data = sendVal.codeUnits;
    }

    print(sendVal);

    await characteristic.write(data);

    return true;
  }

  Future<bool> setAutocal(DoserDevice ddev, String mls) async {
    final characteristic = ddev.characteristics[DoserEndpoint.autocal.index];

    if (characteristic == null) {
      return false;
    }

    await characteristic.write(mls.codeUnits);

    return true;

  }

  Future<bool> setNewName(DoserDevice ddev, String name) async {
    final characteristic = ddev.characteristics[DoserEndpoint.devname.index];

    if (characteristic == null) {
      return false;
    }

    await characteristic.write(name.codeUnits);

    return true;
  }

  Future<bool> setSysTime(DoserDevice ddev) async {
    final characteristic = ddev.characteristics[DoserEndpoint.deviceInfo.index];

    if (characteristic == null) {
      return false;
    }


    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Uint8List bytes = (ByteData(8)..setInt64(
        0,
        timestamp,
        Endian.little,
    )).buffer.asUint8List();

    await characteristic.write(bytes);

    return true;

  }


  BluetoothDevice? getBleDevice() {
    return connected_device;
  }

  void listen_to_device() {
    _connection_sub?.cancel();
    final device = connected_device;

    if (device == null) {
      _connection_state_controller.add(false);
      return;
    }
    _connection_sub = device.connectionState.listen((state) {
        if(state == BluetoothConnectionState.disconnected) connected_device = null;
        _connection_state_controller.add(state == BluetoothConnectionState.connected);
    });
  }

  Future<void> dispose() async {
    await _connection_sub?.cancel();
    await _connection_state_controller.close();
  }
}
