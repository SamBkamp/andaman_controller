import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';
import 'theme_data.dart';
import 'schedule.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'TimedSchedulePage.dart';

class DoserPage extends StatefulWidget {
  final DoserDevice device;
  final Ble_manager blemanager;
  final DeviceRegistry registry;
  final Theme_data theme = const Theme_data();

  const DoserPage({
      super.key,
      required this.device,
      required this.blemanager,
      required this.registry,
  });

  @override
  State<DoserPage> createState() => _DoserPageState();
}


class _DoserPageState extends State<DoserPage> {
  Schedule dose_sched = Schedule(ScheduleType.periodic, "0", period: "10");
  bool? connected;
  bool direction = false;
  bool TEST_FLAG = true;
  final dose_controller = TextEditingController();
//  final seconds_controller = TextEditingController();
  final insta_dose_amount_controller = TextEditingController();
  final actual_calibration_dose_controller = TextEditingController();
  final rename_device_controller = TextEditingController();
  int selected_hours = 0;
  int selected_minutes = 0;
  int selected_seconds = 0;
  late FixedExtentScrollController hours_controller;
  late FixedExtentScrollController minutes_controller;
  late FixedExtentScrollController seconds_controller;
  bool save_success = false;
  StreamSubscription<bool>? connection_sub;


