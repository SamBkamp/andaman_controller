import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';
import 'theme_data.dart';

class DoserPage extends StatefulWidget {
  final DoserDevice device;
  final Ble_manager blemanager;
  final Theme_data theme = const Theme_data();

  const DoserPage({
    super.key,
    required this.device,
    required this.blemanager,
  });

  @override
  State<DoserPage> createState() => _DoserPageState();
}

enum ScheduleType {
  periodic,
  daily,
}

class _DoserPageState extends State<DoserPage> {
  ScheduleType _schedule_type = ScheduleType.periodic;
  bool? connected;
  bool direction = false;
  bool TEST_FLAG = true;
  final dose_controller = TextEditingController();
  final seconds_controller = TextEditingController();
  final insta_dose_amount_controller = TextEditingController();
  final actual_calibration_dose_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connect_device();
  }

  @override
  void dispose() {
    dose_controller.dispose();
    seconds_controller.dispose();
    insta_dose_amount_controller.dispose();
    actual_calibration_dose_controller.dispose();
    super.dispose();
  }

  Future<void> connect_device() async {
    final result = await widget.blemanager.connect_to_device(widget.device);

    setState(() {
        connected = result;
    });
  }


  Widget connection_status() {
    String text = "Disconnected";
    if (connected == null) {
      text = "Connecting...";
    } else if (connected!) {
      text = "Connected";
    }

    return widget.theme.small_text_bold(text);
  }


  void direction_changed(dir){
    setState(() {
        direction = dir;
    });
  }


  Widget manual_dosing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: TextField(
            controller: insta_dose_amount_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),
        const Text("ml"),
        SizedBox(width: 20),
        FilledButton(
          onPressed: (){},
          child: const Text("Dose"),
        ),
      ]
    );

  }

  Widget calibration_dose() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        FilledButton(
          onPressed: (){},
          child: const Text("10 ml calibration dose"),
        ),
      ]
    );
  }

  Widget actual_calibration_amount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        Text("measured:"),
        SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: TextField(
            controller: actual_calibration_dose_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),
        Text("ml"),
        SizedBox(width: 20),
        FilledButton(
          onPressed: (){},
          child: const Text("Update Calibration"),
        ),
      ]
    );
  }
  
  Widget dose_sched_selector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: TextField(
            controller: dose_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),

        const Text("ml every"),

        SizedBox(
          width: 100,
          child: TextField(
            controller: seconds_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
          ),
        ),

        const Text("seconds"),
      ],
    );
  }

  Future<void> commit_changes() async {
    //await widget.ble.commit_changes(widget.device);

    // Whatever you want to do after the device confirms it.
  }

  Widget schedule_type_drop() {
    return DropdownButton<ScheduleType>(
      value: _schedule_type,
      underline: const SizedBox(),
      items: const [ DropdownMenuItem(
          value: ScheduleType.periodic,
          child: Text("Periodic"),
        ),
        DropdownMenuItem(
          value: ScheduleType.daily,
          child: Text("Evenly throughout day"),
        ),
      ],
      onChanged: (value) { if (value != null) { setState(() { _schedule_type = value; }); } },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard_visible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: ListView(
        keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          device_hero(context),
          const SizedBox(height: 20), //padding
          // Configuration UI will eventually go here
          if((connected != null && connected!) || TEST_FLAG) ...[
            section_header("Settings"),
            setting_row("Direction", Switch(value: direction, onChanged: (value)=>direction_changed(value)), 3, 7),
            setting_row("Schedule", schedule_type_drop(), 3, 7, bottom_padding: 0),
            setting_row(null, dose_sched_selector(), 3, 7, top_padding: 0),
            section_header("Tools"),
            setting_row("Manual Dosing", manual_dosing(), 5, 5),
            setting_row("Calibration", calibration_dose(), 5, 5, bottom_padding: 0),
            setting_row(null, actual_calibration_amount(), 5, 5, top_padding: 0),

          ]
        ],
      ),

      floatingActionButton: keyboard_visible
      ? FloatingActionButton(
        onPressed: commit_changes,
        child: const Icon(Icons.save),
      )
      : FloatingActionButton.extended(
        onPressed: commit_changes,
        label: widget.theme.subtitle_text("Save changes"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Expanded info_col(){
    return Expanded(
      flex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.theme.title_text(widget.device.name),
          const SizedBox(height: 8),
          widget.theme.small_text(widget.device.uuid),
          const SizedBox(height: 12),
          connection_status(),
        ],
      ),
    );
  }

  Expanded icon_col(){
    return Expanded(
      flex: 4,
      child: Center(
        child: SizedBox(
          width: 90,
          height: 90,
          child: Image.asset(
            'assets/doser_clipaart.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  //this has GOT to be factored down. This language is hell
  Widget device_hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 5,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          icon_col(),
          info_col(),
        ],
      ),
    );
  }

  Widget section_header(String text) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 20,
        bottom: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget setting_row(String? name, Widget? setting, int width1, int width2, {double top_padding = 14, double bottom_padding = 14}){
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: top_padding,
        bottom: bottom_padding,
      ),
      child: Row(
        children: [
          if (name != null)
          Expanded(
            flex: width1,
            child: widget.theme.subtitle_text(name),
          ),
          if (setting != null)
          Expanded(
            flex: width2,
            child: Align(
              alignment: Alignment.centerRight,
              child: setting,
            ),
          ),
        ],
      ),
    );
  }

//  Widget setting_row(String name, Widget setting, int width1, int width2){
//    return Padding(
//      padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 14,),
//      child: Row(
//        children: [
//          Expanded( flex: width1, child: widget.theme.subtitle_text(name),),
//          Expanded(
//            flex: width2,
//            child: Align( alignment: Alignment.centerRight, child: setting,),
//          ),
//        ],
//      ),
//    );
//  }
//
}
