import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DoserEndpoint {
  deviceInfo,
  dose,
  schedule,
  autocal,
  direction,
  devname,
  timedsched,
  ota_update,
  tz_update,
}


class DoserDevice {
  String name;
  String uuid;
  List<BluetoothCharacteristic?> characteristics = List.filled(DoserEndpoint.values.length, null);
  BluetoothDevice? device;

  DoserDevice({
    required this.name,
    required this.uuid,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uuid': uuid,
    };
  }

  factory DoserDevice.fromJson(Map<String, dynamic> json) {
    return DoserDevice(
      name: json['name'],
      uuid: json['uuid'],
    );
  }

  void setName(String newName){
    this.name = newName;
  }
}

class DeviceRegistry extends ChangeNotifier{
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  List<DoserDevice> devices = [];

  Future<void> load() async {
    print('-----------------------------------------------------');
    final stored = await prefs.getString('devices');

    if (stored == null) {
      devices = [];
      return;
    }

    final List<dynamic> jsonList = jsonDecode(stored);

    devices = jsonList
    .map((json) => DoserDevice.fromJson(json))
    .toList();

  }

  Future<void> _update_device_nvs() async {
    final jsonList = devices
    .map((device) => device.toJson())
    .toList();

    await prefs.setString(
      'devices',
      jsonEncode(jsonList),
    );
  }

  Future<void> delete(DoserDevice device) async {
    devices.remove(device);
    _update_device_nvs();
    notifyListeners();
  }

  Future<void> add(DoserDevice device) async {
    devices.add(device);
    _update_device_nvs();
    notifyListeners();
  }

  int total_devices() {
    return devices.length;
  }

  DoserDevice device_by_index(int index) {
    return devices[index];
  }

  //get devices without loading from nvs
  List<DoserDevice> devices_noload() {
    return devices;
  }

  Future<void> update_name(DoserDevice device, String name) async{
    final ddev_idx = devices.indexOf(device);
    if(ddev_idx >= 0){
      devices[ddev_idx].name = name;
      _update_device_nvs();
    }

  }

}