  @override
  void initState() {
    super.initState();

    hours_controller = FixedExtentScrollController(initialItem: 0);
    minutes_controller = FixedExtentScrollController(initialItem: 0);
    seconds_controller = FixedExtentScrollController(initialItem: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
        connect_device();
    });
  }

  @override
  void dispose() {
    dose_controller.dispose();
    hours_controller.dispose();
    minutes_controller.dispose();
    seconds_controller.dispose();
    insta_dose_amount_controller.dispose();
    actual_calibration_dose_controller.dispose();
    rename_device_controller.dispose();
    connection_sub?.cancel();
    super.dispose();
  }


  Future<void> connect_device() async {
    rename_device_controller.text = widget.device.name;
    final result = await widget.blemanager.connect_to_device(widget.device);
    final newDir = await widget.blemanager.getDirection(widget.device);
    Schedule sched = await widget.blemanager.getSchedule(widget.device);
    await widget.blemanager.setSysTime(widget.device);
    int? period_seconds = int.tryParse(sched.period);

    print("CONNECTION STATUS: $result");

    if (!mounted) return;
    if(!result){
      setState((){connected = result;});
      return;
    }

    connection_sub = widget.blemanager.connection_state.listen((connected_stat) {
        if (!mounted) return;

        setState(() {
            connected = connected_stat;
        });
    });

    setState(() {
        connected = result;
        direction = newDir;
        dose_sched = sched;
        dose_controller.text = sched.ml;
        //seconds_controller.text = sched.period;
        if(period_seconds != null){
          selected_hours = period_seconds ~/ 3600;
          selected_minutes = (period_seconds % 3600) ~/ 60;
          selected_seconds = period_seconds % 60;
        }
    });
    if (period_seconds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          hours_controller.jumpToItem(selected_hours);
          minutes_controller.jumpToItem(selected_minutes);
          seconds_controller.jumpToItem(selected_seconds);
      });

  }


  Widget connection_status() {
    String text = "Disconnected";
    Color colour =  Theme.of(context).colorScheme.error;
    if (connected == null) {
      text = "Connecting...";
      colour = Color.fromRGBO(0xFD, 0xCA, 0x40, 1.0);
    } else if (connected!) {
      text = "Connected";
      colour = Color.fromRGBO(0xDA, 0xFF, 0x7D, 1.0);
    }
    return widget.theme.small_text_bold(text, colour: colour);
  }


  void direction_changed(dir){
    setState(() {
        direction = dir;
    });
    widget.blemanager.setDirection(widget.device, dir);
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
        SizedBox(width: 50),
        FilledButton(
          onPressed: (){
            widget.blemanager.manual_dose(widget.device, insta_dose_amount_controller.text);
          },
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
          onPressed: (){widget.blemanager.manual_dose(widget.device, "10");},
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
          onPressed: (){widget.blemanager.setAutocal(widget.device, actual_calibration_dose_controller.text);},
          child: const Text("Update Calibration"),
        ),
      ]
    );
  }

  Widget time_picker_column({
      required int value,
      required int max_value,
      required FixedExtentScrollController controller,
      required ValueChanged<int> on_changed,
  }) {
    return SizedBox(
      height: 120,
      width: 65,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        physics: const FixedExtentScrollPhysics(),
        controller: controller,
        onSelectedItemChanged: on_changed,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max_value + 1,
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 20),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget dose_sched_selector() {
    print("INSIDE DOSE_SCHED_SEL: $selected_hours : $selected_minutes : $selected_seconds");
    print("type: ${ScheduleType}");
    if(dose_sched?.type == ScheduleType.periodic){
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: TextField(
              controller: dose_controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: true,),
            ),
          ),

          const Text("ml every"),


          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              time_picker_column(
                value: selected_hours,
                max_value: 99,
                controller: hours_controller,
                on_changed: (value) {
                  setState(() => selected_hours = value);
                  print("Hi");
                },
              ),
              const Text(":"),
              time_picker_column(
                value: selected_minutes,
                max_value: 59,
                controller: minutes_controller,
                on_changed: (value) {
                  setState(() => selected_minutes = value);
                },
              ),
              const Text(":"),
              time_picker_column(
                value: selected_seconds,
                max_value: 59,
                controller: seconds_controller,
                on_changed: (value) {
                  setState(() => selected_seconds = value);
                },
              ),
            ],
          )
        ],
      );
    } else{
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimedSchedulePage(device: widget.device,
                theme: widget.theme,
                sched: dose_sched,
              ),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: const Text("Edit schedule →"),
      );
    }
  }

  Future<void> commit_changes() async {
    if(dose_sched == null) return;

    dose_sched!.ml = dose_controller.text;
    if(dose_sched!.type == ScheduleType.periodic){
      dose_sched!.period = (selected_hours*3600 + selected_minutes * 60 + selected_seconds).toString();
      String help = dose_sched!.period;
      print("calculated period: $help");
    }


    await widget.blemanager.setSchedule(widget.device, dose_sched!);


    //flash button green
    setState(() {
        save_success = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
        save_success = false;
    });
    if (!mounted) return;
  }

  Widget schedule_type_drop() {
    return DropdownButton<ScheduleType>(
      value: (dose_sched == null ? ScheduleType.periodic : dose_sched!.type),
      underline: const SizedBox(),
      items: const [ DropdownMenuItem(
          value: ScheduleType.periodic,
          child: Text("Periodic"),
        ),
        DropdownMenuItem(
          value: ScheduleType.timed,
          child: Text("Timed"),
        ),
      ],
      onChanged: (value) { if (value != null) { setState(() { dose_sched!.type = value; }); } },
      //onChanged: (value) {  setState(() { dose_sched!.type = value; }); },
    );
  }

  Widget save_settings() {
    Color button_color = save_success ? Colors.green : Theme.of(context).colorScheme.primary;
    Color text_color = save_success ? Colors.white : Theme.of(context).colorScheme.onPrimary;
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: button_color),
      onPressed: commit_changes,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          Icon(Icons.save, color: text_color),
          SizedBox(width: 10),
          Text( "Save changes", style: TextStyle(color: text_color),),
        ],
      ),
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
          if((connected != null && connected!) || TEST_FLAG) ...[
            section_header("Settings"),
            setting_row("Direction", Switch(value: direction, onChanged: (value)=>direction_changed(value)), 3, 7),
            setting_row("Schedule", schedule_type_drop(), 3, 7, bottom_padding: 0),
            setting_row(null, dose_sched_selector(), 1, 9, top_padding: 0),
            setting_row(null, save_settings(), 1, 9, top_padding: 0),
            section_header("Tools"),
            setting_row("Manual Dosing", manual_dosing(), 5, 5),
            setting_row("Calibration", calibration_dose(), 4, 6, bottom_padding: 0),
            setting_row(null, actual_calibration_amount(), 5, 5, top_padding: 0),

          ]
          else if(connected == null) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> save_name(BuildContext dialog_context) async {
    if (dialog_context.mounted) {
      Navigator.pop(dialog_context, rename_device_controller.text.trim());
    }
    widget.blemanager.setNewName(widget.device, rename_device_controller.text);
    widget.registry.update_name(widget.device, rename_device_controller.text);
    //widget.device.name = rename_device_controller.text;
  }


  Future<void> rename_device(BuildContext context) async {

    final new_name = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialog_context) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: rename_device_controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Device name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog_context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            //TODO: make the onpressed also commit it to BLE
            onPressed: () => save_name(dialog_context),
            child: const Text('Save'),
           ),
        ],
      ),
    );
  }



  IconButton edit_name_button() {
    return IconButton(
      onPressed: () => rename_device(context),
      icon: const Icon(Icons.edit_outlined),
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }

  Expanded info_col() {
    return Expanded(
      flex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: widget.theme.title_text(widget.device.name),
                ),
              ),
              const SizedBox(width: 2),
              edit_name_button(),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: widget.theme.small_text(widget.device.uuid),
            ),
          ),
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
}
